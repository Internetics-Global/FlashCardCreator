//
//  MasterViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PublicPackRequest.h"
#import "ZipFileDownloadHelper.h"
#import "MBProgressHUD.h"

@class DetailViewController;
@class Pack;
@class Card;

@interface MasterViewController : UITableViewController <PublicPackRequestDelegate, ZipFileDownloadHelperDelegate, MBProgressHUDDelegate> {
    
    Pack *_currentPack;
    Card *_currentCard;
    int _indexCard;  //selected card index
    
    UIPopoverController *_packListPickerPopover;
    
    //public pack related
    BOOL _isCurrentPackPublic;
    Pack *_publicPack;
    NSString *_saveZipFilePath;
    ZipFileDownloadHelper *_zipFileDownloadHelp;
    
    //progress indicator related
    MBProgressHUD *_HUD;
    float _progressivePercent;
    
    UIButton *_backgroundOfCreateCardView;
    
}

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, strong) Pack *publicPack;
@property (nonatomic, assign) int indexCard;
@property (nonatomic, assign) BOOL isCurrentPackPublic;

@property (nonatomic, strong) UIButton *backgroundOfCreateCardView;

@end
