//
//  DataManager.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "DataManager.h"
#import "Reachability.h"
#import "User.h"
#import "Card.h"


@implementation DataManager

- (void)getUser{
#warning this is not finally completed
}

-(void)getUserCompleteNotification:(NSNotification *)notification{

    [[NSNotificationCenter defaultCenter] postNotificationName:GET_USER_COMPLETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GET_USER_COMPLETE_NOTIFICATION object:nil];
}


+ (BOOL)apiReachable{
	if (![[Reachability reachabilityWithHostName:@"www.google.com"] currentReachabilityStatus] == NotReachable) {
        
		return YES;
	}else {
        NSLog(@"%s:network is NOT reachable",__FUNCTION__);
		return NO;
	}
}

+ (void)apiReachableAlert {
    if ( NotReachable == [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NO Internet"
                                                        message:@"Please check your network"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
	}
}

+ (Pack *) parseRemotePublicPack:(NSArray *) publicCardRawArray {
#warning to use simulated data
    Pack *pack = [[[Pack alloc] init] autorelease];
    pack.packID = PUBLIC_PACK_ID;
    pack.userID = [User defaultUser].userID;
    pack.packName = @"public";
    pack.languageName = @"en";
    pack.isPublic = YES;
    pack.thumbPicURL = PUBLIC_PACK_THUMB_IMAGE_URL;
    
    for (int i =0; i<[publicCardRawArray count]; i++) {
        Card *card = [[[Card alloc] init] autorelease];
        card.packID = pack.packID;
        card.cardID = [[publicCardRawArray[i] objectForKey:@"card_id"] integerValue];
        card.cardName = [publicCardRawArray[i] objectForKey:@"card_name"];
        card.thumbPicURL = [publicCardRawArray[i] objectForKey:@"thumb_pic"];
        card.onlineFileURLL = [publicCardRawArray[i] objectForKey:@"dropbox_zip_link"];
        [[pack cards] addObject:card];
    }
    
    return pack;
}


@end
