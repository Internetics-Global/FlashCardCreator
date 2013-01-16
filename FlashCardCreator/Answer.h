//
//  Answer.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Answer : NSObject {
    NSInteger _answerID;
    NSInteger _cardID;
	NSString *_title;
    NSString *_content;
    NSString *_imageFullPath;
    NSString *_logoFullPath;
}

@property (nonatomic, assign) NSInteger answerID;
@property (nonatomic, assign) NSInteger cardID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *imageFullPath;
@property (nonatomic, copy) NSString *logoFullPath;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;

+ (NSMutableDictionary *) answerForCardID:(NSInteger)cardID;

@end
