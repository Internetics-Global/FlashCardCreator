//
//  CreatePackViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 15/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Pack;
@class PackListViewControllerV2;

@interface CreatePackViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    UITextField *_packNameText;
    UITextField *_sidebarTitle;
    UIImageView *_coverImageView;
    UITextField *_creatorText;
    UIPopoverController *_imagePickerPopover;
    UIImagePickerController *_picker;
    
    Pack *_newPack;
}

@end
