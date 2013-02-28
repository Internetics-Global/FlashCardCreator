//
//  DetailViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "DetailViewController.h"
#import "MoreInfoTableViewController.h"
#import "QuestionView.h"
#import "AnswerView.h"
#import "FlashCardView.h"
#import "Card.h"
#import "User.h"
#import "Pack.h"
#import "SHK.h"
#import <DropboxSDK/DropboxSDK.h>
#import "SHKItem.h"
#import "FileOperationHelper.h"
#import "DataManager.h"
#import "Reachability.h"
#import "PlayView.h"
#import "FCCBarButton.h"

@implementation DetailViewController

@synthesize currentCard = _currentCard;
@synthesize currentPack = _currentPack;
@synthesize indexCard = _indexCard;
@synthesize masterPopoverController = _masterPopoverController;

#pragma mark -
#pragma mark Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLinked:) name:DROPBOX_LINKED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedPackNotification:) name:CURRENT_PACK_SELECTED_NOTIFICATION object:nil];
        
        float flashCardYPositionInScrollView;
        if (isUserInterfaceIdiomPhone) {
            flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPhone)/2; //Since it's horizontal movement, so this is a constant value
            _previousCardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone)];
            _currentCardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone)];
            _nextCardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone)];
            
        } else {
            flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPad)/2; //Since it's horizontal movement, so this is a constant value
            _previousCardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)];
            _currentCardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)];
            _nextCardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)];
        }
        
        //Just for debug use
        _previousCardView.tag = 110;
        _currentCardView.tag = 111;
        _nextCardView.tag = 112;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:134.0/255 green:134.0/255 blue:149.0/255 alpha:1];
}


- (void)loadView {
    [super loadView];
    
    //we don't setting button on iPhone
    _settingButton = [[UIBarButtonItem alloc]
                                      initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"setting_button.png"] target:self action:@selector(moreButtonClicked:)]];
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc]
                                   initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"play_button.png"] target:self action:@selector(playButtonClicked:)]];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc]
                                    initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"share_button.png"] target:self action:@selector(shareButtonClicked:)]];
    if (isUserInterfaceIdiomPhone) {
        self.navigationItem.rightBarButtonItems =
        @[playButton, shareButton];
    } else {
        self.navigationItem.rightBarButtonItems =
                                @[_settingButton, playButton, shareButton];
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
    
    if (isUserInterfaceIdiomPhone){
        _scrollView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT);
        [self showCurrentCardInScrollView];
    } else {
        _scrollView.frame = CGRectMake(0, 0, IPAD_UI_DETAIL_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
        
        if ([_currentPack cards].count !=0) {
            //Load card view when not:1. downloading;2. not every time
            BOOL isExamplePackDownloadedSuccessful = [[NSUserDefaults standardUserDefaults] boolForKey:@"isExamplePackDownloadedSuccessful"];
            if (isExamplePackDownloadedSuccessful == TRUE) {
                static dispatch_once_t oncetoken;
                dispatch_once(&oncetoken, ^{
                    [self showCurrentCardInScrollView];
                });
            }
        }
    }

}

#pragma mark -
#pragma mark - Layout 

- (void) showCurrentCardInScrollView {
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
}

- (void)layoutScrollObjectsForiPad
{
    CGRect rect;
    
    for (FlashCardView *cardView in [_scrollView subviews]) {
        [cardView removeFromSuperview];
    }
    
    if ([_currentPack cards].count == 0) {
        return;
    }
    
    //1. Content size
    [_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPAD_UI_DETAIL_WIDTH), IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT)];
    
    //2. Set current
    [_currentCardView reset:_currentCard curPack:_currentPack];
    _currentCardView.enableSaveNotification = YES;
    
    rect = _currentCardView.frame;
    CGFloat curXLoc = (IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2;
    curXLoc += IPAD_UI_DETAIL_WIDTH *_indexCard;
    rect.origin.x = curXLoc;
    _currentCardView.frame = rect;
    [_scrollView addSubview:_currentCardView];

    [_currentCardView refreshQuestionAnserView];
    [_currentCardView checkCardEditable];
    
    //3. Set previous
    if (_indexCard == 0) {
        //_previousCardView = nil;
    } else {

        [_previousCardView reset:[_currentPack cards][_indexCard-1] curPack:_currentPack];
        
        rect.origin.x = curXLoc -IPAD_UI_DETAIL_WIDTH;
        _previousCardView.frame = rect;
        [_scrollView addSubview:_previousCardView]; 
        
        [_previousCardView refreshQuestionAnserView];
        [_previousCardView checkCardEditable];
    }
    
    //5. Set next
    if (([[_currentPack cards] count]-1) == _indexCard) {
        //_nextCardView = nil;
    } else {
        [_nextCardView reset:[_currentPack cards][_indexCard+1] curPack:_currentPack];
        
        rect.origin.x = curXLoc +IPAD_UI_DETAIL_WIDTH;
        _nextCardView.frame = rect;
        [_scrollView addSubview:_nextCardView]; 
        
        [_nextCardView refreshQuestionAnserView];
        [_nextCardView checkCardEditable];
    }

}

- (void)layoutScrollObjectsForiPhone
{
    CGRect rect;
    
    for (FlashCardView *cardView in [_scrollView subviews]) {
        [cardView removeFromSuperview];
    }
    
    if ([_currentPack cards].count == 0) {
        return;
    }
    
    //1. Content size
    [_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPHONE_UI_WIDTH), _scrollView.frame.size.height)];
    
    //2. Set current
    [_currentCardView reset:_currentCard curPack:_currentPack];
    _currentCardView.enableSaveNotification = YES;
    
    rect = _currentCardView.frame;
    CGFloat curXLoc = (IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2;
    curXLoc += IPHONE_UI_WIDTH *_indexCard;
    rect.origin.x = curXLoc;
    _currentCardView.frame = rect;
    [_scrollView addSubview:_currentCardView]; 
    
    [_currentCardView refreshQuestionAnserView];
    [_currentCardView checkCardEditable];
    
    //3. Set previous
    if (_indexCard == 0) {
        //_previousCardView = nil;
    } else {
        _previousCardView.currentPack = _currentPack;
        _previousCardView.currentCard = [_currentPack cards][_indexCard-1];
        
        rect.origin.x = curXLoc -IPHONE_UI_WIDTH;
        _previousCardView.frame = rect;
        [_scrollView addSubview:_previousCardView];
        
        [_previousCardView refreshQuestionAnserView];
    }
    
    //4. Set next
    if (([[_currentPack cards] count]-1) == _indexCard) {
        //_nextCardView = nil;
    } else {
        _nextCardView.currentPack = _currentPack;
        _nextCardView.currentCard = [_currentPack cards][_indexCard+1];
        
        rect.origin.x = curXLoc + IPHONE_UI_WIDTH;
        _nextCardView.frame = rect;
        [_scrollView addSubview:_nextCardView];  
        [_nextCardView refreshQuestionAnserView];
    }
}

#pragma mark -
#pragma mark UIBarButtonItem action (only for iPad)

- (void)moreButtonClicked:(id) sender
{
    MoreInfoTableViewController *moreInfoViewController = [[MoreInfoTableViewController alloc] init];
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:moreInfoViewController];
    if (_settingPopoverController == nil) {
        _settingPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    }
    _settingPopoverController.popoverContentSize = CGSizeMake(320, 300);
    [_settingPopoverController presentPopoverFromBarButtonItem:_settingButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

- (void)playButtonClicked:(id) sender
{
    PlayView *playView = [[PlayView alloc] init];
    if (isUserInterfaceIdiomPhone) {
        playView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT);
    } else {
        playView.frame = CGRectMake(0, 0, IPAD_UI_WIDTH, IPAD_UI_HEIGHT);    
    }
    playView.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if ((self.currentCard == nil) || (self.currentPack == nil)) {
        [Common alertViewCommon:@"Current card or pack is nil"];
        return;
    }
    playView.currentPack = self.currentPack;
    playView.currentCard = self.currentCard;
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [UIView transitionWithView:keyWindow duration:0.5 options: UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        [keyWindow.rootViewController.view addSubview:playView];
        [keyWindow.rootViewController.view bringSubviewToFront:playView];
    } completion:nil];
    
}

- (void)backButtonClicked:(id) sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark - Dropbox and Share related

- (void)shareButtonClicked:(id) sender
{
    //Step1: check whether need to upload pack again
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
    if (!dict) {
        //do nothing
    } else {
        NSString *updateDate = [dict objectForKey:@"update_date"];
        NSString *shareDate = [dict objectForKey:@"share_date"];
        NSString *shareLink = [dict objectForKey:@"share_link"];
        if ((updateDate != nil) && (shareDate != nil) & (shareLink != nil)) {
            if ([[FileOperationHelper convertStringToNSDate:updateDate]
                     compare:
                 [FileOperationHelper convertStringToNSDate:shareDate]]
                         == NSOrderedAscending) {
                NSLog(@"updateDate is earlier than shareDate");
                [self shareAction:shareLink];
                return;
            }
        }
    }
    
    //Step2: do upload and share if not meet
    if (![[DBSession sharedSession] isLinked]) {
		[[DBSession sharedSession] linkFromController:[[UIApplication sharedApplication] keyWindow].rootViewController];
    } else {
        [self exectueShareAfterDropboxLinked];
    }

}

- (void) dropboxLinked:(id)notification
{
    NSNumber *linkedNum = [[notification userInfo] objectForKey:@"linked"];
    
    if(![linkedNum boolValue])
    {
        [Common alertViewCommon:@"Failed to login to Dropbox."];
    } else
    {
        [self exectueShareAfterDropboxLinked];
    }
}

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void) exectueShareAfterDropboxLinked {
    
    NSString *generatedZipFilePath = nil;
    //step1: create zip file
    if (_currentPack) {
        generatedZipFilePath = [FileOperationHelper zipPackForUpload:_currentPack];
    } else {
        [Common alertViewCommon:@"You need to select a pack first"];
        NSLog(@"%s:Pack to share is nil or public pack",__FUNCTION__);
        return;
    }

    //step2: upload to dropbox
    if ([DataManager apiReachable] == NO) {
        [Common alertViewCommon:@"Please check your network"];
        return;
    }
    
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    }
    _restClient.delegate = self;
    
    //Create or replace current
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
    NSString *saveName;
    if ([dict objectForKey:@"share_filename"]) {
        saveName = [dict objectForKey:@"share_filename"];
    } else {
        saveName = [NSString stringWithFormat:@"card%f%d.zip", [[NSDate date] timeIntervalSince1970], arc4random()];    
    }
    
    //we use the deprecated method to replace: http://stackoverflow.com/questions/10682749/how-to-overwrite-file-with-parent-rev-using-dropbox-api-in-ios
    [_restClient uploadFile:saveName toPath:@"/FlashCardCreator"
              fromPath:generatedZipFilePath];
    [self showProgressIndicator];
    
    //step3: create dropbox linkage which locate in uploadedFile:

}

- (void) shareAction:(NSString *)shareLinkage {

    NSString *urlSchemeLinkage = [shareLinkage stringByReplacingOccurrencesOfString:@"https://" withString:@"fcc://"];
    
    SHKItem *item = [SHKItem URL:[NSURL URLWithString:urlSchemeLinkage] title:@"example" contentType:SHKURLContentTypeUndefined];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

#pragma mark -
#pragma mark - DBRestClientDelegate related

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    
    _isCreatingShareLinkage = YES;
    
    //step3: create dropbox linkage
    [_restClient loadSharableLinkForFile:metadata.path shortUrl:NO];
    
    //step4: share via sharekit, which locate in loadedSharableLink:
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
    [_HUD hide:YES];
    [Common alertViewCommon:@"Failure to upload"];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath {
    _progressivePercent = progress;
    _HUD.progress = progress;
    
    if (progress == 1)
        _isCreatingShareLinkage = YES;
}

- (void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    NSLog(@"Share linkage create successfully with linkage - %@", link);
    [_HUD hide:YES];
    
    _isCreatingShareLinkage = NO;
    
    //share_date info
    NSString *sharedate = [FileOperationHelper getTodayString];
    NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
    [dict setObject:sharedate forKey:@"share_date"];
    [dict setObject:link forKey:@"share_link"];
    [dict setObject:[[path componentsSeparatedByString:@"/"]lastObject] forKey:@"share_filename"];  // similiar like like card1361507800.569792-1108896928.zip
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:_currentPack.packName];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self shareAction:link];
    
}

- (void)restClient:(DBRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error {
    
    _HUD.labelText = @"Fail to create share linkage";
    _isCreatingShareLinkage = NO;
    NSLog(@"Share linkage create failed with error - %@", error);
}

#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)showProgressIndicator {
	
	_HUD = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
    //_HUD.color = [UIColor blackColor];
    CGAffineTransform at = CGAffineTransformMakeRotation(-M_PI/2);
    [_HUD setTransform:at];
    _HUD.mode = MBProgressHUDModeDeterminate;
    _HUD.delegate = self;
    _HUD.labelText = @"Uploading first...";
    _HUD.detailsLabelText = @"to Dropbox and create share linkage";
    _isCreatingShareLinkage = NO;
    [_HUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
    
    [[[UIApplication sharedApplication] keyWindow] insertSubview:_HUD atIndex:0];
    [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:_HUD];
    
}

- (void)myProgressTask {
	while (_progressivePercent < 1.0f) {
		_HUD.progress = _progressivePercent;
		usleep(50000);
	}
    _progressivePercent = 0;
    
    _HUD.mode = MBProgressHUDModeIndeterminate;
    _HUD.labelText = @"Then create share link...";
    
    while (_isCreatingShareLinkage == YES) {
        usleep(50000);    
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
	[_HUD removeFromSuperview];
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    //Step1: calculate page(index)
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    NSLog (@"current page is :%d", page);
    
    if ((page == _indexCard +1) || (page == _indexCard -1)) {
        _indexCard = page;
        _currentCard = [_currentPack cards][page];
        [self showCurrentCardInScrollView];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_DETAIL_SCROLL_NOTFICATION object:[NSString stringWithFormat:@"%d",page]];
    }
    
}

- (void) selectedPackNotification:(NSNotification *) notification {
    int index = [(NSString *)[notification object] intValue];
    self.currentPack = [[User defaultUser] packs][index];
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


@end
