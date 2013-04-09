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
    NSString *_sidebarTitle;
    NSString *_coverImageURL;
	NSInteger _userID;
    NSString *_languageName;
    NSString *_creator; //we use OpenUDID to generate
    NSString *_creatorNickName; //User input this during creating pack
    NSMutableArray *_cards;
}

@property (nonatomic, assign) NSInteger packID;
@property (nonatomic, copy) NSString *packName;
@property (nonatomic, copy) NSString *sidebarTitle;
@property (nonatomic, copy) NSString *coverImageURL;
@property (nonatomic, assign) NSInteger userID;
@property (nonatomic, copy) NSString *languageName;
@property (nonatomic, assign) BOOL isPublic;
@property (nonatomic, strong) NSMutableArray *cards;
@property (nonatomic, copy) NSString *creator;
@property (nonatomic, copy) NSString *creatorNickName;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)addCard:(Card *)card;
- (void)removeCard:(Card *)card;
- (void)save;
- (void)destroy;

- (NSMutableArray *)snOrderedCards;

+ (NSMutableArray *) packsForUserID:(NSInteger)userID;

@end

