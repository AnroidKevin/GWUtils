//
//  GWKeyboardScrollManager.h
//  GWUtils
//
//  Created by huangqisheng on 14/12/29.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GWKeyboardScrollManager : NSObject

// 以此视图作为参照，计算应该滑动的距离，此视图尽力设置为占满全屏的视图。
// 并且滑动视图和firstresponder应该包含在此视图的子视图树中
@property (nonatomic, weak, readonly) UIView *scrollRootView;

// 键盘显示时，默认滑动此视图，不可为空
@property (nonatomic, weak, readonly) UIView *scrollingView;

// 滑动视图滑动后，下边距与键盘的距离。默认为20个点
@property (nonatomic, assign) CGFloat scrollMargin;

// 是否使用UIKeyboardWillHideNotification消息来控制键盘的隐藏。默认为YES
// YES为是，不需要在调用keyboardWillDismissAnimated:方法;
// NO为否，如果需要消失键盘的时候滑动视图，必须调用keyboardWillDismissAnimated:
@property (nonatomic, assign) BOOL usingKeyboardWillHideNotificationToDismissKeyboard;

/**
 *  @brief  初始化方法
 *
 *  @param scrollRootView 计算滑动距离的参照视图，不可为空
 *  @param scrollingView  键盘显示消失时，滑动此视图，不可为空
 *
 *  @return instance
 */
- (instancetype)initWithScrollRootView:(UIView *)scrollRootView
                         scrollingView:(UIView *)scrollingView;

/**
 *  @brief  键盘显示，可调用此方法，来滑动视图，以便让预期的视图不被键盘遮住。
 *
 *  @param firstResponder 预期不能被遮住的视图
 *  @param animated       滑动试图时，是否使用动画
 */
- (void)keyboardWillShowWithFirstResponder:(UIView *)firstResponder
                                  animated:(BOOL)animated;

/**
 *  @brief  键盘消失时，调用此方法，让滑动后的视图恢复到滑动前的位置。
 *          建议使用usingKeyboardWillHideNotificationToDismissKeyboard来控制消失滑动
 *
 *  @param animated 滑动试图时，是否使用动画
 */
- (void)keyboardWillDismissAnimated:(BOOL)animated;

@end
