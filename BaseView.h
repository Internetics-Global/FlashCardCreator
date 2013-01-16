//
//  BaseView.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 10/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;


@interface BaseView : UIView <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    UIImageView *_logoImage;
    NSString *_logoImageFullPath;
    UITextView *_content;
    UITextView *_title;
    UIImageView *_image;
    NSString *_imageFullPath;
    Card *_currentCard;
    BOOL _keyboardShown;
    UIPopoverController *_imagePickerPopover;
    UIImagePickerController *_picker;
    
    BOOL _isLogoImageViewClicked;
}

@property (strong, nonatomic) Card *currentCard;
@property (strong, nonatomic) UIImageView *logoImage;
@property (copy, nonatomic)  NSString *logoImageFullPath;
@property (strong, nonatomic) UITextView *content;
@property (strong, nonatomic) UITextView *title;
@property (strong, nonatomic) UIImageView *image;
@property (copy, nonatomic)  NSString *imageFullPath;

@end
