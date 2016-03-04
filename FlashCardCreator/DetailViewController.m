//
//  DetailViewController.m
//  FFC
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "DetailViewController.h"
#import "MoreInfoTableViewController.h"
#import "FlashCard.h"
#import "Card.h"
#import "User.h"
#import "Pack.h"
#import "Question.h"
#import "Answer.h"
#import "CSS.h"
#import "Reachability.h"
#import "PlayViewControllerV2.h"
#import "FCCBarButton.h"

#import "AWSS3UploadHelper.h"
#import "DropboxShareKitHelper.h"

#import "UIImage+Scale.h"
#import "FileOperationHelper.h"
#import "OpenUDID.h"
#import "AppDelegate.h"

#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>

#import "UIButton+Extensions.h"

#import <BlocksKit/UIAlertView+BlocksKit.h>

#import "TipHelper.h"

enum template_color_enum {
    template_color_enum_blue = 0,
    template_color_enum_coffee = 1,
    template_color_enum_gray = 2,
    template_color_enum_purple = 3,
    template_color_enum_red = 4
    };

enum popover_enum {
    popover_enum_share = 0,
    popover_enum_template_select = 1,
    popover_enum_play = 2,
};


@interface DetailViewController () <PFSignUpViewControllerDelegate,PFLogInViewControllerDelegate,UIAlertViewDelegate,DBSessionDelegate,NSURLConnectionDataDelegate>{
    AWSS3UploadHelper        *_amazonShareHelper;
    DropboxSharekitHelper    *_dropboxShareHelper;
    
}

@end


@implementation DetailViewController

@synthesize currentCard = _currentCard;
@synthesize currentPack = _currentPack;
@synthesize indexCard = _indexCard;
@synthesize masterPopoverController = _masterPopoverController;
@synthesize settingPopoverController = _settingPopoverController;
@synthesize helpPopoverController = _helpPopoverController;

#pragma mark -
#pragma mark Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedPackNotification:) name:CURRENT_PACK_SELECTED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideNavigationBarNotification:) name:HIDE_NAVIGATION_BAR_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNavigationBarNotification:) name:SHOW_NAVIGATION_BAR_NOTIFICATION object:nil];
        
        if (isUserInterfaceIdiomPhone) {
            //需要在进入后台时，隐藏键盘并重新显示navigationbar,否则再次进入前台会导致navigation bar消失。
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(previousCardNotification:)
                                                     name:@"PREVIOUS_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(nextCardNotification:)
                                                     name:@"NEXT_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPackAddedNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPackFinishedNotification:) name:EDIT_PACK_FINISHED_NOTIFICATION object:nil];
        
        if (isUserInterfaceIdiomPhone == false) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareLinkCreatedNotification:) name:SHARE_LINK_CREATED_NOTIFICATION object:nil];
        }
        
    }
    return self;
}

- (void)viewDidLoad
{
    [iConsole info:@"%s",__FUNCTION__];
    [super viewDidLoad];
    
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

        _previousCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,kFlashCardViewTopMarginWithNav_Detail_iPhone,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone) defaultPack:_currentPack defaultCard:_currentCard];
        _currentCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,kFlashCardViewTopMarginWithNav_Detail_iPhone,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone)
                                                defaultPack:_currentPack defaultCard:_currentCard];
        _nextCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,kFlashCardViewTopMarginWithNav_Detail_iPhone,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone)
                                             defaultPack:_currentPack defaultCard:_currentCard];
        
    } else {
        float flashCardYPositionInScrollView;
        flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPad)/2; //Since it's horizontal movement, so this is a constant value
        _previousCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)
                                                 defaultPack:_currentPack defaultCard:_currentCard];
        _currentCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)
                                                defaultPack:_currentPack defaultCard:_currentCard];
        _nextCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)
                                             defaultPack:_currentPack defaultCard:_currentCard];
    }
    
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
       //do nothing
    } else {
        //self.automaticallyAdjustsScrollViewInsets = NO; //we will add this back when xcode5 is finally released
    }
    

}


- (void)loadView {
    [iConsole info:@"%s",__FUNCTION__];
    [super loadView];
    
    UIButton *templateBackgroundSelectButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"template_background_change_button.png"] target:self action:@selector(selectCardBackgroundTemplate:)];
    _templateBackgroundSelectBarButton = [[UIBarButtonItem alloc]
                                       initWithCustomView:templateBackgroundSelectButton];;
    
    //we don't setting button on iPhone
    _settingButton = [[UIBarButtonItem alloc]
                                      initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"setting_button.png"] target:self action:@selector(moreButtonClicked:)]];
    UIButton *playButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"play_button.png"] target:self action:@selector(playButtonClicked:)];
    UIBarButtonItem *playBarButton = [[UIBarButtonItem alloc]
                                   initWithCustomView:playButton];
    
    UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc]
                                    initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"share_button.png"] target:self action:@selector(shareButtonClicked:)]];
    
    UIButton *helpButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"helping_button.png"] target:self action:@selector(helpButtonClicked:)];
    _helpBarButton = [[UIBarButtonItem alloc]
                                   initWithCustomView:helpButton];
    
    if (isUserInterfaceIdiomPhone) {
        
        templateBackgroundSelectButton.contentEdgeInsets = UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset, 0, -K_Navigation_Item_Inset_Offset);
        [templateBackgroundSelectButton setHitTestEdgeInsets:UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset, 0, -K_Navigation_Item_Inset_Offset)];
        helpButton.contentEdgeInsets = UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset*2, 0, -K_Navigation_Item_Inset_Offset*2);
        [helpButton setHitTestEdgeInsets:UIEdgeInsetsMake(0, K_Navigation_Item_Inset_Offset*2, 0, -K_Navigation_Item_Inset_Offset*2)];
        
        self.navigationItem.rightBarButtonItems =
        @[playBarButton,_templateBackgroundSelectBarButton,_helpBarButton];
    } else {
        self.navigationItem.rightBarButtonItems =
                                @[playBarButton,shareBarButton,_settingButton,_helpBarButton,_templateBackgroundSelectBarButton];
    }
    
    //Don't need the back button when on iPad
    if (isUserInterfaceIdiomPhone) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked:)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.delegate = self;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.clipsToBounds = YES;
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = YES;
    _scrollView.backgroundColor =[UIColor clearColor];
    [self.view addSubview:_scrollView];
    
    _scrollView.scrollEnabled = false;
    
}


- (void)viewWillAppear:(BOOL)animated {
    [iConsole info:@"%s",__FUNCTION__];
    [super viewWillAppear:animated];
    if (isUserInterfaceIdiomPhone){
        _scrollView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT);
        [self showCurrentCardInScrollView:NO];
    } else {
        _scrollView.frame = CGRectMake(0, 0, IPAD_UI_DETAIL_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
        
        if ([_currentPack cards].count !=0) {
            //Load card view when not:1. downloading;2. not every time
            __weak __typeof(&*self)weakSelf = self;
            
            BOOL isExamplePackDownloadedSuccessful = [[NSUserDefaults standardUserDefaults] boolForKey:@"isExamplePackDownloadedSuccessful"];
            if (isExamplePackDownloadedSuccessful == TRUE) {
                static dispatch_once_t oncetoken;
                dispatch_once(&oncetoken, ^{
                    [weakSelf showCurrentCardInScrollView:NO];
                });
            }
        }
    }
    

    //iOS7 special, since UIImagePickerController will display status bar forcely.
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}


- (void) viewDidAppear:(BOOL)animated {
    [iConsole info:@"%s",__FUNCTION__];
    [super viewDidAppear:animated];
    
    static dispatch_once_t onceToken;
    __weak __typeof(&*self)weakSelf = self;
    dispatch_once(&onceToken, ^{
        
        if ([UIApplication sharedApplication].statusBarOrientation==UIDeviceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation ==UIDeviceOrientationLandscapeRight) {
            //show pack info rather than first card
            if (isUserInterfaceIdiomPhone == FALSE) {
                [weakSelf showPackInfoView];
            }
        }
        
    });
    
    
    if (isUserInterfaceIdiomPhone == FALSE) {
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed] == FALSE) {
            [[TipHelper defaultHelper] showTipForRightNaviBarItemHelpInView:self.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 200, 0, 0, 0)];
        }
    }
    
    
    

}


#pragma mark -
#pragma mark - Layout 

- (void) showCurrentCardInScrollView:(BOOL) shouldResetSegment {
    [iConsole info:@"%s",__FUNCTION__];
    if (isUserInterfaceIdiomPhone) {
        [self layoutScrollObjectsForiPhone];
        [_scrollView setContentOffset:CGPointMake(_indexCard*(IPHONE_UI_WIDTH),0) animated:NO];
    } else {
        [self layoutScrollObjectsForiPad];
        [_scrollView setContentOffset:CGPointMake(_indexCard*(IPAD_UI_DETAIL_WIDTH),0) animated:NO];
    }
    
    UILabel *label;
    
    if (isUserInterfaceIdiomPhone) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = [UIFont boldSystemFontOfSize:16.0];
        label.textAlignment = NSTextAlignmentCenter;
        [label sizeToFit];
    }else {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 550, 44)];
        label.font = [UIFont boldSystemFontOfSize:20.0];
        label.textAlignment = NSTextAlignmentLeft;
    }
    label.backgroundColor = [UIColor clearColor];
    label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    
    label.textColor = [UIColor whiteColor]; // change this color
    label.text = _currentPack.packName;
    [self.navigationItem setTitleView:label];
    
    if ((shouldResetSegment == YES) && (_currentCardView.segmentedControl.selectedSegmentIndex == 1)) {
        _currentCardView.segmentedControl.selectedSegmentIndex = 0;
        [_currentCardView segmentedControlQAClicked:nil];
    }
    
    _scrollView.userInteractionEnabled = YES; //在特殊情况下scrollviewdidenddecelerating（这里会重置_scrollView.userInteractionEnabled = YES）没有被调用，导致界面完全失去响应，所以这里需要加一个backup
    

}

- (void)layoutScrollObjectsForiPad
{
    [iConsole info:@"%s",__FUNCTION__];
    CGRect rect;
    
    for (FlashCard *cardView in [_scrollView subviews]) {
        [cardView removeFromSuperview];
    }
    
    if ([_currentPack cards].count == 0) {
        return;
    }
    
    //1. Content size
    [_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPAD_UI_DETAIL_WIDTH), IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT)];
    
    //2. Set current
    _currentCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    _currentCardView.currentCard = _currentCard;
    _currentCardView.currentPack = _currentPack;
    rect = _currentCardView.frame;
    CGFloat curXLoc = (IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2;
    curXLoc += IPAD_UI_DETAIL_WIDTH *_indexCard;
    rect.origin.x = curXLoc;
    _currentCardView.frame = rect;
    [_scrollView addSubview:_currentCardView];

    [_currentCardView refreshAll:false withIndexPlaying:_indexCard];
    
    //3. Set previous
    _previousCardView.tag = PREVIOUS_FLASHCARDVIEW_TAG;
    if (_indexCard == 0) {
        //_previousCardView = nil;
    } else {
        _previousCardView.currentCard = [_currentPack cards][_indexCard-1];
        _previousCardView.currentPack = _currentPack;
        rect.origin.x = curXLoc -IPAD_UI_DETAIL_WIDTH;
        _previousCardView.frame = rect;
        [_scrollView addSubview:_previousCardView]; 
        [_previousCardView refreshAll:false withIndexPlaying:_indexCard-1];
    }
    
    //5. Set next
    _nextCardView.tag = NEXT_FLASHCARDVIEW_TAG;
    if (([[_currentPack cards] count]-1) == _indexCard) {
        //_nextCardView = nil;
    } else {
        _nextCardView.currentCard = [_currentPack cards][_indexCard+1];
        _nextCardView.currentPack = _currentPack;
        rect.origin.x = curXLoc +IPAD_UI_DETAIL_WIDTH;
        _nextCardView.frame = rect;
        [_scrollView addSubview:_nextCardView]; 
        
        [_nextCardView refreshAll:false withIndexPlaying:_indexCard+1];
    }

}

- (void)layoutScrollObjectsForiPhone
{
    [iConsole info:@"%s",__FUNCTION__];
    CGRect rect;
    
    if ([_currentPack cards].count == 0) {
        return;
    }
    
    for (FlashCard *card in [_scrollView subviews]) {
        [card removeFromSuperview];
    }
    
    //1. Content size
    [_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPHONE_UI_WIDTH), _scrollView.frame.size.height)];
    
    //2. Set current
    _currentCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    _currentCardView.currentCard = _currentCard;
    _currentCardView.currentPack = _currentPack;
    rect = _currentCardView.frame;
    CGFloat curXLoc = (IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2;
    curXLoc += IPHONE_UI_WIDTH *_indexCard;
    rect.origin.x = curXLoc;
    _currentCardView.frame = rect;
    if (_currentCardView.superview == nil) {
        [_scrollView addSubview:_currentCardView];    
    }
    
    [_currentCardView refreshAll:false withIndexPlaying:_indexCard];

    
    //3. Set previous
    _previousCardView.tag = PREVIOUS_FLASHCARDVIEW_TAG;
    if (_indexCard == 0) {
    } else {
        _previousCardView.currentCard = [_currentPack cards][_indexCard-1];
        _previousCardView.currentPack = _currentPack;
        rect.origin.x = curXLoc -IPHONE_UI_WIDTH;
        _previousCardView.frame = rect;
        if (_previousCardView.superview == nil) {
            [_scrollView addSubview:_previousCardView];    
        }
        [_previousCardView refreshAll:false withIndexPlaying:_indexCard-1];
    }
    
    //5. Set next
    _nextCardView.tag = NEXT_FLASHCARDVIEW_TAG;
    if (([[_currentPack cards] count]-1) == _indexCard) {
    } else {
        _nextCardView.currentCard = [_currentPack cards][_indexCard+1];
        _nextCardView.currentPack = _currentPack;
        rect.origin.x = curXLoc +IPHONE_UI_WIDTH;
        _nextCardView.frame = rect;
        if (_nextCardView.superview == nil) {
            [_scrollView addSubview:_nextCardView];
        }
        [_nextCardView refreshAll:false withIndexPlaying:_indexCard+1];
    }

}

#pragma mark -
#pragma mark UIBarButtonItem action (only for iPad)

- (void)shareButtonClicked:(id) sender {
    [iConsole info:@"%s",__FUNCTION__];
    
    [self dismissKeyboardGlobally];
    
    if (!isUserInterfaceIdiomPhone) {
        [_settingPopoverController dismissPopoverAnimated:YES];
        [_helpPopoverController dismissPopoverAnimated:YES];
    }
    
    
    PopoverView *shareSelectPopupPopoverView = [PopoverView showPopoverAtPoint:CGPointMake(CGRectGetMidX(((UIButton *)sender).frame), CGRectGetMaxY(((UIButton *)sender).frame))
                                                                        inView:self.navigationController.view
                                                                     withTitle:NSLocalizedString(@"Label_Please_Select",@"")
                                                               withStringArray:[NSArray arrayWithObjects:NSLocalizedString(@"Optional_Install_From_The_Code",@""), NSLocalizedString(@"Optional_Share_The_Pack",@""), nil]
                                                                      delegate:self];
    shareSelectPopupPopoverView.tag = popover_enum_share;
    
    
    
}

// on iPad, Help button only  exists on detail
- (void)helpButtonClicked:(id) sender
{
    [self dismissKeyboardGlobally];
    
    BOOL isNotAllowShowTooltip_Master = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Master_Not_Allow];
    BOOL isNotAllowShowTooltip_Detail = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Detail_Not_Allow];
    BOOL isNotAllowShowTooltip_FlashCard = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_FlashCard_Not_Allow];
    
    
    if ((isNotAllowShowTooltip_Master || isNotAllowShowTooltip_FlashCard || isNotAllowShowTooltip_Detail)
        || [[TipHelper defaultHelper] isAllInvisible]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO  forKey:K_Tooltip_FlashCard_Not_Allow];
        [defaults setBool:NO  forKey:K_Tooltip_Master_Not_Allow];
        [defaults setBool:NO  forKey:K_Tooltip_Detail_Not_Allow];
        [defaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_TOOLTIPS_NOTIFICATION object:nil userInfo:nil];
        if (isUserInterfaceIdiomPhone == false) {
            [self showTooltips];
        }
        
        
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES  forKey:K_Tooltip_FlashCard_Not_Allow];
        [defaults setBool:YES  forKey:K_Tooltip_Master_Not_Allow];
        [defaults setBool:YES  forKey:K_Tooltip_Detail_Not_Allow];
        [defaults synchronize];
        
        [[TipHelper defaultHelper] hideEverything];
    }
}


-(void) showTooltips {
    [[TipHelper defaultHelper] showTipForRightNaviBarItemPlayInView:self.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 45, 0, 0, 0)];
    [[TipHelper defaultHelper] showTipForRightNaviBarItemShareInView:self.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 95, 0, 0, 0)];
    [[TipHelper defaultHelper] showTipForRightNaviBarItemSettingInView:self.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 145, 0, 0, 0)];
    [[TipHelper defaultHelper] showTipForRightNaviBarItemHelpInView:self.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 200, 0, 0, 0)];
    [[TipHelper defaultHelper] showTipForRightNaviBarItemPaletteInView:self.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 250, 0, 0, 0)];
    
}


- (void) selectCardBackgroundTemplate:(id) sender {
    [iConsole info:@"%s",__FUNCTION__];
    if ([Common isOwner:_currentPack] == FALSE) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
        return;
        
    }
    
    
    PopoverView *templateBackgroundSelectPopoverView = [PopoverView showPopoverAtPoint:CGPointMake(CGRectGetMidX(((UIButton *)sender).frame), CGRectGetMaxY(((UIButton *)sender).frame))
                                                                        inView:self.navigationController.view
                                                                     withTitle:NSLocalizedString(@"Label_Color_Select",@"")
                                                               withStringArray:[NSArray arrayWithObjects:NSLocalizedString(@"Optional_Blue",@""), NSLocalizedString(@"Optional_Coffee",@""),NSLocalizedString(@"Optional_Gray",@""),NSLocalizedString(@"Optional_Purple",@""),NSLocalizedString(@"Optional_Red",@""), nil]
                                                                      delegate:self];
    templateBackgroundSelectPopoverView.tag = popover_enum_template_select;
}

- (void)moreButtonClicked:(id) sender
{
    [iConsole info:@"%s",__FUNCTION__];
    
    [self dismissKeyboardGlobally];
    
    if (!isUserInterfaceIdiomPhone) {
        [_helpPopoverController dismissPopoverAnimated:YES];
    }
    
    MoreInfoTableViewController *moreInfoViewController = [[MoreInfoTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:moreInfoViewController];
    if (_settingPopoverController == nil) {
        _settingPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
        _settingPopoverController.delegate = self;
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            _settingPopoverController.backgroundColor = [UIColor colorWithRed:127.0/255 green:127.0/255 blue:127.0/255 alpha:1];
        }
    }
    
    _settingPopoverController.popoverContentSize = CGSizeMake(320, 480);
    CGRect rect = CGRectOffset(_settingButton.customView.frame, 0, -49);
    [_settingPopoverController presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

- (void)playButtonClicked:(id) sender
{
    [iConsole info:@"%s",__FUNCTION__];
    
    [self dismissKeyboardGlobally];
    
    if (!isUserInterfaceIdiomPhone) {
        [_settingPopoverController dismissPopoverAnimated:YES];
        [_helpPopoverController dismissPopoverAnimated:YES];
    }
    
    PlayViewControllerV2 *playViewController = [[PlayViewControllerV2 alloc] init];
    
    int playIndex = [Common getPlayOption];
    switch (playIndex) {
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
    
    if ((self.currentCard == nil) || (self.currentPack == nil)) {
        [Common alertViewCommon:@"Current card or pack is nil"];
        return;
    }
    
    if (!isUserInterfaceIdiomPhone) {
        [_settingPopoverController dismissPopoverAnimated:YES];
        [_helpPopoverController dismissPopoverAnimated:YES];
    }
    
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow.rootViewController presentViewController:playViewController animated:YES completion:nil];
    
}

- (void)backButtonClicked:(id) sender
{
    [iConsole info:@"%s",__FUNCTION__];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Split view

- (void)splitViewController:(MGSplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    [iConsole info:@"%s",__FUNCTION__];
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(MGSplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    [iConsole info:@"%s",__FUNCTION__];
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}


#pragma mark -
#pragma mark Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    [iConsole info:@"%s",__FUNCTION__];
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [iConsole info:@"%s",__FUNCTION__];
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    if ((page == _indexCard +1) || (page == _indexCard -1)) {
        
        _scrollView.userInteractionEnabled = FALSE; // avoid blank pages.
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //Step1: calculate page(index)
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if ((page == _indexCard +1) || (page == _indexCard -1)) {
        [iConsole info:@"%s: _indexCard = %d",__FUNCTION__,_indexCard];
        _indexCard = page;
        _currentCard = [_currentPack cards][page];
        [self showCurrentCardInScrollView:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_DETAIL_SCROLL_NOTFICATION object:[NSString stringWithFormat:@"%d",page]];
    }
    _scrollView.userInteractionEnabled = YES;
    
}


-(void)shareLinkCreatedNotification:(NSNotification *)notification {
    
    NSString *shareLink = [notification object];
    _currentPack.shareLink = shareLink;
    
    [self updateRightPackInfoView];
}

-(void)editPackFinishedNotification:(NSNotification *)notification{
    [iConsole info:@"%s",__FUNCTION__];
    self.currentPack = (Pack *)[notification object];
    
    if (isUserInterfaceIdiomPhone) {
        //iPhone中并不存在如下的逻辑
        return;
    }
    
    [self updateRightPackInfoView];
    
    
    UILabel *titleLabel = (UILabel *)(self.navigationItem.titleView);
    titleLabel.text = self.currentPack.packName;
}

-(void)newPackAddedNotification:(NSNotification *)notification{
    [iConsole info:@"%s",__FUNCTION__];
    self.currentPack = (Pack *)[notification object];
    
    if (isUserInterfaceIdiomPhone) {
        //iPhone中并不存在如下的逻辑
        return;
    }
    
    UILabel *titleLabel = (UILabel *)(self.navigationItem.titleView);
    titleLabel.text = self.currentPack.packName;
    
    [self updateRightPackInfoView];
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Detail_Not_Allow];
    BOOL val2 = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed];
    if (val == FALSE && val2) {
        [self showTooltips];
    }
    
    
}

- (void) updateRightPackInfoView {
    for (UIView *myView in [_rightPackView subviews]) {
        if ([myView isKindOfClass:[UILabel class]]) {
            
            if (myView.tag == 0) {
                
                [(UILabel *)myView setText:[NSString stringWithFormat:@"%@: %d",NSLocalizedString(@"Title_Total_Number_Card",@""),[_currentPack cards].count]];
                
            } else if (myView.tag == 1) {
                
                if (self.currentPack.shareLink.length >0 && [Common isOwner:_currentPack]) {
                    myView.hidden = NO;
                    ((UILabel *)myView).text = [NSString stringWithFormat:@"%@:  %@",NSLocalizedString(@"Title_Share_Code",@""),[self.currentPack.shareLink lastPathComponent]];
                } else {
                    myView.hidden = YES;
                }
                
                
            }
            
        } else if ([myView isKindOfClass:[UIImageView class]]) {
            
            if ([Common isPlaceholderFilePathOrDirectory:_currentPack.coverImageURL]) {
                ((UIImageView *)myView).image = [UIImage imageNamed:@"default_pack_cover_image"];
            } else {
                NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentPack.coverImageURL lastPathComponent]];
                ((UIImageView *)myView).image = [UIImage imageWithContentsOfFile:path];
            }
            
        }
    }
}


- (void) selectedPackNotification:(NSNotification *) notification {
    [iConsole info:@"%s",__FUNCTION__];
    Pack *pack = (Pack *)[notification object];
    NSMutableArray *allPacks = [[User defaultUser] packs];
    for (Pack *itempPack in allPacks) {
        if (itempPack.packID == pack.packID) {
            self.currentPack = itempPack;
            break;
        }
    }
    
    UILabel *titleLable = (UILabel *)self.navigationItem.titleView;
    [titleLable setText:_currentPack.packName];
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Detail_Not_Allow];
    BOOL val2 = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed];
    if (val == FALSE && val2) {
        [self showTooltips];
    }
}

- (void) hideNavigationBarNotification:(NSNotification *) notification {
    [iConsole info:@"%s",__FUNCTION__];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void) showNavigationBarNotification:(NSNotification *) notification {
    [iConsole info:@"%s",__FUNCTION__];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void) applicationWillResignActiveNotification :(NSNotification *) notification{
    [iConsole info:@"%s",__FUNCTION__];
    [self.view endEditing:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark - PopoverViewDelegate Methods

- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
    [iConsole info:@"%s",__FUNCTION__];
    dispatch_async(dispatch_get_main_queue(), ^{
       [popoverView dismiss];
    });

    
    if (popoverView.tag == popover_enum_share) {
        switch (index) {
            case 0: {
                __weak __typeof(&*self)weakSelf = self;
                UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:NSLocalizedString(@"DIALOG_INPUT_DOWNLOAD_CODE",@"") message:nil];
                [alertView textFieldAtIndex:0].text = @"";
                [alertView textFieldAtIndex:0].placeholder = @"p8c5cv1";
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
                
                
                break;
            }
            case 1: {
                
                if (_currentPack.isAllowShare) {
                    
#ifdef FFC_WITHOUT_SUBSCRIPTION
                    
                    //Dropbox only
                    if (![[DBSession sharedSession] isLinked]) {
                        [DBSession sharedSession].delegate = self;
                        //会通过application:(UIApplication *)application openURL 到达MasterViewController的dropboxLinkedNotification
                        //不需要在本类中设置dropboxLinkedNotification
                        [[DBSession sharedSession] linkFromController:self];
                        APP_DELEGATE.isAllowToShareAfterDropboxLogIn = YES;
                    } else {
                        _dropboxShareHelper = [[DropboxSharekitHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
                        [_dropboxShareHelper shareAction];
                    }
#else
                    
                    if ([DBSession sharedSession].isLinked) {  //这个必须放在else if ([PFUser currentUser])
                        
                        _dropboxShareHelper = [[DropboxSharekitHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
                        [_dropboxShareHelper shareAction];
                        
                        
                    } else if ([PFUser currentUser]) {

                        [iConsole info:@"%s: [PFUser currentUser].username = %@",__FUNCTION__,[PFUser currentUser].username];
                        
                        _amazonShareHelper = [[AWSS3UploadHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
                        [_amazonShareHelper shareAction];
                        
                        
                    }  else {
                        //则表明用AWS服务，且还没有创建user
                        PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
                        logInController.fields = (PFLogInFieldsUsernameAndPassword
                                                  | PFLogInFieldsLogInButton
                                                  | PFLogInFieldsPasswordForgotten
                                                  | PFLogInFieldsFacebook
                                                  | PFLogInFieldsTwitter
                                                  | PFLogInFieldsSignUpButton
                                                  | PFLogInFieldsDismissButton);
                        
                        logInController.signUpController.fields = (PFSignUpFieldsUsernameAndPassword
                                                                   | PFSignUpFieldsEmail
                                                                   | PFSignUpFieldsAdditional
                                                                   | PFSignUpFieldsDismissButton
                                                                   | PFSignUpFieldsSignUpButton);
                        logInController.signUpController.delegate = APP_DELEGATE.masterViewController;
                        
                        logInController.delegate = APP_DELEGATE.masterViewController;
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:logInController animated:YES completion:nil];
                        
                        APP_DELEGATE.isAllowToShowPackList = NO;
                    }
#endif
                    
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
        
        if (![Common isOwner:_currentPack]) {
            [Common alertViewCommon:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"")];
            return;
        }
        
        
        //Step3: Get the selected info
        NSString *templateBackgroundName;
        switch (index) {
            case template_color_enum_coffee:
                templateBackgroundName = @"card_background_coffee.png";
                break;
            case template_color_enum_blue:
                templateBackgroundName = @"card_background_blue.png";
                break;
            case template_color_enum_red:
                templateBackgroundName = @"card_background_red.png";
                break;
            case template_color_enum_gray:
                templateBackgroundName = @"card_background_gray.png";
                break;
            case template_color_enum_purple:
                templateBackgroundName = @"card_background_purple.png";
                break;
            default:
                break;
        }
        
        //Show progress indicator and invoke other long-time post-execution
        if (!_HUD)
            _HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
        
        [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
        [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
        
        _HUD.mode = MBProgressHUDModeIndeterminate;
        _HUD.labelText = NSLocalizedString(@"DIALOG_APPLY_TO_ALL_CARD",@"");
        [_HUD show:YES];
        [self performSelector:@selector(execTemplateBackgroundChangeTask:) withObject:templateBackgroundName afterDelay:0.01];
    } else if (popoverView.tag == popover_enum_play) {
        
        
    }
    
}



- (void) execTemplateBackgroundChangeTask:(NSString *)templateBackgroundName {
    [iConsole info:@"%s",__FUNCTION__];
    //Step4: Change all cards card template background, screenshot them, and save them
    [_currentCardView reSceenshotAll:kReasonTemplateBackgroundChangeEnum withStringVal:templateBackgroundName];
    [_currentCardView refreshAll];
    
    //Step5: tell the master view to update cell
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    
    [_HUD removeFromSuperview];
    _HUD = nil;
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
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _scrollView.delegate = nil;
    _helpPopoverController.delegate = nil;
    _settingPopoverController.delegate = nil;
}

#pragma mark -
#pragma mark - UIAlertViewDelegate


- (void) downloadPackWithCode:(NSString *)downloadCode {
    
    NSString *urlStr = [NSString stringWithFormat:@"http://tinyurl.com/%@",downloadCode];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [NSURLConnection connectionWithRequest:request delegate:self];
    //NSURLConnectionDataDelegate will take care following actions
}


#pragma mark – UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    //we ignore  _masterPopoverController by not setting delegate = self
    self.settingPopoverController = nil;
    self.helpPopoverController = nil;
}



/**
 *  Only applicable for iPad
 *  call this when:
 *  1. select any card in the left card list view
 */
- (void) hidePackInfoView {
    if (_rightPackView) {
        [_rightPackView removeFromSuperview];
        _rightPackView = nil;
        _scrollView.hidden = NO;
    }
    
}


/**
 *  Only applicable for iPad
 *  call this when:
 *  1. start up app
 *  2. finishing creating a new pack
 *  3. selecting an existing pack
 */
- (void) showPackInfoView {
    [iConsole info:@"%s",__FUNCTION__];
    if (isUserInterfaceIdiomPhone == FALSE) {
        
        [_rightPackView removeFromSuperview];
        _rightPackView = nil;
        
        _rightPackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
        _rightPackView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        _rightPackView.backgroundColor = [UIColor clearColor];
        
        _scrollView.hidden = YES;
        
        
        UIImageView *rightPackImageView = [[UIImageView alloc] init];
        rightPackImageView.frame = CGRectMake((IPAD_UI_DETAIL_WIDTH - 300)/2, 130, 400, 400);
        rightPackImageView.autoresizingMask = UIViewAutoresizingNone;
        rightPackImageView.layer.opacity = 0.85;
//        rightPackImageView.layer.shadowOpacity= 0.3;
//        rightPackImageView.layer.shadowColor = [UIColor greenColor].CGColor;
////        rightPackImageView.layer.shadowOffset = CGSizeMake(0.f, 12.0f);
//        rightPackImageView.layer.shadowRadius = 20;
        rightPackImageView.layer.masksToBounds = YES;
        rightPackImageView.backgroundColor = [UIColor clearColor];
        
        [_rightPackView addSubview:rightPackImageView];
        
        if ([Common isPlaceholderFilePathOrDirectory:_currentPack.coverImageURL]) {
            rightPackImageView.image = [UIImage imageNamed:@"default_pack_cover_image_transparent"];
        } else {
            NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentPack.coverImageURL lastPathComponent]];
            rightPackImageView.image = [UIImage imageWithContentsOfFile:path];
        }
        
        rightPackImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        UILabel *rightPackCardNo = [[UILabel alloc] init];
        rightPackCardNo.textColor = [UIColor whiteColor];
        rightPackCardNo.autoresizingMask =  UIViewAutoresizingNone;
        rightPackCardNo.backgroundColor = [UIColor clearColor];
        rightPackCardNo.textAlignment = UITextAlignmentCenter;
        rightPackCardNo.font = [UIFont systemFontOfSize: 24];
        rightPackCardNo.tag = 0;
        CGRect rect = rightPackImageView. frame;
        rect.origin.y = rect.origin.y +rect.size.height+16;
        rect.size.height = 25;
        rightPackCardNo.frame = rect;
        [_rightPackView addSubview:rightPackCardNo];
        
        UILabel *shareCodeLabel = [[UILabel alloc] init];
        shareCodeLabel.textColor = [UIColor whiteColor];
        shareCodeLabel.autoresizingMask =  UIViewAutoresizingNone;
        shareCodeLabel.backgroundColor = [UIColor clearColor];
        shareCodeLabel.textAlignment = UITextAlignmentCenter;
        shareCodeLabel.font = [UIFont systemFontOfSize: 16];
        shareCodeLabel.tag = 1;
        rect = rightPackCardNo.frame;
        rect.origin.y = rect.origin.y +rect.size.height+16;
        rect.size.height = 25;
        shareCodeLabel.frame = rect;
        [_rightPackView addSubview:shareCodeLabel];
        
        if ((rightPackImageView.image != nil) && (_currentPack != nil)) {
            [rightPackCardNo setText:[NSString stringWithFormat:@"%@: %d",NSLocalizedString(@"Title_Total_Number_Card",@""),[_currentPack cards].count]];
            
            if ((self.currentPack.shareLink.length >0) && [Common isOwner:_currentPack]) {
                shareCodeLabel.hidden = NO;
                shareCodeLabel.text = [NSString stringWithFormat:@"%@:  %@",NSLocalizedString(@"Title_Share_Code",@""),[self.currentPack.shareLink lastPathComponent]];
            } else {
                shareCodeLabel.hidden = YES;
            }
        }
        
        
        [self.view addSubview:_rightPackView];
        
        [self.view bringSubviewToFront:_rightPackView];
        
        if (APP_DELEGATE.isDownloadingPack) {
            _rightPackView.hidden = YES;
        } else {
            _rightPackView.hidden = NO;
        }
        
        
        UILabel *titleLable = (UILabel *)self.navigationItem.titleView;
        [titleLable setText:_currentPack.packName];
        
    }
}


- (void) dismissKeyboardGlobally {
    
    [self resignTextSubviewsFrom:self.view];
}

- (void) resignTextSubviewsFrom:(UIView *)view {
    
    
    NSArray *subviews = [view subviews];
    
    if ([subviews count] == 0) return;
    
    for (UIView *subview in subviews) {
        
        if (([subview isKindOfClass:[UITextView class]] || [subview isKindOfClass:[UITextField class]]) && (subview.isFirstResponder)) {
            [subview resignFirstResponder];
        }
        
        [self resignTextSubviewsFrom:subview];
    }
}

- (void) switchToQuestionCard {
    
    if (_currentCardView.segmentedControl.selectedSegmentIndex == 0) {
        //already on question card
        return;
    }
    
    _currentCardView.segmentedControl.selectedSegmentIndex = 0;
    
    [_currentCardView segmentedControlQAClicked:nil];
    
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
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOAD_PACK_NOTIFICATION object:[unshortedURL absoluteString]];
                    
                    
                    
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


#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
    [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
}

@end
