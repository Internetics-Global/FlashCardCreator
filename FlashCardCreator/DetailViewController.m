//
//  DetailViewController.m
//  FlashCardCreator
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
#import "UIImage+Scale.h"
#import "FileOperationHelper.h"
#import "OpenUDID.h"
#import "AppDelegate.h"

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
    popover_enum_template_select = 1
};



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
    
    _templateBackgroundSelectButton = [[UIBarButtonItem alloc]
                                       initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"template_background_change_button.png"] target:self action:@selector(selectCardBackgroundTemplate:)]];;
    
    //we don't setting button on iPhone
    _settingButton = [[UIBarButtonItem alloc]
                                      initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"setting_button.png"] target:self action:@selector(moreButtonClicked:)]];
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc]
                                   initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"play_button.png"] target:self action:@selector(playButtonClicked:)]];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc]
                                    initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"share_button.png"] target:self action:@selector(shareButtonClicked:)]];
    
    _helpButton = [[UIBarButtonItem alloc]
                                   initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"helping_button.png"] target:self action:@selector(helpButtonClicked:)]];
    
    if (isUserInterfaceIdiomPhone) {
        self.navigationItem.rightBarButtonItems =
        @[playButton,_templateBackgroundSelectButton,_helpButton];
    } else {
        self.navigationItem.rightBarButtonItems =
                                @[playButton,shareButton,_settingButton,_helpButton,_templateBackgroundSelectButton];
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

    [_currentCardView refreshAll:[_isResizedArray[_indexCard] boolValue] withIndexPlaying:_indexCard];
    
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
        [_previousCardView refreshAll:[_isResizedArray[_indexCard-1] boolValue] withIndexPlaying:_indexCard-1];
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
        
        [_nextCardView refreshAll:[_isResizedArray[_indexCard+1] boolValue] withIndexPlaying:_indexCard+1];
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
    
    [_currentCardView refreshAll:[_isResizedArray[_indexCard] boolValue] withIndexPlaying:_indexCard];

    
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
        [_previousCardView refreshAll:[_isResizedArray[_indexCard-1] boolValue] withIndexPlaying:_indexCard-1];
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
        [_nextCardView refreshAll:[_isResizedArray[_indexCard+1] boolValue] withIndexPlaying:_indexCard+1];
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
                               withTitle:@"Please select"
                         withStringArray:[NSArray arrayWithObjects:@"Install from the code", @"Share the pack", nil]
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
    
    
    if (isNotAllowShowTooltip_Master || isNotAllowShowTooltip_FlashCard || isNotAllowShowTooltip_Detail) {
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
    if ([_currentCard.creator isEqualToString:[OpenUDID value]] == FALSE) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"You can only edit card that you have created it." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
        
    }
    
    
    PopoverView *templateBackgroundSelectPopoverView = [PopoverView showPopoverAtPoint:CGPointMake(CGRectGetMidX(((UIButton *)sender).frame), CGRectGetMaxY(((UIButton *)sender).frame))
                                                                        inView:self.navigationController.view
                                                                     withTitle:@"Color select"
                                                               withStringArray:[NSArray arrayWithObjects:@"Blue", @"Coffee",@"Gray",@"Purple",@"Red", nil]
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
            _settingPopoverController.backgroundColor = [UIColor colorWithRed:63.0/255 green:63.0/255 blue:63.0/255 alpha:0.3];
        }
    }
    
    _settingPopoverController.popoverContentSize = CGSizeMake(320, 480);
    [_settingPopoverController presentPopoverFromBarButtonItem:_settingButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

- (void)playButtonClicked:(id) sender
{
    [iConsole info:@"%s",__FUNCTION__];
    PlayViewControllerV2 *playViewController = [[PlayViewControllerV2 alloc] init];
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
    [iConsole info:@"%s",__FUNCTION__];
    //Step1: calculate page(index)
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if ((page == _indexCard +1) || (page == _indexCard -1)) {
        _indexCard = page;
        _currentCard = [_currentPack cards][page];
        [self showCurrentCardInScrollView:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_DETAIL_SCROLL_NOTFICATION object:[NSString stringWithFormat:@"%d",page]];
    }
    _scrollView.userInteractionEnabled = YES;
    
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
    if (val == FALSE) {
        [self showTooltips];
    }
    
    
}

- (void) updateRightPackInfoView {
    for (UIView *myView in [_rightPackView subviews]) {
        if ([myView isKindOfClass:[UILabel class]]) {
            
            if (myView.tag == 0) {
                
                [(UILabel *)myView setText:[NSString stringWithFormat:@"%@: %d",NSLocalizedString(@"Title_Total_Number_Card",@""),[_currentPack cards].count]];
                
            } else if (myView.tag == 1) {
                
                NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
                NSString *shareCode = [rawDict objectForKey:@"redirected_url"];
                if (shareCode.length >0) {
                    myView.hidden = NO;
                    ((UILabel *)myView).text = [NSString stringWithFormat:@"Share code:  %@",[shareCode lastPathComponent]];
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
    _isResizedArray = nil;
    int index = [(NSString *)[notification object] intValue];
    self.currentPack = [[User defaultUser] packs][index];
    
    UILabel *titleLable = (UILabel *)self.navigationItem.titleView;
    [titleLable setText:_currentPack.packName];
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Detail_Not_Allow];
    if (val == FALSE) {
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
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Input download code"
                                                                message:nil
                                                               delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                                      otherButtonTitles:NSLocalizedString(@"Keyboard_Cancel",@""), nil];
                [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                [alert textFieldAtIndex:0].text = @"";
                [alert textFieldAtIndex:0].placeholder = @"p8c5cv1";
                alert.delegate = self;
                [alert show];
                break;
            }
            case 1: {
                
                if ([_currentPack cards].count == 0) {
                    return;
                }
                
                if (_currentPack.isAllowShare) {
                    if ((_currentPack) && (_currentCard)) {
                        double delayInSeconds = 0.4;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            _shareHelper = [[AWSS3UploadHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
                            [_shareHelper shareAction];
                        });
                    } else {
                        [iConsole info:@"%s:_currentPack or _currentCard is nil",__FUNCTION__];
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
        
        if (![_currentPack.creator isEqualToString:[OpenUDID value]]) {
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
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [iConsole info:@"%s",__FUNCTION__];
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
}

#pragma mark – UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    //we ignore  _masterPopoverController by not setting delegate = self
    self.settingPopoverController = nil;
    self.helpPopoverController = nil;
}

#pragma mark –  PREVIOUS_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION and NEXT_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION

/**
 *  PlayViewController也有类似的逻辑
 *  previousCardNotification和nextCardNotification方法体逻辑基本一样，
 *  分开写虽然逻辑有些啰嗦，但是思路更清晰，
 */
-(void) previousCardNotification:(NSNotification *)notification {
    [iConsole info:@"%s",__FUNCTION__];
    if ([_currentPack.creator isEqualToString:[OpenUDID value]]) {
        return;
    }
    
    if (_isResizedArray == nil) {
        _isResizedArray = [NSMutableArray array];
        for (int i = 0;i<[[_currentPack cards] count];i++) {
            _isResizedArray[i]= @"NO";
        }
    }
    
    
    NSArray *myArray = [notification object];
    
    if (_indexCard >0) {
        
        if ([_isResizedArray[_indexCard - 1] boolValue] == YES) {
            return;
        }
        
        Card *card = [_currentPack cards][_indexCard - 1];
        //与play mode不同的是，这里我们不需要加入：kFlashCardViewProporation_iPhone
        card.question.css.subheadingSize = [myArray[0] floatValue];
        card.question.css.mainSize = [myArray[1] floatValue] ;
        card.question.css.subSize = [myArray[2] floatValue] ;
        
        [iConsole info:@"%s:css.subheadingSize = %f, css.mainSize = %f and css.subSize = %f",__FUNCTION__,
              card.question.css.subheadingSize,card.question.css.mainSize,card.question.css.subSize];
        
        _isResizedArray[_indexCard - 1] = @YES;
        
    }
    
    
}

/** 
 *  PlayViewController也有类似的逻辑
 *  previousCardNotification和nextCardNotification方法体逻辑基本一样，
 *  分开写虽然逻辑有些啰嗦，但是思路更清晰，
 */
-(void) nextCardNotification:(NSNotification *)notification {
    [iConsole info:@"%s",__FUNCTION__];
    if ([_currentPack.creator isEqualToString:[OpenUDID value]]) {
        return;
    }
    
    if (_isResizedArray == nil) {
        _isResizedArray = [NSMutableArray array];
        for (int i = 0;i<[[_currentPack cards] count];i++) {
            _isResizedArray[i]= @"NO";
        }
    }
    
    NSArray *myArray = [notification object];
    
    if (_indexCard < [[_currentPack cards] count] - 1) {
        
        if ([_isResizedArray[_indexCard + 1] boolValue] == YES) {
            return;
        }
        
        Card *card = [_currentPack cards][_indexCard + 1];
        //与play mode不同的是，这里我们不需要加入：kFlashCardViewProporation_iPhone
        card.question.css.subheadingSize = [myArray[0] floatValue] ;
        card.question.css.mainSize = [myArray[1] floatValue] ;
        card.question.css.subSize = [myArray[2] floatValue] ;
        
        [iConsole info:@"%s:css.subheadingSize = %f, css.mainSize = %f and css.subSize = %f",__FUNCTION__,
              card.question.css.subheadingSize,card.question.css.mainSize,card.question.css.subSize];
        
        _isResizedArray[_indexCard + 1] = @YES;
    }
    
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
            
            NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
            NSString *shareCode = [rawDict objectForKey:@"redirected_url"];
            if ((shareCode.length >0) && ([_currentCard.creator isEqualToString:[OpenUDID value]])) {
                shareCodeLabel.hidden = NO;
                shareCodeLabel.text = [NSString stringWithFormat:@"Share code:  %@",[shareCode lastPathComponent]];
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

@end
