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
    NSString *_movieFullPath;
    
    NSString *_logoFullPath;  //we don't use this field
    NSInteger _templateID;
    
    CSS *_css;

    NSInteger _lineNoSubheading;
    NSInteger _lineNoMain;
    NSInteger _lineNoSub;
    
    NSString *_backgroundImageFullPath;
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
@property (nonatomic, assign) NSInteger templateID;

@property (assign, nonatomic) NSInteger lineNoSubheading;
@property (assign, nonatomic) NSInteger lineNoMain;
@property (assign, nonatomic) NSInteger lineNoSub;

@property (strong, nonatomic) CSS *css;

@property (copy, nonatomic) NSString *backgroundImageFullPath;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableDictionary *) answerForCardID:(NSInteger)cardID;

@end
