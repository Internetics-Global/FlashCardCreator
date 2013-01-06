//
//  MasterViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PublicPackRequest.h"
#import "PackListTableViewController.h"

@class DetailViewController;
@class Pack;

@interface MasterViewController : UITableViewController <PublicPackRequestDelegate, PackListDelegate> {
    BOOL _isPublicPack;
    Pack *_currentPack;
    Pack *_publicPack;
    UIPopoverController *_packListPickerPopover;
}

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (nonatomic, retain) Pack *currentPack;
@property (nonatomic, retain) Pack *publicPack;

@end
