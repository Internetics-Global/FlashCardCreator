//
//  Question.h
//  FlashCardCreator
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
    NSString *_movieFullPath;
    
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

@property (nonatomic, copy) NSString *imageFullPath;
//youtube linkage or an local url
@property (nonatomic, copy) NSString *movieFullPath;

@property (nonatomic, copy) NSString *logoFullPath;
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

@property (copy, nonatomic) NSString *backgroundImageFullPath;

@property (copy, nonatomic) NSString *recordedSoundFullPath;

@property (strong, nonatomic) CSS *css;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableDictionary *) questionForCardID:(NSInteger)cardID;

@end
