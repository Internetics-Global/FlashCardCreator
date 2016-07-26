//
//  Question.h
//  FFC
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CSS;

@interface Question : NSObject {
    NSInteger _questionID;
    NSInteger _cardID;
    NSInteger _cssID;
	NSString *_title;//This field should be card based, however, forhistory reason, it put here
    NSString *_subheading;
    NSString *_main;
    NSString *_sub;
    NSString *_imageFullPath;
    NSString *_imageFullPath2;
    NSString *_movieFullPath;
    NSString *_movieFullPath2;
    
    NSString *_logoFullPath;
    NSString *_logoURLLinkage;
    NSInteger _templateID;
    
    NSInteger _autoresizeFlag;
    
    NSInteger _lineNoSubheading;
    NSInteger _lineNoMain;
    NSInteger _lineNoSub;
    
    NSString *_backgroundImageFullPath;
    
    NSString *_recordedSoundFullPath;
    
    CSS *_css;
}

@property (nonatomic, assign) NSInteger questionID;
@property (nonatomic, assign) NSInteger cardID;
@property (nonatomic, assign) NSInteger cssID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subheading;
@property (nonatomic, copy) NSString *main;
@property (nonatomic, copy) NSString *sub;

@property (nonatomic, copy, getter=getImageFullPath) NSString *imageFullPath;
@property (nonatomic, copy, getter=getImageFullPath2) NSString *imageFullPath2;


/**
 *  完整path,而不是只是一个文件名
 */
@property (nonatomic, copy, getter=getMovieFullPath) NSString *movieFullPath;

/**
 *  完整path,而不是只是一个文件名
 */
@property (nonatomic, copy, getter=getMovieFullPath2) NSString *movieFullPath2;

/**
 *  完整path,而不是只是一个文件名
 */
@property (nonatomic, copy,getter=getBackgroundImageFullPath) NSString *backgroundImageFullPath;

/**
 *  完整path,而不是只是一个文件名
 */
@property (nonatomic, copy,getter=getRecordedSoundFullPath) NSString *recordedSoundFullPath;

/**
 *  完整path,而不是只是一个文件名
 */
@property (nonatomic, copy, getter=getLogoFullPath) NSString *logoFullPath;

@property (nonatomic, copy) NSString *logoURLLinkage;
@property (nonatomic, assign) NSInteger templateID;

/**
 *  autoresize logic to determine best font. only for non-editable card
 *  0，允许；1， 不允许
 */
@property (nonatomic, assign) NSInteger autoresizeFlag;

@property (assign, nonatomic) NSInteger lineNoSubheading;
@property (assign, nonatomic) NSInteger lineNoMain;
@property (assign, nonatomic) NSInteger lineNoSub;

@property (strong, nonatomic) CSS *css;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableDictionary *) questionForCardID:(NSInteger)cardID;

- (id)copyWithZone:(NSZone *)zone;

@end
