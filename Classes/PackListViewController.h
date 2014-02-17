//
//  PackListViewController.m
//  SwipeViewExample
//
//  Created by Nick Lockwood on 28/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwipeView.h"
#import "User.h"
@class Pack;

@interface PackListViewController : UIViewController <SwipeViewDelegate, SwipeViewDataSource,UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIAlertViewDelegate> {
    SwipeView *_swipeView;
    UIPageControl *_pageControl;
    
    NSInteger _packIDInMasterView;
    
    UIBarButtonItem *_editBtnItem; // "create a new pack" and "done" share this common button
    
    UIImagePickerController *_picker;
    UIPopoverController *_imagePickerPopover;
    
    Pack  *_currentPack;
    int _currentIndex;
    
    SortTypeEnum _sortTypeEnum;

}

@property (nonatomic, strong) IBOutlet SwipeView *swipeView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *userNewButton;
@property (weak, nonatomic) IBOutlet UIButton *sortedByCreatedButton;
@property (weak, nonatomic) IBOutlet UIButton *sortedByViewedButton;

@property (nonatomic, assign) NSInteger indexCurrentPack;
@property (nonatomic, assign) NSInteger packIDInMasterView;

- (IBAction)pageControlTapped;

@end
