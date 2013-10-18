//
//  UINavigationController+DismissKeyboard.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 16/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "UINavigationController+DismissKeyboard.h"

@implementation UINavigationController (DismissKeyboard)


//see background to do this:
//http://stackoverflow.com/questions/3019709/modal-dialog-does-not-dismiss-keyboard/6268520#6268520

- (BOOL)disablesAutomaticKeyboardDismissal{
    return NO;
}



#pragma mark -
#pragma mark - Rotate control

//Restrict all the Navigation controller to landscape
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotate {
    
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskLandscape;
}


@end
