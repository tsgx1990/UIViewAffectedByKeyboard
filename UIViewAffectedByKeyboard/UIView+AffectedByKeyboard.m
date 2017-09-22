//
//  UIView+AffectedByKeyboard.m
//  UIViewAffectedByKeyboard
//
//  Created by guanglong on 2017/9/22.
//  Copyright © 2017年 lgl. All rights reserved.
//

#import "UIView+AffectedByKeyboard.h"
#import <objc/runtime.h>


#define KBNOTI_MAX_KEYBOARD_HEIGHT      ([UIScreen mainScreen].bounds.size.height - 108)
#define KBNOTI_MAX_KEYBOARD_DURATION    0.3

static float kbnoti_keyboardHeight = 250;
static NSTimeInterval kbnoti_keyboardDuration = 0.25;
static UIViewAnimationCurve kbnoti_keyboardCurve = 0;

@protocol _UIView_AffectedByKeyboard_Proxy_Delegate <NSObject>

@optional
- (void)abkbProxy_keyboardWillShow:(NSNotification*)noti;
- (void)abkbProxy_keyboardWillHide:(NSNotification *)noti;
- (void)abkbProxy_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context;

@end

@class _UIView_AffectedByKeyboard_Proxy_;
@interface UIView () <_UIView_AffectedByKeyboard_Proxy_Delegate>

@property (nonatomic, strong) _UIView_AffectedByKeyboard_Proxy_ *_affectedByKeyboard_proxy;
@property (nonatomic, assign) CGFloat _affectedByKeyboard_BoundsOffsetY;

@end

#pragma mark - - _UIView_AffectedByKeyboard_Proxy_

@interface _UIView_AffectedByKeyboard_Proxy_ : NSObject

@property (nonatomic, assign) BOOL on;

@property (nonatomic, unsafe_unretained) UIView *view;

@property (nonatomic, weak) UIView<_UIView_AffectedByKeyboard_Proxy_Delegate> *delegate;

@property (nonatomic, readonly) NSArray *observedKeyPaths;

@end

@implementation _UIView_AffectedByKeyboard_Proxy_

- (void)setOn:(BOOL)on
{
    if (_on) {
        [self removeAllObservers];
    }
    _on = on;
    if (_on) {
        NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
        [notiCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [notiCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        for (NSString *keyPath in self.observedKeyPaths) {
            [self.view addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
        }
    }
}

- (void)keyboardWillShow:(NSNotification*)noti
{
    if ([self.delegate respondsToSelector:@selector(abkbProxy_keyboardWillShow:)]) {
        [self.delegate abkbProxy_keyboardWillShow:noti];
    }
    
    if (self.delegate.isFirstResponder) {
        
        CGRect keyboardFrame;
        NSTimeInterval animationDuration;
        UIViewAnimationCurve animationCurve;
        [[noti.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
        [[noti.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
        [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
        
        kbnoti_keyboardHeight = MAX(keyboardFrame.size.height, 100);
        float maxHeight = KBNOTI_MAX_KEYBOARD_HEIGHT;
        kbnoti_keyboardHeight = MIN(kbnoti_keyboardHeight, maxHeight);
        
        kbnoti_keyboardDuration = MAX(animationDuration, 0.1);
        NSTimeInterval maxDuration = KBNOTI_MAX_KEYBOARD_DURATION;
        kbnoti_keyboardDuration = MIN(kbnoti_keyboardDuration, maxDuration);
        
        kbnoti_keyboardCurve = animationCurve;
        
        [self handleKeyboardShowState:YES];
    }
}

- (void)keyboardWillHide:(NSNotification*)noti
{
    if ([self.delegate respondsToSelector:@selector(abkbProxy_keyboardWillHide:)]) {
        [self.delegate abkbProxy_keyboardWillHide:noti];
    }
    
    if (self.delegate.isFirstResponder) {
        [self handleKeyboardShowState:NO];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([self.delegate respondsToSelector:@selector(abkbProxy_observeValueForKeyPath:ofObject:change:context:)]) {
        [self.delegate abkbProxy_observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    if (self.delegate && self.delegate == object) {
        if ([self.observedKeyPaths containsObject:keyPath]) {
            [self handleKeyboardShowState:self.delegate.isFirstResponder];
        }
    }
}

- (void)handleKeyboardShowState:(BOOL)show
{
    UIView* controllerView = self.superControllerView;
    if (show) {
        float keyboardHeight = kbnoti_keyboardHeight + self.view.kbAffect_adjustHeight;
        CGRect newTFRect = [self.view convertRect:self.view.bounds toView:controllerView];
        // textField和键盘的距离
        CGFloat dist = controllerView.bounds.size.height - (keyboardHeight + CGRectGetMaxY(newTFRect));
        CGFloat offsetY = dist < 0 ? -dist : 0;
        [self animateWithAnimations:^{
            controllerView._affectedByKeyboard_BoundsOffsetY = offsetY;
        }];
    }
    else {
        [self animateWithAnimations:^{
            controllerView._affectedByKeyboard_BoundsOffsetY = 0;
        }];
    }
}

- (void)animateWithAnimations:(void(^)())animations
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kbnoti_keyboardDuration];
    [UIView setAnimationCurve:kbnoti_keyboardCurve];
    animations();
    [UIView commitAnimations];
}

- (UIView*)superControllerView
{
    UIView* superControllerView = nil;
    UIViewController* responder = (UIViewController*)self.view.nextResponder;
    do {
        if ([responder isKindOfClass:[UIViewController class]]) {
            superControllerView = responder.view;
            break;
        }
    } while ((responder = (UIViewController*)responder.nextResponder));
    return superControllerView;
}

- (NSArray *)observedKeyPaths
{
    return @[@"firstResponder", @"frame"];
}

- (void)removeAllObservers
{
    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [notiCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    for (NSString *keyPath in self.observedKeyPaths) {
        [self.view removeObserver:self forKeyPath:keyPath context:NULL];
    }
}

- (void)dealloc
{
    if (self.on) {
        [self removeAllObservers];
    }
}

@end

#pragma mark - - UIView (AffectedByKeyboard)

@implementation UIView (AffectedByKeyboard)

- (void)setKbAffect_on:(BOOL)kbAffect_on
{
    objc_setAssociatedObject(self, _cmd, @(kbAffect_on), OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (kbAffect_on && !self._affectedByKeyboard_proxy) {
        _UIView_AffectedByKeyboard_Proxy_ *proxy = [_UIView_AffectedByKeyboard_Proxy_ new];
        proxy.view = self;
        proxy.delegate = self;
        proxy.on = YES;
        self._affectedByKeyboard_proxy = proxy;
    }
    if (!kbAffect_on) {
        self._affectedByKeyboard_proxy = nil;
    }
}

- (BOOL)kbAffect_on
{
    return [objc_getAssociatedObject(self, @selector(setKbAffect_on:)) boolValue];
}

- (void)setKbAffect_adjustHeight:(CGFloat)kbAffect_adjustHeight
{
    objc_setAssociatedObject(self, _cmd, @(kbAffect_adjustHeight), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CGFloat)kbAffect_adjustHeight
{
    return [objc_getAssociatedObject(self, @selector(setKbAffect_adjustHeight:)) floatValue];
}

#pragma mark - - _UIView_AffectedByKeyboard_Proxy_Delegate
//- (void)abkbProxy_keyboardWillShow:(NSNotification *)noti
//{
//    [self pri_abkb_resetSubviewsProxyIfNeeded:^(UIView *subview) {
//        [subview._affectedByKeyboard_proxy keyboardWillShow:noti];
//    }];
//}
//
//- (void)abkbProxy_keyboardWillHide:(NSNotification *)noti
//{
//    [self pri_abkb_resetSubviewsProxyIfNeeded:^(UIView *subview) {
//        [subview._affectedByKeyboard_proxy keyboardWillHide:noti];
//    }];
//}

- (void)abkbProxy_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    [self pri_abkb_resetSubviewsProxyIfNeeded:^(UIView *subview) {
        [subview._affectedByKeyboard_proxy observeValueForKeyPath:keyPath ofObject:subview change:nil context:NULL];
    }];
}

- (void)pri_abkb_resetSubviewsProxyIfNeeded:(void(^)(UIView *subview))callback
{
    if (![self conformsToProtocol:@protocol(UITextInput)]) {
        
        for (UIView *subview in self.subviews) {
            if (!objc_getAssociatedObject(subview, @selector(setKbAffect_on:))) {
                subview.kbAffect_on = self.kbAffect_on;
                subview.kbAffect_adjustHeight = self.kbAffect_adjustHeight;
                callback(subview); // callback需要实现递归调用
            }
        }
    }
}

- (void)kbAffect_resetIfNeeded
{
    if (![self conformsToProtocol:@protocol(UITextInput)]) {
        for (UIView *subview in self.subviews) {
            subview.kbAffect_on = self.kbAffect_on;
            subview.kbAffect_adjustHeight = self.kbAffect_adjustHeight;
            [subview kbAffect_resetIfNeeded];
        }
    }
}

#pragma mark - - proxy
- (void)set_affectedByKeyboard_proxy:(_UIView_AffectedByKeyboard_Proxy_ *)_affectedByKeyboard_proxy
{
    objc_setAssociatedObject(self, _cmd, _affectedByKeyboard_proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_UIView_AffectedByKeyboard_Proxy_ *)_affectedByKeyboard_proxy
{
    return objc_getAssociatedObject(self, @selector(set_affectedByKeyboard_proxy:));
}

- (void)set_affectedByKeyboard_BoundsOffsetY:(CGFloat)_affectedByKeyboard_BoundsOffsetY
{
    CGRect selfBounds = self.bounds;
    selfBounds.origin.y -= (self._affectedByKeyboard_BoundsOffsetY - _affectedByKeyboard_BoundsOffsetY);
    self.bounds = selfBounds;
    objc_setAssociatedObject(self, _cmd, @(_affectedByKeyboard_BoundsOffsetY), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CGFloat)_affectedByKeyboard_BoundsOffsetY
{
    return [objc_getAssociatedObject(self, @selector(set_affectedByKeyboard_BoundsOffsetY:)) floatValue];
}

@end
