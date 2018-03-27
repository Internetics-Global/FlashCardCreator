//
//  Answer.h
//  FFC
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CSS;

@interface Answer : NSObject {
    NSInteger _answerID;
    NSInteger _cardID;
    NSInteger _cssID;
	NSString *_title;//This field should be card based, however, forhistory reason, it put here
    NSString *_subheading;
    NSString *_main;
    NSString *_sub;
    
    NSString *_imageFullPath;
    NSString *_imageFullPath2;
    
    /*
     *  including local video and youtube link
     */
    NSString *_movieFullPath;
    
    /*
     *  including local video and youtube link
     */
    NSString *_movieFullPath2;
    
    NSString *_logoFullPath;  //we don't use this field
    NSInteger _templateID;
    
    NSInteger _autoresizeFlag;
    
    CSS *_css;

    NSInteger _lineNoSubheading;
    NSInteger _lineNoMain;
    NSInteger _lineNoSub;
}

@property (nonatomic, assign) NSInteger answerID;
@property (nonatomic, assign) NSInteger cardID;
@property (nonatomic, assign) NSInteger cssID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subheading;
@property (nonatomic, copy) NSString *main;
@property (nonatomic, copy) NSString *sub;

@property (nonatomic, copy, getter=getImageFullPath) NSString *imageFullPath;


@property (nonatomic, copy, getter=getImageFullPath2) NSString *imageFullPath2;

@property (nonatomic, copy,getter=getMovieFullPath) NSString *movieFullPath;

@property (nonatomic, copy,getter=getMovieFullPath2) NSString *movieFullPath2;

@property (nonatomic, copy,getter=getBackgroundImageFullPath) NSString *backgroundImageFullPath;

@property (nonatomic, copy,getter=getRecordedSoundFullPath) NSString *recordedSoundFullPath;


@property (nonatomic, copy,getter=getLogoFullPath) NSString *logoFullPath;


@property (nonatomic, assign) NSInteger templateID;

@property (nonatomic, assign) NSInteger autoresizeFlag;

@property (assign, nonatomic) NSInteger lineNoSubheading;
@property (assign, nonatomic) NSInteger lineNoMain;
@property (assign, nonatomic) NSInteger lineNoSub;

@property (strong, nonatomic) CSS *css;


- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableDictionary *) answerForCardID:(NSInteger)cardID;

- (id)copyWithZone:(NSZone *)zone;

@end
