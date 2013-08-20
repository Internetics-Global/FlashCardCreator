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

@class DetailViewController;
@class Pack;
@class Card;
@class DropboxSharekitHelper;

@interface MasterViewController : UIViewController <ZipFileDownloadHelperDelegate, MBProgressHUDDelegate,FMMoveTableViewDelegate,FMMoveTableViewDataSource> {
    
    Pack *_currentPack;
    Card *_currentCard;
    NSUInteger _indexCard;  //selected card index
    NSUInteger _indexPack;  //selected pack index;
    
    UIPopoverController *_packListPickerPopover;
    ZipFileDownloadHelper *_zipFileDownloadHelp;
    
    //progress indicator related
    MBProgressHUD *_HUD;
    float _progressivePercent;
    
    UIButton *_backgroundOfCreateCardView;
    
    UIButton *_addCardButton;
    UIView *_addCardButtonBackground;
    UIView *_rightPackView;
    UIImageView *_rightPackImage;
    UILabel *_rightPackCardNo;
    UIBarButtonItem *_selectPackButton;
    
    FMMoveTableView *_tableView;
    
    //for Amazon simpleDB
    NSString *_amazonSimpleDBItemName;
    int       _currentDownloadCount;
    
    DropboxSharekitHelper *_shareHelper;
}

@property (nonatomic, strong) DetailViewController *detailViewController;
@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, assign) NSUInteger indexCard;
@property (nonatomic, assign) NSUInteger indexPack;
@property (nonatomic, strong) UIButton *backgroundOfCreateCardView;

@property (nonatomic, strong) FMMoveTableView *tableView;

- (void)shareButtonClicked;

@end
