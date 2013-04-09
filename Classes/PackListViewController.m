//
//  PackListViewController.M
//  SwipeViewExample
//
//  Created by Nick Lockwood on 28/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PackListViewController.h"

#import "Pack.h"
#import "User.h"
#import "FileOperationHelper.h"


@implementation PackListViewController

@synthesize swipeView = _swipeView;
@synthesize pageControl = _pageControl;
@synthesize packArray = _packArray;
@synthesize currentPackName = _currentPackName;

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
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
            self.navigationItem.leftBarButtonItem = backButton;
        }
        
        _editBtnItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Edit", @"") style:UIBarButtonItemStylePlain target:self action:@selector(editBtnItemClicked:)];
        self.navigationItem.rightBarButtonItem = _editBtnItem;
        
        _hideDeleteButton = TRUE;
        
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [self.swipeView reloadData];    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    
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
        _swipeView.alignment = SwipeViewAlignmentEdge;
    }
    //configure page control
    _pageControl.numberOfPages = [_packArray count];
    _pageControl.defersCurrentPageDisplay = YES;
    
    self.title = @"Pack List";
    
    [self resetPackContent];
    
    if ([[User defaultUser] packs].count <= 1) {
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        self.navigationItem.rightBarButtonItem = _editBtnItem;
    }
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
    UIButton *deleteButton;
     
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 235)];
    contentView.backgroundColor = [UIColor clearColor];
    view = contentView;
        

    coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 0, 180.0f, 150.0f)];
    coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    coverImageView.layer.cornerRadius = 10;
    coverImageView.layer.masksToBounds = YES;
    [view addSubview:coverImageView];
    coverImageView.image = [UIImage imageWithContentsOfFile:[_packArray objectAtIndex:index]];
    
    indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 160.0f, 200, 40.0f)];
    indexLabel.textAlignment = UITextAlignmentCenter;
    indexLabel.numberOfLines = 2; 
    indexLabel.textColor = [UIColor whiteColor];
    indexLabel.backgroundColor = [UIColor clearColor];
    indexLabel.font = [UIFont systemFontOfSize:16];
    [view addSubview:indexLabel];
    Pack *currentPack = (Pack *)[[[User defaultUser] packs] objectAtIndex:index];
    if (currentPack.creatorNickName.length ==0) {
        indexLabel.text = currentPack.creatorNickName;    
    } else {
        indexLabel.text = [NSString stringWithFormat:@"%@\n (by %@)",currentPack.packName, currentPack.creatorNickName];    
    }

    
    deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [deleteButton setTitle:NSLocalizedString(@"NavigationBarItem_Delete", @"") forState:UIControlStateNormal];
    [deleteButton setBackgroundImage:[[UIImage imageNamed:@"redButton.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [UIFont systemFontOfSize:14];
    deleteButton.tintColor = [UIColor whiteColor];
    [deleteButton addTarget:self action:@selector(deleteCurrentPack:) forControlEvents:UIControlEventTouchDown];
    deleteButton.tag = index;
    deleteButton.userInteractionEnabled = TRUE;
    deleteButton.frame = CGRectMake(50.0f, 205.0f, 100.0, 30);
    NSString *str = ((Pack *)[[[User defaultUser] packs] objectAtIndex:index]).packName;
    if ((!_hideDeleteButton) && (![_currentPackName isEqualToString:str]) && (_packArray.count > 1)) {
        [view addSubview:deleteButton];
    }
    
    
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
                                           
- (void) editBtnItemClicked:(id)sender {
    if ([((UIBarButtonItem *) sender).title isEqualToString:NSLocalizedString(@"NavigationBarItem_Edit", @"")]) {
        _editBtnItem.title = NSLocalizedString(@"NavigationBarItem_Done", @"");
        _hideDeleteButton = FALSE;
        [_swipeView reloadData];
    } else {
        _editBtnItem.title = NSLocalizedString(@"NavigationBarItem_Edit", @"");
        _hideDeleteButton = YES;
        if ([[User defaultUser] packs].count <= 1) {
            self.navigationItem.rightBarButtonItem = nil;
        } else {
            self.navigationItem.rightBarButtonItem = _editBtnItem;
        }
        [_swipeView reloadData];
        
    }
    
}

- (void) backButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) deleteCurrentPack:(id) sender {
    
    NSInteger index = ((UIButton *)sender).tag;
    Pack *currentPack = [[[User defaultUser] packs] objectAtIndex:index];
    [[User defaultUser] removePack:currentPack];
    [self resetPackContent];
    
    //Recalculate:
    Pack *latestPack = [[[User defaultUser] packs] lastObject];
    if (latestPack != nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:latestPack.packID forKey:@"lastCreatedPackID"]; //packID is a time related unique id
        //Update_date info
        NSString *updateDate = [FileOperationHelper getTodayString];
        NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:latestPack.packName];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
        [dict setObject:updateDate forKey:@"update_date"];
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:latestPack.packName];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [_swipeView reloadData];
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
