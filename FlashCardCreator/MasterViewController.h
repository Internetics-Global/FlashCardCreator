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
#import "FMMoveTableView.h"
#import "FMMoveTableViewCell.h"
#import "PopoverView.h"

@class DetailViewController;
@class Pack;
@class Card;
@class DropboxSharekitHelper;

@interface MasterViewController : UIViewController <ZipFileDownloadHelperDelegate, MBProgressHUDDelegate,FMMoveTableViewDelegate,FMMoveTableViewDataSource, UIAlertViewDelegate,PopoverViewDelegate> {
    
    Pack *_currentPack;
    Card *_currentCard;
    NSUInteger _indexCard;  //selected card index
    
    UIPopoverController *_packListPickerPopover;
    ZipFileDownloadHelper *_zipFileDownloadHelper;
    
    //progress indicator related
    MBProgressHUD *_HUD;
    float _progressivePercent;
    
    UIButton *_backgroundOfCreateCardView;
    
    UIButton *_addCardButton;
    UIView *_addCardButtonBackground;
    
    /**
     *  General pack info (like pack image and no of cards) on the right.
     *  Only applicable for iPhone (on iPad, we have the similar logic on the detail view)
     */
    UIView *_rightPackView;
    
    
    UIImageView *_rightPackImage;
    UILabel *_rightPackCardNo;
    UILabel *_shareCodeLabel;
    
    UIBarButtonItem *_selectPackButton;
    
    FMMoveTableView *_tableView;
    
    //for Amazon simpleDB
    NSString *_amazonSimpleDBItemName;
    int       _currentDownloadCount;
    int       _maxDownloadCount;
    
    DropboxSharekitHelper *_shareHelper;
    
    NSIndexPath *_currentIndexPath;//only used during deleting a card (commitEditingStyle)
}

@property (nonatomic, strong) DetailViewController *detailViewController;
@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, assign) NSUInteger indexCard;
@property (nonatomic, assign) NSUInteger indexPack;
@property (nonatomic, strong) UIButton *backgroundOfCreateCardView;
@property (nonatomic, strong) FMMoveTableView *tableView;



- (void)shareButtonClicked:(id) sender;

@end
