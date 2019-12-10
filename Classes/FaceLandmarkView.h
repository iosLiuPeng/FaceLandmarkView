//
//  FaceLandmarkView.h
//  FaceSecret
//
//  Created by 刘鹏i on 2019/6/12.
//  Copyright © 2019 musjoy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^OnceAnimationCompletion)(void);///< 单次动画结束回调
typedef BOOL(^CyclicAnimationCompletion)(void);///< 循环动画，每次动画结束时返回是否重新开始动画

@interface FaceLandmarkView : UIView
@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) NSArray *scanningPoint;
@property (nonatomic, strong) NSArray *contourPoint;

/// 单次动画
- (void)startAnimationWithCompletion:(OnceAnimationCompletion)completion;

/// 循环动画
- (void)startCyclicAnimationWithCompletion:(CyclicAnimationCompletion)completion;

- (void)endAnimation;
@end

NS_ASSUME_NONNULL_END
