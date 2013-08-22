//
//  PackListViewController.m
//  SwipeViewExample
//
//  Created by Nick Lockwood on 28/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwipeView.h"

@class Pack;

@interface PackListViewController : UIViewController <SwipeViewDelegate, SwipeViewDataSource,UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIAlertViewDelegate> {
    SwipeView *_swipeView;
    UIPageControl *_pageControl;
    NSMutableArray *_packArray;
    
    NSInteger _packIDInMasterView;
    BOOL _hideDeleteButton;
    
    UIBarButtonItem *_editBtnItem;
    
    UIImagePickerController *_picker;
    UIPopoverController *_imagePickerPopover;
    
    Pack  *_currentPack;
    
    int _currentIndex;
}

@property (nonatomic, strong) IBOutlet SwipeView *swipeView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) NSMutableArray *packArray;
@property (nonatomic, assign) NSInteger indexCurrentPack;
@property (nonatomic, assign) NSInteger packIDInMasterView;

- (IBAction)pageControlTapped;

@end
