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
#import "Pack.h"
#import "SHK.h"
#import <DropboxSDK/DropboxSDK.h>
#import "SHKItem.h"
#import "FileOperationHelper.h"
#import "DataManager.h"

#define kScrollViewObjectWidth_iPad 660.0
#define kScrollViewObjectHeight_iPad 660.0
#define kScrollViewObjectMargin_iPad 50

#define kScrollViewObjectWidth_iPhone 480.0
#define kScrollViewObjectHeight_iPhone (320-44)
#define kScrollViewObjectMargin_iPhone 20

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController

@synthesize currentCard = _currentCard;
@synthesize currentPack = _currentPack;
@synthesize indexCard = _indexCard;

#pragma mark -
#pragma mark Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Question & Answer", @"Question & Answer");
        _cardArray = [[NSMutableArray alloc] init];
        _isShare = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLinked:) name:DROPBOX_LINKED_NOTIFICATION object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
}


- (void)loadView {
    [super loadView];
    
    //we don't setting button on iPhone
    UIBarButtonItem *settingButton = [[UIBarButtonItem alloc] initWithTitle:@"More" style:UIBarButtonItemStylePlain target:self action:@selector(moreButtonClicked:)];
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                   target:self action:@selector(playButtonClicked)];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithTitle:@"Share the card" style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonClicked)];
    if (isUserInterfaceIdiomPhone) {
        self.navigationItem.rightBarButtonItems =
        @[playButton, shareButton];
    } else {
        self.navigationItem.rightBarButtonItems =
                                @[settingButton, playButton, shareButton];
    }
    
    //Don't need the back button when on iPad
    if (isUserInterfaceIdiomPhone) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _scrollView.delegate = self;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.clipsToBounds = YES;
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.backgroundColor =[UIColor clearColor];
    [self.view addSubview:_scrollView];
    
    if (isUserInterfaceIdiomPhone) {
        [self layoutScrollObjectsForiPhone];
    } else {
        [self layoutScrollObjectsForiPad];
    }
    
    //for start-up
    if (_indexCard > 0) {
        [self showCurrentCardInScrollView];
    }
}


- (void) showCurrentCardInScrollView {
    if (isUserInterfaceIdiomPhone) {
        [self layoutScrollObjectsForiPhone];
        [_scrollView setContentOffset:CGPointMake(_indexCard*(kScrollViewObjectWidth_iPhone+kScrollViewObjectMargin_iPhone),0) animated:NO];
        
    } else {
        [self layoutScrollObjectsForiPad];
        [_scrollView setContentOffset:CGPointMake(_indexCard*(kScrollViewObjectWidth_iPad+kScrollViewObjectMargin_iPad),0) animated:NO];
    }
    
    
    [_cardArray[_indexCard] refreshQuestionAnserView];
}


- (void)layoutScrollObjectsForiPad
{
    [_cardArray removeAllObjects];
    CGFloat curXLoc = 0;
    for (int index = 0; index < [[_currentPack cards] count]; index++)
	{
		FlashCardView *cardView = [[FlashCardView alloc] initWithFrame:CGRectMake(0,0,IPAD_UI_DETAIL_WIDTH,IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT)];
        cardView.tag = index;	// tag our images for later use when we place them in serial fashion
        cardView.currentCard = self.currentCard;
		CGRect rect = cardView.frame;
        rect.origin = CGPointMake(curXLoc, 0);
        cardView.frame = rect;
		[_scrollView addSubview:cardView];
        curXLoc += (kScrollViewObjectWidth_iPad+kScrollViewObjectMargin_iPad);
        [_cardArray addObject:cardView];
        
        
	}
	
	[_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * (kScrollViewObjectWidth_iPad+kScrollViewObjectMargin_iPad)), kScrollViewObjectHeight_iPad)];
    
    
}

- (void)layoutScrollObjectsForiPhone
{
    [_cardArray removeAllObjects];
    CGFloat curXLoc = 0;
    for (int index = 0; index < [[_currentPack cards] count]; index++)
	{
		FlashCardView *cardView = [[FlashCardView alloc] initWithFrame:CGRectMake(0,0,480,320-IPHONE_UI_NAVIGATION_BAR_HEIGHT)];
        cardView.tag = index;	// tag our images for later use when we place them in serial fashion
        cardView.currentCard = self.currentCard;
		CGRect rect = cardView.frame;
        rect.origin = CGPointMake(curXLoc, 0);
        cardView.frame = rect;
		[_scrollView addSubview:cardView];
        curXLoc += (kScrollViewObjectWidth_iPhone+kScrollViewObjectMargin_iPhone);
        [_cardArray addObject:cardView];
        
        
	}
	
	[_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * (kScrollViewObjectWidth_iPhone+kScrollViewObjectMargin_iPhone)), kScrollViewObjectHeight_iPhone)];
    
    
}

#pragma mark -
#pragma mark Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
    
    // Update the view.
    [self configureView];

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.detailItem) {
        //self.detailDescriptionLabel.text = (NSString *)(self.detailItem) ;
    }
}

#pragma mark -
#pragma mark UIBarButtonItem action  only for iPad

- (void)moreButtonClicked:(id) sender
{
    MoreInfoTableViewController *moreInfoViewController = [[MoreInfoTableViewController alloc] init];
    
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:moreInfoViewController];
    
    if (_settingPopoverController == nil) {
        _settingPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    }
    
    _settingPopoverController.popoverContentSize = CGSizeMake(320, 300);
    
    [_settingPopoverController presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

- (void)playButtonClicked
{
    [Common alertViewCommon:@"this is an example"];
}

- (void)backButtonClicked
{
    [self.navigationController popViewControllerAnimated:YES];
    
}


#pragma mark -
#pragma mark - Dropbox and Share related

- (void)shareButtonClicked
{
    _isShare = YES;
    
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
        if (_isShare) {
            [self exectueShareAfterDropboxLinked];
            _isShare = NO;
        }
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
    
    if (_currentCard == nil)
        return;
    
    if ([DataManager apiReachable] == NO) {
        [Common alertViewCommon:@"Please check your network"];
        return;
    }
    
    //step1: create zip file
    NSString *generatedZipFilePath = [FileOperationHelper zipCardForUpload:_currentCard];
    
    //step2: upload to dropbox
    NSString *saveName = [NSString stringWithFormat:@"card%f%d.zip", [[NSDate date] timeIntervalSince1970], arc4random()];
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    }
    _restClient.delegate = self;
    //if folder not exist, create automatically
    [_restClient uploadFile:saveName toPath:@"/FlashCardCreator"
              withParentRev:nil fromPath:generatedZipFilePath];
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    }
    [self.view addSubview:_HUD];
    _HUD.mode = MBProgressHUDModeIndeterminate;
	_HUD.labelText = @"Uploading to dropbox to create share link...";
    [_HUD show:YES];
    
    //step3: create dropbox linkage which locate in uploadedFile:

}

- (void) shareAction:(NSString *)shareLinkage {

    NSString *urlSchemeLinkage = [shareLinkage stringByReplacingOccurrencesOfString:@"https://www." withString:@"fcc://"];
    
    SHKItem *item = [SHKItem URL:[NSURL URLWithString:urlSchemeLinkage] title:@"example" contentType:SHKURLContentTypeUndefined];
    
    //SHKItem *item = [SHKItem text:urlSchemeLinkage];
     /*item.facebookURLSharePictureURI = @"http://www.state.gov/cms_images/india_tajmahal_2003_06_252.jpg";
     item.facebookURLShareDescription = @"description text";
     item.tags = [NSArray arrayWithObjects:@"apple inc.",@"computers",@"mac", nil];
     item.mailToRecipients = [NSArray arrayWithObjects:@"frodo@middle-earth.me", @"gandalf@middle-earth.me", nil];
     item.textMessageToRecipients = [NSArray arrayWithObjects: @"581347615", @"581344543", nil];*/
     
    
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    [_HUD show:FALSE];
    [_HUD removeFromSuperview];
    
    //step3: create dropbox linkage
    [_restClient loadSharableLinkForFile:metadata.path shortUrl:NO];
    
    //step4: share via sharekit, which locate in loadedSharableLink:
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
    [_HUD show:FALSE];
    [_HUD removeFromSuperview];
    [Common alertViewCommon:@"Failure to upload"];
}

- (void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    NSLog(@"Share linkage create successfully with linkage - %@", link);
    [self shareAction:link];
    
}

- (void)restClient:(DBRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error {
    NSLog(@"Share linkage create failed with error - %@", error);    
}


//warning, need to be finished
- (void) shareCardViaShareLinkage:(NSString *) shareLink {
    NSURL *url = [NSURL URLWithString:@"www.microsoft.com"];
    SHKItem *item = [SHKItem URL:url title:@"Hi Friend, I get a incredible card for you" contentType:SHKURLContentTypeWebpage];
    item.shareType = SHKShareTypeURL;
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}
							
#pragma mark -
#pragma mark Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


#pragma mark -
#pragma mark Segment callback

- (void)segmentAction:(id)sender
{
	UISegmentedControl *segControl = sender;
    
    switch (segControl.selectedSegmentIndex)
	{
		case 0:	//show question
		{
			break;
		}
		case 1: //show answer
		{
			break;
		}
	}
}


#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    NSLog (@"current page is :%d", page);
}


@end
