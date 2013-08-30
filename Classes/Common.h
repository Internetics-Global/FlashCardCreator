//
//  Common.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 22/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Common : NSObject

+ (void)alertViewCommon:(NSString *) msg;

+ (int) getScreenWidthInLandscape;
+ (int) getScreenHeightInLandscape;

+ (NSString *) appVersion;

+ (NSString *) build;

@end
