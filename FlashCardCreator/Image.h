//
//  Image.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Image : NSObject {
    NSInteger _imageID;
	NSString *_imageFileName;
    NSInteger _cardID;
    BOOL _isQuestionCard;
}

@property (nonatomic, assign) NSInteger imageID;
@property (nonatomic, copy) NSString *imageFileName;
@property (nonatomic, assign) NSInteger cardID;
@property (nonatomic, assign) BOOL isQuestionCard;

+ (NSMutableArray *) imagesForCardID:(NSInteger)cardID;

@end

