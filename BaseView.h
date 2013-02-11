//
//  BaseView.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 10/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;
@class Pack;

@protocol BaseViewDelegate

- (void) save;  //save all except logo URL and Image
- (void) updatelogoURLForAllCards:(NSString *) urlString;
- (void) updatelogoImageForAllCards:(NSString *) imagePath;

@end

@interface BaseView : UIView <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate,UIAlertViewDelegate> {
    UIImageView *_logoImage;
    NSString *_logoImageFullPath;
    NSString *_logoLinkURL;
    UIButton *_logoLinkageButton;
    UILabel *_packName;
    UITextView *_subheading; // means subheading. only suitable for question
    UITextView *_main;
    UITextView *_sub;
    UITextView *_title;
    UIImageView *_image;
    NSString *_imageFullPath;
    Card *_currentCard;
    Pack *_currentPack;
    BOOL _keyboardShown;
    UIPopoverController *_imagePickerPopover;
    UIImagePickerController *_picker;
    
    BOOL _isLogoImageViewClicked;
    
    id <BaseViewDelegate> __weak _delegate;
    
    NSArray *_buttonArray;
    NSArray *_fontSizeArray;
    NSArray *_colorArray;
    NSArray *_alignArray;
    UIToolbar *_keyboardTopView;
    
    NSInteger _subheadingSize;
	NSString *_subheadingColor;
    NSString *_subheadingAlign;
    NSInteger _mainSize;
	NSString *_mainColor;
    NSString *_mainAlign;
    NSInteger _subSize;
	NSString *_subColor;
    NSString *_subAlign;
}

@property (strong, nonatomic) Card *currentCard;
@property (strong, nonatomic) Pack *currentPack;;
@property (strong, nonatomic) UIImageView *logoImage;
@property (copy, nonatomic)  NSString *logoImageFullPath;
@property (copy, nonatomic)  NSString *logoLinkURL;
@property (strong, nonatomic) UILabel *packName;
@property (strong, nonatomic) UITextView *subheading; 
@property (strong, nonatomic) UITextView *main;
@property (strong, nonatomic) UITextView *sub;
@property (strong, nonatomic) UITextView *title;
@property (strong, nonatomic) UIImageView *image;
@property (copy, nonatomic)  NSString *imageFullPath;

@property (nonatomic, assign) NSInteger subheadingSize;
@property (nonatomic, copy) NSString *subheadingColor;
@property (nonatomic, copy) NSString *subheadingAlign;
@property (nonatomic, assign) NSInteger mainSize;
@property (nonatomic, copy) NSString *mainColor;
@property (nonatomic, copy) NSString *mainAlign;
@property (nonatomic, assign) NSInteger subSize;
@property (nonatomic, copy) NSString *subColor;
@property (nonatomic, copy) NSString *subAlign;

@property (nonatomic,weak) id <BaseViewDelegate> delegate;

- (UIImage *)captureWholeViewAsImage;
- (void) updateCSS;
- (void) updateLogoStatus;

@end
