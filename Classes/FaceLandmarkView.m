//
//  FaceLandmarkView.m
//  FaceSecret
//
//  Created by 刘鹏i on 2019/6/12.
//  Copyright © 2019 musjoy. All rights reserved.
//

#import "FaceLandmarkView.h"

@interface FaceLandmarkView () <CAAnimationDelegate>
@property (nonatomic, strong) NSLayoutConstraint *lytProportion;
@property (nonatomic, copy) OnceAnimationCompletion onceBlock;
@property (nonatomic, copy) CyclicAnimationCompletion cyclicBlock;
@end

@implementation FaceLandmarkView
#pragma mark - Life CYcle
+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self viewConfig];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self viewConfig];
}

#pragma mark - Subjoin
- (void)viewConfig
{
    
}

- (CAShapeLayer *)pointLayer
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = self.layer.bounds;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.fillColor = [[UIColor clearColor] CGColor];
    layer.lineWidth = 2;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    return layer;
}

/// 脸部虚线layer
- (CAShapeLayer *)lineDashLayer
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = self.layer.bounds;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.fillColor = [[UIColor clearColor] CGColor];
    layer.lineWidth = 0.5;
    layer.lineDashPattern = @[@(2), @(5)];
    layer.lineDashPhase = 1;
    return layer;
}

/// 脸部轮廓layer
- (CAShapeLayer *)contourLayer
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = self.layer.bounds;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.fillColor = [[UIColor clearColor] CGColor];
    layer.lineWidth = 1;
    layer.lineDashPattern = @[@(1), @(1)];
    layer.lineDashPhase = 1;
    return layer;
}

#pragma mark - Set
- (void)setImage:(UIImage *)image
{
    _image = image;
    
    if (_lytProportion) {
        // 移除之前的约束
        [self removeConstraint:_lytProportion];
        _lytProportion = nil;
    }
    // 创建约束
    CGFloat multiplier = image.size.width / image.size.height;
    
    _lytProportion = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:multiplier constant:0];
    _lytProportion.priority = 1000.0;
    // 添加约束
    [self addConstraint:_lytProportion];
    
    [self.superview layoutIfNeeded];
}

- (void)setScanningPoint:(NSArray *)scanningPoint
{
    _scanningPoint = [self convertPoints:scanningPoint];
}

- (void)setContourPoint:(NSArray *)contourPoint
{
    _contourPoint = [self convertPoints:contourPoint];
}

/// 转换坐标
- (NSArray *)convertPoints:(NSArray *)array
{
    NSMutableArray *muarr = [NSMutableArray arrayWithCapacity:array.count];
    for (NSValue *value in array) {
        CGPoint point = [value CGPointValue];
        CGPoint convertPoint = CGPointMake(point.x / _image.scale / _image.size.width * self.bounds.size.width, point.y / _image.scale / _image.size.height * self.bounds.size.height);
        [muarr addObject:[NSValue valueWithCGPoint:convertPoint]];
    }
    return [muarr copy];
}

#pragma mark - Public
- (void)drawAllPoints
{
    // 描点动画
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (NSValue *value in _scanningPoint) {
        CGPoint point = [value CGPointValue];
        UIBezierPath *subPath = [UIBezierPath bezierPathWithArcCenter:point radius:1.0 startAngle:0 endAngle:2 * M_PI clockwise:YES];
        [path appendPath:subPath];
    }
    
    CAShapeLayer *layer = [self pointLayer];
    layer.path = path.CGPath;
    [self.layer addSublayer:layer];
    
    // 连虚线
    UIBezierPath *lineDashPath = [UIBezierPath bezierPath];
    
    
    CAShapeLayer *lineDashLayer = [self lineDashLayer];
    lineDashLayer.path = path.CGPath;
    [self.layer addSublayer:lineDashLayer];
}

- (void)endAnimation
{
    _onceBlock = nil;
    _cyclicBlock = nil;
    
    [self clearAnimationLayer];
}

#pragma mark - Private
- (void)clearAnimationLayer
{
    NSArray *subLayers = [self.layer.sublayers copy];;
    for (CALayer *layer in subLayers) {
        [layer removeAllAnimations];
        [layer removeFromSuperlayer];
    }
}

#pragma mark - Animation
- (void)startAnimationWithCompletion:(void(^)(void))completion;
{
    if (_scanningPoint.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }
    
    _onceBlock = completion;
    
    [self animationLandmarkPoint];
}

/// 循环动画
- (void)startCyclicAnimationWithCompletion:(CyclicAnimationCompletion)completion
{
    if (_scanningPoint.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }
    
    _cyclicBlock = completion;
    
    [self animationLandmarkPoint];
}

/// 描点动画
- (void)animationLandmarkPoint
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (NSValue *value in _scanningPoint) {
        CGPoint point = [value CGPointValue];
        UIBezierPath *subPath = [UIBezierPath bezierPathWithArcCenter:point radius:1.0 startAngle:0 endAngle:2 * M_PI clockwise:YES];
        [path appendPath:subPath];
    }
    
    CAShapeLayer *layer = [self pointLayer];
    layer.path = path.CGPath;
    [self.layer addSublayer:layer];
    [self startAnimation:@"animationLandmarkPoint" layer:layer duration:0.8];
}

/// 轮廓动画
- (void)animationContour:(BOOL)isRight
{
    NSArray *points = nil;
    if (isRight) {
        NSArray *array1 = [_contourPoint subarrayWithRange:NSMakeRange(17, 16)];
        points = [array1 arrayByAddingObject:_contourPoint[16]];
    } else {
        points = [_contourPoint subarrayWithRange:NSMakeRange(0, 17)];
    }
    
    UIBezierPath *path = [UIBezierPath bezierPath];

    // 额头点
    CGPoint forehead = [_scanningPoint.firstObject CGPointValue];
    [path moveToPoint:forehead];
    
    // 面部左边点
    CGPoint left = [_contourPoint[0] CGPointValue];
    // 面部右边点
    CGPoint right = [_contourPoint[17] CGPointValue];
    // 左右斜线的中心点，与额头点平行
    CGPoint center = CGPointMake(left.x + (right.x - left.x) / 2.0, left.y + (right.y - left.y) / 2.0);

    // 左边控制点
    CGPoint leftControl = CGPointMake(left.x + (forehead.x - center.x), left.y - (center.y - forehead.y));
    CGPoint rightControl = CGPointMake(right.x + (forehead.x - center.x), right.y - (center.y - forehead.y));
    
//    CGPoint leftControl = CGPointMake(forehead.x - (forehead.x - left.x) * 0.9, left.y - (center.y - forehead.y) - (right.y - left.y) * 0.2);
//    CGPoint rightControl = CGPointMake(forehead.x + (right.x - forehead.x) * 0.9, right.y - (center.y - forehead.y) - (right.y - left.y) * 0.2);
    
    CGPoint control = isRight? rightControl: leftControl;
    [path addQuadCurveToPoint:[points.firstObject CGPointValue] controlPoint:control];
    
    for (NSInteger i = 0; i < points.count; i++) {
        CGPoint point = [points[i] CGPointValue];
        if (i != 0) {
            [path addLineToPoint:point];
        }
    }

    NSString *name = isRight? @"animationContourRight": @"animationContourLeft";
    
    CAShapeLayer *layer = [self contourLayer];
    layer.path = path.CGPath;
    [self.layer addSublayer:layer];
    [self startAnimation:name layer:layer duration:1.2];
}

/// 开始虚线动画
- (void)startLineDashAnimation:(NSString *)name order:(NSArray<NSNumber *> *)order duration:(CGFloat)duration
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    for (NSInteger i = 0; i < order.count; i++) {
        NSInteger index = [order[i] integerValue];
        CGPoint point = [_scanningPoint[index] CGPointValue];
        if (i == 0) {
            [path moveToPoint:point];
        } else {
            [path addLineToPoint:point];
        }
    }
 
    CAShapeLayer *layer = [self lineDashLayer];
    layer.path = path.CGPath;
    [self.layer addSublayer:layer];
    [self startAnimation:name layer:layer duration:duration];
}

/// 开始动画
- (void)startAnimation:(NSString *)name layer:(CALayer *)layer duration:(CGFloat)duration
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = duration;
    animation.repeatCount = 1;
    animation.removedOnCompletion = NO;
    animation.fromValue = [NSNumber numberWithFloat:0.0f];
    animation.toValue = [NSNumber numberWithFloat:1.0f];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    animation.delegate = self;
    [animation setValue:name forKey:@"AnimationName"];
    [layer addAnimation:animation forKey:nil];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSString *name = [anim valueForKey:@"AnimationName"];
    
    // 第二步
    if ([name isEqualToString:@"animationLandmarkPoint"]) {
        [self startLineDashAnimation:@"animationNoseLeft1" order:@[@(11), @(12)] duration:0.5];
        [self startLineDashAnimation:@"animationNoseLeft2" order:@[@(11), @(14), @(18)] duration:0.8];
        [self startLineDashAnimation:@"animationNoseLeft3" order:@[@(11), @(7), @(0)] duration:0.8];
        
        [self startLineDashAnimation:@"animationNoseRight1" order:@[@(13), @(12)] duration:0.5];
        [self startLineDashAnimation:@"animationNoseRight2" order:@[@(13), @(16), @(19)] duration:0.8];
        [self startLineDashAnimation:@"animationNoseRight3" order:@[@(13), @(8), @(0)] duration:0.8];
    }
    
    // 第三步
    if ([name isEqualToString:@"animationNoseLeft2"]) {
        [self startLineDashAnimation:@"animationForehead1" order:@[@(0), @(1), @(5)] duration:0.8];
        [self startLineDashAnimation:@"animationLeftEye2" order:@[@(7), @(6), @(5)] duration:0.8];
        
        [self startLineDashAnimation:@"animationMouth1" order:@[@(16), @(15), @(14)] duration:0.6];
        [self startLineDashAnimation:@"animationMouth2" order:@[@(16), @(17), @(14)] duration:0.6];
    }
    
    if ([name isEqualToString:@"animationNoseRight2"]) {
        [self startLineDashAnimation:@"animationForehead2" order:@[@(0), @(2), @(10)] duration:0.8];
        [self startLineDashAnimation:@"animationRightEye2" order:@[@(8), @(9), @(10)] duration:0.8];
    }

    // 第四步
    if ([name isEqualToString:@"animationForehead1"]) {
        [self animationContour:NO];
        [self animationContour:YES];
    }
    
    // 动画结束，回调
    if ([name isEqualToString:@"animationContourRight"]) {
        if (_onceBlock) {
            _onceBlock();
            _onceBlock = nil;
        }
        
        if (_cyclicBlock) {
            BOOL repeat = _cyclicBlock();
            
            [self clearAnimationLayer];
            
            if (repeat == YES) {
                // 重复
                [self animationLandmarkPoint];
            } else {
                // 停止
                _cyclicBlock = nil;
            }
        }
    }
}


/*
扫描点在scanningPoint中的位置对照
 
0  @"forehead"
1  @"left_eyebrow_upper_middle",
2  @"right_eyebrow_upper_middle",
3  @"contour_left1",
4  @"contour_right1",
5  @"contour_left2",
6  @"left_eye_left_corner",
7  @"left_eye_right_corner",
8  @"right_eye_left_corner",
9  @"right_eye_right_corner",
10 @"contour_right2",
11 @"nose_left_contour3",
12 @"nose_tip",
13 @"nose_right_contour3",
14 @"mouth_left_corner",
15 @"mouth_upper_lip_top",
16 @"mouth_right_corner",
17 @"mouth_lower_lip_bottom",
18 @"contour_left12",
19 @"contour_right12",
20 @"contour_chin"
*/

@end

