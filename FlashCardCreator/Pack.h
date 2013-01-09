//
//  Pack.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

@interface Pack : NSObject {
    NSInteger _packID;
	NSString *_packName;
    NSString *_coverImageURL;
	NSInteger _userID;
    NSString *_languageName;
    BOOL _isPubilc;
    
    NSMutableArray *_cards;
}

@property (nonatomic, assign) NSInteger packID;
@property (nonatomic, copy) NSString *packName;
@property (nonatomic, copy) NSString *coverImageURL;
@property (nonatomic, assign) NSInteger userID;
@property (nonatomic, copy) NSString *languageName;
@property (nonatomic, assign) BOOL isPublic;

@property (nonatomic, strong) NSMutableArray *cards;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)addCard:(Card *)card;
- (void)removeCard:(Card *)card;
- (void)save;

+ (NSMutableArray *) packsForUserID:(NSInteger)userID;

@end

