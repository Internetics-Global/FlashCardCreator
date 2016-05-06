//
//  MutipleTargetHelper.m
//  FlashCardCreator
//
//  Created by Internetics on 6/05/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "MutipleTargetHelper.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>

@implementation MutipleTargetHelper

+ (BOOL) isFullVersion {
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:@"K_Full_Version_Flag"];
    return val;
    
}

+ (void) setFullVersionFlag:(BOOL) flag  {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:flag  forKey:@"K_Full_Version_Flag"];
    [defaults synchronize];
    
}

+ (void) showAlertToUpgradeToFullVersion {
    
    
    [UIAlertView bk_showAlertViewWithTitle:@"This is a FlipFashCard PRO function" message:@"You can upgrade the app to get it!" cancelButtonTitle:@"Not yet" otherButtonTitles:@[@"More details"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
        if (buttonIndex == 0) {
            //cancel button
            
        } else if (buttonIndex == 1) {
            //update logic here
            
        }
        
    }];
    
}

@end
