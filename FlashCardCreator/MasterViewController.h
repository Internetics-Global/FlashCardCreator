//
//  MasterViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZipFileDownloadHelper.h"
#import "MBProgressHUD.h"

@class DetailViewController;
@class Pack;
@class Card;

@interface MasterViewController : UITableViewController <ZipFileDownloadHelperDelegate, MBProgressHUDDelegate> {
    
    Pack *_currentPack;
    Card *_currentCard;
    int _indexCard;  //selected card index
    
    UIPopoverController *_packListPickerPopover;
    ZipFileDownloadHelper *_zipFileDownloadHelp;
    
    //progress indicator related
    MBProgressHUD *_HUD;
    float _progressivePercent;
    
    UIButton *_backgroundOfCreateCardView;
    
    UIButton *_addCardButton;
    UIBarButtonItem *_selectPackButton;
}

@property (nonatomic, strong) DetailViewController *detailViewController;
@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, assign) int indexCard;
@property (nonatomic, strong) UIButton *backgroundOfCreateCardView;

@end
