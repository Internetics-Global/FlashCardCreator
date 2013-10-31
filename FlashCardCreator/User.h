//
//  User.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Pack.h"

typedef enum {
    SortTypeDefault = 0,
    SortTypeLastVisitedAscend = 1,
    SortTypeLastVisitedDescend = 2,
    SortTypeLastCreatedAscend = 3,
    SortTypeLastCreatedDescend =4,
} SortTypeEnum;

@interface User : NSObject{
    NSInteger _userID;
	NSString *_nickName;
    
    NSMutableArray *_packs;
}

@property (nonatomic, assign) NSInteger userID;
@property (nonatomic, copy, readonly) NSString *nickName;

@property (nonatomic, strong) NSMutableArray *packs;

+ (User *)defaultUser;
- (id)initWithDictionary:(NSDictionary *)dict;
- (void)addPack:(Pack *)pack;
-(void)removePack:(Pack *)pack;
- (void) sortPacks:(SortTypeEnum) sortType;

@end
