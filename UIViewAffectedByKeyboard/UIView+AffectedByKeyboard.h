//
//  UIView+AffectedByKeyboard.h
//  UIViewAffectedByKeyboard
//
//  Created by guanglong on 2017/9/22.
//  Copyright © 2017年 lgl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (AffectedByKeyboard)

@property (nonatomic, assign) BOOL kbAffect_on;

@property (nonatomic, assign) CGFloat kbAffect_adjustHeight;

- (void)kbAffect_resetIfNeeded;

@end
