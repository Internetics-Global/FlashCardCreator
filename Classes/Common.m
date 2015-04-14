//
//  Common.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 22/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "Common.h"
#import "RequestUtils.h"

#import "EmoticonHelper.h"
#import "Emoticon.h"

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


/**
 *  当前app所用的版本
 */
+ (int) currentInstalledSqliteVersion {
    int currentVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"SQLiteVersion"];
    return currentVersion;
}

+ (void) setCurrentInstalledSqliteVersion: (int) version {
    [[NSUserDefaults standardUserDefaults] setInteger:version forKey:@"SQLiteVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  即将升级的新版本
 */
+ (int) newUpdatingSqliteVersion {
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SQLiteVersion" ofType:@"plist"]];
    double newVersion = [[dict valueForKeyPath:@"SQLiteVersion"] doubleValue];
    NSAssert(newVersion == (int)newVersion, @"SQLiteVersion must be integer");
    
    return (int)newVersion;
}

+ (CGRect) getScaledViewRect:(UIView *) view withProportion:(float) scaleValue {
    CGRect rect = view.frame;
    rect.origin.x = rect.origin.x * scaleValue;
    rect.origin.y = rect.origin.y * scaleValue;
    rect.size.width = rect.size.width * scaleValue;
    rect.size.height = rect.size.height * scaleValue;
    return rect;
}


+ (BOOL) validateUrl: (NSString *) str {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:str];
}

/**
 *  由于可获得的字体有几百个，我们手动选择其中几个。第一个必须是default
 */
+ (NSArray *) recommendedFonts {
    
    NSMutableArray *fontNames = [[NSMutableArray alloc] initWithObjects:@"Default",@"Arial-BoldMT",@"Chalkduster",@"Courier",@"Papyrus",@"Zapfino", nil];
    return fontNames;
    
}

+ (BOOL) isIncludedInRecommendedFonts:(NSString *) fontName {
    for (NSString *str in [self recommendedFonts]) {
        if ([str isEqualToString:fontName]) {
            return TRUE;
        }
    }
    
    return FALSE;
}

/**
 *  All avaiable fonts on device
 */
+ (NSArray *) allAvailableFonts {
    
    NSMutableArray *fontNames = [[NSMutableArray alloc] init];
    NSArray *fontFamilyNames = [UIFont familyNames];

    for (NSString *familyName in fontFamilyNames)
    {
        [iConsole info:@"Font Family Name = %@", familyName];
        NSArray *names = [UIFont fontNamesForFamilyName:familyName];
        [iConsole info:@"Font Names = %@", fontNames];
        [fontNames addObjectsFromArray:names];
    }
    
    return fontFamilyNames;

}

+ (BOOL) isValidYoutubeLinkage:(NSString *) str {
    return ([str hasPrefix:@"http://www.youtube.com/"]
               || [str hasPrefix:@"http://m.youtube.com/"]
                   || [str hasPrefix:@"https://www.youtube.com/"]
                       || [str hasPrefix:@"https://m.youtube.com/"]);
}

/**
 *  must be like this: http://www.youtube.com/watch?v=gzsrooteAZw
 */
+ (NSString *) youtubeIDFromURL:(NSString *) str {
    NSDictionary *param =  [str URLQueryParameters];
    NSString *idStr = [param objectForKey:@"v"];
    return idStr;
}

/**
 *  Support to directly play in the app
 */
+ (NSString *) embeddedYoutubeURL:(NSString *) str {
    NSString *finalStr = [NSString stringWithFormat:@"http://www.youtube.com/embed/%@",[self youtubeIDFromURL:str]];
    return finalStr;
}

/**
 *  由于不是所有字体都支持unicode(特别是在interchangeability中），所以需要通过这个方法判断
 *  判断是否有symobl包含在str中，当前的方法是一种非有效做法，期待更好的方案
 */
+ (BOOL) isSymbolIncluded:(NSString *)str {
    
    if (str.length == 0) {
        return NO;
    }
    
    for (Emoticon *emotion in [EmoticonHelper defaultEmoticons]) {
        if ([str rangeOfString:emotion.code].location == NSNotFound) {
            
        } else {
            return YES;
        }
    }
    
    
    
    return NO;
    
}

+ (NSString *) userAgentInfo {
    NSString *applicationName =
    [[[NSBundle mainBundle] infoDictionary]
     objectForKey:(__bridge NSString *)kCFBundleExecutableKey];
    NSString *applicationVersion = [[[NSBundle mainBundle] infoDictionary]
                                    objectForKey:(__bridge NSString *)kCFBundleVersionKey];
    NSString *deviceModel = [[UIDevice currentDevice] model];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    double screenScale = [[UIScreen mainScreen] scale];
    NSString *str = [NSString stringWithFormat:@"%@  Build:%@(%@;iOS%@;Scale/%0.2f)",applicationName,applicationVersion,deviceModel,systemVersion, screenScale];
    return str;
}

/**
 *  这个array必须是一个NSString类型的，但是可以转换成int的。而且必须从小到大预先排列好
 */
+ (int) nearestIndexForStringArray:(NSArray *) array withElement:(int) element {
    
    if (element <= [[array firstObject] integerValue]) {
        [iConsole warn:@"%s:please check element =:%d",__FUNCTION__,element];
        return 0;
    }
    
    if (element >= [[array lastObject] integerValue]) {
        [iConsole warn:@"%s:please check element =:%d",__FUNCTION__,element];
        return [array count] - 1;
    }
    
    for (int i = 0; i< [array count] - 1; i++) {
        
        if ((element >= [array[i] integerValue]) && ((element < [array[i +1] integerValue]))) {
            
            return i;
        }
    }
    
    [iConsole error:@"%s:please check element =:%d",__FUNCTION__,element];
    
    return -1;
    
}

+ (BOOL) isDefaultPath :(NSString *) pathStr {
    
    if (pathStr.length == 0) {
        return YES;
    }
    
    if ([[pathStr lastPathComponent] rangeOfString:@"placeholder"].location != NSNotFound) {
        return YES;
    }
    
    if ([[pathStr lastPathComponent] rangeOfString:@"default"].location != NSNotFound) {
        return YES;
    }
    
    
    return NO;
}


@end
