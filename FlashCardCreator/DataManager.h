//
//  DataManager.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Pack.h"

@interface DataManager : NSObject

+ (void)apiReachableAlert;

+ (Pack *) parseRemotePublicPack:(NSArray *) publicCardRawArray;


@end
