//
//  PackListViewController.m
//  PackList
//
//  Created by Wang Bourne on 3/01/13.
//  Copyright (c) 2013 temp. All rights reserved.
//

#import "PackListViewController.h"
#import "PackListView.h"
#import "Pack.h"
#import "User.h"

const CGFloat kScrollObjHeight	= 262.0;
const CGFloat kScrollObjWidth	= 406.0;
const CGFloat kScrollObjHorizonMargin	= 40.0;
const CGFloat kScrollViewWidth  = 600.0;


@interface PackListViewController ()

@end

@implementation PackListViewController

@synthesize imageArray = _imageArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPackAddedNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) loadView {
    [super loadView];
    
    _packListView = [[PackListView alloc] initWithFrame:CGRectMake(0, 0, 700, 262)];
    [self.view addSubview:_packListView];
    [self resetPackContent];
}

- (void) resetPackContent {
    NSMutableArray *imageArray = [NSMutableArray array];
    
    NSString *publicPackImageFile = [NSString stringWithFormat:@"%@/public_pack.png", [[NSBundle mainBundle] resourcePath]];
    [imageArray addObject:publicPackImageFile];
    
    for (Pack *pack in [[User defaultUser] packs]) {
        [imageArray addObject:pack.coverImageURL];
    }
    _packListView.imageArray = imageArray;
}


-(void)newPackAddedNotification:(NSNotification *)notification{
	[self resetPackContent];
    [_packListView layoutSubviews];
}




@end

