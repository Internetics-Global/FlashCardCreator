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


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPackAddedNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
        
        [self resetPackContent];
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
    _swipeView.itemsPerPage = 3;
    _swipeView.truncateFinalPage = YES;
    
    //configure page control
    _pageControl.numberOfPages = [_packArray count];
    _pageControl.defersCurrentPageDisplay = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return [self.packArray count];
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UIView *contentView = view;
    UIImageView *coverImageView ;
    UILabel *indexLabel;
    
    NSLog(@"------%d", index);
    
    //create or reuse view
    if (view == nil)
    {
        
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
        coverImageView.layer.cornerRadius = 10;
        coverImageView.layer.masksToBounds = YES;
        [view addSubview:coverImageView];
    }
    
    //configure view
    coverImageView.image = [UIImage imageWithContentsOfFile:[_packArray objectAtIndex:index]];
    
    if (index == 0) {
        indexLabel.text = PUBLIC_PACK_NAME;
    } else {
        Pack *currentPack = (Pack *)[[[User defaultUser] packs] objectAtIndex:(index-1)];
        
        indexLabel.text = currentPack.packName;
    }
    
    //return view
    return view;
}

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    //update page control page
    _pageControl.currentPage = swipeView.currentPage;
}

- (void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"Selected item at index %i", index);
    [[NSNotificationCenter defaultCenter] postNotificationName:NEW_SELECTED_PACK_NOTIFICATION object:[NSString stringWithFormat:@"%d",index]];
}

- (IBAction)pageControlTapped
{
    //update swipe view page
    [_swipeView scrollToPage:_pageControl.currentPage duration:0.4];
}

- (void) resetPackContent {
    NSMutableArray *imageArray = [NSMutableArray array];
    
    NSString *publicPackImageFile = [NSString stringWithFormat:@"%@/public_pack.png", [[NSBundle mainBundle] resourcePath]];
    [imageArray addObject:publicPackImageFile];
    
    for (Pack *pack in [[User defaultUser] packs]) {
        [imageArray addObject:pack.coverImageURL];
    }
    self.packArray = imageArray;
}


-(void)newPackAddedNotification:(NSNotification *)notification{
	[self resetPackContent];
}


@end
