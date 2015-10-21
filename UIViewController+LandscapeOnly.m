//
//  UIViewController+LandscapeOnly.m
//  FFC
//
//  Created by Bourne Wang on 7/28/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "UIViewController+LandscapeOnly.h"

@implementation UIViewController (LandscapeOnly)

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}


-(BOOL)shouldAutorotate {
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end
