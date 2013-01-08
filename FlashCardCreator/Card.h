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
    NSInteger _cardID;
    NSInteger _packID;
    NSString *_cardName;
    NSString *_thumbPicURL;
    NSString *_onlineFileURL; //this only applies to online cards
    BOOL _isOnline;   // when true, indicate local card does not exist or imcomplete and need to download from remote
    
    Question *_question;
    Answer *_answer;
    
    
}

@property (nonatomic, assign) NSInteger cardID;
@property (nonatomic, assign) NSInteger packID;
@property (nonatomic, copy) NSString *cardName;
@property (nonatomic, copy) NSString *thumbPicURL;
@property (nonatomic, copy) NSString *onlineFileURLL;
@property (nonatomic, assign) BOOL isOnline;

@property (retain, nonatomic) Question *question;
@property (retain, nonatomic) Answer *answer;


- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableArray *) cardsForPackID:(NSInteger)packID;

@end

