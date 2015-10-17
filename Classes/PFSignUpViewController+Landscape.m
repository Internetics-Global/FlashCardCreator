//
//  PFSignUpViewController+Landscape.m
//  FlashCardCreator
//
//  Created by Internetics on 17/10/2015.
//  Copyright © 2015 Internetics. All rights reserved.
//

#import "PFSignUpViewController+Landscape.h"

@implementation PFSignUpViewController (Landscape)


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
    [self.signUpView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"user_auth"]]];
}

@end
