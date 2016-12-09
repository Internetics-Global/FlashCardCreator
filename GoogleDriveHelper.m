//
//  GoogleDriveHelper.m
//  FlashCardCreator
//
//  Created by internetics on 9/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "GoogleDriveHelper.h"

@implementation GoogleDriveHelper

+ (id)sharedHelper {
    static GoogleDriveHelper *sharedHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [[self alloc] init];
    });
    return sharedHelper;
}

- (BOOL)isLinked {
    
    return false;
    
}
- (void)unlinkAll {
    
}


@end
