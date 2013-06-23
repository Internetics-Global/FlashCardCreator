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

@end
