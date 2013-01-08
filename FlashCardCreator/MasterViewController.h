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
#import "ZipFileDownloadHelper.h"
#import "MBProgressHUD.h"

@class DetailViewController;
@class Pack;
@class Card;

@interface MasterViewController : UITableViewController <PublicPackRequestDelegate, PackListDelegate, ZipFileDownloadHelperDelegate, MBProgressHUDDelegate> {
    
    Pack *_currentPack;
    Card *_currentCard;
    UIPopoverController *_packListPickerPopover;
    
    //public pack related
    BOOL _isPublicPack;
    Pack *_publicPack;
    NSString *_saveZipFilePath;
    ZipFileDownloadHelper *_zipFileDownloadHelp;
    
    //progress indicator related
    MBProgressHUD *_HUD;
    float _progressivePercent;
}

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (nonatomic, retain) Pack *currentPack;
@property (nonatomic, retain) Card *currentCard;
@property (nonatomic, retain) Pack *publicPack;

@end
