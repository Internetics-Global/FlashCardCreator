//
//  TBHDSplitViewController.h
//  taobao4iphone
//
//  Created by Xu Jiwei on 10-12-20.
//  Copyright 2010 Taobao.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TBHDShadowContentView.h"

@interface TBHDSplitViewController : TBHDViewController {
    TBHDShadowContentView       *masterViewContainer;
    TBHDShadowContentView       *detailViewContainer;
    
    NSArray                     *viewControllers;
    
    NSString                    *title;
}

+ (TBHDSplitViewController *)tbSplitViewControllerForController:(UIViewController *)controller;

@property (nonatomic, retain) NSArray *viewControllers;
@property (nonatomic, readonly) UIViewController *masterViewController;
@property (nonatomic, readonly) UIViewController *detailViewController;
@property (nonatomic, copy) NSString *title;

@end
