//
//  PFLogInViewController+Landscape.m
//  FlashCardCreator
//
//  Created by Internetics on 17/10/2015.
//  Copyright © 2015 Internetics. All rights reserved.
//

#import "PFLogInViewController+Landscape.h"

@implementation PFLogInViewController (Landscape)

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

// automatically called just before viewDidAppear and after viewWillAppear
- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.logInView.signUpButton setTitle:NSLocalizedString(@"Title_Create_Account",@"") forState:UIControlStateNormal];
}


@end
