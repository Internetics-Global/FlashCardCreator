//
//  PackListViewController.m
//  SwipeViewExample
//
//  Created by Nick Lockwood on 28/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwipeView.h"


@interface PackListViewController : UIViewController <SwipeViewDelegate, SwipeViewDataSource> {
    SwipeView *_swipeView;
    UIPageControl *_pageControl;
    NSMutableArray *_packArray;
    
    NSInteger _indexCurrentPack;
    BOOL _hideDeleteButton;
    
    UIBarButtonItem *_editBtnItem;
}

@property (nonatomic, strong) IBOutlet SwipeView *swipeView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) NSMutableArray *packArray;
@property (nonatomic, assign) NSInteger indexCurrentPack;

- (IBAction)pageControlTapped;

@end
