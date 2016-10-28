//
//  UIView+FindUIViewController.h
//  FlashCardCreator
//
//  Created by internetics on 28/10/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlayViewControllerV2;

@interface UIView (FindUIViewController)
- (UIViewController *) firstAvailableUIViewController;
- (PlayViewControllerV2 *) findPlayViewControllerV2;
@end
