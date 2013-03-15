//
//  FlashCard.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum RescreenshotReason {
    kReasonTemplateBackgroundChangeEnum = 0,
    kReasonLogoImageChangeEnum = 1,
    
} RescreenshotReason;

@class Card;
@class Pack;
@class BadgeLabel;

@interface FlashCard : UIView <UITextViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate, UIAlertViewDelegate> {
    BadgeLabel *_cardSNText;
    UIButton *_changeTemplateButton;
    
    UIImageView  *_backgroundImageView;
    NSString     *_backgroundImageName;
    UIImageView  *_logoImage;
    NSString     *_logoImageFullPath;
    NSString     *_logoLinkURL;
    UIButton     *_logoLinkageButton;
    UILabel      *_packName;
    UITextView   *_subheading; // means subheading. only suitable for question
    UITextView   *_main;
    UITextView   *_sub;
    UITextView   *_title;
    UIImageView  *_image;
    NSString     *_imageFullPath;
    UIScrollView *_verticalScrollView;
    
    NSInteger _subheadingSize;
	NSString  *_subheadingColor;
    NSString  *_subheadingAlign;
    NSInteger _mainSize;
	NSString  *_mainColor;
    NSString  *_mainAlign;
    NSInteger _subSize;
	NSString  *_subColor;
    NSString  *_subAlign;
    
    BOOL    _isLogoImageViewClicked;
    BOOL    _keyboardShown;
    BOOL    _isAllCardsLogoNeedToBeUpdate;
    NSArray *_buttonArray;
    NSArray *_fontSizeArray;
    NSArray *_colorArray;
    NSArray *_alignArray;
    UIToolbar *_keyboardTopView;
    CGFloat _keyboardHeight;
    
    UIImagePickerController *_picker;
    UIPopoverController *_imagePickerPopover;
    UIPopoverController *_popoverController;
}

@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, assign) BOOL isQuestionShowing;
@property (nonatomic, strong)  UISegmentedControl *segmentedControl;;


- (void) checkCardEditable;
- (void) disableCardEdit;
- (void) enableCardEdit;

- (id)initWithFrame:(CGRect)frame defaultPack:(Pack *)pack defaultCard:(Card *) card;

- (void) refreshAll;

- (void) saveEdittedCard;

- (void) doAnswerData;
- (void) doQuestionData;

- (void)segmentAction:(id)sender;

- (UIImage *)captureWholeViewAsImage;

- (void) reSceenshotAll: (RescreenshotReason) why stringVal: (NSString *) val;  //Re-screenshot all cards under current pack

@end
