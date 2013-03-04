//
//  User.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Pack.h"

@interface User : NSObject{
    NSInteger _userID;
	NSString *_nickName;
    
    NSMutableArray *_packs;
}

@property (nonatomic, assign) NSInteger userID;
@property (nonatomic, copy, readonly) NSString *nickName;

@property (nonatomic, strong, readonly) NSMutableArray *packs;

+ (User *)defaultUser;
- (id)initWithDictionary:(NSDictionary *)dict;
- (void)addPack:(Pack *)pack;
-(void)removePack:(Pack *)pack;

@end
