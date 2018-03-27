//
//  Common.h
//  FFC
//
//  Created by Wang Bourne on 22/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Pack;

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
+ (CGRect) getScaledViewRectComparedToBaseIPhone320Height:(UIView *) view;

+ (NSArray *) allAvailableFonts;

+ (BOOL) validateUrl: (NSString *) str;

+ (BOOL) isValidYoutubeLinkage:(NSString *) str;

+ (NSString *) youtubeIDFromURL:(NSString *) str;

+ (NSString *) embeddedYoutubeURL:(NSString *) str;

+ (NSArray *) recommendedFonts;

+ (BOOL) isSymbolIncluded:(NSString *)str;
+ (BOOL) isIncludedInRecommendedFonts:(NSString *) fontName;

+ (NSString *) userAgentInfo;

+ (int) nearestIndexForStringArray:(NSArray *) array withElement:(int) element;

+ (BOOL) isPlaceholderFilePathOrDirectory :(NSString *) pathStr;

+ (BOOL) isDirectoryFormat:(NSString *) filePath;

+ (BOOL) isOwner:(Pack *) currentPack;

+ (BOOL) isValidBucketNameFromParseUserName:(NSString *) parseUserName;


+ (int) getPlayOption;
+ (void) setPlayOption:(int) playOption;

+ (BOOL) isAlphanumeric:(NSString *) str;

+ (NSString *) removeAllCharactersExceptAlphanumericFromString:(NSString *) str;

+ (NSString *) getShareMessage:(NSString *) shareLink;

+ (BOOL) isEmptyString: (NSString *) str;

@end
