//
//  DataManager.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "DataManager.h"
#import <Reachability/Reachability.h>
#import "User.h"
#import "Card.h"


@implementation DataManager

-(void)getUserCompleteNotification:(NSNotification *)notification{

    [[NSNotificationCenter defaultCenter] postNotificationName:GET_USER_COMPLETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GET_USER_COMPLETE_NOTIFICATION object:nil];
}


+ (BOOL)apiReachable{
	if (![[Reachability reachabilityWithHostName:@"www.google.com"] currentReachabilityStatus] == NotReachable) {
        
		return YES;
	}else {
        [iConsole info:@"%s:network is NOT reachable",__FUNCTION__];
		return NO;
	}
}

+ (void)apiReachableAlert {
    if ( NotReachable == [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection"
                                                        message:NSLocalizedString(@"DIALOG_PLEASE_CHECK_YOUR_NETWORK",@"")
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
	}
}

+ (Pack *) parseRemotePublicPack:(NSArray *) publicCardRawArray {
    Pack *pack = [[Pack alloc] init];
    pack.packID = PUBLIC_PACK_ID;
    pack.userID = [User defaultUser].userID;
    pack.packName = @"public";
    pack.languageName = @"en";
    pack.isPublic = YES;
    //pack.coverImageURL = , we set during packlist
    
    for (int i =0; i<[publicCardRawArray count]; i++) {
        Card *card = [[Card alloc] init];
        card.packID = pack.packID;
        card.cardID = [(publicCardRawArray[i])[@"card_id"] integerValue];
        card.cardName = (publicCardRawArray[i])[@"card_name"];
        card.coverImageURL = (publicCardRawArray[i])[@"thumb_pic"];
        [[pack cards] addObject:card];
    }
    
    return pack;
}


@end
