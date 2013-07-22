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

extern BOOL _isDownloadingSamplePack;

@implementation MasterViewController

@synthesize currentPack = _currentPack;
@synthesize currentCard = _currentCard;
@synthesize indexCard = _indexCard;
@synthesize indexPack = _indexPack;
@synthesize backgroundOfCreateCardView = _backgroundOfCreateCardView;
@synthesize tableView = _tableView;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterDetailViewNotification:) name:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadPackNotification:) name:DOWNLOAD_PACK_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterAfterSaveCardNotification:) name:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterAfterDetailScrollNotification:) name:UPDATE_MASTER_AFTER_DETAIL_SCROLL_NOTFICATION object:nil];
        
        //2. Initialize
        _currentPack = [[Pack alloc] init];
        _currentCard = [[Card alloc] init];
        _indexCard = 0;
        _zipFileDownloadHelp =[[ZipFileDownloadHelper alloc] init];
        
        

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        //[self.navigationController.navigationBar setBarTintColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background_navigationbar.png"]]];//we will add this back when xcode5 is finally released
        [self.navigationController.navigationBar setTranslucent:FALSE];
    }
    
    if (isUserInterfaceIdiomPhone) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, IPHONE_UI_MASTER_TABLE_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT) style:UITableViewStylePlain];
    } else {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, IPAD_UI_MASTER_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT) style:UITableViewStylePlain];
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view insertSubview:self.tableView atIndex:0];

    _selectPackButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Packs",@"") style:UIBarButtonSystemItemBookmarks target:self action:@selector(selectAvailablePacks:)];
    
    
    UIBarButtonItem *newPackButton = [[UIBarButtonItem alloc]
                                      initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"add_pack_button.png"] target:self action:@selector(createNewPack:)]];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Edit",@"") style:UIBarButtonItemStylePlain target:self action:@selector(editButtonClicked:)];
    
    self.navigationItem.leftBarButtonItems = @[_selectPackButton,editButton, newPackButton];
    if (isUserInterfaceIdiomPhone) {
        
        UIBarButtonItem *playButton = [[UIBarButtonItem alloc]
                                       initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"play_button.png"] target:self action:@selector(playButtonClicked:)]];
        UIBarButtonItem *shareButton = [[UIBarButtonItem alloc]
                                        initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"share_button.png"] target:self action:@selector(shareButtonClicked)]];
        
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

    if (_addCardButton == nil) {
        if (isUserInterfaceIdiomPhone) {
            _addCardButtonBackground = [[UIView alloc] initWithFrame:CGRectMake(0,0, 160, 60)];
            _addCardButtonBackground.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"add_card_background.png"]];
            _addCardButtonBackground.center = CGPointMake(80,IPHONE_UI_HEIGHT-30);
            _addCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            _addCardButton.center = CGPointMake(80,IPHONE_UI_HEIGHT-30);
            
            
            
        } else {
            
            _addCardButtonBackground = [[UIView alloc] initWithFrame:CGRectMake(0,0, IPAD_UI_MASTER_WIDTH, 80)];
            _addCardButtonBackground.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"add_card_background.png"]];
            _addCardButtonBackground.center = CGPointMake(IPAD_UI_MASTER_WIDTH/2,IPAD_UI_HEIGHT-40);
            
            _addCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
            _addCardButton.center = CGPointMake(IPAD_UI_MASTER_WIDTH/2,IPAD_UI_HEIGHT-30);
        }
        
        [_addCardButton setImage:[UIImage imageNamed:@"plus_button.png"] forState:UIControlStateNormal];
        _addCardButton.showsTouchWhenHighlighted = YES;
        [_addCardButton addTarget:self action:@selector(createNewCard:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //Update right pack information (only appliable for iPhone）
    if ((isUserInterfaceIdiomPhone) && (_currentPack.packID != -1)) {   //must be a valid pack
        
        if (_rightPackView == nil) {
            _rightPackView = [[UIView alloc] initWithFrame:CGRectMake(150, IPHONE_UI_NAVIGATION_BAR_HEIGHT, IPHONE_UI_WIDTH-150-100, IPHONE_UI_HEIGHT)];
            _rightPackView.backgroundColor = [UIColor blackColor];
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
        _rightPackImage.image = [UIImage imageWithContentsOfFile:_currentPack.coverImageURL];
        
        
        if (_rightPackCardNo == nil) {
            _rightPackCardNo = [[UILabel alloc] init];
            _rightPackCardNo.textColor = [UIColor whiteColor];
            _rightPackCardNo.backgroundColor = [UIColor clearColor];
            _rightPackCardNo.textAlignment = UITextAlignmentCenter;
            _rightPackCardNo.font = [UIFont systemFontOfSize: 14];
            CGRect rect = _rightPackImage. frame;
            rect.origin.y = rect.origin.y +rect.size.height+16;
            rect.size.height = 15;
            _rightPackCardNo.frame = rect;
            [_rightPackView addSubview:_rightPackCardNo];
        }
        
        [_rightPackCardNo setText:[NSString stringWithFormat:@"%@: %d",NSLocalizedString(@"Title_Total_Number_Card",@""),[_currentPack cards].count]];
        
        [self.navigationController.view insertSubview:_rightPackView atIndex:0];
        [self.navigationController.view bringSubviewToFront:_rightPackView];
        
    }
    
    [self.navigationController.view addSubview:_addCardButtonBackground];    
    [self.navigationController.view insertSubview:_addCardButton atIndex:0];
    [self.navigationController.view bringSubviewToFront:_addCardButton];
    
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
        
        packListViewController.view.frame = CGRectMake(10, 10, 640, 320);
        packListViewController.view.clipsToBounds = YES;
        packListViewController.view.layer.cornerRadius = 0;
        packListViewController.view.backgroundColor =[UIColor clearColor];
        packListViewController.contentSizeForViewInPopover = CGSizeMake(660, 300);
        
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:packListViewController];
        
        _packListPickerPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        _packListPickerPopover.popoverContentSize = CGSizeMake(640, 320);
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

- (void)shareButtonClicked {
    if ((_currentPack) && (_currentCard)) {
        DropboxSharekitHelper *shareHelper = [[DropboxSharekitHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
        [shareHelper shareAction];
    } else {
        NSLog(@"%s:_currentPack or _currentCard is nil",__FUNCTION__);
    }
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
    
    if ([((UIBarButtonItem *) sender).title isEqualToString:NSLocalizedString(@"NavigationBarItem_Edit", @"")]) {
        self.tableView.editing = TRUE;
        ((UIBarButtonItem *) sender).title = NSLocalizedString(@"NavigationBarItem_Done", @"");
    } else {
        self.tableView.editing = FALSE;
        ((UIBarButtonItem *) sender).title = NSLocalizedString(@"NavigationBarItem_Edit", @"");
        
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

    
    NSString *url = (NSString *)[notification object];
    
    [self downloadURLViaURLScheme:url];
}

- (void) selectedPackNotification:(NSNotification *) notification {
    _indexPack = [(NSString *)[notification object] intValue];
    self.currentPack = [[User defaultUser] packs][_indexPack];
    
    if (!isUserInterfaceIdiomPhone) {
        [_packListPickerPopover dismissPopoverAnimated:YES];
        self.detailViewController.title = _currentPack.packName;
    } else {
        self.title = _currentPack.packName;
    }
    
    [self.tableView reloadData];
    
    if ((!isUserInterfaceIdiomPhone) && ([_currentPack cards].count != 0)) {
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
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
    
    _indexPack = [[[User defaultUser] packs] count] -1;
    _indexCard = 0;
    
    [self.tableView reloadData];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    if (isUserInterfaceIdiomPhone) {
        self.title = _currentPack.packName;
    } else {
        self.detailViewController.title = _currentPack.packName;
        [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
    }
}

- (void) updateMasterAfterSaveCardNotification:(NSNotification *) notification {
    
    NSString *notificationStr = (NSString *)[notification object];
    
    self.currentPack = [[User defaultUser] packs] [_indexPack];
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

#pragma mark -
#pragma mark - Update UI

- (void) updateMasterDetailViewNotification:(NSNotification *) notification {
    //Step1: update master view
    self.currentPack = (Pack *)[notification object];
    self.indexCard = 0;
    //_selectPackButton.title = _currentPack.packName;
    [self.tableView reloadData];
    
    //Step2: update detail view
    self.detailViewController.detailItem = _currentCard.cardName;
    self.detailViewController.currentCard = _currentCard;
    self.detailViewController.currentPack = _currentPack;
    self.detailViewController.indexCard = _indexCard;
    
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:_indexCard inSection:0];
    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
    
    _isDownloadingSamplePack = FALSE;
    
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
        return 80;
    } else {
        return kCellSizeHeight;
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
        backgroundView.backgroundColor = [UIColor colorWithRed:0.23 green:0.50 blue:0.82 alpha:0.8];
        backgroundView.layer.cornerRadius = 0;
        backgroundView.layer.masksToBounds = YES;
        cell.selectedBackgroundView = backgroundView;
        cell.backgroundColor = [UIColor clearColor];
	}
    
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    Card *card = [_currentPack cards][indexPath.row];
    
    //Just to keep consistent: indexPath.row should be same as card.cardSN
    if (card.cardSN != indexPath.row +1) {
        NSLog(@"card.cardSN = %d, indexPath.row = %d", card.cardSN, indexPath.row);
        NSLog(@"******warning: We have to reorder it since it's not consistent");
        card.cardSN = indexPath.row +1;
        [card save];
    }
    
    cell.indexLabel.text = [NSString stringWithFormat:@"%d",card.cardSN];
    

    BOOL flag = ([card.coverImageURL rangeOfString:@".png"].location != NSNotFound) ||
                           ([card.coverImageURL rangeOfString:@".jpg"].location != NSNotFound);
    UIImage *image = [UIImage imageWithContentsOfFile:card.coverImageURL];
    if (flag && (image != NULL)) {
        cell.cellImageView.image = image;
    } else {
        cell.cellImageView.image = [UIImage imageNamed:@"card_cover_image_placeholder.png"];        
    }
    
    if (_indexCard == indexPath.row) {
        [cell setSelected:YES animated:YES];
    }

    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    
    if (![[OpenUDID value] isEqualToString:_currentPack.creator]) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"")];
        return;
    }
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSArray *tempCards = [_currentPack cards];
        
        for (int i = indexPath.row +1; i < [tempCards count] ; i++) {
            ((Card *)tempCards[i]).cardSN = i;
            [((Card *)tempCards[i]) save];
        }
        [_currentPack removeCard:tempCards[indexPath.row]];
        
        _currentPack.cards = [_currentPack snOrderedCards]; //We need to re-order
        
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil]
                              withRowAnimation:UITableViewRowAnimationFade];
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
            [_rightPackCardNo setText:[NSString stringWithFormat:@"Total cards: %d",[_currentPack cards].count]];
        }
        
	}
    
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSLog(@"move from:%d to:%d", fromIndexPath.row, toIndexPath.row);
    
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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
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
        [self unzipFileThenAssemblePack];
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
        from = @"unkown person";
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
        [_zipFileDownloadHelp downloadZipFile:downloadableDropboxURL];
        _zipFileDownloadHelp.delegate = self;
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
    int maxNo = [[dict objectForKey:@"maxNo"] integerValue];
    
    if ((_currentDownloadCount < maxNo)  || (maxNo == 0)) {  //maxNo = 0 means no record in AmazonSDB
        result = TRUE;
    } else {
        result = FALSE;
    }
    
    return result;
}

#pragma mark -
#pragma mark - Unzip and assemble pack/card

- (void) unzipFileThenAssemblePack {
    
    NSString *packPlatformStr;
    
    //Step1: unzip file
    ZipArchive* za = [[ZipArchive alloc] init];
    NSString *downloadedZipPackFileFixedPath = [FileOperationHelper downloadedZipPackFileFixedPath];
    if( [za UnzipOpenFile:downloadedZipPackFileFixedPath] )
    {
        BOOL ret = [za UnzipFileTo:[FileOperationHelper downloadedPackFileDirectory] overWrite:YES];
        if( NO==ret ) {
            NSLog(@"%s\nUnzip file(%@) failed",__FUNCTION__,downloadedZipPackFileFixedPath);
        } else {
            NSLog(@"%s\nUnzip file successfully",__FUNCTION__);
        }
        [za UnzipCloseFile];
        
        [[NSFileManager defaultManager] removeItemAtPath:downloadedZipPackFileFixedPath error:nil];
    } else {
        [Common alertViewCommon:@"Downloaded zip file is broken or unzippable"];
    }
    
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
            pack.creatorNickName = packDict[@"creator_nick_name"];
            
            packPlatformStr = packDict[@"platform"];
            
            //We need to move cover image to imagesDirectory
            error = nil;
            NSString *currentcoverImageURL = [[FileOperationHelper downloadedPackFileDirectory ] stringByAppendingPathComponent:[packDict[@"cover_image"] lastPathComponent]];
            NSString *newCoverImageURL = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[packDict[@"cover_image"] lastPathComponent]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:newCoverImageURL]) {
                [[NSFileManager defaultManager] moveItemAtPath:currentcoverImageURL toPath:newCoverImageURL error:&error];
                if (error) {
                    NSLog(@"%s:Error when moving Pack's cover image",__FUNCTION__);
                    return;
                }
            }
            pack.coverImageURL = newCoverImageURL;
            
        }
    } else {
        NSLog(@"Unexpected packInformation.json format");
    }
    
    //Step3: Update user's pack and database
    pack.userID = [User defaultUser].userID;
    [[User defaultUser] addPack:pack];
    _indexPack = [[[User defaultUser] packs] count] -1;
    
    [[NSFileManager defaultManager] removeItemAtPath:downloadedPackInfoFilePath error:nil];
    
    //Step4: build cards by parsing zipped card
    error = nil;
    NSArray *fileListArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[FileOperationHelper downloadedPackFileDirectory] error:&error];
    if (error) {
        NSLog(@"%s:Error when using contentsOfDirectoryAtPath of NSFileManager",__FUNCTION__);
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
                NSLog(@"%s:Error when unzipping %@",__FUNCTION__,zippedCardFileName);
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
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self updateDownloadLimitCount];
    
    //Step6: send notification
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

- (Card *) unzipFileThenAssembleCard:(NSString *) zippedFilePath platform:(NSString *)packPlatformStr {
    
    //step1: unzip file
    ZipArchive* za = [[ZipArchive alloc] init];
    if( [za UnzipOpenFile:zippedFilePath] )
    {
        BOOL ret = [za UnzipFileTo:[FileOperationHelper imagesDirectory] overWrite:YES];
        if( NO==ret ) {
            NSLog(@"%s\nUnzip file(%@) failed",__FUNCTION__,zippedFilePath);
        } else {
            //NSLog(@"%s\nUnzip file successfully",__FUNCTION__);
        }
        [za UnzipCloseFile];
        
        [[NSFileManager defaultManager] removeItemAtPath:zippedFilePath error:nil];
    } else {
        NSLog(@"%s\nunzip %@ failed", __FUNCTION__,zippedFilePath);
    }
    
    //step2: Assemable question card
    Card *assembledCard = [[Card alloc] init];
    NSString *imagesDir = [[FileOperationHelper cachesDirectory] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    NSString *questionJsonPath = [imagesDir stringByAppendingPathComponent:@"questionTextContent.json"];
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
            [assembledCard question].logoFullPath = [imagesDir stringByAppendingPathComponent:questionDict[@"logo"]];
            [assembledCard question].imageFullPath = [imagesDir stringByAppendingPathComponent:questionDict[@"image"]];
            assembledCard.coverImageURL = [imagesDir stringByAppendingPathComponent:questionDict[@"cover_image"]];
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
                NSLog(@"You are using iPad and pack was made on iPhone");
                [assembledCard question].css.subheadingSize = subheadingSize / FONT_FACTOR_BETWEEN_IPAD_IPHONE;
                [assembledCard question].css.mainSize = mainSize / FONT_FACTOR_BETWEEN_IPAD_IPHONE;
                [assembledCard question].css.subSize = subSize / FONT_FACTOR_BETWEEN_IPAD_IPHONE;
            } else if ([packPlatformStr isEqualToString:@"iPad"] && (isUserInterfaceIdiomPhone)){
                NSLog(@"You are using iPhone and pack was made on iPad");
                [assembledCard question].css.subheadingSize = subheadingSize * FONT_FACTOR_BETWEEN_IPAD_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                [assembledCard question].css.mainSize = mainSize * FONT_FACTOR_BETWEEN_IPAD_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                [assembledCard question].css.subSize = subSize * FONT_FACTOR_BETWEEN_IPAD_IPHONE - FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                
            } else if ((isUserInterfaceIdiomPhone) && (![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                NSLog(@"You are using iPhone and pack was made on non-iOS platform");
                [assembledCard question].css.subheadingSize = 16;
                [assembledCard question].css.mainSize = 20;
                [assembledCard question].css.subSize = 16;
                
            } else if ((!isUserInterfaceIdiomPhone) &&(![packPlatformStr isEqualToString:@"iPhone"]) && (![packPlatformStr isEqualToString:@"iPad"])) {
                NSLog(@"You are using iPad and pack was made on non-iOS platform");
                [assembledCard question].css.subheadingSize = 32;
                [assembledCard question].css.mainSize = 40;
                [assembledCard question].css.subSize = 32;
                
            } else {
                NSLog(@"The platform you are using and pack was made are the same");
                [assembledCard question].css.subheadingSize = subheadingSize;
                [assembledCard question].css.mainSize = mainSize;
                [assembledCard question].css.subSize = subSize;
            }
            
        }
    } else {
        NSLog(@"Unexpected questionTextContent.json format");
    }
    [[NSFileManager defaultManager] removeItemAtPath:questionJsonPath error:nil];
    
    //step3: Assemable answer card
    error = nil;
    NSString *answerJsonPath = [imagesDir stringByAppendingPathComponent:@"answerTextContent.json"];
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
            [assembledCard answer].imageFullPath = [imagesDir stringByAppendingPathComponent:answerDict[@"image"]];
            [assembledCard answer].logoFullPath = [imagesDir stringByAppendingPathComponent:answerDict[@"logo"]];
            
            assembledCard.answer.templateID = [answerDict[@"template_id"] intValue];
            
            [assembledCard answer].css.subheadingAlign = answerDict[@"subheading_align"];
            [assembledCard answer].css.subheadingColor = answerDict[@"subheading_color"];
            [assembledCard answer].css.mainAlign = answerDict[@"main_align"];
            [assembledCard answer].css.mainColor = answerDict[@"main_color"];
            [assembledCard answer].css.subAlign = answerDict[@"sub_align"];
            [assembledCard answer].css.subColor = answerDict[@"sub_color"];
            
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
                [assembledCard answer].css.subheadingSize = subheadingSize / FONT_FACTOR_BETWEEN_IPAD_IPHONE;
                [assembledCard answer].css.mainSize = mainSize / FONT_FACTOR_BETWEEN_IPAD_IPHONE;
                [assembledCard answer].css.subSize = subSize / FONT_FACTOR_BETWEEN_IPAD_IPHONE;
            } else if ([packPlatformStr isEqualToString:@"iPad"] && (isUserInterfaceIdiomPhone)){
                [assembledCard answer].css.subheadingSize = subheadingSize * FONT_FACTOR_BETWEEN_IPAD_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                [assembledCard answer].css.mainSize = mainSize * FONT_FACTOR_BETWEEN_IPAD_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                [assembledCard answer].css.subSize = subSize * FONT_FACTOR_BETWEEN_IPAD_IPHONE -FONT_OFFSET_BETWEEN_IPAD_IPHONE;
                
            } else {
                [assembledCard answer].css.subheadingSize = subheadingSize;
                [assembledCard answer].css.mainSize = mainSize;
                [assembledCard answer].css.subSize = subSize;
            }
            
        }
    } else {
        NSLog(@"Unexpected questionTextContent.json format");
    }
    [[NSFileManager defaultManager] removeItemAtPath:answerJsonPath error:nil];
    
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


@end
