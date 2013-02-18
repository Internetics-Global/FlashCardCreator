//
//  CreatePackViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 15/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Pack;
@class PackListViewController;

@interface CreatePackViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    UITextField *_packNameText;
    UIImageView *_coverImageView;
    UIPopoverController *_imagePickerPopover;
    UIImagePickerController *_picker;
    
    Pack *_newPack;
}

@end
