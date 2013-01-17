//
//  DetailViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "DetailViewController.h"
#import "AboutTableViewController.h"
#import "QuestionView.h"
#import "AnswerView.h"
#import "FlashCardView.h"
#import "Card.h"
#import "Pack.h"
#import "SHK.h"
#import <DropboxSDK/DropboxSDK.h>

#define kScrollViewObjectWidth_iPad 660.0
#define kScrollViewObjectHeight_iPad 660.0
#define kScrollViewObjectMargin_iPad 50

#define kScrollViewObjectWidth_iPhone 300.0
#define kScrollViewObjectHeight_iPhone 300.0
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
    
    UIBarButtonItem *settingButton = [[UIBarButtonItem alloc] initWithTitle:@"Setting" style:UIBarButtonItemStylePlain target:self action:@selector(aboutButtonClicked)];
    
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                   target:self action:@selector(playButtonClicked)];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithTitle:@"Share the card" style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonClicked)];
    
    self.navigationItem.rightBarButtonItems =
    @[settingButton, playButton, shareButton];
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
    [self layoutScrollObjects];
    
    //for start-up
    if (_indexCard > 0) {
        [self showCurrentCardInScrollView];
    }
}


- (void) showCurrentCardInScrollView {
    [self layoutScrollObjects];
    
    [_scrollView setContentOffset:CGPointMake(_indexCard*(kScrollViewObjectWidth_iPad+kScrollViewObjectMargin_iPad),0) animated:NO];
    
    [_cardArray[_indexCard] refreshQuestionAnserView];
}


- (void)layoutScrollObjects
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
#pragma mark UIBarButtonItem action

- (void)aboutButtonClicked
{
    AboutTableViewController *aboutTableViewController = [[AboutTableViewController alloc] init];
    [self presentModalViewController:aboutTableViewController animated:YES];
    
}

- (void)playButtonClicked
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"example"
                                                  message:@"this is an example"
                                                  delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
    [alert show];
}


#pragma mark -
#pragma mark - Dropbox and Share related

- (void)shareButtonClicked
{
    if (![[DBSession sharedSession] isLinked]) {
		[[DBSession sharedSession] linkFromController:self.splitViewController];
    } else {
        [self exectueShareAfterDropboxLinked];
    }

}

- (void) dropboxLinked:(id)notification
{
    NSNumber *linkedNum = [[notification userInfo] objectForKey:@"linked"];
    
    if(![linkedNum boolValue])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error."
                                                        message:@"Failed to login to Dropbox."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else
    {
        [self exectueShareAfterDropboxLinked];
    }
}

- (void) exectueShareAfterDropboxLinked {
    NSString *shareLink = [self createDropboxShareLinkForCurrentCard:nil];
    [self shareCardViaShareLinkage:shareLink];
}

//warning, need to be finished
- (NSString *) createDropboxShareLinkForCurrentCard:(id)notification {
    NSString *shareLink;
    return shareLink;
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
