 //
//  MasterViewController.m
//  FFC
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "User.h"
#import "CardCell.h"
#import "CreateCardViewController.h"
#import "DataManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ZipFileDownloadHelper.h"
#import "ZipArchive.h"
#import "MBProgressHUD.h"
#import "Question.h"
#import "Answer.h"
#import "Pack.h"
#import "Card.h"
#import "CSS.h"
#import "PackListViewControllerV2.h"
#import "DataManager.h"
#import "UIImageView+AFNetworking.h"
#import "CreateEditPackViewController2.h"
#import "UINavigationController+DismissKeyboard.h"
#import "DataManager.h"
#import "FileOperationHelper.h"
#import "MoreInfoTableViewController.h"
#import "FCCBarButton.h"

#import "AWSS3UploadHelper.h"
#import "DropboxShareKitHelper.h"
#import "GoogleDriveShareKitHelper.h"

#import "PlayViewControllerV2.h"
#import "NSArray+Randomised.h"
#import "NSString+QueryString.h"
#import "SimpleDBHelper.h"
#import "SimpleWebBrowserController.h"
#import "AppDelegate.h"
#import "OpenUDID.h"
#import "LineLayout.h"

#import "AMPopTip.h"

#import "TipHelper.h"

#import "CryptorHelper.h"
#import "Base64.h"

#import "Common.h"

#import "UIButton+Extensions.h"

#import <BlocksKit/UIAlertView+BlocksKit.h>

#import "MutipleTargetHelper.h"


#import <SDWebImage/UIImageView+WebCache.h>
#import "MutipleTargetHelper.h"

#import "PurchaseViewController.h"
#import "PackInfoView.h"

#import "GoogleDriveSession.h"
#import "SWTableViewCell.h"

@import Firebase;


/**
 ** Calibration
 *  Different text size have different margin and occupaction, see this article in my evernote: "(different text size  difference margin; different device, different text size)"
 */
const float ZAPFINO_RATIO_FROM_NON_IOS = 3;
const float PAPYRUS_RATIO_FROM_NON_IOS = 1.5;
const float COURIER_RATIO_FROM_NON_IOS = 1.5;
const float DEFAULT_FONT_RATIO_FROM_NON_IOS = 1.4;

@interface MasterViewController () <UIPopoverControllerDelegate,NSURLConnectionDataDelegate,SWTableViewCellDelegate, PackInfoViewDelegate> {
    
    UIButton * _editButton; //used for UIBarbuttonItem
    
    AWSS3UploadHelper          *_amazonShareHelper;
    DropboxSharekitHelper      *_dropboxShareHelper;
    GoogleDriveShareKitHelper  *_googleDriveShareHelper;
    
    /**
     *  不是当前的设备宽度，而是download时source device的宽度。
     */
    int       _downloadedPackSourceDeviceWidth;
    
    
    UIImageView   *_adImageView;
    
    
    /**
     *  General pack info (like pack image and no of cards) on the right.
     *  Only applicable for iPhone (on iPad, we have the similar logic on the detail view)
     */
    PackInfoView *_packInfoView;

}

@end

@implementation MasterViewController

@synthesize currentPack = _currentPack;
@synthesize currentCard = _currentCard;
@synthesize indexCard = _indexCard;
@synthesize backgroundOfCreateCardView = _backgroundOfCreateCardView;
@synthesize tableView = _tableView;


enum popover_enum {
    popover_enum_share = 0,
    popover_enum_template_select = 1,
    popover_enum_play = 2
};

#pragma mark -
#pragma mark - Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //1. Setup notification
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(packDeleteNotification:) name:PACK_DELETE_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPackAddedNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPackFinishedNotification:) name:EDIT_PACK_FINISHED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeBackgroundAfterCardCreatedNotification:) name:REMOVE_BACKGROUND_AFTER_CARD_CREATED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedPackNotification:) name:CURRENT_PACK_SELECTED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterDetailViewAfterParseDownloadPackFinishNotification:) name:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadPackNotification:) name:DOWNLOAD_PACK_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterAfterSaveCardNotification:) name:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterAfterDetailScrollNotification:) name:UPDATE_MASTER_AFTER_DETAIL_SCROLL_NOTFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toCreateNewPackNotification:) name:TO_CREATE_NEW_PACK_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showIntroductionVideoNotification:) name:SHOW_VIDEO_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showVisitStoreNotification:) name:SHOW_VISIT_STORE_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHelpNotification:) name:SHOW_HELP_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNotification:) name:PLAY_NOTIFICATION object:nil];
        
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPackListAfterDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLinkedNotification:) name:DROPBOX_LINKED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCancelledNotification:) name:PARSE_DOWNLOADED_PACK_CANCEL_NOTIFICATION object:nil];
        
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iapPurchaseSuccessNotification:) name:IAP_PURCHASE_SUCCESS_NOTIFICATION object:nil];
        
        if (isUserInterfaceIdiomPhone == false) {
            //在iPhone中，不需要这逻辑
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTooltipNotification:) name:SHOW_TOOLTIPS_NOTIFICATION object:nil];
        } else {
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareLinkCreatedNotification:) name:SHARE_LINK_CREATED_NOTIFICATION object:nil];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPackListAfterDismiss:) name:@"SHOW_PACK_LIST_AFTER_DISMISS" object:nil];
        
        
        //2. Initialize
        _currentPack = [[Pack alloc] init];
        _currentCard = [[Card alloc] init];
        _indexCard = 0;
        _zipFileDownloadHelper =[ZipFileDownloadHelper sharedInstance];
        
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPackListAfterDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.edgesForExtendedLayout = FALSE;
    }
    
    if isUserInterfaceIdiomPhone {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"w1136"]];
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [self.navigationController.navigationBar setTranslucent:YES];
    }
    
    if (isUserInterfaceIdiomPhone) {
        int leftSafeAread = 0;
        if (@available(iOS 11.0, *)) {
            leftSafeAread = UIApplication.sharedApplication.keyWindow.safeAreaInsets.left;
        }
        self.tableView = [[FMMoveTableView alloc] initWithFrame:CGRectMake(leftSafeAread, 0, IPHONE_UI_MASTER_TABLE_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT) style:UITableViewStylePlain];
    } else {
        self.tableView = [[FMMoveTableView alloc] initWithFrame:CGRectMake(0, 0, IPAD_UI_MASTER_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT) style:UITableViewStylePlain];
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view insertSubview:self.tableView atIndex:0];
    
    [self setupNaviBarButtonItems];
    
    
    if (isUserInterfaceIdiomPhone) {
                self.title = _currentPack.packName;
        
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 29)];
                label.font = [UIFont boldSystemFontOfSize:16.0];
                label.textAlignment = NSTextAlignmentLeft;
                label.backgroundColor = [UIColor clearColor];
                label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        
                label.textColor = [UIColor whiteColor]; // change this color
                label.text = _currentPack.packName;
                [self.navigationItem setTitleView:label];
        
    }
    [self.tableView reloadData];
    
    if ([MutipleTargetHelper isFullVersion]) {
        _tableView.allowsSelection = true;
    } else {
        _tableView.allowsSelection = false;
    }
    
    
}


- (void) setupNaviBarButtonItems {
    
    UIButton *selectPackButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"packs_button.png"] target:self action:@selector(selectAvailablePacks:)];
    _selectPackBarButton = [[UIBarButtonItem alloc]
                            initWithCustomView:selectPackButton];
    
    
    UIButton *newPackButton;
    if ([MutipleTargetHelper isFullVersion]) {
        newPackButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"add_pack_button.png"] target:self action:@selector(createNewPack:)];
    } else {
        newPackButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"add_pack_button_dimmed.png"] target:self action:@selector(createNewPack:)];
    }
    UIBarButtonItem *newPackBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithCustomView:newPackButton];
    
    
    if ([MutipleTargetHelper isFullVersion]) {
        _editButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"edit_button.png"] target:self action:@selector(editButtonClicked:)];
    } else {
        _editButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"edit_button_dimmed.png"] target:self action:@selector(editButtonClicked:)];
    }
    UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:_editButton];
    
    
    self.navigationItem.leftBarButtonItems = @[_selectPackBarButton,editBarButtonItem];

    
    if (isUserInterfaceIdiomPhone) {
        
        newPackButton.contentEdgeInsets = UIEdgeInsetsMake(0, -K_Navigation_Item_Inset_Offset*2, 0, K_Navigation_Item_Inset_Offset*2);
        [newPackButton setHitTestEdgeInsets:UIEdgeInsetsMake(0, -K_Navigation_Item_Inset_Offset*2, 0, K_Navigation_Item_Inset_Offset*2)];
        
        _editButton.contentEdgeInsets = UIEdgeInsetsMake(0, -K_Navigation_Item_Inset_Offset, 0, K_Navigation_Item_Inset_Offset);
        [_editButton setHitTestEdgeInsets:UIEdgeInsetsMake(0, -K_Navigation_Item_Inset_Offset, 0, K_Navigation_Item_Inset_Offset)];
        
        UIButton *playButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"play_button.png"] target:self action:@selector(playButtonClicked)];
        playButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        UIBarButtonItem *playBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithCustomView:playButton];
        
        
        UIButton *shareButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"share_button.png"] target:self action:@selector(shareButtonClicked:)];
        
        shareButton.contentEdgeInsets = UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset, 0, -K_Navigation_Item_Inset_Offset);
        [shareButton setHitTestEdgeInsets:UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset, 0, -K_Navigation_Item_Inset_Offset)];
        UIBarButtonItem *shareBarButtonItem = [[UIBarButtonItem alloc]
                                               initWithCustomView:shareButton];
        
        
        UIButton *settingButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"setting_button.png"] target:self action:@selector(moreButtonClicked:)];
        settingButton.contentEdgeInsets = UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset*2, 0, -K_Navigation_Item_Inset_Offset*2);
        [settingButton setHitTestEdgeInsets:UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset*2, 0, -K_Navigation_Item_Inset_Offset*2)];
        UIBarButtonItem *settingBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithCustomView:settingButton];
        
        
        UIButton *helpButton;
        if ([MutipleTargetHelper isFullVersion]) {
            helpButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"helping_button.png"] target:self action:@selector(helpButtonClicked:)];
        } else {
            helpButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"helping_button_dimmed.png"] target:self action:@selector(helpButtonClicked:)];
        }
        helpButton.contentEdgeInsets = UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset*3, 0, -K_Navigation_Item_Inset_Offset*3);
        [helpButton setHitTestEdgeInsets:UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset*3, 0, -K_Navigation_Item_Inset_Offset*3)];
        UIBarButtonItem *helpBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithCustomView:helpButton];
        
        self.navigationItem.rightBarButtonItems =
        @[playBarButtonItem,shareBarButtonItem,settingBarButtonItem,helpBarButtonItem];
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (_addCardButton == nil) {
        if (isUserInterfaceIdiomPhone) {
            int leftSafeAread = 0;
            if (@available(iOS 11.0, *)) {
                leftSafeAread = UIApplication.sharedApplication.keyWindow.safeAreaInsets.left;
            }
            _addCardButtonBackground = [[UIView alloc] initWithFrame:CGRectMake(0,0, 160, 60)];
            _addCardButtonBackground.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"add_card_background.png"]];
            _addCardButtonBackground.center = CGPointMake(80,IPHONE_UI_HEIGHT-30);
            _addCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            _addCardButton.center = CGPointMake(80 + leftSafeAread,IPHONE_UI_HEIGHT-30);
            
            
            
        } else {
            
            _addCardButtonBackground = [[UIView alloc] initWithFrame:CGRectMake(0,0, IPAD_UI_MASTER_WIDTH, 70)];
            _addCardButtonBackground.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"add_card_background.png"]];
            _addCardButtonBackground.center = CGPointMake(IPAD_UI_MASTER_WIDTH/2,IPAD_UI_HEIGHT-35);
            
            _addCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
            _addCardButton.center = CGPointMake(IPAD_UI_MASTER_WIDTH/2,IPAD_UI_HEIGHT-35);
        }
        
        _addCardButtonBackground.hidden = YES;
        
        if ([MutipleTargetHelper isFullVersion]) {
            [_addCardButton setImage:[UIImage imageNamed:@"plus_button.png"] forState:UIControlStateNormal];
            _addCardButton.hidden = false;
        } else {
            [_addCardButton setImage:[UIImage imageNamed:@"plus_button_dimmed.png"] forState:UIControlStateNormal];
            _addCardButton.hidden = true;
        }
        
        _addCardButton.showsTouchWhenHighlighted = YES;
        [_addCardButton addTarget:self action:@selector(createNewCard:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //Update right pack information (only appliable for iPhone）
    if ((isUserInterfaceIdiomPhone) && (_currentPack.packID != -1)) {   //must be a valid pack
        
        if (_packInfoView == nil) {
            _packInfoView = [ [PackInfoView alloc ] initWithFrame:CGRectMake((IPHONE_UI_WIDTH -150- 180)/2 + 150, 10, 180, IPHONE_UI_HEIGHT)];
            _packInfoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            _packInfoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:true];
            _packInfoView.delegate = self;
        } else {
            [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:false];
        }
        
        
            
    
        
        //make sure _packInfoView is under all the AMPopTips
        
        long miniumAMPopTipIndex = 1000000000;// big enough value
        for (UIView *myView in self.view.subviews) {
            long indexNow = [self.view.subviews indexOfObject:myView];
            if ((indexNow < miniumAMPopTipIndex) && ([myView isKindOfClass:[AMPopTip class]])) {
                miniumAMPopTipIndex = indexNow;
            }
        }
        
        if (miniumAMPopTipIndex <= 0) {
            miniumAMPopTipIndex = 1;
        }
        
        
        
        if (_adImageView != nil) {
            [self.view insertSubview:_packInfoView belowSubview:_adImageView];
        } else {
            [self.view insertSubview:_packInfoView atIndex:(miniumAMPopTipIndex -1)];
        }
        
    }
    
    [self.navigationController.view addSubview:_addCardButtonBackground];
    [self.navigationController.view insertSubview:_addCardButton atIndex:0];
    [self.navigationController.view bringSubviewToFront:_addCardButton];
    
    
    BOOL isExamplePackDownloadedSuccessful = [[NSUserDefaults standardUserDefaults] boolForKey:@"isExamplePackDownloadedSuccessful"];
    if (isExamplePackDownloadedSuccessful == FALSE) {
        //do nothing
    } else {
        if (APP_DELEGATE.isDownloadingSamplePack){
            APP_DELEGATE.isDownloadingSamplePack = FALSE;
        }
    }
    
    if ((isUserInterfaceIdiomPhone == FALSE) && ([[_currentPack cards] count] > 0)) {
//        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:_indexCard inSection:0];
//        [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
    }
    
    if (isUserInterfaceIdiomPhone) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed] == FALSE &&
            APP_DELEGATE.isDownloadingPack == FALSE) {
            [[TipHelper defaultHelper] showTipForRightNaviBarItemHelpInView:self.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 190, 0, 0, 0)];
        }
    }
    
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([MutipleTargetHelper isFullVersion] == false && [MutipleTargetHelper isNoAdVersion] == false && isUserInterfaceIdiomPhone && APP_DELEGATE.isDownloadingPack == false) {
        
        [self showAdView];
    }
}


- (void) viewWillDisappear:(BOOL)animated {
    if (isUserInterfaceIdiomPhone) {
        [_packInfoView removeFromSuperview];
    }
    
    [_addCardButtonBackground removeFromSuperview];
    [_addCardButton removeFromSuperview];
}

#pragma mark -
#pragma mark - Create or select Pack

- (void) createNewPack:(id)sender {
    
    if ([MutipleTargetHelper isFullVersion] == false) {
        [MutipleTargetHelper showAlertToUpgradeToFullVersion];
        return;
    }
    
    
    CreateEditPackViewController2 * createPackController;
    if (isUserInterfaceIdiomPhone) {
        createPackController = [[CreateEditPackViewController2 alloc] initWithNibName:@"CreateEditPackViewController2_iPhone" bundle:nil];
    } else {
        createPackController = [[CreateEditPackViewController2 alloc] initWithNibName:@"CreateEditPackViewController2_iPad" bundle:nil];
    }
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:createPackController];
    
    if (isUserInterfaceIdiomPhone) {
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
    } else {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    [self presentModalViewController:navController animated:YES];
    
}

- (void)selectAvailablePacks:(id)sender
{
    
    LineLayout* lineLayout = [[LineLayout alloc] init];
    PackListViewControllerV2 *packListViewController = [[PackListViewControllerV2 alloc] initWithCollectionViewLayout:lineLayout];
    packListViewController.packIDInMasterView = _currentPack.packID;
    
    if (isUserInterfaceIdiomPhone) {
        
        if ([[self.navigationController topViewController] isKindOfClass:[PackListViewControllerV2 class] ]== false) {
            packListViewController.view.backgroundColor = [UIColor colorWithRed:63.0/255 green:63.0/255 blue:63.0/255 alpha:0.3];
            [self.navigationController pushViewController:packListViewController animated:YES];
        }
        
        
        
    } else {
        
        packListViewController.view.clipsToBounds = YES;
        packListViewController.view.layer.cornerRadius = 0;
        packListViewController.view.backgroundColor = [UIColor colorWithRed:63.0/255 green:63.0/255 blue:63.0/255 alpha:0.3];
        packListViewController.contentSizeForViewInPopover = CGSizeMake(970, 340);
        
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:packListViewController];
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            navController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        }
        
        
        if (_packListPickerPopover == nil) {
            _packListPickerPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
            _packListPickerPopover.delegate = self;
            _packListPickerPopover.popoverContentSize = CGSizeMake(950, 340);
            if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
                _packListPickerPopover.backgroundColor = [UIColor colorWithRed:63.0/255 green:63.0/255 blue:63.0/255 alpha:.3];
            }
        }
        packListViewController.popController = _packListPickerPopover;
        
        [_packListPickerPopover presentPopoverFromRect:CGRectMake(0, 0, 50, 50) inView:self.navigationController.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}

#pragma mark -
#pragma mark Create new card

- (void)createNewCard:(id)sender
{
    
    if ([MutipleTargetHelper isFullVersion] == false) {
        [MutipleTargetHelper showAlertToUpgradeToFullVersion];
        return;
    }

    if (![Common isOwner:_currentPack]) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_NOT_ALLOW_CREATE_CARD_THAT_IS_NOT_YOU",@"")];
        return;
    }
    
    //For iPhone, we don't need it
    if (!isUserInterfaceIdiomPhone) {
        if (_backgroundOfCreateCardView == nil) {
            _backgroundOfCreateCardView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
        }
        _backgroundOfCreateCardView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8];
        _backgroundOfCreateCardView.layer.opacity = 0;
        __weak __typeof(&*self)weakSelf = self;
        [UIView animateWithDuration:0.3 animations:^{
            _backgroundOfCreateCardView.layer.opacity = 1;
            [weakSelf.navigationController.view addSubview:_backgroundOfCreateCardView];
        }];
        [_backgroundOfCreateCardView addTarget:self action:@selector(dismissCreateCardView:) forControlEvents:UIControlEventTouchDown];
        
        
        //Avoid fast click to crash app
        _addCardButton.enabled = FALSE;
        _backgroundOfCreateCardView.enabled = FALSE;
        self.view.userInteractionEnabled = NO;
        double delayInSeconds = 0.8;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            _backgroundOfCreateCardView.enabled = YES;
            _addCardButton.enabled = YES;
            weakSelf.view.userInteractionEnabled = YES;
        });
        
    }
    
    
    
    CreateCardViewController *createCardViewController = [[CreateCardViewController alloc] init];
    createCardViewController.currentPack = _currentPack;
    if (!isUserInterfaceIdiomPhone){
        createCardViewController.view.frame =CGRectMake(0,0,IPAD_UI_DETAIL_WIDTH,IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
        [self.detailViewController.navigationController pushViewController:createCardViewController animated:YES];
        
    } else {
        createCardViewController.view.frame =CGRectMake(0,0,480,320-44);
        [self.navigationController pushViewController:createCardViewController animated:YES];
        
    }
    
}

extern BOOL isFromNewCreatedCard;

- (void) dismissCreateCardView:(id)sender {
    
    isFromNewCreatedCard = NO;
    
    [self.detailViewController.navigationController popViewControllerAnimated:YES];
    
    _addCardButton.enabled = NO;
    _backgroundOfCreateCardView.enabled = NO;
    self.view.userInteractionEnabled = NO;
    
    __weak __typeof(&*self)weakSelf = self;
    double delayInSeconds = 0.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [_backgroundOfCreateCardView removeFromSuperview];
        _addCardButton.enabled = YES;
        _backgroundOfCreateCardView.enabled = YES;
        weakSelf.view.userInteractionEnabled = YES;
    });
}

#pragma mark -
#pragma mark UIBarButtonItem action


- (void)playButtonClicked
{
    
    PlayViewControllerV2 *playViewController = [[PlayViewControllerV2 alloc] init];
    
    int playOption = [Common getPlayOption];
    switch (playOption) {
        case 0:
            playViewController.oneOffPlayType = One_Off_Play_Type_Manually;
            break;
        case 1:
            playViewController.oneOffPlayType = One_Off_Play_Type_Auto_Play;
            break;
        case 2:
            playViewController.oneOffPlayType = One_Off_Play_Type_Auto_Play_Loop;
            break;
            
        default:
            break;
    }
    
    playViewController.currentPack = self.currentPack;
    
    
    //playViewController.currentCard = self.currentCard;
    if (isUserInterfaceIdiomPhone) {
        playViewController.view.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT);
    } else {
        playViewController.view.frame = CGRectMake(0, 0, IPAD_UI_WIDTH, IPAD_UI_HEIGHT);
    }
    playViewController.view.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if ((self.currentCard == nil) || (self.currentPack == nil)) {
        [Common alertViewCommon:@"There are no packs loaded"];
        return;
    }
    
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow.rootViewController presentModalViewController:playViewController animated:YES];
    
    
}

- (void)shareButtonClicked:(id) sender {
    
    int offset = 0;
    if (isUserInterfaceIdiomPhone) {
        offset = 5;
    }
    
    CGPoint point = [((UIButton *)sender) convertPoint:CGPointZero toView:self.view];
    CGPoint normalizedPoint = CGPointMake(point.x + CGRectGetWidth(((UIButton *)sender).frame)/2 + offset, point.y + CGRectGetHeight(((UIButton *)sender).frame));
    
    PopoverView *shareSelectPopupPopoverView;
    if ([MutipleTargetHelper isFullVersion]) {
        shareSelectPopupPopoverView = [PopoverView showPopoverAtPoint:normalizedPoint
                                 inView:self.view
                              withTitle:NSLocalizedString(@"Label_Please_Select",@"")
                        withStringArray:[NSArray arrayWithObjects:NSLocalizedString(@"Optional_Install_From_The_Code",@""), NSLocalizedString(@"Optional_Share_The_Pack",@""), nil]
                               delegate:self];
    } else {
        shareSelectPopupPopoverView = [PopoverView showPopoverAtPoint:normalizedPoint
                                                               inView:self.view
                                                            withTitle:NSLocalizedString(@"Label_Please_Select",@"")
                                                      withStringArray:[NSArray arrayWithObjects:NSLocalizedString(@"Optional_Install_From_The_Code",@""), nil]
                                                             delegate:self];
    }
    
    shareSelectPopupPopoverView.tag = popover_enum_share;
    
    
}

- (void)moreButtonClicked:(id) sender
{
    MoreInfoTableViewController *moreInfoViewController = [[MoreInfoTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:moreInfoViewController animated:YES];
}


// on iPhone, Help button only  exists on master
- (void)helpButtonClicked:(id) sender
{
    
    if ([MutipleTargetHelper isFullVersion] == false) {
        [MutipleTargetHelper showAlertToUpgradeToFullVersion];
        return;
    }
    
    
    BOOL isNotAllowShowTooltip_Master = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Master_Not_Allow];
    BOOL isNotAllowShowTooltip_FlashCard = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_FlashCard_Not_Allow];
    BOOL isNotAllowShowTooltip_Detail = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Detail_Not_Allow];
    
    if ((isNotAllowShowTooltip_Master || isNotAllowShowTooltip_FlashCard || isNotAllowShowTooltip_Detail) ||
        ([[TipHelper defaultHelper] isAllInvisible])) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO  forKey:K_Tooltip_FlashCard_Not_Allow];
        [defaults setBool:NO  forKey:K_Tooltip_Master_Not_Allow];
        [defaults setBool:NO  forKey:K_Tooltip_Detail_Not_Allow];
        [defaults synchronize];
        
        if (isUserInterfaceIdiomPhone == false) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_TOOLTIPS_NOTIFICATION object:nil userInfo:nil];
        }
        [self showTooltips];
        
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES  forKey:K_Tooltip_FlashCard_Not_Allow];
        [defaults setBool:YES  forKey:K_Tooltip_Master_Not_Allow];
        [defaults setBool:YES  forKey:K_Tooltip_Detail_Not_Allow];
        [defaults synchronize];
        
        [[TipHelper defaultHelper] hideEverything];
    }
    
}


- (void)editButtonClicked:(id) sender
{
    if ([MutipleTargetHelper isFullVersion] == false) {
        [MutipleTargetHelper showAlertToUpgradeToFullVersion];
        return;
    }
    
    if (self.tableView.editing == FALSE) {
        self.tableView.editing = TRUE;
        [((UIButton *)sender) setImage:[UIImage imageNamed:@"done_button"] forState:UIControlStateNormal];
        
    } else {
        self.tableView.editing = FALSE;
        [((UIButton *)sender) setImage:[UIImage imageNamed:@"edit_button"] forState:UIControlStateNormal];
        
        if (!isUserInterfaceIdiomPhone) {
            if ([[_currentPack cards]count] >0) {
                [self.tableView reloadData];
                NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
                
                
            } else {
                self.detailViewController.title = @"";
                self.detailViewController.currentPack = nil;
                self.detailViewController.indexCard = 0;
                [self.detailViewController showCurrentCardInScrollView:YES];
            }
        }
    }
    
}


#pragma mark -
#pragma mark Notfication related

-(void)shareLinkCreatedNotification:(NSNotification *)notification {
    
    NSString *shareLink = [notification object];
    _currentPack.shareLink = shareLink;
    
    [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:false];
    
    if (_adImageView != nil) {
        [self.view bringSubviewToFront:_adImageView];
    }
    
    if ([MutipleTargetHelper isFullVersion] == false && [MutipleTargetHelper isNoAdVersion] == false && isUserInterfaceIdiomPhone && APP_DELEGATE.isDownloadingPack == false) {
        
        [self showAdView];
    }
}

- (void) downloadPackNotification:(NSNotification *) notification {
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.isDownloadingPack = TRUE;
    
    NSString *url = (NSString *)[notification object];
    
    [self downloadURLViaURLScheme:url];
}

- (void) selectedPackNotification:(NSNotification *) notification {
    
    Pack *pack = (Pack *)[notification object];
    [self selectPack:pack];
    
}

- (void) selectPack:(Pack *) pack {
    
    NSMutableArray *allPacks = [[User defaultUser] packs];
    for (Pack *itempPack in allPacks) {
        if (itempPack.packID == pack.packID) {
            self.currentPack = itempPack;
            break;
        }
    }
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.packIDForMasterViewPack = self.currentPack.packID;
    
    if (!isUserInterfaceIdiomPhone) {
        [_packListPickerPopover dismissPopoverAnimated:YES];
        _packListPickerPopover = nil;
        self.detailViewController.title = _currentPack.packName;
    } else {
                self.title = _currentPack.packName;
        
                UILabel *titleLabel = (UILabel *)self.navigationItem.titleView;
                titleLabel.text = _currentPack.packName;;
    }
    
    [self.tableView setEditing:NO];
    [_editButton setImage:[UIImage imageNamed:@"edit_button.png"] forState:UIControlStateNormal];
    [self.tableView reloadData];
    
    if ((!isUserInterfaceIdiomPhone) && ([_currentPack cards].count != 0)) {
        self.detailViewController.currentPack = _currentPack;
        [self.detailViewController showPackInfoViewWithRebuildScrollView:false];
    } else if ((!isUserInterfaceIdiomPhone) && ([_currentPack cards].count == 0)) {
        self.detailViewController.title = @"";
        self.detailViewController.currentCard = nil;
        self.detailViewController.currentPack = _currentPack;
        self.detailViewController.indexCard = 0;
//        [self.detailViewController showCurrentCardInScrollView:YES];
        [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:false];
        
    }
    
    APP_DELEGATE.isAllowToShowTooltip = YES;
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Master_Not_Allow];
    BOOL val2 = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed];
    if (val == FALSE && val2) {
        [self showTooltips];
    }
    
    
}


-(void)removeBackgroundAfterCardCreatedNotification:(NSNotification *)notification{
    
    //we do refresh tableview cell in updateMasterAfterSaveCardNotification
    
    if (!isUserInterfaceIdiomPhone) {
        [_backgroundOfCreateCardView removeFromSuperview];
    }
}


-(void)editPackFinishedNotification:(NSNotification *)notification {
    self.currentPack = (Pack *)[notification object];
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.packIDForMasterViewPack = self.currentPack.packID;
    
    _indexCard = 0;
    
    [self.tableView reloadData];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    if (isUserInterfaceIdiomPhone) {
            self.title = _currentPack.packName;
        
              UILabel *titleLabel = (UILabel *)self.navigationItem.titleView;
              titleLabel.text = _currentPack.packName;;
        [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:false];
        
    } else {
        self.detailViewController.title = _currentPack.packName;
        [self.detailViewController showPackInfoViewWithRebuildScrollView:false];
    }
}

- (void) packDeleteNotification:(NSNotification *)notification {
    
    if (isUserInterfaceIdiomPhone) {
        if (_packInfoView.hidden == false) {
            [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:true];
        }
        
    } else {
        if ([self.detailViewController isPackInfoViewVisible]) {
            [self.detailViewController showPackInfoViewWithRebuildScrollView:true];
        }
    }
}

-(void)newPackAddedNotification:(NSNotification *)notification{
    self.currentPack = (Pack *)[notification object];
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.packIDForMasterViewPack = self.currentPack.packID;
    
    //Add a new card template
    Card *cardExample = [[Card alloc] init];
    cardExample.cardName = @"Example";
    cardExample.creator = [OpenUDID value];
    cardExample.packID = self.currentPack.packID;
    cardExample.cardSN = 1;  //Start from 1
    cardExample.question.subheading = @"";
    cardExample.question.main = @"";
    cardExample.question.sub = @"";
    cardExample.answer.subheading = @"";
    cardExample.answer.main = @"";
    cardExample.answer.sub = @"";
    cardExample.question.templateID = 0;
    cardExample.answer.templateID = 0;
    
    cardExample.answer.autoresizeFlag = 1;//默认表示允许
    cardExample.question.autoresizeFlag = 1;//默认表示允许
    
    cardExample.question.title = NSLocalizedString(@"ToolbarItem_Question",nil);
    cardExample.answer.title = NSLocalizedString(@"ToolbarItem_Answer",nil);
    [self.currentPack addCard:cardExample];
    
    _indexCard = 0;
    
    [self.tableView reloadData];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    if (isUserInterfaceIdiomPhone) {
        self.title = _currentPack.packName;
        UILabel *titleLabel = (UILabel *)self.navigationItem.titleView;
        titleLabel.text = _currentPack.packName;
        [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:true];
        
    } else {
        self.detailViewController.title = _currentPack.packName;
        [self.detailViewController showPackInfoViewWithRebuildScrollView:true];
    }
    
    APP_DELEGATE.isAllowToShowTooltip = YES;
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Master_Not_Allow];
    BOOL val2 = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed];
    if (val == FALSE && val2) {
        [self showTooltips];
    }
    
}

- (void) updateMasterAfterSaveCardNotification:(NSNotification *) notification {
    
    NSString *notificationStr = (NSString *)[notification object];
    
    //Update current pack and all cards in packs
    NSMutableArray *packs = [[User defaultUser] packs]; //重新获所有的pack
    for (Pack *pack in packs) {
        if (pack.packID == self.currentPack.packID) {
            self.currentPack = pack;
        }
    }
    
    [self.tableView reloadData];
    if ((isUserInterfaceIdiomPhone) || (![notificationStr isEqualToString:@"SENT_FROM_NEW_CARD"])) {
        //when we just edit the current card, we don't update detail view second time
        //or
        //when we in on iPhone
    } else {
        _indexCard = [[_currentPack cards] count] -1;
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:_indexCard inSection:0];
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self.tableView scrollToRowAtIndexPath:selectedIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
        
    }
}

- (void) updateMasterAfterDetailScrollNotification:(NSNotification *) notification {
    _indexCard = [(NSString *)[notification object] integerValue];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:_indexCard inSection:0];
    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
}

- (void) showPackListAfterDidBecomeActiveNotification :(NSNotification *) notification {
    //avoid this kind of issue: [UIPopoverController _commonPresentPopoverFromRect:inView:permittedArrowDirections:animated:]: Popovers cannot be presented from a view which does not have a window.
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.isDownloadingPack == NO && APP_DELEGATE.isAllowToShowPackList && (self.currentPack != nil && [self.currentPack.cards count] > 0)) {
        [self performSelector:@selector(showPackListAfterApplicationDidBecomeActive) withObject:nil afterDelay:0.5];
    }
    
}

- (void) showPackListAfterDismiss :(NSNotification *) notification {
    
    if (self.view.window == nil) {
        //The view's window property is non-nil if a view is currently visible, http://stackoverflow.com/questions/2777438/how-to-tell-if-uiviewcontrollers-view-is-visible
        //当在当前view controller弹出一个对话框时，则self.view.window不是nil,这也就是为什么需要额外参数APP_DELEGATE.isAllowToShowPackList的原因
        return;
    }
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.isDownloadingPack == NO && APP_DELEGATE.isAllowToShowPackList) {
        [self selectAvailablePacks:nil];;
    }
}


- (void) showPackListAfterApplicationDidBecomeActive {
    
    
    if (self.view.window == nil) {
        //The view's window property is non-nil if a view is currently visible, http://stackoverflow.com/questions/2777438/how-to-tell-if-uiviewcontrollers-view-is-visible
        //当在当前view controller弹出一个对话框时，则self.view.window不是nil,这也就是为什么需要额外参数APP_DELEGATE.isAllowToShowPackList的原因
        return;
    }
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.isDownloadingPack == NO && APP_DELEGATE.isAllowToShowPackList) {
        [self selectAvailablePacks:nil];;
    }
    
    
}


- (void) dismissPackListAfterDidEnterBackgroundNotification :(NSNotification *) notification {
    
    [iConsole info:@"%s",__FUNCTION__];
    
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    } else {
        if (_packListPickerPopover) {
            [_packListPickerPopover dismissPopoverAnimated:NO];
            _packListPickerPopover = nil;
        }
    }
    
    APP_DELEGATE.isAllowToShowTooltip = YES;
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Master_Not_Allow];
    BOOL val2 = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed];
    if (val == FALSE && val2) {
        [self showTooltips];
        
    }
}



- (void) iapPurchaseSuccessNotification: (NSNotification *) notification {
    
    if ([MutipleTargetHelper isFullVersion]) {
        [_addCardButton setImage:[UIImage imageNamed:@"plus_button.png"] forState:UIControlStateNormal];
        _addCardButton.hidden = false;
        
        _tableView.allowsSelection = true;
        
    } else {
        [_addCardButton setImage:[UIImage imageNamed:@"plus_button_dimmed.png"] forState:UIControlStateNormal];
        _addCardButton.hidden = true;
        
        _tableView.allowsSelection = false;
    }
    
    [self setupNaviBarButtonItems];
    
    if (isUserInterfaceIdiomPhone) {
        [self removeAdView];
    }
    
}

- (void) downloadCancelledNotification: (NSNotification *) notification {
    
    if (isUserInterfaceIdiomPhone) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed] == FALSE) {
            [[TipHelper defaultHelper] showTipForRightNaviBarItemHelpInView:self.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 190, 0, 0, 0)];
        }
    }
    
    if ([MutipleTargetHelper isFullVersion] == false && [MutipleTargetHelper isNoAdVersion] == false && isUserInterfaceIdiomPhone && APP_DELEGATE.isDownloadingPack == false) {
        
        [self showAdView];
    }
    
    if (isUserInterfaceIdiomPhone == false) {
        [self selectAvailablePacks:nil];
    }
    
}

#pragma mark – PLAY_NOTIFICATION, could be from pack list view, or preview button in card

- (void) playNotification :(NSNotification *) notification {
    
    if (isUserInterfaceIdiomPhone == FALSE) {
        [_packListPickerPopover dismissPopoverAnimated:YES];
        _packListPickerPopover = nil;
    } else {
        //[self.navigationController popToRootViewControllerAnimated:TRUE];
    }
    

    NSDictionary *dict = [notification userInfo];
    
    One_Off_Play_Type oneOffType = [[dict objectForKey:@"oneOffType"] intValue];
    int index                    = [[dict objectForKey:@"packIndex"] intValue];
    BOOL isPreviewOnly           = [[dict objectForKey:@"preview_only"] boolValue];
    BOOL isFromPackList          = [[dict objectForKey:@"isFromPackList"] boolValue];
    
    switch (oneOffType) {
        case 0:
            oneOffType = One_Off_Play_Type_Manually;
            break;
        case 1:
            oneOffType = One_Off_Play_Type_Auto_Play;
            break;
        case 2:
            oneOffType = One_Off_Play_Type_Auto_Play_Loop;
            break;
            
        default:
            oneOffType = One_Off_Play_Type_Unkown;
            break;
    }
    
    Pack *selectedPack;
    if (isPreviewOnly) {
        
        Card *screnshotCard = [notification object];
        
        selectedPack = [[Pack alloc] init];
        selectedPack.cards = [NSMutableArray arrayWithObject:screnshotCard];
        
        {
            //currently, we only need info of creator, but for future potential benefit, we try to copy everything except packID info, shareLink, and fileNameOnAWS
            
            selectedPack.packName = self.currentPack.packName;
            selectedPack.sidebarTitle = self.currentPack.sidebarTitle;
            selectedPack.coverImageURL = self.currentPack.coverImageURL;
            selectedPack.userID = self.currentPack.userID;
            selectedPack.languageName = self.currentPack.languageName;
            selectedPack.creator = self.currentPack.creator;
            selectedPack.creatorNickName = self.currentPack.creatorNickName;
            selectedPack.jobTitle = self.currentPack.jobTitle;
            selectedPack.lastVisitDate = self.currentPack.lastVisitDate;
            selectedPack.createDate = self.currentPack.createDate;
            selectedPack.restorePassword = self.currentPack.restorePassword;
            selectedPack.isAllowShare = self.currentPack.isAllowShare;
            selectedPack.autoPlaySpeed = self.currentPack.autoPlaySpeed;
            selectedPack.platform = self.currentPack.platform;
            
            selectedPack.shareLink = @"";
            selectedPack.fileNameOnAWS = @"";
            selectedPack.packID = [[NSString stringWithFormat:@"%f%ld", [[NSDate date] timeIntervalSince1970], (long)[[User defaultUser] userID]] intValue];
        }
        
        oneOffType = One_Off_Play_Type_Manually; //in preview mode, only manual is supported
        
        
    } else {
        selectedPack = [[[User defaultUser] packs] objectAtIndex:index];
    }
    
    PlayViewControllerV2 *playViewController = [[PlayViewControllerV2 alloc] init];
    playViewController.oneOffPlayType = oneOffType;
    playViewController.previewOnly = isPreviewOnly;
    playViewController.currentPack = selectedPack;
    playViewController.isFromPackList = isFromPackList;
    if ((self.currentCard == nil) || (self.currentPack == nil)) {
        [Common alertViewCommon:@"There are no packs loaded"];
        return;
    }
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow.rootViewController presentModalViewController:playViewController animated:YES];
    
    
}

- (void) toCreateNewPackNotification:(NSNotification *) notification {
    
    if (isUserInterfaceIdiomPhone == false) {
        [_packListPickerPopover dismissPopoverAnimated:YES];
        _packListPickerPopover = nil;
    }
    
    [self createNewPack:nil];
    
}

- (void) showIntroductionVideoNotification:(NSNotification *) notification {
    
    NSURL *url = [NSURL URLWithString:@"http://www.flipflashcards.com/newuser"];
    SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
    controller.hidesToolbar = NO;
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        controller.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:controller animated:YES];
    }
    
}


- (void) showVisitStoreNotification:(NSNotification *) notification {
    
    NSURL *url = [NSURL URLWithString:@"http://www.flipflashcards.com/packs"];
    SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
    controller.hidesToolbar = NO;
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        controller.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:controller animated:YES];
    }
    
}

- (void) showHelpNotification:(NSNotification *) notification {
    
    NSURL *url = [NSURL URLWithString:@"http://www.flipflashcards.com/quick-start-tutorial/"];
    SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
    controller.hidesToolbar = NO;
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        controller.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:controller animated:YES];
    }
    
}

#pragma mark -
#pragma mark - Update UI

- (void) updateMasterDetailViewAfterParseDownloadPackFinishNotification:(NSNotification *) notification {
    //Step1: update master view
    self.currentPack = (Pack *)[notification object];
    
    
    self.indexCard = 0;
    //_selectPackButton.title = _currentPack.packName;
    [self.tableView reloadData];
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.isDownloadingPack = FALSE;
    appDelegate.isAllowToShowPackList = TRUE;
    
    
    if (isUserInterfaceIdiomPhone == FALSE) {
        appDelegate.packIDForMasterViewPack = self.currentPack.packID;
        
        self.detailViewController.detailItem = _currentCard.cardName;
        self.detailViewController.currentCard = _currentCard;
        self.detailViewController.currentPack = _currentPack;
        self.detailViewController.indexCard = _indexCard;
        
        //NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:_indexCard inSection:0];
       // [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self.detailViewController showPackInfoViewWithRebuildScrollView:true];
        
        //ffc sample card must be named as ffc sample cards
        if ([self.currentPack.packName.lowercaseString rangeOfString:@"ffc sample cards"].location != NSNotFound ) {
            [self selectAvailablePacks:nil];
        }
        
    } else {
        
        [self selectAvailablePacks:nil];
        
        [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:true];
        
        if (_adImageView != nil) {
            [self.view bringSubviewToFront:_adImageView];
        }
        
        if ([MutipleTargetHelper isFullVersion] == false && [MutipleTargetHelper isNoAdVersion] == false && isUserInterfaceIdiomPhone && APP_DELEGATE.isDownloadingPack == false) {
            
            [self showAdView];
        }
    }
    
    
    
    
}


- (void) removeAdView {
    if (_adImageView != nil) {
        [_adImageView removeFromSuperview];
        _adImageView = nil;
    }
}

- (void) showAdView {
    
    if (_adImageView != nil) {
        [_adImageView removeFromSuperview];
        _adImageView = nil;
    }
    
    if ([MutipleTargetHelper isFullVersion] && [MutipleTargetHelper isNoAdVersion]) {
        return;
    }
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
    
    
    _adImageView = [[UIImageView alloc] init];
    [_adImageView setContentMode:UIViewContentModeScaleAspectFit];
    _adImageView.autoresizingMask = UIViewAutoresizingNone;
    _adImageView.clipsToBounds = YES;
    _adImageView.frame = CGRectMake(IPHONE_UI_MASTER_TABLE_WIDTH + 10, 15, CGRectGetWidth(self.view.frame) - IPHONE_UI_MASTER_TABLE_WIDTH - 10 *2, 50);
    
    [_adImageView sd_setImageWithURL:[NSURL URLWithString:@"http://www.flipflashcards.com/promo/upgrade.png"] placeholderImage:[UIImage imageNamed:@"ad_banner"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error == nil) {
        }
    }];
//
//    [_adImageView setImage:[UIImage imageNamed:@"ad_banner"]];
    
    _adImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:_adImageView];
    
    _adImageView.userInteractionEnabled = true;
    UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPurchaseView)];
    oneTap.numberOfTapsRequired = 1;
    [_adImageView addGestureRecognizer:oneTap];
    
}


#pragma mark -
#pragma mark UITableViewDataSource and UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ([[_currentPack cards] count]); //test purpose
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (isUserInterfaceIdiomPhone) {
        return kCellSizeHeight_iPhone;
    } else {
        return kCellSizeHeight_iPad;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CardCell";
    
    CardCell *cell = (CardCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[CardCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UIImageView *backgroundView = [[UIImageView alloc] init];
        backgroundView.layer.opacity = 0.8;
        backgroundView.backgroundColor = [UIColor colorWithRed:127.0/255 green:134.0/255 blue:164.0/255 alpha:0.8];
        backgroundView.layer.cornerRadius = 5;
        backgroundView.layer.masksToBounds = YES;
        cell.selectedBackgroundView = backgroundView;
    }
    
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    Card *card = [_currentPack cards][indexPath.row];
    
    //Just to keep consistent: indexPath.row should be same as card.cardSN
    if (card.cardSN != indexPath.row +1) {
        [iConsole info:@"card.cardSN = %ld, indexPath.row = %ld", (long)card.cardSN, (long)indexPath.row];
        [iConsole info:@"******warning: We have to reorder it since it's not consistent"];
        card.cardSN = indexPath.row +1;
        [card save];
    }
    
    cell.indexLabel.text = [NSString stringWithFormat:@"%ld",card.cardSN];
    
    
    NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[card.coverImageURL lastPathComponent]];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if (([Common isPlaceholderFilePathOrDirectory:card.coverImageURL] == FALSE) && (image != NULL)) {
        cell.cellImageView.image = image;
    } else {
        if (self.currentPack.sidebarTitle.length > 0) {
            cell.cellImageView.image = [UIImage imageNamed:@"card_cover_image_placeholder_title.png"];
        } else {
            cell.cellImageView.image = [UIImage imageNamed:@"card_cover_image_placeholder.png"];
        }
        
    }
    
    if (_indexCard == indexPath.row) {
        [cell setSelected:YES animated:YES];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    
    
    cell.leftUtilityButtons = [self leftUtilityButtons];
    cell.rightUtilityButtons = [self rightUtilityButtons];
    cell.delegate = self;
    
    
    return cell;
    
}

- (NSArray *)rightUtilityButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:NSLocalizedString(@"TableView_Cell_Action_Delete",@"")];
    
    return rightUtilityButtons;
}

- (NSArray *)leftUtilityButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.07 green:0.75f blue:0.16f alpha:1.0]
                                                title:NSLocalizedString(@"TableView_Cell_Action_Copy",@"")];
    return leftUtilityButtons;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    [iConsole info:@"%s",__FUNCTION__];
    self.currentCard = [_currentPack cards][indexPath.row];
    _indexCard = indexPath.row;
    
    if (_currentPack.packID == PUBLIC_PACK_ID) {
        [Common alertViewCommon:@"will implement this function soon"];
        
    } else {
        if (isUserInterfaceIdiomPhone ) {
            if (!self.detailViewController) {
                self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil];
            }
            self.detailViewController.currentCard = _currentCard;
            self.detailViewController.currentPack = _currentPack;
            self.detailViewController.indexCard = _indexCard;
            
            [self.detailViewController switchToQuestionCard];
            
            //We need to avoid do pushViewController twice.
            NSArray *viewControllerArray =self.navigationController.viewControllers;
            if (![[viewControllerArray objectAtIndex:[viewControllerArray count]-1] isKindOfClass:[self.detailViewController class]]) {
                [self.navigationController pushViewController:self.detailViewController animated:YES];
            }
        } else {
            self.detailViewController.currentCard = _currentCard;
            self.detailViewController.currentPack = _currentPack;
            self.detailViewController.indexCard = _indexCard;
            [self.detailViewController removePackInfoView];
            [self.detailViewController showCurrentCardInScrollView:YES];
        }
    }
    
    if (isUserInterfaceIdiomPhone) {
        /*
         To conform to the Human Interface Guidelines, selections should not be persistent --
         deselect the row after it has been selected.
         */
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    _currentIndexPath = indexPath;
    
    if (![Common isOwner:_currentPack]) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"")];
        return;
    }
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        __weak __typeof(&*self)weakSelf = self;
        
        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_DELETE_CARD",@"") cancelButtonTitle:NSLocalizedString(@"Keyboard_Delete",@"") otherButtonTitles:@[NSLocalizedString(@"Keyboard_Cancel",@"")] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            [weakSelf didClickDeleteCardAlertView:alertView clickedButtonAtIndex:buttonIndex];
        }];
        
        APP_DELEGATE.isAllowToShowPackList = NO;
    }
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self moveAction:fromIndexPath toIndexPath:toIndexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void) showPurchaseView {
    [MutipleTargetHelper showPurchaseView];
}

- (void) deleteCurrentCard:(NSIndexPath *)indexPath {
    
    NSArray *tempCards = [_currentPack cards];
    
    //remove card from _currentPack
    [_currentPack removeCard:tempCards[indexPath.row]];
    //_currentPack.cards = [_currentPack snOrderedCards]; //We need to re-order
    
    //remove from tableView
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil]
                          withRowAnimation:UITableViewRowAnimationFade];
    
    //reset cardSN
    for (int i = indexPath.row; i < [tempCards count] ; i++) {
        if (((Card *)tempCards[i]).cardSN != i + 1) {
            ((Card *)tempCards[i]).cardSN = i + 1;
            [((Card *)tempCards[i]) save];
        }
    }
    
    //update tableview
    [self.tableView reloadData];
    
    if (!isUserInterfaceIdiomPhone) {
        if ([[_currentPack cards] count] >0) {
           
            if ([self.detailViewController isPackInfoViewVisible]) {
                self.detailViewController.currentPack = _currentPack;
                [self.detailViewController showPackInfoViewWithRebuildScrollView:false];
                
            } else {
                
                NSIndexPath *selectedIndexPath;
                if (indexPath.row != 0) {
                    selectedIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:0];
                } else {
                    selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                }
                [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
            }
            
        } else {
            self.detailViewController.title = @"";
            self.detailViewController.currentCard = nil;
            self.detailViewController.indexCard = 0;
            [self.detailViewController showCurrentCardInScrollView:YES];
        }
    } else {
        
        [_packInfoView refreshWithRebuildScrollView:false];
        
    }
    
}


#pragma mark – SWTableViewDelegate

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return true;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0: {
            //copy
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            if (![Common isOwner:_currentPack]) {
                [Common alertViewCommon:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"")];
                return;
            }
            Card *selectedCard = [_currentPack cards][cellIndexPath.row];
            if (selectedCard && _currentPack) {
                Card *copy = [_currentCard deepCopy];
                [_currentPack insertCard:copy afterCardID:selectedCard.cardID];
                [_currentPack save];
                [self.tableView reloadData];
            }
            
            break;
        }
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0: {
            //delete
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            _currentIndexPath = cellIndexPath;
            if (![Common isOwner:_currentPack]) {
                [Common alertViewCommon:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"")];
                return;
            }
            
            [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_DELETE_CARD",@"") cancelButtonTitle:NSLocalizedString(@"Keyboard_Delete",@"") otherButtonTitles:@[NSLocalizedString(@"Keyboard_Cancel",@"")] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                [self didClickDeleteCardAlertView:alertView clickedButtonAtIndex:buttonIndex];
            }];
            
            APP_DELEGATE.isAllowToShowPackList = NO;
            
            break;
        }
        default:
            break;
    }
}

#pragma mark -
#pragma mark - FMMoveTableView special delegate


- (void)moveTableView:(FMMoveTableView *)tableView willMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (BOOL)moveTableView:(FMMoveTableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return true;
}

- (void)moveTableView:(FMMoveTableView *)tableView moveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [self moveAction:fromIndexPath toIndexPath:toIndexPath];
}


#pragma mark -
#pragma mark - Move action

- (void) moveAction: (NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *) toIndexPath {
    [iConsole info:@"move from:%ld to:%ld", (long)fromIndexPath.row, (long)toIndexPath.row];
    
    if (fromIndexPath.row == toIndexPath.row)
        return;
    
    //Step1: recalculate cardSN
    Card *temp;
    if (fromIndexPath.row < toIndexPath.row) {
        for (int i = fromIndexPath.row +1; i<= toIndexPath.row; i++) {
            temp = (Card *)([_currentPack cards][i]);
            temp.cardSN = i;
            [temp save];
        }
        
        temp = (Card *)([_currentPack cards][fromIndexPath.row]);;
        temp.cardSN = toIndexPath.row + 1;
        [temp save];
        
    } else {
        for (int i = toIndexPath.row; i< fromIndexPath.row; i++) {
            temp = (Card *)([_currentPack cards][i]);
            temp.cardSN = i+2;
            [temp save];
        }
        
        temp = (Card *)([_currentPack cards][fromIndexPath.row]);;
        temp.cardSN = toIndexPath.row + 1;
        [temp save];
    }
    
    //Step2: execute move. We just reset cardSN
    Card *r = [_currentPack cards][fromIndexPath.row];
    r.cardSN = toIndexPath.row +1;
    [r save];
    
    _currentPack.cards = [_currentPack snOrderedCards]; //We need to reorder
    
    
    [self.tableView reloadData];
    if (!isUserInterfaceIdiomPhone) {
//        [self.tableView selectRowAtIndexPath:toIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
//        [self tableView:self.tableView didSelectRowAtIndexPath:toIndexPath];
    }
}

#pragma mark -
#pragma mark - ZipFileDownloadHelperDelegate

- (void)downloadProgressivePercent:(long long)current totalLength:(long long)total {
    _progressivePercent = (float) current/total;
    _HUD.progress = (float) current/total;
}

- (void)downloadSuccess:(BOOL)isSucess {
    if (isSucess == YES) {
        [iConsole info:@"%s, download success",__FUNCTION__];
        [_HUD hide:YES];
        [self checkPassword];
    } else {
        [iConsole info:@"%s,download failed",__FUNCTION__];
    }
}

- (void)downloadFail {
    [_HUD hide:YES];
}

#pragma mark -
#pragma mark - Download action

- (void) downloadURLViaURLScheme:(NSString *)urlStr{
    
    if ([DataManager apiReachable] == NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_TITLE_NO_NETWORK",@"")
                                                        message:NSLocalizedString(@"DIALOG_PLEASE_CHECK_YOUR_NETWORK",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"")
                                              otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    NSString *httpURL = [urlStr stringByReplacingOccurrencesOfString:@"fcc" withString:@"http"]; //TODO, @"http" needs to be changed to @"https" in future
    NSString *downloadableURL = [httpURL stringByReplacingOccurrencesOfString:@"www" withString:@"dl"];
    NSDictionary *params = [NSString queryParamsFromString:downloadableURL];
    NSString *type = params[@"type"];
    NSString *from = params[@"from"];
    
    if (from == NULL) {
        from = @"Unknown person";
    }
    
    NSString *simpleDBItemName;
    if ([urlStr.lowercaseString rangeOfString:@"google.com"].location != NSNotFound) {
        
       //Google drive
        
        //example of urlStr: fcc://drive.google.com/uc?id=0ByMe_Cq4emVvbDg4WGF4WHllV1E&export=download?from=
        NSDictionary *dict = [NSString queryParamsFromString:urlStr];
        simpleDBItemName = [dict objectForKey:@"id"];
        
    } else {
        
        //Dropbox or AWS logic
        
        //example of urlStr "fcc://s3.amazonaws.com/internetics.flashcardcreator/internetics.flashcardcreator/Pack1432614117-1358153070.zip?from=Microsoft"
        //[urlStr lastPathComponent] is kind of "Pack1374148414-1884690931.zip?from=Microsoft"
        NSRange range = [[urlStr lastPathComponent] rangeOfString:@".zip"];
        simpleDBItemName = [[urlStr lastPathComponent] substringToIndex:range.location];
    }
    
    
    
    
    [self showDownloadProgressIndicator:type withSource:from];
    
    __weak __typeof(&*self)weakSelf = self;
    double delayInSeconds = 0.01;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        BOOL isAllowedToDownload;
        if ([type.lowercaseString isEqualToString:@"demo"]) {
            isAllowedToDownload = YES;
        } else {
            isAllowedToDownload = [weakSelf checkDownloadable:simpleDBItemName];
        }
        if (isAllowedToDownload) {
            NSString *downloadableURL = [ZipFileDownloadHelper convertToDownloadableURL:urlStr];
            [_zipFileDownloadHelper downloadZipFile:downloadableURL];
            _zipFileDownloadHelper.delegate = weakSelf;
        }  else {
            [_HUD hide:YES];
            
            double delayInSeconds = 0.3;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [Common alertViewCommon:NSLocalizedString(@"DIALOG_REACH_MAX_DOWNLOAD_LIMIT",@"")];
                [iConsole error:@"%s,You have reached the limit of downloads for this pack",__FUNCTION__];
            });
        }
        
    });
    
}

- (BOOL) checkDownloadable: (NSString *) itemName{
    BOOL result = false;
    
    NSString *defaultDomain = [SimpleDBHelper defaultDomain];
    
    //    itemName = @"Pack1374144082-185879295"; //only for test, will be removed
    
    _amazonSimpleDBItemName = itemName;
    NSMutableDictionary *dict = [SimpleDBHelper fetchAttributeValuesAtItem:itemName withDomainName:defaultDomain];
    
    _currentDownloadCount = [[dict objectForKey:@"currentNo"] intValue];
    _maxDownloadCount = [[dict objectForKey:@"maxNo"] intValue];
    
    if ((_currentDownloadCount < _maxDownloadCount)  || (_maxDownloadCount == 0)) {  //maxNo = 0 means no record in AmazonSDB
        result = TRUE;
        [iConsole info:@"%s:checkDownloadable = YES",__FUNCTION__];
    } else {
        result = FALSE;
        [iConsole info:@"%s:checkDownloadable = NO",__FUNCTION__];
    }
    
    return result;
}


#pragma mark -
#pragma mark - UIAlertViewDelegate

- (void) didClickDeleteCardAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self deleteCurrentCard:_currentIndexPath];
    } else if (buttonIndex == 1) {
        //do nothing
    }
    
    APP_DELEGATE.isAllowToShowPackList = YES;
}

- (void) didClickSetPasswordAlertView:(UIAlertView *)alertView{
    NSString *password = [alertView textFieldAtIndex:0].text;
    
    if (password == NULL) {
        password = @"";
    }
    
    ZipArchive* za = [[ZipArchive alloc] init];
    NSString *downloadedZipPackFileFixedPath = [FileOperationHelper downloadedZipPackFileFixedPath];
    if( [za UnzipOpenFile:downloadedZipPackFileFixedPath Password:password]) {
        BOOL ret = [za UnzipFileTo:[FileOperationHelper downloadedPackFileDirectory] overWrite:YES];
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[FileOperationHelper unzippedPackInfoJsonFilePath] error:nil];
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];
        
        if (( NO==ret ) || (fileSize == 0)) {
            //when password encripted, will go into here to
            [iConsole error:@"%s\nUnzip file(%@) failed",__FUNCTION__,downloadedZipPackFileFixedPath];
            [Common alertViewCommon:NSLocalizedString(@"DIALOG_WRONG_PASSWORD",@"")];
            [za UnzipCloseFile];
        } else {
            [iConsole info:@"%s\nUnzip file successfully",__FUNCTION__];
            [za UnzipCloseFile];
            
            [[NSFileManager defaultManager] removeItemAtPath:downloadedZipPackFileFixedPath error:nil];
            
            [self assemblePack];
        }
        
    } else {
        [iConsole info:@"%sFailure to unzip downloaded file(%@)",__FUNCTION__,downloadedZipPackFileFixedPath];
        [Common alertViewCommon:@"Failure to unzip downloaded file"];
        [za UnzipCloseFile];
    }
    
    APP_DELEGATE.isAllowToShowPackList = YES;
    
}


- (void) downloadPackWithCode:(NSString *)downloadCode {
    
    NSString *urlStr = [NSString stringWithFormat:@"http://tinyurl.com/%@",downloadCode];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [NSURLConnection connectionWithRequest:request delegate:self];
    //NSURLConnectionDataDelegate will take care following actions
}



#pragma mark -
#pragma mark - Unzip and assemble pack/card

- (void) checkPassword {
    
    ZipArchive* za = [[ZipArchive alloc] init];
    NSString *downloadedZipPackFileFixedPath = [FileOperationHelper downloadedZipPackFileFixedPath];
    
    BOOL success = [CryptorHelper decryptFileWithSameOutput:downloadedZipPackFileFixedPath];
    if (success == false) {
        //        [Common alertViewCommon:@"Failure to decrypt zipped share file."];
        //        return;
        [iConsole warn:@"%s:Possiblly you are using a old version without zip file encripted",__FUNCTION__];
    }
    
    [za UnzipOpenFile:downloadedZipPackFileFixedPath];
    if( [za UnzipIsEncrypted]) {
        
        __weak __typeof(&*self)weakSelf = self;
        UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:nil message:NSLocalizedString(@"DIALOG_ENTER_PASSWORD",@"")];
        [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alertView textFieldAtIndex:0].text = @"";
        [alertView bk_setCancelButtonWithTitle:NSLocalizedString(@"Keyboard_Done",@"") handler:^{
            [weakSelf didClickSetPasswordAlertView:alertView];
        }];
        [alertView bk_addButtonWithTitle:NSLocalizedString(@"Keyboard_Cancel",@"") handler:nil];
        [alertView show];
        
        
        
        
        APP_DELEGATE.isAllowToShowPackList = NO;
    } else {
        BOOL ret = [za UnzipFileTo:[FileOperationHelper downloadedPackFileDirectory] overWrite:YES];
        if( NO==ret ) {
            [iConsole error:@"%s\nUnzip file(%@) failed",__FUNCTION__,downloadedZipPackFileFixedPath];
        } else {
            [iConsole info:@"%s\nUnzip file successfully",__FUNCTION__];
        }
        [za UnzipCloseFile];
        
        [[NSFileManager defaultManager] removeItemAtPath:downloadedZipPackFileFixedPath error:nil];
        
        [self assemblePack];
    }
    
}

/**
 *  unzip pack, then save
 */
- (void) assemblePack {
    
    //Step2: buid pack
    Pack *pack = [[Pack alloc] init];
    NSError *error = nil;
    NSString *downloadedPackInfoFilePath = [[FileOperationHelper downloadedPackFileDirectory] stringByAppendingPathComponent:@"packInformation.json"];
    
    NSData *packData = [NSData dataWithContentsOfFile:downloadedPackInfoFilePath];
    if (!packData) {
        [iConsole error:@"%s:error to parse packInformation.json and downloadedPackInfoFilePath = %@",__FUNCTION__,downloadedPackInfoFilePath];
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_ERROR_WHEN_PARSING_PACK_JSON",@"")];
        return;
    }
    id packJsonObject = [NSJSONSerialization JSONObjectWithData:packData options:
                         NSJSONReadingMutableContainers error:&error];
    if (packJsonObject != nil && error == nil) {
        if ([packJsonObject isKindOfClass:[NSDictionary class]]){
            
            NSDictionary *packDict = (NSDictionary *)packJsonObject;
            
            [iConsole info:@"%s:packDict =%@",__FUNCTION__,packDict];
            
            pack.packName = packDict[@"pack_name"];
            
            if ([pack.packName.lowercaseString isEqualToString:@"sample pack test"]) {
                pack.packName = NSLocalizedString(@"Sample_Cards",@"");;
            }
            
            pack.sidebarTitle = packDict[@"sidebar_title"];
            pack.autoPlaySpeed = [packDict[@"auto_play_speed"] intValue];
            pack.creator = packDict[@"creator"];
            pack.createDate = (int)[[NSDate date] timeIntervalSince1970];
            pack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
            pack.creatorNickName = packDict[@"creator_nick_name"];
            pack.jobTitle = packDict[@"job_title"];
            
            pack.restorePassword = packDict[@"restore_password"];
            if (pack.restorePassword.length == 0) {
                pack.restorePassword = [@"" base64EncodedString];
            }
            
            pack.shareLink = packDict[@"share_link"];
            if (pack.shareLink.length == 0) {
                pack.shareLink = @"";
            }
            
            pack.fileNameOnAWS = packDict[@"file_name_on_aws"];
            if (pack.fileNameOnAWS.length == 0) {
                pack.fileNameOnAWS = @"";
            }
            
            pack.languageName = packDict[@"language_name"];
            
            pack.platform = packDict[@"platform"];
            if (pack.platform.length == 0) {
                pack.platform = @"";
            }
            
            //if not exist, return 0;
            _downloadedPackSourceDeviceWidth = [packDict[@"screen_width"] integerValue];
            
            NSString *packIDStr = packDict[@"pack_id"];
            if (packIDStr.length == 0) {
                pack.packID = -1;
            } else {
                pack.packID = [packIDStr integerValue];
                [[User defaultUser] removePackWithPackID:pack.packID];
            }
            
            
            //We need to move cover image to imagesDirectory
            if ([packDict[@"cover_image"] lastPathComponent].length > 0) {
                
                error = nil;
                NSString *currentcoverImageURL = [[FileOperationHelper downloadedPackFileDirectory ] stringByAppendingPathComponent:[packDict[@"cover_image"] lastPathComponent]];
                NSString *newCoverImageURL = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:newCoverImageURL]) {
                    [[NSFileManager defaultManager] moveItemAtPath:currentcoverImageURL toPath:newCoverImageURL error:&error];
                    if (error) {
                        [iConsole error:@"%s:Error when moving Pack's cover image",__FUNCTION__];
                        return;
                    }
                }
                pack.coverImageURL = newCoverImageURL;
            } else {
                pack.coverImageURL = @"";
            }
            
        }
    } else {
        [iConsole info:@"Unexpected packInformation.json format"];
    }
    
    //Step3: Update user's pack and database
    pack.userID = [User defaultUser].userID;
    [[User defaultUser] addPack:pack];
    
    [[NSFileManager defaultManager] removeItemAtPath:downloadedPackInfoFilePath error:nil];
    
    //Step4: build cards by parsing zipped card
    error = nil;
    NSArray *fileListArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[FileOperationHelper downloadedPackFileDirectory] error:&error];
    if (error) {
        [iConsole error:@"%s:Error when using contentsOfDirectoryAtPath of NSFileManager",__FUNCTION__];
    }
    
    BOOL buildCardResultError = FALSE;
    NSMutableArray *array = [NSMutableArray array];
    int cardSNIndex = 0;
    
    
    NSArray *sortedFileListArray = fileListArray;
    if ([fileListArray count] > 0) {
        if (((NSString *)[fileListArray firstObject]).length > 10) {
            //iOS风格的zip (历史原因）
            //比如card14424425751939907424.zip。因为命名是按照timeIntervalSince1970的顺序排序的，所以不需要重排
        } else {
            //Android风格的zip (历史原因）
            //类似这种形式：card6.zip，由于card10.zip会在card8前面，所以需要重新排序
            sortedFileListArray = [fileListArray sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
                long aNumber = [[a substringWithRange:NSMakeRange(4, a.length - 4 - 4)] integerValue];
                long bNumber = [[b substringWithRange:NSMakeRange(4, b.length - 4 - 4)] integerValue];
                return (bNumber <= aNumber);
            }];
        }
    }
    
    for (NSString *zippedCardFileName in sortedFileListArray) {
        Card *assembledCard;
        if ([zippedCardFileName rangeOfString:@".zip"].length != 0) {
            NSString *zippedCardFullPath = [[FileOperationHelper downloadedPackFileDirectory] stringByAppendingPathComponent:zippedCardFileName];
            assembledCard = [self unzipFileThenAssembleCard:zippedCardFullPath platform:pack.platform];
            if (assembledCard) {
                if (assembledCard.cardSN == -1) {
                    //如果meta info无法提供，则我们需要赋值（这个出现在Android only 中）
                    assembledCard.cardSN = cardSNIndex + 1;
                }
                [array addObject:assembledCard];
            }
            else {
                [iConsole info:@"%s:Error when unzipping %@",__FUNCTION__,zippedCardFileName];
                buildCardResultError = TRUE;
            }
            
            cardSNIndex ++;
            
        } else {
            // other files that need to be ignored
        }
        
        
        
    }
    
    if (buildCardResultError == TRUE) {
        [Common alertViewCommon:@"Error when unzipFileThenAssembleCard, please check downloaded pack"];
        return;
    }
    
    NSArray *shuffledCardArray = [array cardSNOrdered];
    for (Card *card in shuffledCardArray) {
        [pack addCard:card];
    }
    
    
    //Step5: set  flag
    if (APP_DELEGATE.isDownloadingSamplePack) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isExamplePackDownloadedSuccessful"];
        APP_DELEGATE.isDownloadingSamplePack = NO;
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:pack.packID forKey:@"lastCreatedPackID"];
    
    NSString *updateDate = [FileOperationHelper getTodayString];
    NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:pack.packName];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
    [dict setObject:updateDate forKey:@"update_date"];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:pack.packName];
    
    //record download linkage
    NSDictionary *downloadLinkageDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedDownloadLinkage"];
    if (downloadLinkageDict == nil) {
        downloadLinkageDict = [NSDictionary dictionary];
    }
    NSMutableDictionary *downloadLinkageMutableDict = [NSMutableDictionary dictionaryWithDictionary:downloadLinkageDict];
    if (_zipFileDownloadHelper.downloadedURL == nil) {
        _zipFileDownloadHelper.downloadedURL = @"";
    }
    [downloadLinkageMutableDict setObject:_zipFileDownloadHelper.downloadedURL forKey:[NSString stringWithFormat:@"%ld",pack.packID]];
    [[NSUserDefaults standardUserDefaults] setObject:downloadLinkageMutableDict forKey:@"savedDownloadLinkage"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //step6. update amazon sinpleDB
    [self updateDownloadLimitCount];
    
    //Step7:
    if ((![Common isOwner:pack])&&(_maxDownloadCount == 1)) {
        pack.isAllowShare = NO;
    } else {
        pack.isAllowShare = YES;
    }
    
    //Step8: send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:pack];
    
}

- (void) updateDownloadLimitCount {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSString *defaultDomain = [SimpleDBHelper defaultDomain];
        NSString *currentNo = [NSString stringWithFormat:@"%d",_currentDownloadCount + 1];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:currentNo, @"currentNo", nil];
        [SimpleDBHelper insertOrUpdateItem:dict withItemName:_amazonSimpleDBItemName withDomainName:defaultDomain];
    });
}

/**
 *  unzipCard, save it then
 */
- (Card *) unzipFileThenAssembleCard:(NSString *) zippedFilePath platform:(NSString *)packPlatformStr {
    
    NSError *error = nil;
    NSString *newFileName = nil;
    
    //step1: unzip file
    ZipArchive* za = [[ZipArchive alloc] init];
    if( [za UnzipOpenFile:zippedFilePath] )
    {
        [[NSFileManager defaultManager] removeItemAtPath:[FileOperationHelper temporaryImagesDirectory] error:nil];
        BOOL ret = [za UnzipFileTo:[FileOperationHelper temporaryImagesDirectory] overWrite:YES];
        if( NO==ret ) {
            [iConsole error:@"%s\nUnzip file(%@) failed",__FUNCTION__,zippedFilePath];
        } else {
            //[iConsole info:@"%s\nUnzip file successfully",__FUNCTION__];
        }
        [za UnzipCloseFile];
        
        [[NSFileManager defaultManager] removeItemAtPath:zippedFilePath error:nil];
    } else {
        [iConsole error:@"%s\nunzip %@ failed", __FUNCTION__,zippedFilePath];
    }
    
    Card *assembledCard = [[Card alloc] init];
    NSString *temporaryImagesDir = [FileOperationHelper temporaryImagesDirectory];
    
    //step2: Assemable question card
    error = nil;
    NSString *questionJsonPath = [temporaryImagesDir stringByAppendingPathComponent:@"questionTextContent.json"];
    NSData *questionData = [NSData dataWithContentsOfFile:questionJsonPath];
    if (!questionData) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_ERROR_WHEN_PARSING_QUESTION_JSON",@"")];
        return nil;
    }
    id questionJsonObject = [NSJSONSerialization JSONObjectWithData:questionData options:NSJSONReadingMutableContainers error:&error];
    if (questionJsonObject != nil && error == nil) {
        
        if ([questionJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *questionDict = (NSDictionary *)questionJsonObject;
            
            [iConsole info:@"%s:questionDict =%@",__FUNCTION__,questionDict];
            
            [assembledCard question].questionID = -1; // -1 means new
            [assembledCard question].cardID = -1;
            [assembledCard question].title = questionDict[@"title"];
            [assembledCard question].main = questionDict[@"main"];
            [assembledCard question].sub = questionDict[@"sub"];
            [assembledCard question].subheading = questionDict[@"subheading"];
            [assembledCard question].logoURLLinkage = questionDict[@"logo_url"];
            
            error = nil;
            newFileName = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            if ([questionDict[@"logo"] length] > 0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"logo"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    [assembledCard question].logoFullPath = newFileName;
                }
            } else {
                [assembledCard question].logoFullPath = @"";
            }
            
            
            error = nil;
            if ([questionDict[@"image"] length] >0) {
                
                NSString *temp = questionDict[@"image"];
                if ([temp.lowercaseString containsString:@"gif"] == false) {
                    newFileName = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                } else {
                    newFileName = [FileOperationHelper generateUniqueGIFImageFilePathUnderImagesFolder];
                }

                
                [[NSFileManager defaultManager] copyItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"image"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    [assembledCard question].imageFullPath = newFileName;
                }
            } else {
                [assembledCard question].imageFullPath = @"";
            }
            
            error = nil;
            
            if ([questionDict[@"image2"] length] >0) {
                
                NSString *temp = questionDict[@"image2"];
                if ([temp.lowercaseString containsString:@"gif"] == false) {
                    newFileName = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                } else {
                    newFileName = [FileOperationHelper generateUniqueGIFImageFilePathUnderImagesFolder];
                }
                
                [[NSFileManager defaultManager] copyItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"image2"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    [assembledCard question].imageFullPath2 = newFileName;
                }
            } else {
                [assembledCard question].imageFullPath2 = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            if ([questionDict[@"cover_image"] length] > 0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"cover_image"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    assembledCard.coverImageURL = newFileName;
                }
            }   else {
                assembledCard.coverImageURL = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            if ([questionDict[@"background_image"] length] > 0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"background_image"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    assembledCard.question.backgroundImageFullPath = newFileName;
                }
            }   else {
                assembledCard.question.backgroundImageFullPath = @"";
            }
            
            
            assembledCard.templateBackgroundName = questionDict[@"template_background"];
            if (assembledCard.templateBackgroundName.length ==0) {
                //compatibility with previous version
                assembledCard.templateBackgroundName = @"card_background_blue.png";
            }
            assembledCard.creator = questionDict[@"creator"];
            
            if (((NSString *)questionDict[@"cardSN"]).length > 0) {
                //表明，将使用meta info的数值（iOS的做法）
                assembledCard.cardSN = [questionDict[@"cardSN"] intValue];
            } else {
                //meta info为空，表明，我们需要后续手动赋值(见上面fileListArray部分的逻辑）。
                assembledCard.cardSN = -1;
                [iConsole info:@"%s: no cardSN field in questionTextContent.json",__FUNCTION__];
            }
            
            
            assembledCard.question.templateID = [questionDict[@"template_id"] intValue];
            
            [assembledCard question].css.subheadingAlign = questionDict[@"subheading_align"];
            [assembledCard question].css.subheadingAlignVertical = questionDict[@"subheading_align_vertical"];
            [assembledCard question].css.subheadingColor = questionDict[@"subheading_color"];
            
            [assembledCard question].css.mainAlign = questionDict[@"main_align"];
            [assembledCard question].css.mainAlignVertical = questionDict[@"main_align_vertical"];
            [assembledCard question].css.mainColor = questionDict[@"main_color"];
            [assembledCard question].css.subAlign = questionDict[@"sub_align"];
            [assembledCard question].css.subAlignVertical = questionDict[@"sub_align_vertical"];
            [assembledCard question].css.subColor = questionDict[@"sub_color"];
            
            {
                NSString *subheadingText2Speech = questionDict[@"subheading_text2speech"];
                if (subheadingText2Speech.length == 0 || [subheadingText2Speech.lowercaseString rangeOfString:@"null"].location != NSNotFound) {
                    subheadingText2Speech = @"";
                }
                [assembledCard question].css.subheadingText2SpeechSound = subheadingText2Speech;
            }
            
            {
                NSString *mainText2Speech = questionDict[@"main_text2speech"];
                if (mainText2Speech.length == 0 || [mainText2Speech.lowercaseString rangeOfString:@"null"].location != NSNotFound) {
                    mainText2Speech = @"";
                }
                [assembledCard question].css.mainText2SpeechSound = mainText2Speech;
            }
            
            {
                NSString *subText2Speech = questionDict[@"sub_text2speech"];
                if (subText2Speech.length == 0 || [subText2Speech.lowercaseString rangeOfString:@"null"].location != NSNotFound) {
                    subText2Speech = @"";
                }
                [assembledCard question].css.subText2SpeechSound = subText2Speech;
            }
            
            [assembledCard question].css.subheadingFont = questionDict[@"subheading_font"];
            [assembledCard question].css.mainFont = questionDict[@"main_font"];
            [assembledCard question].css.subFont = questionDict[@"sub_font"];
            
            [assembledCard question].css.subheadingSemiTransparent = [questionDict[@"subheading_semi_transparent"] integerValue] == 1;
            [assembledCard question].css.mainSemiTransparent = [questionDict[@"main_semi_transparent"] integerValue] == 1;
            [assembledCard question].css.subSemiTransparent = [questionDict[@"sub_semi_transparent"] integerValue] == 1;
            
            [assembledCard question].lineNoSubheading = [questionDict[@"line_number_subheading"] integerValue];
            [assembledCard question].lineNoMain = [questionDict[@"line_number_main"] integerValue];
            [assembledCard question].lineNoSub = [questionDict[@"line_number_sub"] integerValue];
            
            
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
            if ([questionDict[@"movie"] length] > 0) {
                
                if ([Common isValidYoutubeLinkage:questionDict[@"movie"]]) {
                    [assembledCard question].movieFullPath = questionDict[@"movie"];
                } else {
                    
                    [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"movie"]] toPath:newFileName error:&error];
                    if (error) {
                        [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                    } else {
                        [assembledCard question].movieFullPath = newFileName;
                    }
                    
                }
                
            }  else {
                [assembledCard question].movieFullPath = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
            if ([questionDict[@"movie2"] length] > 0) {
                
                if ([Common isValidYoutubeLinkage:questionDict[@"movie2"]]) {
                    [assembledCard question].movieFullPath2 = questionDict[@"movie2"];
                } else {
                    
                    [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"movie2"]] toPath:newFileName error:&error];
                    if (error) {
                        [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                    } else {
                        [assembledCard question].movieFullPath2 = newFileName;
                    }
                    
                }
                
            }  else {
                [assembledCard question].movieFullPath2 = @"";
            }
            
            
            error = nil;
            if ([questionDict[@"audio"] rangeOfString:@".3gp"].location != NSNotFound) { //Android的格式
                newFileName = [FileOperationHelper generateUniqueAudio3GPFilePathUnderImagesFolder];
            } else if ([questionDict[@"audio"] rangeOfString:@".aac"].location != NSNotFound) { //iOS的格式
                newFileName = [FileOperationHelper generateUniqueAudioAACFilePathUnderImagesFolder];
            }
            if ([questionDict[@"audio"] length] > 0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"audio"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    [assembledCard question].recordedSoundFullPath = newFileName;
                }
            }   else {
                [assembledCard question].recordedSoundFullPath = @"";
            }
            
            
            //Deal with font size difference between iPhone and iPad
            int subheadingSize = [questionDict[@"subheading_size"] intValue];;
            int mainSize = [questionDict[@"main_size"] intValue];
            int subSize = [questionDict[@"sub_size"] intValue];
            
            if (subheadingSize == 0) {
                //this occur when no subheading_size field in json file, then we use default value
                subheadingSize = [assembledCard question].css.subheadingSize;
            }
            
            if (mainSize == 0) {
                mainSize = [assembledCard question].css.mainSize;
            }
            
            if (subSize == 0) {
                subSize = [assembledCard question].css.subSize;
            }
            
            if ([packPlatformStr isEqualToString:@"iPhone"] && (!isUserInterfaceIdiomPhone)) {
                [iConsole info:@"You are using iPad and pack was made on iPhone"];
                [assembledCard question].css.subheadingSize = subheadingSize * FONT_FACTOR_FROM_IPHONE_TO_IPAD;
                [assembledCard question].css.mainSize = mainSize * FONT_FACTOR_FROM_IPHONE_TO_IPAD;
                [assembledCard question].css.subSize = subSize * FONT_FACTOR_FROM_IPHONE_TO_IPAD;
            } else if ([packPlatformStr isEqualToString:@"iPad"] && (isUserInterfaceIdiomPhone)){
                [iConsole info:@"You are using iPhone and pack was made on iPad"];
                
                if (subheadingSize <30 || mainSize < 30 || subSize < 30) { //理想情况应该是建立一个calibaration table，需要未来执行。实践发现，当字体太小时，offset就不能太大
                    [assembledCard question].css.subheadingSize = subheadingSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE_TEXT_SIZE_LESS_28;
                    [assembledCard question].css.mainSize = mainSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE_TEXT_SIZE_LESS_28;
                    [assembledCard question].css.subSize = subSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE - FONT_OFFSET_FROM_IPAD_TO_IPHONE_TEXT_SIZE_LESS_28;
                } else {
                    [assembledCard question].css.subheadingSize = subheadingSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE;
                    [assembledCard question].css.mainSize = mainSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE;
                    [assembledCard question].css.subSize = subSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE - FONT_OFFSET_FROM_IPAD_TO_IPHONE;
                }
                
            } else if ((isUserInterfaceIdiomPhone) && (![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                [iConsole info:@"You are using iPhone and pack was made on non-iOS platform"];
                
                //the ideal default size would be subheadingSize = 16, mainSize = 20, subSize = 16
                //如果尺寸太小，取一个为base，其它进行比例缩放
                BOOL baseActionDone = NO;
                
                //之所以comment out，因为这不是一个make sense的逻辑
                //                float factor = 0;
                //                if ((subheadingSize < 16) && (subheadingSize >0)) {
                //                    factor = subheadingSize/16.0;
                //                    [assembledCard question].css.subheadingSize = subheadingSize/factor;// ==16
                //                    [assembledCard question].css.mainSize = mainSize/factor;
                //                    [assembledCard question].css.subSize = subSize/factor;
                //                    baseActionDone = YES;
                //                } else if ((mainSize < 20) && (mainSize >0)) {
                //                    factor = mainSize/20.0;
                //                    [assembledCard question].css.subheadingSize = subheadingSize/factor;
                //                    [assembledCard question].css.mainSize = mainSize/factor; // ==20
                //                    [assembledCard question].css.subSize = subSize/factor;
                //                    baseActionDone = YES;
                //                } else if ((subSize < 16) && (subSize >0)) {
                //                    factor = subSize/16.0;
                //                    [assembledCard question].css.subheadingSize = subheadingSize/factor;
                //                    [assembledCard question].css.mainSize = mainSize/factor;
                //                    [assembledCard question].css.subSize = subSize/factor;  // ==16
                //                    baseActionDone = YES;
                //                }
                
                if (baseActionDone == NO) {
                    
                    float ratio = 1;
                    if (_downloadedPackSourceDeviceWidth > 0) {
                        //注意以下公式中不能用IPHONE_UI_WIDTH
                        //因为相同的DP宽度，iPhone下text size更大，所以需要用K_Weight_From_Android_To_IOS修正
                        ratio = (float)_downloadedPackSourceDeviceWidth/480 / K_Weight_From_Android_To_IOS;
                    }
                    
                    if (isUserInterfaceIdiomPhone) {
                        ratio = ratio *1.15;
                    }
                    
                    if ([[assembledCard question].css.subheadingFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard question].css.subheadingSize = subheadingSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.subheadingFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard question].css.subheadingSize = subheadingSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.subheadingFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard question].css.subheadingSize = subheadingSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard question].css.subheadingSize = subheadingSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                    if ([[assembledCard question].css.mainFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard question].css.mainSize = mainSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.mainFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard question].css.mainSize = mainSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.mainFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard question].css.mainSize = mainSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard question].css.mainSize = mainSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                    if ([[assembledCard question].css.subFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard question].css.subSize = subSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.subFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard question].css.subSize = subSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.subFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard question].css.subSize = subSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard question].css.subSize = subSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }                }
                
                
            } else if ((!isUserInterfaceIdiomPhone) &&(![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                [iConsole info:@"You are using iPad and pack was made on non-iOS platform"];
                
                //the ideal default size would be subheadingSize = 32, mainSize = 40, subSize = 32
                //如果尺寸太小，取一个为base，其它进行比例缩放
                BOOL baseActionDone = NO;
                
                //之所以comment out，因为这不是一个make sense的逻辑
                //                float factor = 0;
                //                if ((subheadingSize < 32) && (subheadingSize >0)) {
                //                    factor = subheadingSize/32.0;
                //                    [assembledCard question].css.subheadingSize = subheadingSize/factor;// ==32
                //                    [assembledCard question].css.mainSize = mainSize/factor;
                //                    [assembledCard question].css.subSize = subSize/factor;
                //                    baseActionDone = YES;
                //                } else if ((mainSize < 40) && (mainSize >0)) {
                //                    factor = mainSize/40.0;
                //                    [assembledCard question].css.subheadingSize = subheadingSize/factor;
                //                    [assembledCard question].css.mainSize = mainSize/factor; // ==40
                //                    [assembledCard question].css.subSize = subSize/factor;
                //                    baseActionDone = YES;
                //                } else if ((subSize < 32) && (subSize >0)) {
                //                    factor = subSize/32.0;
                //                    [assembledCard question].css.subheadingSize = subheadingSize/factor;
                //                    [assembledCard question].css.mainSize = mainSize/factor;
                //                    [assembledCard question].css.subSize = subSize/factor;  // ==32
                //                    baseActionDone = YES;
                //                }
                
                if (baseActionDone == NO) {
                    
                    float ratio = 1;
                    if (_downloadedPackSourceDeviceWidth > 0) {
                        ratio = (float)_downloadedPackSourceDeviceWidth/IPAD_UI_WIDTH/K_Weight_From_Android_To_IOS;
                    }
                    
                    if ([[assembledCard question].css.subheadingFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard question].css.subheadingSize = subheadingSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.subheadingFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard question].css.subheadingSize = subheadingSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.subheadingFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard question].css.subheadingSize = subheadingSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard question].css.subheadingSize = subheadingSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                    if ([[assembledCard question].css.mainFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound ) {
                        [assembledCard question].css.mainSize = mainSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    }  else if ([[assembledCard question].css.mainFont.lowercaseString rangeOfString:@"papyrus"].location!= NSNotFound) {
                        [assembledCard question].css.mainSize = mainSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    }  else if ([[assembledCard question].css.mainFont.lowercaseString rangeOfString:@"courier"].location!= NSNotFound) {
                        [assembledCard question].css.mainSize = mainSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    }  else {
                        [assembledCard question].css.mainSize = mainSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                    if ([[assembledCard question].css.subFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard question].css.subSize = subSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.subFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard question].css.subSize = subSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard question].css.subFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard question].css.subSize = subSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard question].css.subSize = subSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                }
                
            } else {
                [iConsole info:@"The platform you are using and pack was made are the same"];
                [assembledCard question].css.subheadingSize = subheadingSize;
                [assembledCard question].css.mainSize = mainSize;
                [assembledCard question].css.subSize = subSize;
            }
            
        }
    } else {
        [iConsole info:@"Unexpected questionTextContent.json format"];
    }
    [[NSFileManager defaultManager] removeItemAtPath:questionJsonPath error:nil];
    
    //step3: Assemable answer card
    error = nil;
    NSString *answerJsonPath = [temporaryImagesDir stringByAppendingPathComponent:@"answerTextContent.json"];
    NSData *answerData = [NSData dataWithContentsOfFile:answerJsonPath];
    if (!answerData) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_ERROR_WHEN_PARSING_ANSWER_JSON",@"")];
        return nil;
    }
    id answerJsonObject = [NSJSONSerialization JSONObjectWithData:answerData options:
                           NSJSONReadingMutableContainers error:&error];
    if (answerJsonObject != nil && error == nil) {
        if ([answerJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *answerDict = (NSDictionary *)answerJsonObject;
            
            [iConsole info:@"%s:answerDict =%@",__FUNCTION__,answerDict];
            
            [assembledCard answer].answerID = -1;
            [assembledCard answer].cardID = -1;
            [assembledCard answer].title = answerDict[@"title"];
            [assembledCard answer].main = answerDict[@"main"];
            [assembledCard answer].sub = answerDict[@"sub"];
            [assembledCard answer].subheading = answerDict[@"subheading"];
            
            if ([[assembledCard answer].main rangeOfString:@"Point to"].length > 0) {
                error = nil;
            }
            
            
            error = nil;
            if ([answerDict[@"image"] length] > 0) {
                
                NSString *temp = answerDict[@"image"];
                if ([temp.lowercaseString containsString:@"gif"] == false) {
                    newFileName = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                } else {
                    newFileName = [FileOperationHelper generateUniqueGIFImageFilePathUnderImagesFolder];
                }
                
                [[NSFileManager defaultManager] copyItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"image"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    [assembledCard answer].imageFullPath = newFileName;
                }
            } else {
                [assembledCard answer].imageFullPath = @"";
            }
            
            error = nil;
            if ([answerDict[@"image2"] length] > 0) {
                
                NSString *temp = answerDict[@"image2"];
                if ([temp.lowercaseString containsString:@"gif"] == false) {
                    newFileName = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                } else {
                    newFileName = [FileOperationHelper generateUniqueGIFImageFilePathUnderImagesFolder];
                }
                
                [[NSFileManager defaultManager] copyItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"image2"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    [assembledCard answer].imageFullPath2 = newFileName;
                }
            } else {
                [assembledCard answer].imageFullPath2 = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            if ([answerDict[@"logo"] length] >0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"logo"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    [assembledCard answer].logoFullPath = newFileName;
                }
            } else {
                [assembledCard answer].logoFullPath = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            if ([answerDict[@"background_image"] length] >0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"background_image"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    [assembledCard answer].backgroundImageFullPath = newFileName;
                }
            } else {
                [assembledCard answer].backgroundImageFullPath = @"";
            }
            
            assembledCard.answer.templateID = [answerDict[@"template_id"] intValue];
            
            [assembledCard answer].css.subheadingAlign = answerDict[@"subheading_align"];
            [assembledCard answer].css.subheadingAlignVertical = answerDict[@"subheading_align_vertical"];
            [assembledCard answer].css.subheadingColor = answerDict[@"subheading_color"];
            
            [assembledCard answer].css.mainAlign = answerDict[@"main_align"];
            [assembledCard answer].css.mainAlignVertical = answerDict[@"main_align_vertical"];
            [assembledCard answer].css.mainColor = answerDict[@"main_color"];
            
            [assembledCard answer].css.subAlign = answerDict[@"sub_align"];
            [assembledCard answer].css.subAlignVertical = answerDict[@"sub_align_vertical"];
            [assembledCard answer].css.subColor = answerDict[@"sub_color"];
            
            {
                NSString *subheadingText2Speech = answerDict[@"subheading_text2speech"];
                if (subheadingText2Speech.length == 0 || [subheadingText2Speech.lowercaseString rangeOfString:@"null"].location != NSNotFound) {
                    subheadingText2Speech = @"";
                }
                [assembledCard answer].css.subheadingText2SpeechSound = subheadingText2Speech;
            }
            
            {
                NSString *mainText2Speech = answerDict[@"main_text2speech"];
                if (mainText2Speech.length == 0 || [mainText2Speech.lowercaseString rangeOfString:@"null"].location != NSNotFound) {
                    mainText2Speech = @"";
                }
                [assembledCard answer].css.mainText2SpeechSound = mainText2Speech;
            }
            
            {
                NSString *subText2Speech = answerDict[@"sub_text2speech"];
                if (subText2Speech.length == 0 || [subText2Speech.lowercaseString rangeOfString:@"null"].location != NSNotFound) {
                    subText2Speech = @"";
                }
                [assembledCard answer].css.subText2SpeechSound = subText2Speech;
            }
            
            [assembledCard answer].css.subheadingFont = answerDict[@"subheading_font"];
            [assembledCard answer].css.mainFont = answerDict[@"main_font"];
            [assembledCard answer].css.subFont = answerDict[@"sub_font"];
            
            [assembledCard answer].css.subheadingSemiTransparent = [answerDict[@"subheading_semi_transparent"] integerValue] == 1;
            [assembledCard answer].css.mainSemiTransparent = [answerDict[@"main_semi_transparent"] integerValue] == 1;
            [assembledCard answer].css.subSemiTransparent = [answerDict[@"sub_semi_transparent"] integerValue] == 1;
            
            [assembledCard answer].lineNoSubheading = [answerDict[@"line_number_subheading"] integerValue];
            [assembledCard answer].lineNoMain = [answerDict[@"line_number_main"] integerValue];
            [assembledCard answer].lineNoSub = [answerDict[@"line_number_sub"] integerValue];
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
            if ([answerDict[@"movie"] length] > 0) {
                //youtube link
                if ([Common isValidYoutubeLinkage:answerDict[@"movie"]]) {
                    [assembledCard answer].movieFullPath = answerDict[@"movie"];
                } else {
                    //with video file locally
                    [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"movie"]] toPath:newFileName error:&error];
                    if (error) {
                        [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                    } else {
                        [assembledCard answer].movieFullPath = newFileName;
                    }
                }
                
            }   else {
                [assembledCard answer].movieFullPath = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
            if ([answerDict[@"movie2"] length] > 0) {
                //youtube link
                if ([Common isValidYoutubeLinkage:answerDict[@"movie2"]]) {
                    [assembledCard answer].movieFullPath2 = answerDict[@"movie2"];
                } else {
                    //with video file locally
                    [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"movie2"]] toPath:newFileName error:&error];
                    if (error) {
                        [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                    } else {
                        [assembledCard answer].movieFullPath2 = newFileName;
                    }
                }
                
            }   else {
                [assembledCard answer].movieFullPath2 = @"";
            }
            
            error = nil;
            if ([answerDict[@"audio"] rangeOfString:@".3gp"].location != NSNotFound) { //Android的格式
                newFileName = [FileOperationHelper generateUniqueAudio3GPFilePathUnderImagesFolder];
            } else if ([answerDict[@"audio"] rangeOfString:@".aac"].location != NSNotFound) { //iOS的格式
                newFileName = [FileOperationHelper generateUniqueAudioAACFilePathUnderImagesFolder];
            }
            if ([answerDict[@"audio"] length] > 0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"audio"]] toPath:newFileName error:&error];
                if (error) {
                    [iConsole error:@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName];
                } else {
                    [assembledCard answer].recordedSoundFullPath = newFileName;
                }
            }   else {
                [assembledCard answer].recordedSoundFullPath = @"";
            }
            
            //Deal with font size difference between iPhone and iPad
            int subheadingSize = [answerDict[@"subheading_size"] intValue];;
            int mainSize = [answerDict[@"main_size"] intValue];
            int subSize = [answerDict[@"sub_size"] intValue];
            
            if (subheadingSize == 0) {
                //this occur when no subheading_size field in json file, then we use default value
                subheadingSize = [assembledCard answer].css.subheadingSize;
            }
            
            if (mainSize == 0) {
                mainSize = [assembledCard answer].css.mainSize;
            }
            
            if (subSize == 0) {
                subSize = [assembledCard answer].css.subSize;
            }
            
            if ([packPlatformStr isEqualToString:@"iPhone"] && (!isUserInterfaceIdiomPhone)) {
                [assembledCard answer].css.subheadingSize = subheadingSize * FONT_FACTOR_FROM_IPHONE_TO_IPAD;
                [assembledCard answer].css.mainSize = mainSize * FONT_FACTOR_FROM_IPHONE_TO_IPAD;
                [assembledCard answer].css.subSize = subSize * FONT_FACTOR_FROM_IPHONE_TO_IPAD;
            } else if ([packPlatformStr isEqualToString:@"iPad"] && (isUserInterfaceIdiomPhone)){
                
                if (subheadingSize <30 || mainSize < 30 || subSize < 30) { //理想情况应该是建立一个calibaration table，需要未来执行。实践发现，当字体太小时，offset就不能太大
                    [assembledCard answer].css.subheadingSize = subheadingSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE_TEXT_SIZE_LESS_28;
                    [assembledCard answer].css.mainSize = mainSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE_TEXT_SIZE_LESS_28;
                    [assembledCard answer].css.subSize = subSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE_TEXT_SIZE_LESS_28;
                } else {
                    [assembledCard answer].css.subheadingSize = subheadingSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE;
                    [assembledCard answer].css.mainSize = mainSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE;
                    [assembledCard answer].css.subSize = subSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_FROM_IPAD_TO_IPHONE;
                }
                
            } else if ((isUserInterfaceIdiomPhone) && (![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                [iConsole info:@"You are using iPhone and pack was made on non-iOS platform"];
                
                //the ideal default size would be subheadingSize = 16, mainSize = 20, subSize = 16
                //need to take care when it's too small. we don't need to worry when it's too big because we have resize logic later
                float factor = 0;
                BOOL baseActionDone = NO;
                
                //之所以comment out，因为这不是一个make sense的逻辑
                //                if ((subheadingSize < 16) && (subheadingSize >0)) {
                //                    factor = subheadingSize/16.0;
                //                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;// ==16
                //                    [assembledCard answer].css.mainSize = mainSize/factor;
                //                    [assembledCard answer].css.subSize = subSize/factor;
                //                    baseActionDone = YES;
                //                } else if ((mainSize < 20) && (mainSize >0)) {
                //                    factor = mainSize/20.0;
                //                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;
                //                    [assembledCard answer].css.mainSize = mainSize/factor; // ==20
                //                    [assembledCard answer].css.subSize = subSize/factor;
                //                    baseActionDone = YES;
                //                } else if ((subSize < 16) && (subSize >0)) {
                //                    factor = subSize/16.0;
                //                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;
                //                    [assembledCard answer].css.mainSize = mainSize/factor;
                //                    [assembledCard answer].css.subSize = subSize/factor;  // ==16
                //                    baseActionDone = YES;
                //                }
                
                if (baseActionDone == NO) {
                    
                    float ratio = 1;
                    if (_downloadedPackSourceDeviceWidth > 0) {
                        //注意以下公式中不能用IPHONE_UI_WIDTH
                        //因为相同的DP宽度，iPhone下text size更大，所以需要用K_Weight_From_Android_To_IOS修正
                        ratio = (float)_downloadedPackSourceDeviceWidth/480/K_Weight_From_Android_To_IOS;
                    }
                    
                    
                    if (isUserInterfaceIdiomPhone) {
                        ratio = ratio *1.15;
                        
                        
                    }
                    
                    if ([[assembledCard answer].css.subheadingFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard answer].css.subheadingSize = subheadingSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.subheadingFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard answer].css.subheadingSize = subheadingSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.subheadingFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard answer].css.subheadingSize = subheadingSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard answer].css.subheadingSize = subheadingSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                    if ([[assembledCard answer].css.mainFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard answer].css.mainSize = mainSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.mainFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard answer].css.mainSize = mainSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    }  else if ([[assembledCard answer].css.mainFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard answer].css.mainSize = mainSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    }  else {
                        [assembledCard answer].css.mainSize = mainSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                    if ([[assembledCard answer].css.subFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard answer].css.subSize = subSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.subFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard answer].css.subSize = subSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.subFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard answer].css.subSize = subSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard answer].css.subSize = subSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                    
                }
                
            } else if ((!isUserInterfaceIdiomPhone) &&(![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                [iConsole info:@"You are using iPad and pack was made on non-iOS platform"];
                
                //the ideal default size would be subheadingSize = 32, mainSize = 40, subSize = 32
                //need to take care when it's too small. we don't need to worry when it's too big because we have resize logic later
                float factor = 0;
                BOOL baseActionDone = NO;
                
                //之所以comment out，因为这不是一个make sense的逻辑
                //                if ((subheadingSize < 32) && (subheadingSize >0)) {
                //                    factor = subheadingSize/32.0;
                //                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;// ==32
                //                    [assembledCard answer].css.mainSize = mainSize/factor;
                //                    [assembledCard answer].css.subSize = subSize/factor;
                //                    baseActionDone = YES;
                //                } else if ((mainSize < 40) && (mainSize >0)) {
                //                    factor = mainSize/40.0;
                //                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;
                //                    [assembledCard answer].css.mainSize = mainSize/factor; // ==40
                //                    [assembledCard answer].css.subSize = subSize/factor;
                //                    baseActionDone = YES;
                //                } else if ((subSize < 32) && (subSize >0)) {
                //                    factor = subSize/32.0;
                //                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;
                //                    [assembledCard answer].css.mainSize = mainSize/factor;
                //                    [assembledCard answer].css.subSize = subSize/factor;  // ==32
                //                    baseActionDone = YES;
                //                }
                
                
                if (baseActionDone == NO) {
                    
                    float ratio = 1;
                    if (_downloadedPackSourceDeviceWidth > 0) {
                        ratio = (float)_downloadedPackSourceDeviceWidth/IPAD_UI_WIDTH / K_Weight_From_Android_To_IOS;
                    }
                    
                    
                    if ([[assembledCard answer].css.subheadingFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard answer].css.subheadingSize = subheadingSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.subheadingFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard answer].css.subheadingSize = subheadingSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.subheadingFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard answer].css.subheadingSize = subheadingSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard answer].css.subheadingSize = subheadingSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                    if ([[assembledCard answer].css.mainFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard answer].css.mainSize = mainSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.mainFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard answer].css.mainSize = mainSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.mainFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard answer].css.mainSize = mainSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard answer].css.mainSize = mainSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                    
                    if ([[assembledCard answer].css.subFont.lowercaseString rangeOfString:@"zapfino"].location != NSNotFound) {
                        [assembledCard answer].css.subSize = subSize/ratio/ZAPFINO_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.subFont.lowercaseString rangeOfString:@"papyrus"].location != NSNotFound) {
                        [assembledCard answer].css.subSize = subSize/ratio/PAPYRUS_RATIO_FROM_NON_IOS;
                    } else if ([[assembledCard answer].css.subFont.lowercaseString rangeOfString:@"courier"].location != NSNotFound) {
                        [assembledCard answer].css.subSize = subSize/ratio/COURIER_RATIO_FROM_NON_IOS;
                    } else {
                        [assembledCard answer].css.subSize = subSize/ratio/DEFAULT_FONT_RATIO_FROM_NON_IOS;
                    }
                }
                
            } else {
                [iConsole info:@"The platform you are using and pack was made are the same"];
                [assembledCard answer].css.subheadingSize = subheadingSize;
                [assembledCard answer].css.mainSize = mainSize;
                [assembledCard answer].css.subSize = subSize;
            }
            
        }
    } else {
        [iConsole info:@"Unexpected questionTextContent.json format"];
    }
    [[NSFileManager defaultManager] removeItemAtPath:answerJsonPath error:nil];
    
    [[NSFileManager defaultManager] removeItemAtPath:temporaryImagesDir error:nil];
    
    return assembledCard;
    
}

#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)hudTappedButton:(MBProgressHUD *)hud {
    [_zipFileDownloadHelper cancelDownload];
    
    APP_DELEGATE.isNotAllowDownloadSamplePack = YES; //although we don't know whether it's to download sample or other packs, it does not matter
    APP_DELEGATE.isDownloadingPack = NO;
    APP_DELEGATE.isDownloadingSamplePack = NO;
}

- (void)showDownloadProgressIndicator:(NSString *) type withSource:(NSString *) from {
    
    _progressivePercent = 0;
    
    _HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
    _HUD.buttonTitle = @"    Cancel    ";
    _HUD.buttonTitleColor = [UIColor whiteColor];
    
    [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
    [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
    
    // Set determinate mode
    _HUD.mode = MBProgressHUDModeDeterminate;
    
    _HUD.delegate = self;
    if ([type isEqualToString:@"demo"]) {
        _HUD.labelText = NSLocalizedString(@"DIALOG_DOWNLOAD_PACK",@"");
    } else {
        //        _HUD.labelText = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"DIALOG_DOWNLOAD_PACK_FROM_FRIENDS",@""), from];
        _HUD.labelText = NSLocalizedString(@"DIALOG_DOWNLOAD_PACK_FROM_FRIENDS",@"");
    }
    
    // myProgressTask uses the HUD instance to update progress
    [_HUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
    
}



- (void)myProgressTask {
    while (_progressivePercent < 1.0f) {
        _HUD.progress = _progressivePercent;
        usleep(50000);
    }
    
    _progressivePercent = 0;
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [_HUD removeFromSuperview];
}


#pragma mark -
#pragma mark Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark -
#pragma mark - Memory Management

// will not be called in iOS 6
// will not be called when it's current view
- (void)viewDidUnload
{
    [super viewDidUnload];
    [self my_viewDidUnload];
}

// in iOS 6, view is no longer unloaded so do it manually
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && [self.view window] == nil) {
        self.view = nil;
        [self my_viewDidUnload];
    }
}

- (void)my_viewDidUnload
{
    _selectPackBarButton = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark – PopoverviewDelegate

- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
    
    [iConsole info:@"%s",__FUNCTION__];
    
    [popoverView dismiss];
    
    
    if (popoverView.tag == popover_enum_share) {
        switch (index) {
            case 0: {
                
                if ([MutipleTargetHelper isFullVersion] == false && [MutipleTargetHelper isNoAdVersion] == false ) {
                    [MutipleTargetHelper showAlertToUpgradeToFullVersion];
                    return;
                }
        
                
                __weak __typeof(&*self)weakSelf = self;
                
                UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:NSLocalizedString(@"DIALOG_INPUT_DOWNLOAD_CODE",@"") message:nil];
                [alertView textFieldAtIndex:0].text = @"";
                [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
                [alertView bk_addButtonWithTitle:NSLocalizedString(@"Keyboard_Cancel",@"") handler:nil];
                [alertView bk_setCancelButtonWithTitle:NSLocalizedString(@"Keyboard_Done",@"") handler:^{
                    
                    [[alertView textFieldAtIndex:0] resignFirstResponder];
                    
                    NSString *downloadCode = [alertView textFieldAtIndex:0].text;
                    downloadCode = [downloadCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if (downloadCode.length > 0) {
                        if (!_HUD)
                            _HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
                        
                        [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
                        [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
                        
                        _HUD.mode = MBProgressHUDModeIndeterminate;
                        _HUD.labelText = NSLocalizedString(@"Title_Process_Share_Code",@"");
                        [_HUD show:YES];
                        [weakSelf downloadPackWithCode:downloadCode];
                    }
                    
                }];
                [alertView show];
                
                
                APP_DELEGATE.isAllowToShowPackList = NO;
                break;
            }
            case 1: {
                
                if ([MutipleTargetHelper isFullVersion] == false) {
                    [MutipleTargetHelper showAlertToUpgradeToFullVersion];
                    return;
                }
                
                if (_currentPack.isAllowShare && _currentCard) {
                    
                    if (([DropboxClientsManager authorizedClient] != nil || [DropboxClientsManager authorizedTeamClient] != nil)) {
                        [self shareViaDropbox];
                    } else if ([[GoogleDriveSession sharedSession] isLinked]) {
                        [self shareViaGoogleDrive];
                    } else if ([FIRAuth auth].currentUser != nil) {
                        [self shareViaAWS];
                    } else {
                        
                        __weak __typeof(&*self)weakSelf = self;
                        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_STORAGE_SELECTION",@"") message:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"DIALOG_STORAGE_SELECTION_DROPBOX",@""), NSLocalizedString(@"DIALOG_STORAGE_SELECTION_GOOGLE_DRIVE",@""), NSLocalizedString(@"DIALOG_STORAGE_SELECTION_AWS",@""),nil] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                            
                            if (buttonIndex == 0) {
                                //cancel button
                                
                            } else if (buttonIndex == 1) {
                                //dropbox
                                [weakSelf shareViaDropbox];
                                
                            } else if (buttonIndex == 2) {
                                //google drive
                                [weakSelf shareViaGoogleDrive];
                                
                            } else if (buttonIndex == 3) {
                                //google drive
                                [weakSelf shareViaAWS];
                                
                            }
                            
                        }];
                        
                    }
                    
                    
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:NSLocalizedString(@"DIALOG_SHARE_FUNCTION_FORBIDDEN_BY_CREATOR",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                    [alertView show];
                }
                
                break;
            }
            default:
                break;
        }
        
    } else if (popoverView.tag == popover_enum_template_select) {
        // on iPhone, we don't do this
        
    } else if (popoverView.tag == popover_enum_play) {
        
        
    }
    
}



#pragma mark – Tooltips

- (void) showTooltips {
    
    if ([MutipleTargetHelper isFullVersion] == false) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        //1.
        CGRect rect = _addCardButton.frame;
        rect.origin.y = rect.origin.y - 30;
        
        
        [[TipHelper defaultHelper] showTipForCreateCardInView:weakSelf.view fromFrame:rect];
        
        //2.
        if (isUserInterfaceIdiomPhone) {
            [[TipHelper defaultHelper] showTipForLeftNaviBarItemEditPackInView:weakSelf.view fromFrame:CGRectMake(85, 0, 0, 0)];
            [[TipHelper defaultHelper] showTipForLeftNaviBarItemOpenPackInView:weakSelf.view fromFrame:CGRectMake(40, 0, 0, 0)];
            
        } else {
            [[TipHelper defaultHelper] showTipForLeftNaviBarItemEditPackInView:weakSelf.view fromFrame:CGRectMake(87, 0, 0, 0)];
            [[TipHelper defaultHelper] showTipForLeftNaviBarItemOpenPackInView:weakSelf.view fromFrame:CGRectMake(37, 0, 0, 0)];
        }
        
        //3.
        if (isUserInterfaceIdiomPhone) {
            [[TipHelper defaultHelper] showTipForRightNaviBarItemPlayInView:weakSelf.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 50, 0, 0, 0)];;
            [[TipHelper defaultHelper] showTipForRightNaviBarItemShareInView:weakSelf.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 100, 0, 0, 0)];
            [[TipHelper defaultHelper] showTipForRightNaviBarItemSettingInView:weakSelf.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 145, 0, 0, 0)];
            [[TipHelper defaultHelper] showTipForRightNaviBarItemHelpInView:weakSelf.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 190, 0, 0, 0)];
            
        }
        
    });
    
    
}


- (void) showTooltipNotification:(NSNotification *) notification {
    [self showTooltips];
}



#pragma mark – Popover
//当通过dismissPopoverAnimated执行时，不会call到这个method
//当点击popover外面区域时，会调用这个方法
//具体见这里：http://stackoverflow.com/questions/3567033/dismissing-uipopovercontroller-with-dismisspopoveranimated-wont-call-delegate
//为了让这个方法能被called，我们的做法是：[self.popController.delegate popoverControllerDidDismissPopover:self.popController];
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    
    if (isUserInterfaceIdiomPhone == FALSE) {
        _packListPickerPopover = nil;
    }
    
    APP_DELEGATE.isAllowToShowTooltip = YES;
    
    APP_DELEGATE.isAllowToShowPackList = YES;
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Master_Not_Allow];
    BOOL val2 = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Master_Not_Allow];
    if (val == FALSE && val2) {
        [self showTooltips];
    }
    
}




#pragma mark -
#pragma mark - DROPBOX_LINKED_NOTIFICATION

- (void) dropboxLinkedNotification:(id)notification
{
    [iConsole info:@"%s",__FUNCTION__];
    NSNumber *linkedNum = [[notification userInfo] objectForKey:@"linked"];
    
    if(![linkedNum boolValue])
    {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
    } else
    {
        if (APP_DELEGATE.isAllowToShareAfterDropboxLogIn) {
            _dropboxShareHelper = [[DropboxSharekitHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
            [_dropboxShareHelper shareAction];
        }
    }
}

#pragma mark – NSURLConnectionDataDelegate

/**
 *  这个方法在请求将要被发送出去之前会调用
 *  返回值是一个NSURLRequest就是那个真正将要被发送的请求
 *  第二个参数request就是被重定向处理过后的请求 在这里就可以拿到需要的URL
 *  第三个参数response是一个将要触发重定向的请求
 
 *  在FFC项目中，
 *  1. 如果没有重定向，比如这种（http://tinyurl.com/xpppxxxxxxxxx），response为nil。此方法执行后，调用connectionDidFinishLoading结束
 *  2. 如果有重定向，比如这种（http://tinyurl.com/yahoo)，则会被调用3次，1次response为nil，2次是reponse中包含重定向的url.最后，同上面一样，调用connectionDidFinishLoading结束。值得注意的，我们实际中只调用了二次，因为我们用了：return  nil;
 */
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if (httpResponse) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            [_HUD removeFromSuperview];
            _HUD = nil;
        });
        
        NSString *unshortedURLStr = [httpResponse.allHeaderFields objectForKey:@"Location"];
        if (unshortedURLStr) {
            NSURL *unshortedURL = [NSURL URLWithString:unshortedURLStr];
            
            double delayInSeconds = 0.01;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if ([[unshortedURL scheme] isEqualToString:@"fcc"]) {
                    
                    [connection cancel];
                    
                    [self downloadPackNotification:[NSNotification notificationWithName:DOWNLOAD_PACK_NOTIFICATION object:[unshortedURL absoluteString]]];
                    
                    
                } else {
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"Title_Share_Code_Not_Right",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CLOSE",@"") otherButtonTitles:nil, nil];
                    [alertView show];
                    
                }
            });
            
        } else {
            [iConsole error:@"%s: httpResponse.allHeaderFields = %@",__FUNCTION__,httpResponse.allHeaderFields];
        }
        
        return  nil;
        
        
    } else {
        //不能再这里执行[_HUD removeFromSuperview]，因为redirect会导致本方法会被调用的多次
    }
    
    
    return request;
}

/**
 *  如果connection:willSendRequest:redirectResponse返回nil,就不会执行此方法  (也就是说，如果我们的share code正确，就不会执行到这里
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection; {
    
    [iConsole info:@"%s",__FUNCTION__];
    
    if (_HUD) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            [_HUD removeFromSuperview];
            _HUD = nil;
        });
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"Title_Share_Code_Not_Right",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CLOSE",@"") otherButtonTitles:nil, nil];
        [alertView show];
    }
    
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (_HUD) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            [_HUD removeFromSuperview];
            _HUD = nil;
            
            if (error.code == -1009) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:NSLocalizedString(@"DIALOG_PLEASE_CHECK_YOUR_NETWORK",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CLOSE",@"") otherButtonTitles:nil, nil];
                [alertView show];
            } else {
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"Title_Share_Code_Not_Right",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CLOSE",@"") otherButtonTitles:nil, nil];
                [alertView show];
                
            }
            
        });
        
        
    }
    
}

#pragma mark – PackInfoViewDelegate

- (void)packInfoView:(PackInfoView *)packInfoVIew didScrollToPack:(Pack *)pack {
    
    self.currentPack = pack;
    [self selectPack:pack];
    
    
}

- (void)playButtonClickedOnPackInfoView{
    
    [self playButtonClicked];
    
}

#pragma mark – Others

- (void) shareViaAWS {
    
    if ([FIRAuth auth].currentUser == nil) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please sign in to FFC Drive in Settings > FFC Drive" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        
    } else {
        [iConsole info:@"%s: [FIRAuth auth].currentUser.email = %@",__FUNCTION__,[FIRAuth auth].currentUser.email];
        
        _amazonShareHelper = [[AWSS3UploadHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
        [_amazonShareHelper shareAction];
    }

}

- (void) shareViaGoogleDrive {
    
    if (![[GoogleDriveSession sharedSession] isLinked]) {
        
        __weak __typeof(&*self)weakSelf = self;
        
        APP_DELEGATE.isAllowToShowPackList = false;
        [[GoogleDriveSession sharedSession] authWithSuccessCompletion:^{
            
            _googleDriveShareHelper = [[GoogleDriveShareKitHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:weakSelf];
            [_googleDriveShareHelper shareAction];
            
        }];
        
    } else {
        
        _googleDriveShareHelper = [[GoogleDriveShareKitHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
        [_googleDriveShareHelper shareAction];
    }
    
}

- (void) shareViaDropbox {
    
    //Dropbox only
    if (!([DropboxClientsManager authorizedClient] != nil || [DropboxClientsManager authorizedTeamClient] != nil)) {
        //会通过application:(UIApplication *)application openURL 到达MasterViewController的dropboxLinkedNotification
        //不需要在本类中设置dropboxLinkedNotification
        [DropboxClientsManager authorizeFromController:[UIApplication sharedApplication]
                                            controller:APP_DELEGATE.window.rootViewController
                                               openURL:^(NSURL *url) {
                                                   [[UIApplication sharedApplication] openURL:url];
                                               }
                                           browserAuth:NO];
        APP_DELEGATE.isAllowToShareAfterDropboxLogIn = YES;
    } else {
        _dropboxShareHelper = [[DropboxSharekitHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
        [_dropboxShareHelper shareAction];
    }
}

//
//#pragma mark -
//#pragma mark DBSessionDelegate methods
//
//- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
//    [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
//}


@end
