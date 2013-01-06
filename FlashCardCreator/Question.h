//
//  Question.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Question : NSObject {
    NSInteger _questionID;
    NSInteger _cardID;
	NSString *_title;
    NSString *_type;  //????????
    NSString *_imageName;
}

@property (nonatomic, assign) NSInteger questionID;
@property (nonatomic, assign) NSInteger cardID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *imageName;

+ (NSMutableArray *) questionsForCardID:(NSInteger)cardID;

@end
