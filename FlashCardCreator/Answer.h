//
//  Answer.h
//  FlashCardCreator
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
    //youtube linkage or an local url
    NSString *_movieFullPath;
    
    NSString *_logoFullPath;  //we don't use this field
    NSInteger _templateID;
    
    NSInteger _autoresizeFlag;
    
    CSS *_css;

    NSInteger _lineNoSubheading;
    NSInteger _lineNoMain;
    NSInteger _lineNoSub;
    
    NSString *_backgroundImageFullPath;
    
    NSString *_recordedSoundFullPath;
}

@property (nonatomic, assign) NSInteger answerID;
@property (nonatomic, assign) NSInteger cardID;
@property (nonatomic, assign) NSInteger cssID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subheading;
@property (nonatomic, copy) NSString *main;
@property (nonatomic, copy) NSString *sub;

@property (nonatomic, copy) NSString *imageFullPath;
@property (nonatomic, copy) NSString *movieFullPath;

@property (nonatomic, copy) NSString *logoFullPath;

/**
 *  autoresize logic to determine best font
 */
@property (nonatomic, assign) NSInteger templateID;

@property (nonatomic, assign) NSInteger autoresizeFlag;

@property (assign, nonatomic) NSInteger lineNoSubheading;
@property (assign, nonatomic) NSInteger lineNoMain;
@property (assign, nonatomic) NSInteger lineNoSub;

@property (strong, nonatomic) CSS *css;

@property (copy, nonatomic) NSString *backgroundImageFullPath;

@property (copy, nonatomic) NSString *recordedSoundFullPath;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableDictionary *) answerForCardID:(NSInteger)cardID;

@end
