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
#import "Reachability.h"
#import "PlayViewController.h"
#import "FCCBarButton.h"
#import "DropboxShareKitHelper.h"
#import "HelpViewController.h"
#import "UIImage+Scale.h"
#import "FileOperationHelper.h"

enum template_color_enum {
    template_color_enum_blue = 1,
    template_color_enum_coffee = 2,
    template_color_enum_gray = 3,
    template_color_enum_purple = 4,
    template_color_enum_red = 5
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

@synthesize templateBackgroundSelectPopup  = _templateBackgroundSelectPopup;
@synthesize shareSelectPopup  = _shareSelectPopup;

#pragma mark -
#pragma mark Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedPackNotification:) name:CURRENT_PACK_SELECTED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideNavigationBarNotification:) name:HIDE_NAVIGATION_BAR_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNavigationBarNotification:) name:SHOW_NAVIGATION_BAR_NOTIFICATION object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:134.0/255 green:134.0/255 blue:149.0/255 alpha:1];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [self.navigationController.navigationBar setTranslucent:FALSE];
    }
    
    float flashCardYPositionInScrollView;
    if (isUserInterfaceIdiomPhone) {
        flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPhone)/2+5; //Since it's horizontal movement, so this is a constant value
        _previousCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone) defaultPack:_currentPack defaultCard:_currentCard];
        _currentCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone)
                                                defaultPack:_currentPack defaultCard:_currentCard];
        _nextCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone)
                                             defaultPack:_currentPack defaultCard:_currentCard];
        
    } else {
        flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPad)/2; //Since it's horizontal movement, so this is a constant value
        _previousCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)
                                                 defaultPack:_currentPack defaultCard:_currentCard];
        _currentCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)
                                                defaultPack:_currentPack defaultCard:_currentCard];
        _nextCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)
                                             defaultPack:_currentPack defaultCard:_currentCard];
    }
    
    [[_currentCardView layer] setShadowOffset:CGSizeMake(1, 1)];
    [[_currentCardView layer] setShadowRadius:3];
    [[_currentCardView layer] setShadowOpacity:0.5];
    [[_currentCardView layer] setShadowColor:[UIColor whiteColor].CGColor];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
       //do nothing
    } else {
        //self.automaticallyAdjustsScrollViewInsets = NO; //we will add this back when xcode5 is finally released
    }
    

}


- (void)loadView {
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
        @[playButton,_templateBackgroundSelectButton];
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
    [super viewWillAppear:animated];
    if (isUserInterfaceIdiomPhone){
        _scrollView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT);
        [self showCurrentCardInScrollView:NO];
    } else {
        _scrollView.frame = CGRectMake(0, 0, IPAD_UI_DETAIL_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
        
        if ([_currentPack cards].count !=0) {
            //Load card view when not:1. downloading;2. not every time
            BOOL isExamplePackDownloadedSuccessful = [[NSUserDefaults standardUserDefaults] boolForKey:@"isExamplePackDownloadedSuccessful"];
            if (isExamplePackDownloadedSuccessful == TRUE) {
                static dispatch_once_t oncetoken;
                dispatch_once(&oncetoken, ^{
                    [self showCurrentCardInScrollView:NO];
                });
            }
        }
    }
    

    //iOS7 special, since UIImagePickerController will display status bar forcely.
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}


#pragma mark -
#pragma mark - Layout 

- (void) showCurrentCardInScrollView:(BOOL) shouldResetSegment {
    if (isUserInterfaceIdiomPhone) {
        [self layoutScrollObjectsForiPhone];
        [_scrollView setContentOffset:CGPointMake(_indexCard*(IPHONE_UI_WIDTH),0) animated:NO];
    } else {
        [self layoutScrollObjectsForiPad];
        [_scrollView setContentOffset:CGPointMake(_indexCard*(IPAD_UI_DETAIL_WIDTH),0) animated:NO];
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    if (isUserInterfaceIdiomPhone) {
        label.font = [UIFont boldSystemFontOfSize:16.0];
    }else {
        label.font = [UIFont boldSystemFontOfSize:20.0];    
    }
    label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor]; // change this color
    label.text = _currentPack.packName;
    [label sizeToFit];
    [self.navigationItem setTitleView:label];
    
    if ((shouldResetSegment == YES) && (_currentCardView.segmentedControl.selectedSegmentIndex == 1)) {
        _currentCardView.segmentedControl.selectedSegmentIndex = 0;
        [_currentCardView segmentAction:nil];
    }

}

- (void)layoutScrollObjectsForiPad
{
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

    [_currentCardView refreshAll];
    
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
        [_previousCardView refreshAll];
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
        
        [_nextCardView refreshAll];
    }

}

- (void)layoutScrollObjectsForiPhone
{
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
    [_currentCardView refreshAll];

    
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
        [_previousCardView refreshAll];
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
        [_nextCardView refreshAll];
    }

}

#pragma mark -
#pragma mark UIBarButtonItem action (only for iPad)

- (void)shareButtonClicked:(id) sender {
    
    if (self.templateBackgroundSelectPopup) {
        [self.templateBackgroundSelectPopup hide];
    }
    
    if (self.shareSelectPopup) {
        [self.shareSelectPopup hide];
    }
    
    if (!isUserInterfaceIdiomPhone) {
        [_settingPopoverController dismissPopoverAnimated:YES];
        [_helpPopoverController dismissPopoverAnimated:YES];
    }
    
    PopupListComponent *popupList = [[PopupListComponent alloc] init];
    NSArray* listItems = [NSArray arrayWithObjects:
                 [[PopupListComponentItem alloc] initWithCaption:@"Install from Code" image:nil
                                                          itemId:0 showCaption:YES],
                 [[PopupListComponentItem alloc] initWithCaption:@"Share the pack"  image:nil
                                                          itemId:1 showCaption:YES],
                 nil];
    
    popupList.imagePaddingHorizontal = 5;
    if (isUserInterfaceIdiomPhone) {
        popupList.font = [UIFont systemFontOfSize:12];
    } else {
        popupList.font = [UIFont systemFontOfSize:14];
    }
    popupList.tag = popover_enum_share;
    popupList.imagePaddingVertical = 2;
    popupList.textPaddingHorizontal = 5;
    popupList.alignment = UIControlContentHorizontalAlignmentLeft;
    [popupList showAnchoredTo:sender inView:self.navigationController.view withItems:listItems withDelegate:self];
    
    self.shareSelectPopup = popupList;
    
}

- (void)helpButtonClicked:(id) sender
{
    if (!isUserInterfaceIdiomPhone) {
        [_settingPopoverController dismissPopoverAnimated:YES];
    }
    
    HelpViewController *helpViewController = [[HelpViewController alloc] init];
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:helpViewController];
    if (_helpPopoverController == nil) {
        _helpPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    }
    _helpPopoverController.popoverContentSize = CGSizeMake(486, 510);
    [_helpPopoverController presentPopoverFromBarButtonItem:_helpButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void) selectCardBackgroundTemplate:(id) sender {
    if (self.templateBackgroundSelectPopup) {
        [self.templateBackgroundSelectPopup hide];
    }
    
    if (self.shareSelectPopup) {
        [self.shareSelectPopup hide];
    }
    
    PopupListComponent *popupList = [[PopupListComponent alloc] init];
    NSArray* listItems = nil;
    listItems = [NSArray arrayWithObjects:
                 [[PopupListComponentItem alloc] initWithCaption:@"Blue" image:[UIImage imageNamed:@"template_color_blue.png"]
                                                          itemId:template_color_enum_blue showCaption:YES],
                 [[PopupListComponentItem alloc] initWithCaption:@"Coffee"  image:[UIImage imageNamed:@"template_color_coffee.png"]
                                                          itemId:template_color_enum_coffee showCaption:YES],
                 [[PopupListComponentItem alloc] initWithCaption:@"Gray"  image:[UIImage imageNamed:@"template_color_gray.png"]
                                                          itemId:template_color_enum_gray showCaption:YES],
                 [[PopupListComponentItem alloc] initWithCaption:@"Purple"  image:[UIImage imageNamed:@"template_color_purple.png"]
                                                          itemId:template_color_enum_purple showCaption:YES],
                 [[PopupListComponentItem alloc] initWithCaption:@"Red"  image:[UIImage imageNamed:@"template_color_red.png"]
                                                          itemId:template_color_enum_red showCaption:YES],
                 nil];
    
    
    popupList.imagePaddingHorizontal = 5;
    if (isUserInterfaceIdiomPhone) {
        popupList.font = [UIFont systemFontOfSize:12];
    } else {
        popupList.font = [UIFont systemFontOfSize:14];
    }
    popupList.imagePaddingVertical = 2;
    popupList.textPaddingHorizontal = 5;
    popupList.alignment = UIControlContentHorizontalAlignmentLeft;
    popupList.tag = popover_enum_template_select;

    [popupList showAnchoredTo:sender inView:self.navigationController.view withItems:listItems withDelegate:self];
    
    self.templateBackgroundSelectPopup = popupList;
}

- (void)moreButtonClicked:(id) sender
{
    if (!isUserInterfaceIdiomPhone) {
        [_helpPopoverController dismissPopoverAnimated:YES];
    }
    
    MoreInfoTableViewController *moreInfoViewController = [[MoreInfoTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:moreInfoViewController];
    if (_settingPopoverController == nil) {
        _settingPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    }
    
    _settingPopoverController.popoverContentSize = CGSizeMake(320, 480);
    [_settingPopoverController presentPopoverFromBarButtonItem:_settingButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

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
    
    if (!isUserInterfaceIdiomPhone) {
        [_settingPopoverController dismissPopoverAnimated:YES];
        [_helpPopoverController dismissPopoverAnimated:YES];
    }
    
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow.rootViewController presentViewController:playViewController animated:YES completion:nil];
    
}

- (void)backButtonClicked:(id) sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Split view

- (void)splitViewController:(MGSplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(MGSplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}


#pragma mark -
#pragma mark Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
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
        _indexCard = page;
        _currentCard = [_currentPack cards][page];
        [self showCurrentCardInScrollView:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_DETAIL_SCROLL_NOTFICATION object:[NSString stringWithFormat:@"%d",page]];
    }
    _scrollView.userInteractionEnabled = YES;
    
}

- (void) selectedPackNotification:(NSNotification *) notification {
    int index = [(NSString *)[notification object] intValue];
    self.currentPack = [[User defaultUser] packs][index];
}

- (void) hideNavigationBarNotification:(NSNotification *) notification {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void) showNavigationBarNotification:(NSNotification *) notification {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark -
#pragma mark - PopupListComponentDelegate delegate
- (void) popupListcomponent:(PopupListComponent *)sender choseItemWithId:(int)itemId
{
    //Step1: close popover window
    self.templateBackgroundSelectPopup = nil;
    self.shareSelectPopup = nil;
    
    
    //Step2: Check exception
    if ([_currentPack cards].count == 0) {
        return;
    }
    
    if (sender.tag == popover_enum_share) {
        switch (itemId) {
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
                if ((_currentPack) && (_currentCard)) {
                    _shareHelper = [[DropboxSharekitHelper alloc] initWithCurrentCard:_currentCard currentPack:_currentPack baseViewController:self];
                    [_shareHelper shareAction];
                } else {
                    NSLog(@"%s:_currentPack or _currentCard is nil",__FUNCTION__);
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
        switch (itemId) {
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
            _HUD = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
        
        [[[UIApplication sharedApplication] keyWindow] insertSubview:_HUD atIndex:0];
        [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:_HUD];
        
        _HUD.mode = MBProgressHUDModeIndeterminate;
        _HUD.labelText = NSLocalizedString(@"DIALOG_APPLY_TO_ALL_CARD",@"");
        [_HUD show:YES];
        [self performSelector:@selector(execTemplateBackgroundChangeTask:) withObject:templateBackgroundName afterDelay:0.01];
    }
    
}

- (void) execTemplateBackgroundChangeTask:(NSString *)templateBackgroundName {
    //Step4: Change all cards card template background, screenshot them, and save them
    [_currentCardView reSceenshotAll:kReasonTemplateBackgroundChangeEnum withStringVal:templateBackgroundName];
    [_currentCardView refreshAll];
    
    //Step5: tell the master view to update cell
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    
    [_HUD removeFromSuperview];
    _HUD = nil;
}

- (void) popupListcompoentDidCancel:(PopupListComponent *)sender
{
    NSLog(@"Popup cancelled");
    self.templateBackgroundSelectPopup = nil;
    self.shareSelectPopup = nil;
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
}

#pragma mark -
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
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


@end
