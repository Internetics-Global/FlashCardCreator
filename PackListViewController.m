//
//  PackListViewController.M
//  SwipeViewExample
//
//  Created by Nick Lockwood on 28/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PackListViewController.H"

#import "Pack.h"
#import "User.h"


@implementation PackListViewController

@synthesize swipeView = _swipeView;
@synthesize pageControl = _pageControl;
@synthesize packArray = _packArray;

#pragma mark -
#pragma mark - Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        //From: click "add pack" button on navigation bar
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePackListNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
        
        //From: add downloaded pack
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePackListNotification:) name:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:nil];
        
        //Don't need the back button when on iPad 
        if (isUserInterfaceIdiomPhone) {
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
            self.navigationItem.leftBarButtonItem = backButton;
        }
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //configure swipe view
    _swipeView.alignment = SwipeViewAlignmentCenter;
    _swipeView.pagingEnabled = YES;
    _swipeView.wrapEnabled = NO;
    _swipeView.truncateFinalPage = YES;
    int packSize = [[[User defaultUser] packs] count];
    if (packSize == 1) {
        _swipeView.itemsPerPage = 1;
    } else if (packSize == 2)
        _swipeView.itemsPerPage = 2;
    else {
        _swipeView.itemsPerPage = 3;
    }
    //configure page control
    _pageControl.numberOfPages = [_packArray count];
    _pageControl.defersCurrentPageDisplay = YES;
    
    self.title = @"Pack List";
    
    [self resetPackContent];
}

#pragma mark -
#pragma mark - Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark - SwipeViewDelegate and SwipeViewDataSource

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return [self.packArray count];
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UIView *contentView = view;
    UIImageView *coverImageView ;
    UILabel *indexLabel;
     
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 250.0f, 200.0f)];
    contentView.backgroundColor = [UIColor clearColor];
    view = contentView;
        
    indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 200.0f, 230.0f, 20.0f)];
    indexLabel.textAlignment = UITextAlignmentCenter;
    indexLabel.textColor = [UIColor whiteColor];
    indexLabel.backgroundColor = [UIColor clearColor];
    indexLabel.font = [UIFont systemFontOfSize:16];
    [view addSubview:indexLabel];
        
    coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 210.0f, 180.0f)];
    coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    coverImageView.layer.cornerRadius = 10;
    coverImageView.layer.masksToBounds = YES;
    [view addSubview:coverImageView];

    //configure view
    coverImageView.image = [UIImage imageWithContentsOfFile:[_packArray objectAtIndex:index]];
    
    Pack *currentPack = (Pack *)[[[User defaultUser] packs] objectAtIndex:index];
    indexLabel.text = currentPack.packName;
    
    [view layoutSubviews];
    
    return view;
}

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    //update page control page
    _pageControl.currentPage = swipeView.currentPage;
}

- (void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"Selected item at index %d", index);
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];    
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_PACK_SELECTED_NOTIFICATION object:[NSString stringWithFormat:@"%d",index]];
}

#pragma mark -
#pragma mark - Reset DataSource

- (void) resetPackContent {
    NSMutableArray *imageArray = [NSMutableArray array];
    
    for (Pack *pack in [[User defaultUser] packs]) {
        [imageArray addObject:pack.coverImageURL];
    }
    self.packArray = imageArray;
}

#pragma mark -
#pragma mark - Notification related

-(void)updatePackListNotification:(NSNotification *)notification{
	[self resetPackContent];
    [self.swipeView reloadData];
}

#pragma mark -
#pragma mark - Control touch event

- (IBAction)pageControlTapped
{
    //update swipe view page
    [_swipeView scrollToPage:_pageControl.currentPage duration:0.4];
}

- (void) backButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
