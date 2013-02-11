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
	NSString *_title;
    NSString *_subheading;
    NSString *_main;
    NSString *_sub;
    NSString *_imageFullPath;
    NSString *_logoFullPath;
    NSString *_logoURLLinkage;
    
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
@property (nonatomic, copy) NSString *logoFullPath;
@property (nonatomic, copy) NSString *logoURLLinkage;

@property (strong, nonatomic) CSS *css;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableDictionary *) questionForCardID:(NSInteger)cardID;

@end
