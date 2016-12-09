//
//  GoogleDriveHelper.h
//  FlashCardCreator
//
//  Created by internetics on 9/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^AuthSuccessCompletion)();

@interface GoogleDriveHelper : NSObject

+ (id)sharedHelper;

- (BOOL)isLinked; 
- (void)unlinkAll;

- (void)authWithSuccessCompletion:(nonnull AuthSuccessCompletion) authSuccessCompletion;

@end
