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

+ (int) currentInstalledSqliteVersion;

+ (void) setCurrentInstalledSqliteVersion: (int) version;

+ (int) newUpdatingSqliteVersion;

//同等比例放大缩小
+ (CGRect) getScaledViewRect:(UIView *) view withProportion:(float) scaleValue;

+ (NSArray *) allAvailableFonts;

+ (BOOL) validateUrl: (NSString *) str;

+ (BOOL) isValidYoutubeLinkage:(NSString *) str;
+ (NSString *) youtubeIDFromURL:(NSString *) str;

+ (NSString *) embeddedYoutubeURL:(NSString *) str;

@end
