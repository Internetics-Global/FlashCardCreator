//
//  UIImagePickerController+NoRotate.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 15/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "UIImagePickerController+NoRotate.h"

@implementation UIImagePickerController (NoRotate)


//See the background for doing this
//http://stackoverflow.com/questions/12540597/supported-orientations-has-no-common-orientation-with-the-application-and-shoul

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end
