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
    NSString *_type;
    NSString *_summary;
    NSString *_detail;
    NSString *_imageFullPath;
    NSString *_logoFullPath;
}

@property (nonatomic, assign) NSInteger questionID;
@property (nonatomic, assign) NSInteger cardID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, copy) NSString *imageFullPath;
@property (nonatomic, copy) NSString *logoFullPath;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableDictionary *) questionForCardID:(NSInteger)cardID;

@end
