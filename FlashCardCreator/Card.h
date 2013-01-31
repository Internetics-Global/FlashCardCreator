//
//  Card.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Question;
@class Answer;

@interface Card : NSObject {
    NSInteger _cardID; //system allocate it
    NSInteger _packID;
    NSInteger _cardSN;  //user can change it
    NSString *_cardName;
    NSString *_coverImageURL;
    NSString *_creator; //we use OpenUDID to generate
    Question *_question;
    Answer *_answer;
    
    
}

@property (nonatomic, assign) NSInteger cardID;
@property (nonatomic, assign) NSInteger packID;
@property (nonatomic, assign) NSInteger cardSN;
@property (nonatomic, copy) NSString *cardName;
@property (nonatomic, copy) NSString *coverImageURL;
@property (nonatomic, copy) NSString *creator;
@property (strong, nonatomic) Question *question;
@property (strong, nonatomic) Answer *answer;


- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableArray *) cardsForPackID:(NSInteger)packID;

@end

