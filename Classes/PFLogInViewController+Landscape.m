//
//  PFLogInViewController+Landscape.m
//  FlashCardCreator
//
//  Created by Internetics on 17/10/2015.
//  Copyright © 2015 Internetics. All rights reserved.
//

#import "PFLogInViewController+Landscape.h"
#import <objc/runtime.h>

static char const * const ObjectTagKey = "ObjectTag";
@implementation PFLogInViewController (Landscape)

- (void) setFromSetting:(BOOL)fromSetting
{
    NSNumber *number = [NSNumber numberWithBool: fromSetting];
    objc_setAssociatedObject(self, ObjectTagKey, number , OBJC_ASSOCIATION_RETAIN);
}

- (BOOL) fromSetting
{
    NSNumber *number = objc_getAssociatedObject(self, ObjectTagKey);
    return [number boolValue];
}

#pragma mark – Rotation Control

//>= ios6  支持的屏幕旋转方向
-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

//>= ios6  是否支持屏幕旋转
-(BOOL)shouldAutorotate {
    return YES;
    
}

//>= ios6 一开始的屏幕旋转方向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeLeft;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"user_auth"]]];
    [[self.logInView logo] setContentMode:UIViewContentModeScaleAspectFit];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.logInView.signUpButton setTitle:@"Create account" forState:UIControlStateNormal];
}


@end
