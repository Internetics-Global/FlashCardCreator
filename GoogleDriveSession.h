//
//  GoogleDriveSession.h
//  FlashCardCreator
//
//  Created by internetics on 12/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^AuthSuccessCompletion)();

@class GTLRDriveService;

@interface GoogleDriveSession : NSObject

@property (copy, nonatomic) NSString *accessToken;


+ (id)sharedSession;

- (BOOL)isLinked;
- (void)unlinkAll;

- (GTLRDriveService *)driveService;

- (void)authWithSuccessCompletion:(nonnull AuthSuccessCompletion) authSuccessCompletion;


@end
