//
//  Common.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 22/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "Common.h"

@implementation Common

+ (void)alertViewCommon:(NSString *) msg {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
}

+ (int) getScreenWidthInLandscape {
    int width;
    if (isUserInterfaceIdiomPhone) {
        width = IPHONE_UI_WIDTH;
    } else {
        width = IPAD_UI_WIDTH;
    }
    
    return width;
}

+ (int) getScreenHeightInLandscape {
    int height;
    if (isUserInterfaceIdiomPhone) {
        height = IPHONE_UI_HEIGHT;
    } else {
        height = IPAD_UI_HEIGHT;
    }
    
    return height;
}

+ (NSString *) appVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

+ (NSString *) build
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
}


+ (int) sqliteVersion {
    int currentVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"SQLiteVersion"];
    return currentVersion;
}

+ (void) setSqliteVersion: (int) version {
    [[NSUserDefaults standardUserDefaults] setInteger:version forKey:@"SQLiteVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (CGRect) getScaledViewRect:(UIView *) view withProportion:(float) scaleValue {
    CGRect rect = view.frame;
    rect.origin.x = rect.origin.x * scaleValue;
    rect.origin.y = rect.origin.y * scaleValue;
    rect.size.width = rect.size.width * scaleValue;
    rect.size.height = rect.size.height * scaleValue;
    return rect;
}



@end
