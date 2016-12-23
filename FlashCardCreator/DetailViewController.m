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
#import "GoogleDriveShareKitHelper.h"

#import "UIImage+Scale.h"
#import "FileOperationHelper.h"
#import "OpenUDID.h"
#import "AppDelegate.h"

#import "UIButton+Extensions.h"

#import <BlocksKit/UIAlertView+BlocksKit.h>

#import <SDWebImage/UIImageView+WebCache.h>

#import "TipHelper.h"
#import "MutipleTargetHelper.h"

#import "PurchaseViewController.h"
#import "PackInfoView.h"

#import "GoogleDriveSession.h"

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


@interface DetailViewController () <UIAlertViewDelegate,NSURLConnectionDataDelegate, PackInfoViewDelegate>{
    AWSS3UploadHelper         *_amazonShareHelper;
    DropboxSharekitHelper     *_dropboxShareHelper;
    GoogleDriveShareKitHelper *_googleDriveShareHelper;
    
    UIImageView              *_adImageView;
    
    
    /**
     *  General pack info (like pack image and no of cards) on the right.
     *  Only applicable for iPad (on iPad, we have the similar logic on the master view)
     */
    PackInfoView        *_packInfoView;
    
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCancelledNotification:) name:PARSE_DOWNLOADED_PACK_CANCEL_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iapPurchaseSuccessNotification:) name:IAP_PURCHASE_SUCCESS_NOTIFICATION object:nil];
        
        if (isUserInterfaceIdiomPhone == false) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareLinkCreatedNotification:) name:SHARE_LINK_CREATED_NOTIFICATION object:nil];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(soundRecordingSavedNotification:) name:SOUND_RECORDING_SAVED_NOTIFICATION object:nil];
        
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
    
    [self setupNaviBarButtonItems];
    
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

- (void) setupNaviBarButtonItems {
    
    UIButton *templateBackgroundSelectButton;
    if ([MutipleTargetHelper isFullVersion]) {
        templateBackgroundSelectButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"template_background_change_button.png"] target:self action:@selector(selectCardBackgroundTemplate:)];
    } else {
        templateBackgroundSelectButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"template_background_change_button_dimmed.png"] target:self action:@selector(selectCardBackgroundTemplate:)];
    }
    _templateBackgroundSelectBarButton = [[UIBarButtonItem alloc]
                                          initWithCustomView:templateBackgroundSelectButton];;
    
    //we don't setting button on iPhone
    _settingButton = [[UIBarButtonItem alloc]
                      initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"setting_button.png"] target:self action:@selector(moreButtonClicked:)]];
    UIButton *playButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"play_button.png"] target:self action:@selector(playButtonClicked)];
    UIBarButtonItem *playBarButton = [[UIBarButtonItem alloc]
                                      initWithCustomView:playButton];
    
    UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc]
                                       initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"share_button.png"] target:self action:@selector(shareButtonClicked:)]];
    
    UIButton *helpButton;
    if ([MutipleTargetHelper isFullVersion]) {
        helpButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"helping_button.png"] target:self action:@selector(helpButtonClicked:)];
    } else {
        helpButton = [FCCBarButton buttonWithImage:[UIImage imageNamed:@"helping_button_dimmed.png"] target:self action:@selector(helpButtonClicked:)];
    }
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
}

- (void) removeAdView {
    if (_adImageView != nil) {
        [_adImageView removeFromSuperview];
        _adImageView = nil;
    }
}

- (void) showAdView {
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
    
    if (_adImageView != nil) {
        [_adImageView removeFromSuperview];
        _adImageView = nil;
    }
    
    if ([MutipleTargetHelper isFullVersion] || [MutipleTargetHelper isNoAdVersion]) {
        return;
    }
    
    _adImageView = [[UIImageView alloc] init];
    [_adImageView setContentMode:UIViewContentModeScaleAspectFit];
    _adImageView.autoresizingMask = UIViewAutoresizingNone;
    _adImageView.clipsToBounds = YES;
    _adImageView.frame = CGRectMake(25, 15, CGRectGetWidth(self.view.frame) - 50, 70);
    
    [_adImageView sd_setImageWithURL:[NSURL URLWithString:@"http://www.flipflashcards.com/promo/upgrade.png"] placeholderImage:[UIImage imageNamed:@"ad_banner"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error == nil) {
        }
            }];
    
//    [_adImageView setImage:[UIImage imageNamed:@"ad_banner"]];
    
    _adImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:_adImageView];
    
    
    _adImageView.userInteractionEnabled = true;
    UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPurchaseView)];
    oneTap.numberOfTapsRequired = 1;
    [_adImageView addGestureRecognizer:oneTap];
    
    
    
}



- (void)viewWillAppear:(BOOL)animated {
    [iConsole info:@"%s",__FUNCTION__];
    [super viewWillAppear:animated];
    
    {
        static dispatch_once_t onceToken;
        __weak __typeof(&*self)weakSelf = self;
        dispatch_once(&onceToken, ^{
            
            if ([UIApplication sharedApplication].statusBarOrientation==UIDeviceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation ==UIDeviceOrientationLandscapeRight) {
                //show pack info rather than first card
                if (isUserInterfaceIdiomPhone == FALSE) {
                    
                    [weakSelf setupPackInfoView];
                    
                    if (isUserInterfaceIdiomPhone == FALSE) {
                        
                        if ([[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed] == FALSE && APP_DELEGATE.isDownloadingPack == FALSE) {
                            [[TipHelper defaultHelper] showTipForRightNaviBarItemHelpInView:weakSelf.view fromFrame:CGRectMake(CGRectGetWidth(weakSelf.view.frame)- 200, 0, 0, 0)];
                        }
                    }
                    
                    if ([MutipleTargetHelper isFullVersion] == false && [MutipleTargetHelper isNoAdVersion] == false && isUserInterfaceIdiomPhone == false && APP_DELEGATE.isDownloadingPack == false) {
                        [weakSelf showAdView];
                    }
                }
            }
            
        });
        
        
    }

    
    {
        if (isUserInterfaceIdiomPhone){
            _scrollView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT);
            [self showCurrentCardInScrollView:NO];
        } else {
            _scrollView.frame = CGRectMake(0, 0, IPAD_UI_DETAIL_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
            
            if ([_currentPack cards].count !=0 && [self isPackInfoViewVisible] == false) {
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
        
        if ([MutipleTargetHelper isFullVersion] == false && [MutipleTargetHelper isNoAdVersion] == false && isUserInterfaceIdiomPhone == false && APP_DELEGATE.isDownloadingPack == false) {
            [self showAdView];
        }
        
        
        //iOS7 special, since UIImagePickerController will display status bar forcely.
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    
    {
        //this is quite tricky.
        //The scene is when you back from play, this text alignement will be top, rather than expected center if you have already vertically center.
        //Seem a bug from Apple, so this is a temp solution but works.
        [_currentCardView updateQuestionAnswerAllTextViewVeriticalAlignment];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_currentCardView pauseEmbeddedVideoAndGif];
}

- (void) viewDidAppear:(BOOL)animated {
    [iConsole info:@"%s",__FUNCTION__];
    [super viewDidAppear:animated];
    
    if ([self isPackInfoViewVisible] == false) {
        [_currentCardView pauseEmbeddedVideoAndGif];
    }
    
}

- (void) showPurchaseView {
    [MutipleTargetHelper showPurchaseView];
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
        [cardView cleanMultimediaViews]; ;
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
        [card cleanMultimediaViews];
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
    
    
    PopoverView *shareSelectPopupPopoverView;
    
    if ([MutipleTargetHelper isFullVersion]) {
        shareSelectPopupPopoverView = [PopoverView showPopoverAtPoint:CGPointMake(CGRectGetMidX(((UIButton *)sender).frame), CGRectGetMaxY(((UIButton *)sender).frame))
                                                               inView:self.navigationController.view
                                                            withTitle:NSLocalizedString(@"Label_Please_Select",@"")
                                                      withStringArray:[NSArray arrayWithObjects:NSLocalizedString(@"Optional_Install_From_The_Code",@""), NSLocalizedString(@"Optional_Share_The_Pack",@""), nil]
                                                             delegate:self];
    } else {
        
        shareSelectPopupPopoverView = [PopoverView showPopoverAtPoint:CGPointMake(CGRectGetMidX(((UIButton *)sender).frame), CGRectGetMaxY(((UIButton *)sender).frame))
                                                               inView:self.navigationController.view
                                                            withTitle:NSLocalizedString(@"Label_Please_Select",@"")
                                                      withStringArray:[NSArray arrayWithObjects:NSLocalizedString(@"Optional_Install_From_The_Code",@""), nil]
                                                             delegate:self];
    }
    
    
    shareSelectPopupPopoverView.tag = popover_enum_share;
    
    
    
}

// on iPad, Help button only  exists on detail
- (void)helpButtonClicked:(id) sender
{
    
    if ([MutipleTargetHelper isFullVersion] == false) {
        [MutipleTargetHelper showAlertToUpgradeToFullVersion];
        return;
    }
    
    
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
    
    if ([MutipleTargetHelper isFullVersion] == false) {
        [MutipleTargetHelper showAlertToUpgradeToFullVersion];
        return;
    }
    
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
    
    _settingPopoverController.popoverContentSize = CGSizeMake(320, 490);
    CGRect rect = CGRectOffset(_settingButton.customView.frame, 0, -49);
    [_settingPopoverController presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

- (void)playButtonClicked;
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
        case 0: {
            playViewController.oneOffPlayType = One_Off_Play_Type_Manually;
            break;
        }
        case 1: {
            playViewController.oneOffPlayType = One_Off_Play_Type_Auto_Play;
            
            break;
        }
        case 2: {
            playViewController.oneOffPlayType = One_Off_Play_Type_Auto_Play_Loop;
            
            break;
        }
        default:
            break;
    }
    
    playViewController.currentPack = self.currentPack;
    
    if ((self.currentCard == nil) || (self.currentPack == nil)) {
        [Common alertViewCommon:@"There are no packs loaded"];
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


-(void)soundRecordingSavedNotification:(NSNotification *)notification {
    NSDictionary *dict = [notification userInfo];
    
    NSString *question = [dict objectForKey:@"question"];
    NSString *answer = [dict objectForKey:@"answer"];
    
    if (question != nil) {
        _currentCardView.currentCard.question.recordedSoundFullPath = question;
    }
    
    if (answer != nil) {
        _currentCardView.currentCard.answer.recordedSoundFullPath = answer;
    }
}

-(void)shareLinkCreatedNotification:(NSNotification *)notification {
    
    NSString *shareLink = [notification object];
    _currentPack.shareLink = shareLink;
    
    [self showPackInfoViewWithRebuildScrollView:false];
}

- (void) iapPurchaseSuccessNotification:(NSNotification *) notification {
    
    if (isUserInterfaceIdiomPhone == false) {
        [self removeAdView];
    }
    
    [self setupNaviBarButtonItems];
    
}


- (void) downloadCancelledNotification: (NSNotification *) notification {
    
    if (isUserInterfaceIdiomPhone == FALSE) {
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed] == FALSE) {
            [[TipHelper defaultHelper] showTipForRightNaviBarItemHelpInView:self.view fromFrame:CGRectMake(CGRectGetWidth(self.view.frame)- 200, 0, 0, 0)];
        }
    }
    
    if ([MutipleTargetHelper isFullVersion] == false && [MutipleTargetHelper isNoAdVersion] == false && isUserInterfaceIdiomPhone == false && APP_DELEGATE.isDownloadingPack == false) {
        [self showAdView];
    }
}

-(void)editPackFinishedNotification:(NSNotification *)notification{
    [iConsole info:@"%s",__FUNCTION__];
    self.currentPack = (Pack *)[notification object];
    
    if (isUserInterfaceIdiomPhone) {
        //iPhone中并不存在如下的逻辑
        return;
    }
    
    [self showPackInfoViewWithRebuildScrollView:false];
    
    
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
    
    [self showPackInfoViewWithRebuildScrollView:true];
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Detail_Not_Allow];
    BOOL val2 = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed];
    if (val == FALSE && val2) {
        [self showTooltips];
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
    
    [self showPackInfoViewWithRebuildScrollView:false];
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
                
                
                if ([MutipleTargetHelper isFullVersion] == false) {
                    [MutipleTargetHelper showAlertToUpgradeToFullVersion];
                    return;
                }
                
                if (_currentPack.isAllowShare) {
                    
                    if (([DropboxClientsManager authorizedClient] != nil || [DropboxClientsManager authorizedTeamClient] != nil)) {
                        [self shareViaDropbox];
                    } else if ([[GoogleDriveSession sharedSession] isLinked]) {
                        [self shareViaGoogleDrive];
                    } else {
     
                        __weak __typeof(&*self)weakSelf = self;
                        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_STORAGE_SELECTION",@"") message:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"DIALOG_STORAGE_SELECTION_DROPBOX",@""), NSLocalizedString(@"DIALOG_STORAGE_SELECTION_GOOGLE_DRIVE",@""), nil] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                            
                            if (buttonIndex == 0) {
                                //cancel button
                                
                            } else if (buttonIndex == 1) {
                                //dropbox
                                [weakSelf shareViaDropbox];
                                
                            } else if (buttonIndex == 2) {
                                //google drive
                                [weakSelf shareViaGoogleDrive];
                                
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
 *  iPad only
 */
- (void) setupPackInfoView {
    [iConsole info:@"%s",__FUNCTION__];
    if (isUserInterfaceIdiomPhone == FALSE) {
        
        [_packInfoView removeFromSuperview];
        _packInfoView = nil;
        
        _scrollView.hidden = YES;
        
        _packInfoView = [ [PackInfoView alloc ] initWithFrame:CGRectMake(0,0, 400, 550)];
        _packInfoView.center = self.view.center;
        _packInfoView.delegate = self;
        [self.view addSubview:_packInfoView];
        [self.view bringSubviewToFront:_packInfoView];
        
        [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:true];
        
        if (APP_DELEGATE.isDownloadingPack) {
            _packInfoView.hidden = YES;
        } else {
            _packInfoView.hidden = NO;
        }
        
        
        UILabel *titleLable = (UILabel *)self.navigationItem.titleView;
        [titleLable setText:_currentPack.packName];
        
        if (_adImageView != nil) {
            [self.view bringSubviewToFront:_adImageView];
        }
        
    }

}

/**
 *  iPad only
 *  call this when:
 *  1. select any card in the left card list view
 */
- (void) removePackInfoView {
    
    if (isUserInterfaceIdiomPhone) {
        return;
    }
    
    if (_packInfoView) {
        [_packInfoView removeFromSuperview];
        _packInfoView = nil;
        _scrollView.hidden = NO;
    }
    
}

- (BOOL) isPackInfoViewVisible {

    return (_packInfoView != nil) && (_packInfoView.hidden == false);
}


/**
 *  iPad only
 */
- (void) showPackInfoViewWithRebuildScrollView:(BOOL) b {
    
    if (self.currentPack == nil) {
        return;
    }
    
    if (isUserInterfaceIdiomPhone) {
        return;
    }
    
    //in this case, self.currentPack needs to be updated
    NSArray *packs = [[User defaultUser] packs];
    for (Pack *item in packs) {
        if (item.packID == self.currentPack.packID) {
            self.currentPack = item;
            break;
        }
    }
    
    
    _scrollView.hidden = YES;
    
    if (_packInfoView == nil) {
        [self setupPackInfoView];
    } else {
        _packInfoView.hidden = NO;
        [_packInfoView scrollTo:self.currentPack WithRebuildScrollView:b];
    }
    
    [_currentCardView pauseEmbeddedVideoAndGif];
    
    
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


#pragma mark – PackInfoViewDelegate

- (void)packInfoView:(PackInfoView *)packInfoVIew didScrollToPack:(Pack *)pack {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_PACK_SELECTED_NOTIFICATION object:pack];
    
    
}

- (void)playButtonClickedOnPackInfoView{
    
    [self playButtonClicked];
    
}

#pragma mark – Others

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
                                            controller:self
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


//#pragma mark -
//#pragma mark DBSessionDelegate methods
//
//- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
//    [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
//}

@end
