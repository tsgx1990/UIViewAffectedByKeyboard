//
//  ViewController.m
//  UIViewAffectedByKeyboard
//
//  Created by guanglong on 2017/9/22.
//  Copyright © 2017年 lgl. All rights reserved.
//

#import "ViewController.h"
#import "UIView+AffectedByKeyboard.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    UIView *subv = [[UIView alloc] initWithFrame:self.view.bounds];
    subv.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:subv];
    
    self.view.kbAffect_on = YES;
    self.view.kbAffect_adjustHeight = 20;
    
    CGFloat tfy = self.view.frame.size.height - 40;
    
    UITextField *tf0 = [[UITextField alloc] initWithFrame:CGRectMake(20, tfy, 100, 30)];
    tf0.borderStyle = UITextBorderStyleLine;
    tf0.placeholder = @"0";
    [self.view addSubview:tf0];
    
    UITextField *tf1 = [[UITextField alloc] initWithFrame:CGRectMake(20, tfy - 40, 100, 30)];
    tf1.kbAffect_on = NO;
    tf1.borderStyle = UITextBorderStyleLine;
    tf1.placeholder = @"1";
    [self.view addSubview:tf1];
    
    UITextField *tf2 = [[UITextField alloc] initWithFrame:CGRectMake(20, tfy - 80, 100, 30)];
    tf2.kbAffect_on = NO;
    tf2.borderStyle = UITextBorderStyleLine;
    tf2.placeholder = @"2";
    [subv addSubview:tf2];
    
    UITextField *tf3 = [[UITextField alloc] initWithFrame:CGRectMake(20, tfy - 120, 100, 30)];
    tf3.borderStyle = UITextBorderStyleLine;
    tf3.placeholder = @"3";
    [subv addSubview:tf3];
    
    UITextView *tv0 = [[UITextView alloc] initWithFrame:CGRectMake(20, tfy - 200, 200, 60)];
    tv0.backgroundColor = [UIColor orangeColor];
    tv0.text = @"hello";
    [subv addSubview:tv0];
    
//    [self.view kbAffect_resetIfNeeded];
//    tf1.kbAffect_on = YES;
//    tf1.kbAffect_adjustHeight = 80;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UITextField *tf33 = [[UITextField alloc] initWithFrame:CGRectMake(222, tfy - 180, 100, 30)];
        tf33.borderStyle = UITextBorderStyleLine;
        tf33.placeholder = @"33";
        [self.view addSubview:tf33];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self.view.window endEditing:YES];
}

@end
