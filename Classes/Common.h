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

+ (NSArray *) recommendedFonts;

+ (BOOL) isSymbolIncluded:(NSString *)str;
+ (BOOL) isIncludedInRecommendedFonts:(NSString *) fontName;

+ (NSString *) userAgentInfo;

+ (int) nearestIndexForStringArray:(NSArray *) array withElement:(int) element;

/*
 * default path is kind of answer_placeholder_content,question_placeholder_logo,default_pack_cover_image, etc
 * 在本项目中，所有非default图片都是由数字组成
 */
+ (BOOL) isPlaceholderFilePathOrDirectory :(NSString *) pathStr;

+ (BOOL) isDirectoryFormat:(NSString *) filePath;

@end
