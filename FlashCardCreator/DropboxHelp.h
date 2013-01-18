//
//  DropboxHelp.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 17/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Card;

@interface DropboxHelp : NSObject {
    
    NSString *_cardAssembleDir;
}

- (NSString *) zipCardForUpload:(Card *) card;

@end
