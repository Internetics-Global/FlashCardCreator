//
//  TBHDSplitViewController.m
//  taobao4iphone
//
//  Created by Xu Jiwei on 10-12-20.
//  Copyright 2010 Taobao.com. All rights reserved.
//

#import "TBHDSplitViewController.h"

#import "TBHDMainViewController.h"

#import "TBHDControllerMap.h"
#import "TBHDViewController+Private.h"


#define kLandscapeMasterViewWidth       260.0
#define kLandscapeDetailViewWidth       690.0

#define kPortraitMasterViewWidth        291.0
#define kPortraitDetailViewWidth        768.0+20


@implementation TBHDSplitViewController

//@synthesize delegate;
@synthesize viewControllers;
@synthesize title;

#pragma mark -
#pragma mark Static

static TBHDControllerMap *splitViewControllerMap = nil;

+ (void)initialize {
    if (self == [TBHDSplitViewController class]) {
        splitViewControllerMap = [[TBHDControllerMap alloc] init];
    }
}

+ (TBHDSplitViewController *)tbSplitViewControllerForController:(UIViewController *)controller {
    return [splitViewControllerMap objectForKey:controller];
}

#pragma mark -
#pragma mark Properties

- (void)setViewControllers:(NSArray *)arr {
    if (arr != viewControllers) {
        UIViewController* newMasterViewController = [arr objectAtIndex:0];
        UIViewController* newDetailViewController = [arr objectAtIndex:1];
        BOOL isMasterChanged = newMasterViewController != self.masterViewController;
        BOOL isDetailChanged = newDetailViewController != self.detailViewController;
        
        // 替换Content view   
        if (isMasterChanged) {
            [self.masterViewController viewWillDisappear:NO];
            [masterViewContainer setContentView:newMasterViewController.view];
            [self.masterViewController viewDidDisappear:NO];
            [newMasterViewController viewWillAppear:NO];
        }
        if (isDetailChanged) {
            [self.detailViewController viewWillDisappear:NO];
            [detailViewContainer setContentView:newDetailViewController.view];
            [self.detailViewController viewDidDisappear:NO];
            [newDetailViewController viewWillAppear:NO];
        }
        
        // 设置对应关系
        for (UIViewController *controller in viewControllers) {         
            [splitViewControllerMap removeObjectForKey:controller];
            [controller tbHDViewController].tbSplitViewController = nil;
        }
        for (UIViewController *controller in arr) {
            [splitViewControllerMap setObject:self forKey:controller];
            [controller tbHDViewController].tbSplitViewController = self;
        }
        [arr retain];
        [viewControllers release];
        viewControllers = arr;
    }
}

- (UIViewController *)masterViewController {
    return [viewControllers objectAtIndex:0];
}

- (UIViewController *)detailViewController {
    return [viewControllers objectAtIndex:1];
}

#pragma mark -
#pragma mark View lifecycle

- (void)setFrameOfViewControllersForOrintation:(UIInterfaceOrientation)orientation {
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        // 横屏
        masterViewContainer.alpha = 1.0;
        masterViewContainer.frame = CGRectMake(-6, -3, kLandscapeMasterViewWidth+2+12, 705);
        detailViewContainer.frame = CGRectMake(kLandscapeMasterViewWidth-1-6, -8, kLandscapeDetailViewWidth+12, 710);
        
    } else {
        // 坚屏
        masterViewContainer.alpha = 0.0;
        masterViewContainer.frame = CGRectMake(-8-291, 0, 291, 702);
        detailViewContainer.frame = CGRectMake(-8, -8, 788, 1024-20-54-75+16);
    }
    
    [masterViewContainer layoutSubviews];
    [detailViewContainer layoutSubviews];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    NSLog(@"%s",__FUNCTION__);
    [super viewDidLoad];
    
    masterViewContainer = [[TBHDShadowContentView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:masterViewContainer];
    
    detailViewContainer = [[TBHDShadowContentView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:detailViewContainer];
    
    [self setFrameOfViewControllersForOrintation:[TBHDMainViewController interfaceOrientation]];
    
    UIViewController *controller = [viewControllers objectAtIndex:0];
    masterViewContainer.contentView = controller.view;
    
    controller = [viewControllers objectAtIndex:1];
    detailViewContainer.contentView = controller.view;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setFrameOfViewControllersForOrintation:[TBHDMainViewController interfaceOrientation]];
    
    for (UIViewController *viewController in viewControllers) {
        [viewController viewWillAppear:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated]; 
    
    for (UIViewController* viewController in viewControllers) {
        [viewController viewWillDisappear:animated];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [self setFrameOfViewControllersForOrintation:toInterfaceOrientation];
    for (UIViewController* viewController in viewControllers) {
        [viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    [UIView commitAnimations];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return SHOULD_ROTATE_TO_INTERFACE_ORIENTATION(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    NSLog(@"%s",__FUNCTION__);
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    NSLog(@"%s",__FUNCTION__);
    TB_RELEASE(masterViewContainer);
    TB_RELEASE(detailViewContainer);

    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)hasViewBorderShadow {
    return YES;
}

- (void)dealloc {
    NSLog(@"%s",__FUNCTION__);
    for (UIViewController *controller in viewControllers) {
        [splitViewControllerMap removeObjectForKey:controller];
    }
    TB_RELEASE(title);
    TB_RELEASE(viewControllers);
    TB_RELEASE(masterViewContainer);
    TB_RELEASE(detailViewContainer);
    
    [super dealloc];
}


@end
