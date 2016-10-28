//
//  UIView+FindUIViewController.m
//  FlashCardCreator
//
//  Created by internetics on 28/10/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "UIView+FindUIViewController.h"
#import "PlayViewControllerV2.h"


@implementation UIView (FindUIViewController)
- (UIViewController *) firstAvailableUIViewController {
    // convenience function for casting and to "mask" the recursive function
    return (UIViewController *)[self traverseResponderChainForUIViewController];
}

- (PlayViewControllerV2 *) findPlayViewControllerV2 {
    // convenience function for casting and to "mask" the recursive function
    return (PlayViewControllerV2 *)[self traverseResponderChainForPlayViewControllerV2];
}

- (id) traverseResponderChainForUIViewController {
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder traverseResponderChainForUIViewController];
    } else {
        return nil;
    }
}

- (id) traverseResponderChainForPlayViewControllerV2 {
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[PlayViewControllerV2 class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder traverseResponderChainForPlayViewControllerV2];
    } else {
        return nil;
    }
}

@end
