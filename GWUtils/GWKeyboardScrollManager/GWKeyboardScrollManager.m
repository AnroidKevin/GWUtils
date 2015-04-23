//
//  GWKeyboardScrollManager.m
//  GWUtils
//
//  Created by huangqisheng on 14/12/29.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "GWKeyboardScrollManager.h"

@implementation GWKeyboardScrollManager {
    
    BOOL _isScrolledToShow;
    
    // 当前键盘高度
    CGFloat _currentKeyboardHeight;
    // 动画时长，来自于键盘的动画时长，默认0.25
    CGFloat _animationDuration;
    // 动画曲线，默认UIViewAnimationCurveLinear
    UIViewAnimationCurve _animationCurve;
    
    // 绝对滑动距离，既所有滑动的距离总和
    CGFloat _absolutelyScrollDistance;
    // 本次需要滑动的距离
    CGFloat _currentScrollDistance;
    
    // 当前需要始终显示的视图
    __weak UIView *_currentFirstResponder;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithScrollRootView:(UIView *)scrollRootView
                         scrollingView:(UIView *)scrollingView {
    
    if (self = [super init]) {
        
        _scrollRootView = scrollRootView;
        _scrollingView = scrollingView;
        _scrollMargin = 20.f;
        _animationCurve = UIViewAnimationCurveLinear;
        _animationDuration = 0.25;
        
        // 键盘高度默认值
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            _currentKeyboardHeight = 406;
        } else {
            
            if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _currentKeyboardHeight = 198;
            } else {
                _currentKeyboardHeight = 253;
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardFrameWillChange:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
        
        [self setUsingKeyboardWillHideNotificationToDismissKeyboard:YES];
    }
    return self;
}

- (instancetype)init {
    
    NSAssert(0, @"Please use initWithScrollRootView:scrollingView:");
    return nil;
}

- (void)setUsingKeyboardWillHideNotificationToDismissKeyboard:(BOOL)usingKeyboardWillHideNotificationToDismissKeyboard {
    
    if (!_usingKeyboardWillHideNotificationToDismissKeyboard
        && usingKeyboardWillHideNotificationToDismissKeyboard) {
        
        // 注册键盘消失事件
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHideNotice:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        _usingKeyboardWillHideNotificationToDismissKeyboard = usingKeyboardWillHideNotificationToDismissKeyboard;
    } else if (_usingKeyboardWillHideNotificationToDismissKeyboard
               && !usingKeyboardWillHideNotificationToDismissKeyboard) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIKeyboardWillHideNotification
                                                      object:nil];
        _usingKeyboardWillHideNotificationToDismissKeyboard = usingKeyboardWillHideNotificationToDismissKeyboard;
    }
}

#pragma mark - scroll view while keyboard show or hide
- (void)keyboardWillShowWithFirstResponder:(UIView *)firstResponder
                                scrollView:(UIView *)scrollView
                                  animated:(BOOL)animated {
    NSAssert(_scrollRootView != nil, @"scrollRootView cannot be nil");
    
    // 首先让原来滑动的视图恢复
    if (scrollView != _scrollingView) {
        
        [self keyboardWillDismissAnimated:NO];
    }
    _isScrolledToShow = YES;
    _currentFirstResponder = firstResponder;
    
    // 计算滑动的绝对高度和本次滑动的高度
    [self resetScrollDistanceWithFirstResponder:firstResponder];
    
    if (_currentScrollDistance == 0) {
        
        return;
    }
    // 滑动视图
    if (animated) {
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:_animationDuration];
        [UIView setAnimationCurve:_animationCurve];
    }
    CGRect scrollingFrame = _scrollingView.frame;
    scrollingFrame.origin.y += _currentScrollDistance;
    _scrollingView.frame = scrollingFrame;
    if (animated) {
        
        [UIView commitAnimations];
    }
}

- (void)keyboardWillShowWithFirstResponder:(UIView *)firstResponder
                                  animated:(BOOL)animated {
    NSAssert(_scrollingView != nil, @"scrollingView cannot be nil when using this method");
    
    _isScrolledToShow = YES;
    
    [self keyboardWillShowWithFirstResponder:firstResponder
                                  scrollView:self.scrollingView
                                    animated:animated];
}

- (void)keyboardWillDismissAnimated:(BOOL)animated {
    
    if (!_isScrolledToShow) {
        
        return;
    }
    
    // 滑动视图
    if (animated) {
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:_animationDuration];
        [UIView setAnimationCurve:_animationCurve];
    }
    CGRect scrollingFrame = _scrollingView.frame;
    scrollingFrame.origin.y -= _absolutelyScrollDistance;
    _scrollingView.frame = scrollingFrame;
    if (animated) {
        
        [UIView commitAnimations];
    }
    
    // 重置
    _isScrolledToShow = NO;
    _absolutelyScrollDistance = 0.f;
    _currentScrollDistance = 0.f;
}

#pragma mark - private
- (void)resetScrollDistanceWithFirstResponder:(UIView *)firstResponder {
    
    CGRect rectInRootView = [firstResponder convertRect:firstResponder.bounds
                                                 toView:self.scrollRootView];
    
    // 取最小margin，防止当firstResponder在scrollingView底部时，键盘上方出现黑条
    CGFloat tmpScrollMargin = MIN(_scrollMargin, self.scrollRootView.frame.size.height - CGRectGetMaxY(rectInRootView));
    
    CGFloat estimatedScrollDistance = self.scrollRootView.frame.size.height - _currentKeyboardHeight - CGRectGetMaxY(rectInRootView) - tmpScrollMargin;
    CGFloat originAbsolutelyDistance = _absolutelyScrollDistance;
    
    _currentScrollDistance = estimatedScrollDistance;
    _absolutelyScrollDistance += estimatedScrollDistance;
    
    // 上滑距离之后，firstResponder的顶部不能超出rootScrollView的顶部或屏幕的顶部
    if (_absolutelyScrollDistance < 0
        && ABS(_absolutelyScrollDistance) > rectInRootView.origin.y) {
        
        _currentScrollDistance = -rectInRootView.origin.y + _scrollMargin - _absolutelyScrollDistance;
        _absolutelyScrollDistance = -rectInRootView.origin.y + _scrollMargin;
    }
    // 如果累积滑动大于0，则恢复原视图
    if (_absolutelyScrollDistance > 0) {
        
        _currentScrollDistance = -originAbsolutelyDistance;
        _absolutelyScrollDistance = 0.f;
    }
}

// 键盘高度改变，调整滑动距离
- (void)keyboardHeightWillChangeFrom:(CGFloat)originKeyboardHeight
                                  to:(CGFloat)toKeyboardHeight {
    
    _currentKeyboardHeight = toKeyboardHeight;
    [self keyboardWillShowWithFirstResponder:_currentFirstResponder
                                    animated:YES];
}

#pragma mark - notice
- (void)keyboardWillHideNotice:(NSNotification *)notice {
    
    if (_usingKeyboardWillHideNotificationToDismissKeyboard) {
        
        [self keyboardWillDismissAnimated:YES];
    }
}

// 重置键盘高度和动画相关信息
- (void)keyboardFrameWillChange:(NSNotification *)notice {
    
    CGRect keyboardEndRect = [[notice.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardAnimationDuration = [[notice.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve animationCurve = [[notice.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    _animationDuration = keyboardAnimationDuration;
    _animationCurve = animationCurve;
    
    if (keyboardEndRect.size.height != _currentKeyboardHeight) {
        
        CGFloat originKeyboardHeight = _currentKeyboardHeight;
        _currentKeyboardHeight = keyboardEndRect.size.height;
        
        if (_isScrolledToShow) {
            
            [self keyboardHeightWillChangeFrom:originKeyboardHeight
                                            to:_currentKeyboardHeight];
        }
    }
}

@end
