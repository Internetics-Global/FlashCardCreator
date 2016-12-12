//
//  GoogleDriveSession.h
//  FlashCardCreator
//
//  Created by internetics on 12/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^AuthSuccessCompletion)();

@interface GoogleDriveSession : NSObject


+ (id)sharedSession;

- (BOOL)isLinked;
- (void)unlinkAll;

- (void)authWithSuccessCompletion:(nonnull AuthSuccessCompletion) authSuccessCompletion;


@end
