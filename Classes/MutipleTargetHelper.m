//
//  MutipleTargetHelper.m
//  FlashCardCreator
//
//  Created by Internetics on 6/05/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "MutipleTargetHelper.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "PurchaseViewController.h"

#define K_Full_Version_Flag @"K_Full_Version_Flag"
#define K_No_Ad_Version_Flag @"K_No_Ad_Version_Flag"

@implementation MutipleTargetHelper


+ (BOOL) isFullVersion {
    
    return true;
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Full_Version_Flag];
    return val;
    
}


+ (void) setFullVersionFlag:(BOOL) flag  {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:flag  forKey:K_Full_Version_Flag];
    [defaults synchronize];
    
}


+ (BOOL) isNoAdVersion {
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_No_Ad_Version_Flag];
    return val;
    
}

+ (void) setNoAdVersionFlag:(BOOL) flag  {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:flag  forKey:K_No_Ad_Version_Flag];
    [defaults synchronize];
    
}

+ (void) showAlertToUpgradeToFullVersion {
    
    
    [UIAlertView bk_showAlertViewWithTitle:@"This is a FlipFlashCard PRO function" message:@"You can upgrade the app to get it!" cancelButtonTitle:@"Not yet" otherButtonTitles:@[@"More details"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
        if (buttonIndex == 0) {
            //cancel button
            
        } else if (buttonIndex == 1) {
            //update logic here
            
            [self showPurchaseView];
            
        }
        
    }];
    
}

+ (void) showPurchaseView {
    
    PurchaseViewController *controller = [[PurchaseViewController alloc] init];
    UINavigationController *naviController = [[UINavigationController alloc] initWithRootViewController:controller];
    if (isUserInterfaceIdiomPhone) {
    } else {
        naviController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:naviController animated:true completion:nil];
    
}

@end
