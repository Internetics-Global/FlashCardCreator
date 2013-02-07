//
//  BaseView.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 10/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;

@protocol BaseViewDelegate

- (void) save;

@end

@interface BaseView : UIView <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    UIImageView *_logoImage;
    NSString *_logoImageFullPath;
    UITextView *_type; // only suitable for question
    UITextView *_summary;
    UITextView *_detail;
    UITextView *_title;
    UIImageView *_image;
    NSString *_imageFullPath;
    Card *_currentCard;
    BOOL _keyboardShown;
    UIPopoverController *_imagePickerPopover;
    UIImagePickerController *_picker;
    
    BOOL _isLogoImageViewClicked;
    
    id <BaseViewDelegate> __weak _delegate;
}

@property (strong, nonatomic) Card *currentCard;
@property (strong, nonatomic) UIImageView *logoImage;
@property (copy, nonatomic)  NSString *logoImageFullPath;
@property (strong, nonatomic) UITextView *type; 
@property (strong, nonatomic) UITextView *summary;
@property (strong, nonatomic) UITextView *detail;
@property (strong, nonatomic) UITextView *title;
@property (strong, nonatomic) UIImageView *image;
@property (copy, nonatomic)  NSString *imageFullPath;

@property (nonatomic,weak) id <BaseViewDelegate> delegate;

- (UIImage *)captureWholeViewAsImage;

@end
