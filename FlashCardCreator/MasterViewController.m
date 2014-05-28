//
//  MasterViewController.m
//  FlashCardCreator
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
#import "PackListViewController.h"
#import "DataManager.h"
#import "UIImageView+AFNetworking.h"
#import "CreatePackViewController.h"
#import "UINavigationController+DismissKeyboard.h"
#import "DataManager.h"
#import "FileOperationHelper.h"
#import "MoreInfoTableViewController.h"
#import "FCCBarButton.h"
#import "DropboxShareKitHelper.h"
#import "PlayViewController.h"
#import "HelpViewController.h"
#import "NSArray+Randomised.h"
#import "NSString+QueryString.h"
#import "AmazonClientManager.h"
#import "SimpleWebBrowserController.h"
#import "AppDelegate.h"
#import "OpenUDID.h"
#import "Common.h"

extern BOOL _isDownloadingSamplePack;

@implementation MasterViewController

@synthesize currentPack = _currentPack;
@synthesize currentCard = _currentCard;
@synthesize indexCard = _indexCard;
@synthesize backgroundOfCreateCardView = _backgroundOfCreateCardView;
@synthesize tableView = _tableView;


typedef enum {
    UIAlertViewTypeEnum_SetPassword  = 0,
    UIAlertViewTypeEnum_DeleteCard = 1,
    UIAlertViewTypeEnum_Download_From_Code = 2
} UIAlertViewTypeEnum;

enum popover_enum {
    popover_enum_share = 0,
    popover_enum_template_select = 1
};

#pragma mark -
#pragma mark - Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //1. Setup notification

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPackAddedNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeBackgroundAfterCardCreatedNotification:) name:REMOVE_BACKGROUND_AFTER_CARD_CREATED_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedPackNotification:) name:CURRENT_PACK_SELECTED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterDetailViewAfterParseDownloadPackFinishNotification:) name:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadPackNotification:) name:DOWNLOAD_PACK_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterAfterSaveCardNotification:) name:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterAfterDetailScrollNotification:) name:UPDATE_MASTER_AFTER_DETAIL_SCROLL_NOTFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toCreateNewPackNotification:) name:TO_CREATE_NEW_PACK_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showIntroductionVideoNotification:) name:SHOW_VIDEO_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNotification:) name:PLAY_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPackListNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPackListNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        
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
    
    if isUserInterfaceIdiomPhone {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"w1136"]];
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [self.navigationController.navigationBar setTranslucent:FALSE];
    }
    
    if (isUserInterfaceIdiomPhone) {
        self.tableView = [[FMMoveTableView alloc] initWithFrame:CGRectMake(0, 0, IPHONE_UI_MASTER_TABLE_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT) style:UITableViewStylePlain];
    } else {
        self.tableView = [[FMMoveTableView alloc] initWithFrame:CGRectMake(0, 0, IPAD_UI_MASTER_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT) style:UITableViewStylePlain];
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view insertSubview:self.tableView atIndex:0];

    _selectPackButton = [[UIBarButtonItem alloc]
                         initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"packs_button.png"] target:self action:@selector(selectAvailablePacks:)]];
    
    UIBarButtonItem *newPackBarButtonItem = [[UIBarButtonItem alloc]
                                      initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"add_pack_button.png"] target:self action:@selector(createNewPack:)]];
    
    
    UIButton * editButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"edit_button.png"] target:self action:@selector(editButtonClicked:)];
    editButton.tag = 0;
    UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:editButton];
    
    
    self.navigationItem.leftBarButtonItems = @[_selectPackButton,editBarButtonItem, newPackBarButtonItem];
    if (isUserInterfaceIdiomPhone) {
        
        UIBarButtonItem *playButton = [[UIBarButtonItem alloc]
                                       initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"play_button.png"] target:self action:@selector(playButtonClicked:)]];
        UIBarButtonItem *shareButton = [[UIBarButtonItem alloc]
                                        initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"share_button.png"] target:self action:@selector(shareButtonClicked:)]];
        
        UIBarButtonItem *settingButton = [[UIBarButtonItem alloc]
                                          initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"setting_button.png"] target:self action:@selector(moreButtonClicked:)]];
        
        UIBarButtonItem *helpButton = [[UIBarButtonItem alloc]
                                          initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"helping_button.png"] target:self action:@selector(helpButtonClicked:)]];
        
        self.navigationItem.rightBarButtonItems =
            @[playButton,shareButton,settingButton,helpButton];
    }
    

    if (isUserInterfaceIdiomPhone) {
        self.title = _currentPack.packName;
    }
    [self.tableView reloadData];

    
    
    
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];
    
    if (_addCardButton == nil) {
        if (isUserInterfaceIdiomPhone) {
            _addCardButtonBackground = [[UIView alloc] initWithFrame:CGRectMake(0,0, 160, 60)];
            _addCardButtonBackground.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"add_card_background.png"]];
            _addCardButtonBackground.center = CGPointMake(80,IPHONE_UI_HEIGHT-30);
            _addCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            _addCardButton.center = CGPointMake(80,IPHONE_UI_HEIGHT-30);
            
            
            
        } else {
            
            _addCardButtonBackground = [[UIView alloc] initWithFrame:CGRectMake(0,0, IPAD_UI_MASTER_WIDTH, 70)];
            _addCardButtonBackground.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"add_card_background.png"]];
            _addCardButtonBackground.center = CGPointMake(IPAD_UI_MASTER_WIDTH/2,IPAD_UI_HEIGHT-35);
            
            _addCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
            _addCardButton.center = CGPointMake(IPAD_UI_MASTER_WIDTH/2,IPAD_UI_HEIGHT-35);
        }
        
        _addCardButtonBackground.hidden = YES;
        
        [_addCardButton setImage:[UIImage imageNamed:@"plus_button.png"] forState:UIControlStateNormal];
        _addCardButton.showsTouchWhenHighlighted = YES;
        [_addCardButton addTarget:self action:@selector(createNewCard:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //Update right pack information (only appliable for iPhone）
    if ((isUserInterfaceIdiomPhone) && (_currentPack.packID != -1)) {   //must be a valid pack
        
        if (_rightPackView == nil) {
            _rightPackView = [[UIView alloc] initWithFrame:CGRectMake(150, IPHONE_UI_NAVIGATION_BAR_HEIGHT, IPHONE_UI_WIDTH-150-100, IPHONE_UI_HEIGHT)];
        }
        
        if (_rightPackImage == nil) {
            _rightPackImage = [[UIImageView alloc] init];
            _rightPackImage.frame = CGRectMake(0, 0, 180, 144);
            _rightPackImage.contentMode = UIViewContentModeScaleAspectFit;
            _rightPackImage.center = CGPointMake((IPHONE_UI_WIDTH-150)/2-20, (IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT)/2-20);
            _rightPackImage.layer.cornerRadius = 5;
            _rightPackImage.layer.masksToBounds = TRUE;
            _rightPackImage.layer.opacity = 0.85;
            [_rightPackView addSubview:_rightPackImage];
        }
        
        NSString *fileName = [_currentPack.coverImageURL lastPathComponent];
        if ([fileName isEqualToString:@"default_pack_cover_image.jpg"]) {
            _rightPackImage.image = [UIImage imageNamed:@"default_pack_cover_image.jpg"];
        } else {
            NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:fileName];
            _rightPackImage.image = [UIImage imageWithContentsOfFile:path];
        }
        
        
        if (_rightPackCardNo == nil) {
            _rightPackCardNo = [[UILabel alloc] init];
            _rightPackCardNo.textColor = [UIColor whiteColor];
            _rightPackCardNo.backgroundColor = [UIColor clearColor];
            _rightPackCardNo.textAlignment = NSTextAlignmentCenter;
            _rightPackCardNo.font = [UIFont systemFontOfSize: 14];
            CGRect rect = _rightPackImage. frame;
            rect.origin.y = rect.origin.y +rect.size.height+16;
            rect.size.height = 15;
            _rightPackCardNo.frame = rect;
            [_rightPackView addSubview:_rightPackCardNo];
        }
        
        if (_rightPackImage != nil) {
          [_rightPackCardNo setText:[NSString stringWithFormat:@"%@: %d",NSLocalizedString(@"Title_Total_Number_Card",@""),[_currentPack cards].count]];    
        }
        
        
        [self.navigationController.view insertSubview:_rightPackView atIndex:0];
        [self.navigationController.view bringSubviewToFront:_rightPackView];
        
    }
    
    [self.navigationController.view addSubview:_addCardButtonBackground];    
    [self.navigationController.view insertSubview:_addCardButton atIndex:0];
    [self.navigationController.view bringSubviewToFront:_addCardButton];
    
    
    BOOL isExamplePackDownloadedSuccessful = [[NSUserDefaults standardUserDefaults] boolForKey:@"isExamplePackDownloadedSuccessful"];
    if (isExamplePackDownloadedSuccessful == FALSE) {
        //do nothing
    } else if (_isDownloadingSamplePack){
        _isDownloadingSamplePack = FALSE;
        
    }
    
}


- (void) viewWillDisappear:(BOOL)animated {
    if (isUserInterfaceIdiomPhone) {
        [_rightPackView removeFromSuperview];
    }
    
    [_addCardButtonBackground removeFromSuperview];
    [_addCardButton removeFromSuperview];
}

#pragma mark -
#pragma mark - Create or select Pack

- (void) createNewPack:(id)sender {
    CreatePackViewController * createPackController = [[CreatePackViewController alloc] init];
	UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:createPackController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
	[self presentModalViewController:navController animated:YES];

}

- (void)selectAvailablePacks:(id)sender
{
    
    PackListViewController *packListViewController = [[PackListViewController alloc] initWithNibName:@"PackListViewController" bundle:nil];
    packListViewController.packIDInMasterView = _currentPack.packID;
    
    if (isUserInterfaceIdiomPhone) {
        packListViewController.view.frame = CGRectMake(10, 10, 320, 131);
        [self.navigationController pushViewController:packListViewController animated:YES];
        
    } else {
        
        packListViewController.view.frame = CGRectMake(10, 10, 950, 345);
        packListViewController.view.clipsToBounds = YES;
        packListViewController.view.layer.cornerRadius = 0;
        packListViewController.view.backgroundColor =[UIColor clearColor];
        packListViewController.contentSizeForViewInPopover = CGSizeMake(970, 325);
        
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:packListViewController];
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            navController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        }
        
        
        if (_packListPickerPopover == nil) {
            _packListPickerPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
            _packListPickerPopover.popoverContentSize = CGSizeMake(950, 345);
            if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
                _packListPickerPopover.backgroundColor = [UIColor colorWithRed:63.0/255 green:63.0/255 blue:63.0/255 alpha:.3];
            }
        }
        
        [_packListPickerPopover presentPopoverFromRect:CGRectMake(0, 0, 50, 50) inView:self.navigationController.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}

#pragma mark -
#pragma mark Create new card

- (void)createNewCard:(id)sender
{
    if (![_currentPack.creator isEqualToString:[OpenUDID value]]) {
        [Common alertViewCommon:NSLocalizedString(@"NOT_ALLOW_CREATE_CARD_THAT_IS_NOT_YOU",@"")];
        return;
    }
    
    //For iPhone, we don't need it
    if (!isUserInterfaceIdiomPhone) {
        if (_backgroundOfCreateCardView == nil) {
            _backgroundOfCreateCardView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
        }
        _backgroundOfCreateCardView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8];
        _backgroundOfCreateCardView.layer.opacity = 0;
        [UIView animateWithDuration:0.3 animations:^{
            _backgroundOfCreateCardView.layer.opacity = 1;
            [self.navigationController.view addSubview:_backgroundOfCreateCardView];
        }];
        [_backgroundOfCreateCardView addTarget:self action:@selector(dismissCreateCardView:) forControlEvents:UIControlEventTouchDown];
        
        
        //Avoid fast click to crash app
        _addCardButton.enabled = FALSE;
        _backgroundOfCreateCardView.enabled = FALSE;
        double delayInSeconds = 0.6;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            _addCardButton.enabled = YES;
            _backgroundOfCreateCardView.enabled = YES;
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

- (void) dismissCreateCardView:(id)sender {
    if ([sender isMemberOfClass:[UIButton class]]) {
        [(UIButton *)sender removeFromSuperview];
    }
    [self.detailViewController.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIBarButtonItem action

- (void)playButtonClicked:(id) sender
{
    PlayViewController *playViewController = [[PlayViewController alloc] init];
    playViewController.currentPack = self.currentPack;
    //playViewController.currentCard = self.currentCard;
    if (isUserInterfaceIdiomPhone) {
        playViewController.view.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT);
    } else {
        playViewController.view.frame = CGRectMake(0, 0, IPAD_UI_WIDTH, IPAD_UI_HEIGHT);
    }
    playViewController.view.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if ((self.currentCard == nil) || (self.currentPack == nil)) {
        [Common alertViewCommon:@"Current card or pack is nil"];
        return;
    }
    
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow.rootViewController presentModalViewController:playViewController animated:YES];
    
}

- (void)shareButtonClicked:(id) sender {

    PopoverView *shareSelectPopupPopoverView = [PopoverView showPopoverAtPoint:CGPointMake(CGRectGetMidX(((UIButton *)sender).frame), CGRectGetMaxY(((UIButton *)sender).frame))
                                                                        inView:self.navigationController.view
                                                                     withTitle:@"Please select"
                                                               withStringArray:[NSArray arrayWithObjects:@"Install from the code", @"Share the pack", nil]
                                                                      delegate:self];
    shareSelectPopupPopoverView.tag = popover_enum_share;

    
}

- (void)moreButtonClicked:(id) sender
{
    MoreInfoTableViewController *moreInfoViewController = [[MoreInfoTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:moreInfoViewController animated:YES];
}


- (void)helpButtonClicked:(id) sender
{
    HelpViewController *helpViewController = [[HelpViewController alloc] init];
    [self.navigationController pushViewController:helpViewController animated:YES];
}


- (void)editButtonClicked:(id) sender
{
    if (![[OpenUDID value] isEqualToString:_currentPack.creator]) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"")];
        return;
    }
    
    if (((UIButton *)sender).tag == 0) {
        self.tableView.editing = TRUE;
        [((UIButton *)sender) setImage:[UIImage imageNamed:@"done_button"] forState:UIControlStateNormal];
        ((UIButton *)sender).tag = 1;
    } else {
        self.tableView.editing = FALSE;
        ((UIButton *)sender).tag = 0;
        [((UIButton *)sender) setImage:[UIImage imageNamed:@"edit_button"] forState:UIControlStateNormal];
        
        if (!isUserInterfaceIdiomPhone) {
            if ([[_currentPack cards]count] >0) {
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

- (void) downloadPackNotification:(NSNotification *) notification {

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.isDownloadingPack = TRUE;
    
    NSString *url = (NSString *)[notification object];
    
    [self downloadURLViaURLScheme:url];
}

- (void) selectedPackNotification:(NSNotification *) notification {
    int index = [(NSString *)[notification object] intValue];
    self.currentPack = [[User defaultUser] packs][index];
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.packIDForMasterViewPack = self.currentPack.packID;
    
    if (!isUserInterfaceIdiomPhone) {
        [_packListPickerPopover dismissPopoverAnimated:YES];
        self.detailViewController.title = _currentPack.packName;
    } else {
        self.title = _currentPack.packName;
    }
    
    [self.tableView reloadData];
    
    //每次选择新的pack都需要初始化
    if (isUserInterfaceIdiomPhone == FALSE) {
        self.detailViewController.isResizedArray = nil;
    }
    
    if ((!isUserInterfaceIdiomPhone) && ([_currentPack cards].count != 0)) {
        self.detailViewController.currentPack = _currentPack;
        [self.detailViewController showPackInfoView];
    } else if ((!isUserInterfaceIdiomPhone) && ([_currentPack cards].count == 0)) {
        self.detailViewController.title = @"";
        self.detailViewController.currentCard = nil;
        self.detailViewController.currentPack = _currentPack;
        self.detailViewController.indexCard = 0;
        [self.detailViewController showCurrentCardInScrollView:YES];
        
    }
    
}


-(void)removeBackgroundAfterCardCreatedNotification:(NSNotification *)notification{
	
    //we do refresh tableview cell in updateMasterAfterSaveCardNotification
    
    if (!isUserInterfaceIdiomPhone) {
        [_backgroundOfCreateCardView removeFromSuperview];
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
    cardExample.question.title = NSLocalizedString(@"ToolbarItem_Question",nil);
    cardExample.answer.title = NSLocalizedString(@"ToolbarItem_Answer",nil);
    [self.currentPack addCard:cardExample];
    
    _indexCard = 0;
    
    [self.tableView reloadData];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    if (isUserInterfaceIdiomPhone) {
        self.title = _currentPack.packName;
    } else {
        self.detailViewController.title = _currentPack.packName;
        [self.detailViewController showPackInfoView];
    }
}

- (void) updateMasterAfterSaveCardNotification:(NSNotification *) notification {
    
    NSString *notificationStr = (NSString *)[notification object];
    
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

- (void) showPackListNotification :(NSNotification *) notification {
    //avoid this kind of issue: [UIPopoverController _commonPresentPopoverFromRect:inView:permittedArrowDirections:animated:]: Popovers cannot be presented from a view which does not have a window.
    [self performSelector:@selector(showPackListAfterApplicationDidBecomeActive) withObject:nil afterDelay:0.5];
}


- (void) showPackListAfterApplicationDidBecomeActive {
    
    if (self.view.window == nil) {
        return;//for safe and to avoid same issue in showPackListNotification
    }
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.isDownloadingPack == FALSE) {
        [self selectAvailablePacks:nil];
    }
}


- (void) dismissPackListNotification :(NSNotification *) notification {
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    } else {
        if (_packListPickerPopover) {
            [_packListPickerPopover dismissPopoverAnimated:NO];
        }
    }
}

- (void) playNotification :(NSNotification *) notification {
    
    if (isUserInterfaceIdiomPhone == FALSE) {
        [_packListPickerPopover dismissPopoverAnimated:YES];
    } else {
        //[self.navigationController popToRootViewControllerAnimated:TRUE];
    }
    
    int index = [[notification object] intValue];
    Pack *selectedPack = [[[User defaultUser] packs] objectAtIndex:index];
    
    PlayViewController *playViewController = [[PlayViewController alloc] init];
    playViewController.currentPack = selectedPack;
    if (isUserInterfaceIdiomPhone) {
        playViewController.view.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT);
    } else {
        playViewController.view.frame = CGRectMake(0, 0, IPAD_UI_WIDTH, IPAD_UI_HEIGHT);
    }
    playViewController.view.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if ((self.currentCard == nil) || (self.currentPack == nil)) {
        [Common alertViewCommon:@"Current card or pack is nil"];
        return;
    }
    
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow.rootViewController presentModalViewController:playViewController animated:YES];
}

- (void) toCreateNewPackNotification:(NSNotification *) notification {
    
    if (isUserInterfaceIdiomPhone == false) {
        [_packListPickerPopover dismissPopoverAnimated:YES];
    }
    
    [self createNewPack:nil];
    
}

- (void) showIntroductionVideoNotification:(NSNotification *) notification {
    
    NSURL *url = [NSURL URLWithString:@"http://www.youtube.com/embed/TJkmc8-eyvE"];
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
    
    [self selectAvailablePacks:nil];
    
    if (isUserInterfaceIdiomPhone == FALSE) {
        AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.packIDForMasterViewPack = self.currentPack.packID;
        appDelegate.isDownloadingPack = FALSE;
        
        self.detailViewController.detailItem = _currentCard.cardName;
        self.detailViewController.currentCard = _currentCard;
        self.detailViewController.currentPack = _currentPack;
        self.detailViewController.indexCard = _indexCard;
        
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:_indexCard inSection:0];
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self.detailViewController showPackInfoView];
        //[self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
    }
    
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
        DDLogInfo(@"card.cardSN = %d, indexPath.row = %d", card.cardSN, indexPath.row);
        DDLogInfo(@"******warning: We have to reorder it since it's not consistent");
        card.cardSN = indexPath.row +1;
        [card save];
    }
    
    cell.indexLabel.text = [NSString stringWithFormat:@"%d",card.cardSN];
    

    BOOL flag = ([card.coverImageURL rangeOfString:@".png"].location != NSNotFound) ||
                           ([card.coverImageURL rangeOfString:@".jpg"].location != NSNotFound);
    NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[card.coverImageURL lastPathComponent]];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if (flag && (image != NULL)) {
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
    

    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDLogInfo(@"%s",__FUNCTION__);
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
            
            //We need to avoid do pushViewController twice.
            NSArray *viewControllerArray =self.navigationController.viewControllers;
            if (![[viewControllerArray objectAtIndex:[viewControllerArray count]-1] isKindOfClass:[self.detailViewController class]]) {
                [self.navigationController pushViewController:self.detailViewController animated:YES];
            }
        } else {
            self.detailViewController.currentCard = _currentCard;
            self.detailViewController.currentPack = _currentPack;
            self.detailViewController.indexCard = _indexCard;
            [self.detailViewController hidePackInfoView];
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
    
    if (![[OpenUDID value] isEqualToString:_currentPack.creator]) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"")];
        return;
    }
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:NSLocalizedString(@"DIALOG_DELETE_CARD",@"")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Delete",@"")
                                              otherButtonTitles:NSLocalizedString(@"Keyboard_Cancel",@""), nil];
        alert.tag = UIAlertViewTypeEnum_DeleteCard;
        alert.delegate = self;
        [alert show];
    }
    
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
            NSIndexPath *selectedIndexPath;
            if (indexPath.row != 0) {
                selectedIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:0];
            } else {
                selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            }
            [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
        } else {
            self.detailViewController.title = @"";
            self.detailViewController.currentCard = nil;
            self.detailViewController.indexCard = 0;
            [self.detailViewController showCurrentCardInScrollView:YES];
        }
    } else {
        //Update right pack info
        if (_rightPackImage.image != nil) {
          [_rightPackCardNo setText:[NSString stringWithFormat:@"Total cards: %d",[_currentPack cards].count]];
        }
        
    }
    
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self moveAction:fromIndexPath toIndexPath:toIndexPath];    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark -
#pragma mark - FMMoveTableView special delegate


- (void)moveTableView:(FMMoveTableView *)tableView willMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (BOOL)moveTableView:(FMMoveTableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![[OpenUDID value] isEqualToString:_currentPack.creator]) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"")];
        return false;
    }  else {
        return true;
    }
}

- (void)moveTableView:(FMMoveTableView *)tableView moveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [self moveAction:fromIndexPath toIndexPath:toIndexPath];
}


#pragma mark -
#pragma mark - Move action

- (void) moveAction: (NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *) toIndexPath {
    DDLogInfo(@"move from:%d to:%d", fromIndexPath.row, toIndexPath.row);
    
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
        [self.tableView selectRowAtIndexPath:toIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:toIndexPath];
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
        [_HUD hide:YES];
        [self checkPassword];
    }
}

- (void)downloadFail {
    [_HUD hide:YES];
}

#pragma mark -
#pragma mark - Download action

- (void) downloadURLViaURLScheme:(NSString *)urlStr{
    
    if ([DataManager apiReachable] == NO) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_PLEASE_CHECK_YOUR_NETWORK",@"")];
        
        return;
    }
    
    NSString *httpURL = [urlStr stringByReplacingOccurrencesOfString:@"fcc" withString:@"http"];
    NSString *downloadableURL = [httpURL stringByReplacingOccurrencesOfString:@"www" withString:@"dl"];
    NSDictionary *params = [NSString queryParamsFromString:downloadableURL];
    NSString *type = params[@"type"];
    NSString *from = params[@"from"];
    
    if (from == NULL) {
        from = @"Unknown person";
    }
    
    
    if ([urlStr rangeOfString:@".zip"].length == 0) {
        [Common alertViewCommon:@"Incorrect URL share linkage (must end with .zip"];
        return;
    }
    
    //urlStr is kind of "fcc://www.dropbox.com/s/xdkukqr6ezjntu7/Pack1374148414-1884690931.zip?from=Microsoft"
    //[urlStr lastPathComponent] is kind of "Pack1374148414-1884690931.zip?from=Microsoft"
    NSRange range = [[urlStr lastPathComponent] rangeOfString:@".zip"];
    NSString *simpleDBItemName = [[urlStr lastPathComponent] substringToIndex:range.location];
    BOOL isAllowedToDownload = [self checkDownloadable:simpleDBItemName];
    if (isAllowedToDownload) {
        [self showProgressIndicator:type withSource:from];
        NSString *downloadableDropboxURL = [ZipFileDownloadHelper convertToDropboxDownloadURL:urlStr];
        [_zipFileDownloadHelper downloadZipFile:downloadableDropboxURL];
        _zipFileDownloadHelper.delegate = self;
    }  else {
        [Common alertViewCommon:@"You have reached the limit of downloads for this pack"];
    }
    
}

- (BOOL) checkDownloadable: (NSString *) itemName{
    BOOL result = false;
    
    NSString *defaultDomain = [AmazonClientManager defaultDomain];
    //itemName = @"Pack1374144082-185879295"; //only for test, will be removed
    _amazonSimpleDBItemName = itemName;
    NSMutableDictionary *dict = [AmazonClientManager fetchAttributeValuesAtItem:itemName withDomainName:defaultDomain];
    
    _currentDownloadCount = [[dict objectForKey:@"currentNo"] integerValue];
    _maxDownloadCount = [[dict objectForKey:@"maxNo"] integerValue];
    
    if ((_currentDownloadCount < _maxDownloadCount)  || (_maxDownloadCount == 0)) {  //maxNo = 0 means no record in AmazonSDB
        result = TRUE;
    } else {
        result = FALSE;
    }
    
    return result;
}


#pragma mark -
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case UIAlertViewTypeEnum_SetPassword:{
            NSString *password = [alertView textFieldAtIndex:0].text;
            
            if (password == NULL) {
                password = @"";
            }
            
            if (buttonIndex == 0) {
                ZipArchive* za = [[ZipArchive alloc] init];
                NSString *downloadedZipPackFileFixedPath = [FileOperationHelper downloadedZipPackFileFixedPath];
                if( [za UnzipOpenFile:downloadedZipPackFileFixedPath Password:password]) {
                    BOOL ret = [za UnzipFileTo:[FileOperationHelper downloadedPackFileDirectory] overWrite:YES];
                    
                    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[FileOperationHelper unzippedPackInfoJsonFilePath] error:nil];
                    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
                    long long fileSize = [fileSizeNumber longLongValue];
                    
                    if (( NO==ret ) || (fileSize == 0)) {
                        //when password encripted, will go into here to
                        DDLogInfo(@"%s\nUnzip file(%@) failed",__FUNCTION__,downloadedZipPackFileFixedPath);
                        [Common alertViewCommon:@"Wrong password"];
                        [za UnzipCloseFile];
                    } else {
                        DDLogInfo(@"%s\nUnzip file successfully",__FUNCTION__);
                        [za UnzipCloseFile];
                        
                        [[NSFileManager defaultManager] removeItemAtPath:downloadedZipPackFileFixedPath error:nil];
                        
                        [self assemblePack];
                    }
                    
                } else {
                    DDLogInfo(@"%sFailure to unzip downloaded file(%@)",__FUNCTION__,downloadedZipPackFileFixedPath);
                    [Common alertViewCommon:@"Failure to unzip downloaded file"];
                    [za UnzipCloseFile];
                }
            } else if (buttonIndex == 1) {
                //cancel and do nothing. For example, downloaded zip file is broken or unzippable
            }
            
            break;
        }
            
            
        case UIAlertViewTypeEnum_DeleteCard: {
            if (buttonIndex == 0) {
                [self deleteCurrentCard:_currentIndexPath];
            } else if (buttonIndex == 1) {
                //do nothing
            }
            break;
        }
            
        case UIAlertViewTypeEnum_Download_From_Code: {
            if (buttonIndex == 0) {
                NSString *downloadCode = [alertView textFieldAtIndex:0].text;
                if (downloadCode.length > 0) {
                    NSString *urlStr = nil;
                    if ([downloadCode rangeOfString:@"http://tinyurl.com"].length >0) {
                        urlStr = downloadCode;
                    } else {
                        urlStr = [NSString stringWithFormat:@"http://tinyurl.com/%@",downloadCode];
                    }
                    
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
                }
            } else {
                //do nothing
            }            
            
            break;
        }
            
        default:
            break;
    }
}


#pragma mark -
#pragma mark - Unzip and assemble pack/card

- (void) checkPassword {
    
    ZipArchive* za = [[ZipArchive alloc] init];
    NSString *downloadedZipPackFileFixedPath = [FileOperationHelper downloadedZipPackFileFixedPath];
    [za UnzipOpenFile:downloadedZipPackFileFixedPath];
    if( [za UnzipIsEncrypted]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Input a password"
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                              otherButtonTitles:NSLocalizedString(@"Keyboard_Cancel",@""), nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alert textFieldAtIndex:0].text = @"";
        alert.tag = UIAlertViewTypeEnum_SetPassword;
        alert.delegate = self;
        [alert show];
    } else {
        BOOL ret = [za UnzipFileTo:[FileOperationHelper downloadedPackFileDirectory] overWrite:YES];
        if( NO==ret ) {
            DDLogInfo(@"%s\nUnzip file(%@) failed",__FUNCTION__,downloadedZipPackFileFixedPath);
        } else {
            DDLogInfo(@"%s\nUnzip file successfully",__FUNCTION__);
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
    
    NSString *packPlatformStr;
    
    //Step2: buid pack
    Pack *pack = [[Pack alloc] init];
    NSError *error = nil;
    NSString *downloadedPackInfoFilePath = [[FileOperationHelper downloadedPackFileDirectory] stringByAppendingPathComponent:@"packInformation.json"];
    NSData *packData = [NSData dataWithContentsOfFile:downloadedPackInfoFilePath];
    if (!packData) {
        [Common alertViewCommon:@"Error when parsing packInformation.json"];
        return;
    }
    id packJsonObject = [NSJSONSerialization JSONObjectWithData:packData options:
                           NSJSONReadingMutableContainers error:&error];
    if (packJsonObject != nil && error == nil) {
        if ([packJsonObject isKindOfClass:[NSDictionary class]]){
            
            NSDictionary *packDict = (NSDictionary *)packJsonObject;
            pack.packName = packDict[@"pack_name"];
            pack.sidebarTitle = packDict[@"sidebar_title"];
            pack.creator = packDict[@"creator"];
            pack.createDate = (int)[[NSDate date] timeIntervalSince1970];
            pack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
            pack.creatorNickName = packDict[@"creator_nick_name"];
            
            packPlatformStr = packDict[@"platform"];
            
            //We need to move cover image to imagesDirectory
            if ([packDict[@"cover_image"] lastPathComponent].length > 0) {
                
                error = nil;
                NSString *currentcoverImageURL = [[FileOperationHelper downloadedPackFileDirectory ] stringByAppendingPathComponent:[packDict[@"cover_image"] lastPathComponent]];
                NSString *newCoverImageURL = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:newCoverImageURL]) {
                    [[NSFileManager defaultManager] moveItemAtPath:currentcoverImageURL toPath:newCoverImageURL error:&error];
                    if (error) {
                        DDLogInfo(@"%s:Error when moving Pack's cover image",__FUNCTION__);
                        return;
                    }
                }
                pack.coverImageURL = newCoverImageURL;
            } else {
                pack.coverImageURL = @"";
            }
            
        }
    } else {
        DDLogInfo(@"Unexpected packInformation.json format");
    }
    
    //Step3: Update user's pack and database
    pack.userID = [User defaultUser].userID;
    [[User defaultUser] addPack:pack];
    
    [[NSFileManager defaultManager] removeItemAtPath:downloadedPackInfoFilePath error:nil];
    
    //Step4: build cards by parsing zipped card
    error = nil;
    NSArray *fileListArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[FileOperationHelper downloadedPackFileDirectory] error:&error];
    if (error) {
        DDLogInfo(@"%s:Error when using contentsOfDirectoryAtPath of NSFileManager",__FUNCTION__);
    }
    
    BOOL buildCardResultError = FALSE;
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *zippedCardFileName in fileListArray) {
        Card *assembledCard;
        if ([zippedCardFileName rangeOfString:@".zip"].length != 0) {
            NSString *zippedCardFullPath = [[FileOperationHelper downloadedPackFileDirectory] stringByAppendingPathComponent:zippedCardFileName];
            assembledCard = [self unzipFileThenAssembleCard:zippedCardFullPath platform:packPlatformStr];
            if (assembledCard)
                [array addObject:assembledCard];
            else {
                DDLogInfo(@"%s:Error when unzipping %@",__FUNCTION__,zippedCardFileName);
                buildCardResultError = TRUE;
            }
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
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isExamplePackDownloadedSuccessful"];
    
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
    [downloadLinkageMutableDict setObject:_zipFileDownloadHelper.downloadedURL forKey:[NSString stringWithFormat:@"%d",pack.packID]];
    [[NSUserDefaults standardUserDefaults] setObject:downloadLinkageMutableDict forKey:@"savedDownloadLinkage"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];

    //step6. update amazon sinpleDB
    [self updateDownloadLimitCount];
    
    //Step7:
    if ((![pack.creator isEqualToString:[OpenUDID value]])&&(_maxDownloadCount == 1)) {
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
        NSString *defaultDomain = [AmazonClientManager defaultDomain];
        NSString *currentNo = [NSString stringWithFormat:@"%d",_currentDownloadCount + 1];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:currentNo, @"currentNo", nil];
        [AmazonClientManager insertOrUpdateItem:dict withItemName:_amazonSimpleDBItemName withDomainName:defaultDomain];
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
            DDLogInfo(@"%s\nUnzip file(%@) failed",__FUNCTION__,zippedFilePath);
        } else {
            //DDLogInfo(@"%s\nUnzip file successfully",__FUNCTION__);
        }
        [za UnzipCloseFile];
        
        [[NSFileManager defaultManager] removeItemAtPath:zippedFilePath error:nil];
    } else {
        DDLogInfo(@"%s\nunzip %@ failed", __FUNCTION__,zippedFilePath);
    }
    
    Card *assembledCard = [[Card alloc] init];
    NSString *temporaryImagesDir = [FileOperationHelper temporaryImagesDirectory];
    
    //step2: Assemable question card
    error = nil;
    NSString *questionJsonPath = [temporaryImagesDir stringByAppendingPathComponent:@"questionTextContent.json"];
    NSData *questionData = [NSData dataWithContentsOfFile:questionJsonPath];
    if (!questionData) {
        [Common alertViewCommon:@"Error when parsing questionTextContent.json"];
        return nil;
    }
    id questionJsonObject = [NSJSONSerialization JSONObjectWithData:questionData options:NSJSONReadingMutableContainers error:&error];
    if (questionJsonObject != nil && error == nil) {
        
        if ([questionJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *questionDict = (NSDictionary *)questionJsonObject;
            [assembledCard question].questionID = -1; // -1 means new
            [assembledCard question].cardID = -1;
            [assembledCard question].title = questionDict[@"title"];
            [assembledCard question].main = questionDict[@"main"];
            [assembledCard question].sub = questionDict[@"sub"];
            [assembledCard question].subheading = questionDict[@"subheading"];
            [assembledCard question].logoURLLinkage = questionDict[@"logo_url"];
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            if ([questionDict[@"logo"] length] > 0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"logo"]] toPath:newFileName error:&error];
                if (error) {
                    DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                } else {
                    [assembledCard question].logoFullPath = newFileName;
                }
            } else {
                [assembledCard question].logoFullPath = @"";
            }
            
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            if ([questionDict[@"image"] length] >0) {
                [[NSFileManager defaultManager] copyItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"image"]] toPath:newFileName error:&error];
                if (error) {
                    DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                } else {
                    [assembledCard question].imageFullPath = newFileName;
                }
            } else {
                [assembledCard question].imageFullPath = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            if ([questionDict[@"cover_image"] length] > 0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"cover_image"]] toPath:newFileName error:&error];
                if (error) {
                    DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                } else {
                    assembledCard.coverImageURL = newFileName;
                }
            }   else {
                assembledCard.coverImageURL = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            if ([questionDict[@"background_image"] length] > 0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:questionDict[@"background_image"]] toPath:newFileName error:&error];
                if (error) {
                    DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
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
            assembledCard.cardSN = [questionDict[@"cardSN"] intValue];
            assembledCard.question.templateID = [questionDict[@"template_id"] intValue];
            
            [assembledCard question].css.subheadingAlign = questionDict[@"subheading_align"];
            [assembledCard question].css.subheadingColor = questionDict[@"subheading_color"];
            [assembledCard question].css.mainAlign = questionDict[@"main_align"];
            [assembledCard question].css.mainColor = questionDict[@"main_color"];
            [assembledCard question].css.subAlign = questionDict[@"sub_align"];
            [assembledCard question].css.subColor = questionDict[@"sub_color"];
            
            [assembledCard question].css.subheadingFont = questionDict[@"subheading_font"];
            [assembledCard question].css.mainFont = questionDict[@"main_font"];
            [assembledCard question].css.subFont = questionDict[@"sub_font"];
            
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
                        DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                    } else {
                        [assembledCard question].movieFullPath = newFileName;
                    }
                    
                }
                
            }  else {
                [assembledCard question].movieFullPath = @"";
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
                    DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                } else {
                    [assembledCard question].recordedSoundFullPath = newFileName;
                }
            }   else {
                [assembledCard question].recordedSoundFullPath = @"";
            }
            
            
            //Deal with font size difference between iPhone and iPad
            int subheadingSize = [questionDict[@"subheading_size"] integerValue];;
            int mainSize = [questionDict[@"main_size"] integerValue];
            int subSize = [questionDict[@"sub_size"] integerValue];
            
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
                DDLogInfo(@"You are using iPad and pack was made on iPhone");
                [assembledCard question].css.subheadingSize = subheadingSize * FONT_FACTOR_FROM_IPHONE_TO_IPAD;
                [assembledCard question].css.mainSize = mainSize * FONT_FACTOR_FROM_IPHONE_TO_IPAD;
                [assembledCard question].css.subSize = subSize * FONT_FACTOR_FROM_IPHONE_TO_IPAD;
            } else if ([packPlatformStr isEqualToString:@"iPad"] && (isUserInterfaceIdiomPhone)){
                DDLogInfo(@"You are using iPhone and pack was made on iPad");
                [assembledCard question].css.subheadingSize = subheadingSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                [assembledCard question].css.mainSize = mainSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                [assembledCard question].css.subSize = subSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE - FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                
            } else if ((isUserInterfaceIdiomPhone) && (![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                DDLogInfo(@"You are using iPhone and pack was made on non-iOS platform");

                //the ideal default size would be subheadingSize = 16, mainSize = 20, subSize = 16
                //need to take care when it's too small. we don't need to worry when it's too big because we have resize logic later
                float factor = 0;
                if ((subheadingSize < 16) && (subheadingSize >0)) {
                    factor = subheadingSize/16.0;
                    [assembledCard question].css.subheadingSize = subheadingSize/factor;// ==16
                    [assembledCard question].css.mainSize = mainSize/factor;
                    [assembledCard question].css.subSize = subSize/factor; 
                } else if ((mainSize < 20) && (mainSize >0)) {
                    factor = mainSize/20.0;
                    [assembledCard question].css.subheadingSize = subheadingSize/factor;
                    [assembledCard question].css.mainSize = mainSize/factor; // ==20
                    [assembledCard question].css.subSize = subSize/factor;
                } else if ((subSize < 16) && (subSize >0)) {
                    factor = subSize/16.0;
                    [assembledCard question].css.subheadingSize = subheadingSize/factor;
                    [assembledCard question].css.mainSize = mainSize/factor;
                    [assembledCard question].css.subSize = subSize/factor;  // ==16
                }
                
                
            } else if ((!isUserInterfaceIdiomPhone) &&(![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                DDLogInfo(@"You are using iPad and pack was made on non-iOS platform");
                
                //the ideal default size would be subheadingSize = 32, mainSize = 40, subSize = 32
                //need to take care when it's too small. we don't need to worry when it's too big because we have resize logic later
                float factor = 0;
                if ((subheadingSize < 32) && (subheadingSize >0)) {
                    factor = subheadingSize/32.0;
                    [assembledCard question].css.subheadingSize = subheadingSize/factor;// ==32
                    [assembledCard question].css.mainSize = mainSize/factor;
                    [assembledCard question].css.subSize = subSize/factor;
                } else if ((mainSize < 40) && (mainSize >0)) {
                    factor = mainSize/40.0;
                    [assembledCard question].css.subheadingSize = subheadingSize/factor;
                    [assembledCard question].css.mainSize = mainSize/factor; // ==40
                    [assembledCard question].css.subSize = subSize/factor;
                } else if ((subSize < 32) && (subSize >0)) {
                    factor = subSize/32.0;
                    [assembledCard question].css.subheadingSize = subheadingSize/factor;
                    [assembledCard question].css.mainSize = mainSize/factor;
                    [assembledCard question].css.subSize = subSize/factor;  // ==32
                }
                
            } else {
                DDLogInfo(@"The platform you are using and pack was made are the same");
                [assembledCard question].css.subheadingSize = subheadingSize;
                [assembledCard question].css.mainSize = mainSize;
                [assembledCard question].css.subSize = subSize;
            }
            
        }
    } else {
        DDLogInfo(@"Unexpected questionTextContent.json format");
    }
    [[NSFileManager defaultManager] removeItemAtPath:questionJsonPath error:nil];
    
    //step3: Assemable answer card
    error = nil;
    NSString *answerJsonPath = [temporaryImagesDir stringByAppendingPathComponent:@"answerTextContent.json"];
    NSData *answerData = [NSData dataWithContentsOfFile:answerJsonPath];
    if (!answerData) {
        [Common alertViewCommon:@"Error when parsing answerTextContent.json"];
        return nil;
    }
    id answerJsonObject = [NSJSONSerialization JSONObjectWithData:answerData options:
                           NSJSONReadingMutableContainers error:&error];
    if (answerJsonObject != nil && error == nil) {
        if ([answerJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *answerDict = (NSDictionary *)answerJsonObject;
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
            newFileName = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            if ([answerDict[@"image"] length] > 0) {
                [[NSFileManager defaultManager] copyItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"image"]] toPath:newFileName error:&error];
                if (error) {
                    DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                } else {
                    [assembledCard answer].imageFullPath = newFileName;
                }
            } else {
                [assembledCard answer].imageFullPath = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            if ([answerDict[@"logo"] length] >0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"logo"]] toPath:newFileName error:&error];
                if (error) {
                    DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                } else {
                    [assembledCard answer].logoFullPath = newFileName;
                }
            } else {
                [assembledCard answer].logoFullPath = @"";
            }
            
            error = nil;
            newFileName = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            if ([answerDict[@"background_image"] length] >0) {
                [[NSFileManager defaultManager] moveItemAtPath:[temporaryImagesDir stringByAppendingPathComponent:answerDict[@"background_image"]] toPath:newFileName error:&error];
                if (error) {
                    DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                } else {
                    [assembledCard answer].backgroundImageFullPath = newFileName;
                }
            } else {
                [assembledCard answer].backgroundImageFullPath = @"";
            }
            
            assembledCard.answer.templateID = [answerDict[@"template_id"] intValue];
            
            [assembledCard answer].css.subheadingAlign = answerDict[@"subheading_align"];
            [assembledCard answer].css.subheadingColor = answerDict[@"subheading_color"];
            [assembledCard answer].css.mainAlign = answerDict[@"main_align"];
            [assembledCard answer].css.mainColor = answerDict[@"main_color"];
            [assembledCard answer].css.subAlign = answerDict[@"sub_align"];
            [assembledCard answer].css.subColor = answerDict[@"sub_color"];
            
            [assembledCard answer].css.subheadingFont = answerDict[@"subheading_font"];
            [assembledCard answer].css.mainFont = answerDict[@"main_font"];
            [assembledCard answer].css.subFont = answerDict[@"sub_font"];
            
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
                        DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                    } else {
                        [assembledCard answer].movieFullPath = newFileName;
                    }
                }
                
            }   else {
                [assembledCard answer].movieFullPath = @"";
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
                    DDLogInfo(@"%s:Error during moveItemAtPath to %@",__FUNCTION__,newFileName);
                } else {
                    [assembledCard answer].recordedSoundFullPath = newFileName;
                }
            }   else {
                [assembledCard answer].recordedSoundFullPath = @"";
            }
            
            //Deal with font size difference between iPhone and iPad
            int subheadingSize = [answerDict[@"subheading_size"] integerValue];;
            int mainSize = [answerDict[@"main_size"] integerValue];
            int subSize = [answerDict[@"sub_size"] integerValue];
            
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
                [assembledCard answer].css.subheadingSize = subheadingSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                [assembledCard answer].css.mainSize = mainSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                [assembledCard answer].css.subSize = subSize * FONT_FACTOR_FROM_IPAD_TO_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                
            } else if ((isUserInterfaceIdiomPhone) && (![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                DDLogInfo(@"You are using iPhone and pack was made on non-iOS platform");
                
                //the ideal default size would be subheadingSize = 16, mainSize = 20, subSize = 16
                //need to take care when it's too small. we don't need to worry when it's too big because we have resize logic later
                float factor = 0;
                if ((subheadingSize < 16) && (subheadingSize >0)) {
                    factor = subheadingSize/16.0;
                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;// ==16
                    [assembledCard answer].css.mainSize = mainSize/factor;
                    [assembledCard answer].css.subSize = subSize/factor;
                } else if ((mainSize < 20) && (mainSize >0)) {
                    factor = mainSize/20.0;
                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;
                    [assembledCard answer].css.mainSize = mainSize/factor; // ==20
                    [assembledCard answer].css.subSize = subSize/factor;
                } else if ((subSize < 16) && (subSize >0)) {
                    factor = subSize/16.0;
                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;
                    [assembledCard answer].css.mainSize = mainSize/factor;
                    [assembledCard answer].css.subSize = subSize/factor;  // ==16
                }
                
            } else if ((!isUserInterfaceIdiomPhone) &&(![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                DDLogInfo(@"You are using iPad and pack was made on non-iOS platform");
                
                //the ideal default size would be subheadingSize = 32, mainSize = 40, subSize = 32
                //need to take care when it's too small. we don't need to worry when it's too big because we have resize logic later
                float factor = 0;
                if ((subheadingSize < 32) && (subheadingSize >0)) {
                    factor = subheadingSize/32.0;
                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;// ==32
                    [assembledCard answer].css.mainSize = mainSize/factor;
                    [assembledCard answer].css.subSize = subSize/factor;
                } else if ((mainSize < 40) && (mainSize >0)) {
                    factor = mainSize/40.0;
                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;
                    [assembledCard answer].css.mainSize = mainSize/factor; // ==40
                    [assembledCard answer].css.subSize = subSize/factor;
                } else if ((subSize < 32) && (subSize >0)) {
                    factor = subSize/32.0;
                    [assembledCard answer].css.subheadingSize = subheadingSize/factor;
                    [assembledCard answer].css.mainSize = mainSize/factor;
                    [assembledCard answer].css.subSize = subSize/factor;  // ==32
                }
                
            } else {
                DDLogInfo(@"The platform you are using and pack was made are the same");
                [assembledCard answer].css.subheadingSize = subheadingSize;
                [assembledCard answer].css.mainSize = mainSize;
                [assembledCard answer].css.subSize = subSize;
            }
            
        }
    } else {
        DDLogInfo(@"Unexpected questionTextContent.json format");
    }
    [[NSFileManager defaultManager] removeItemAtPath:answerJsonPath error:nil];
    
    [[NSFileManager defaultManager] removeItemAtPath:temporaryImagesDir error:nil];
    
    return assembledCard;
    
}

#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)showProgressIndicator:(NSString *) type withSource:(NSString *) from {
    
    _progressivePercent = 0;
	
    _HUD = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
    
    //_HUD.color = [UIColor blackColor];
    //make sure to be in front and disable user interaction
    CGAffineTransform at = CGAffineTransformMakeRotation(-M_PI/2);
    [_HUD setTransform:at];
    
    [[[UIApplication sharedApplication] keyWindow] insertSubview:_HUD atIndex:0];
    [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:_HUD];
    
    // Set determinate mode
    _HUD.mode = MBProgressHUDModeDeterminate;
    
    _HUD.delegate = self;
    if ([type isEqualToString:@"demo"]) {
        _HUD.labelText = NSLocalizedString(@"DIALOG_DOWNLOAD_PACK",@"");    
    } else {
        _HUD.labelText = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"DIALOG_DOWNLOAD_PACK_FROM_FRIENDS",@""), from];
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
    _selectPackButton = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark – PopoverviewDelegate

- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
    
    [popoverView dismiss];
    
    
    if (popoverView.tag == popover_enum_share) {
        switch (index) {
            case 0: {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Input download code"
                                                                message:nil
                                                               delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                                      otherButtonTitles:NSLocalizedString(@"Keyboard_Cancel",@""), nil];
                [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                [alert textFieldAtIndex:0].text = @"";
                [alert textFieldAtIndex:0].placeholder = @"p8c5tv6";
                alert.tag = UIAlertViewTypeEnum_Download_From_Code;
                alert.delegate = self;
                [alert show];
                break;
            }
            case 1: {
                
                if (_currentPack.isAllowShare) {
                    if ((_currentPack) && (_currentCard)) {
                        _shareHelper = [[DropboxSharekitHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
                        [_shareHelper shareAction];
                    } else {
                        DDLogInfo(@"%s:_currentPack or _currentCard is nil",__FUNCTION__);
                    }
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Share function is forbidden by the pack creator" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                }
                
                break;
            }
            default:
                break;
        }
        
    } else {
        
    }
    
}



@end
