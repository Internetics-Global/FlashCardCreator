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
    
    
    UITextView   *_title;
    NSString     *_imageFullPath;
    UIScrollView *_verticalScrollView;
    
    UITextView   *_subheadingQuestion;
    UITextView   *_mainQuestion;
    UITextView   *_subQuestion;
    UIImageView  *_imageQuestion;
    NSInteger    _subheadingSizeQuestion;
	NSString     *_subheadingColorQuestion;
    NSString     *_subheadingAlignQuestion;
    NSInteger    _mainSizeQuestion;
	NSString     *_mainColorQuestion;
    NSString     *_mainAlignQuestion;
    NSInteger    _subSizeQuestion;
	NSString     *_subColorQuestion;
    NSString     *_subAlignQuestion;
    
    UITextView   *_subheadingAnswer;
    UITextView   *_mainAnswer;
    UITextView   *_subAnswer;
    UIImageView  *_imageAnswer;
    NSInteger    _subheadingSizeAnswer;
	NSString     *_subheadingColorAnswer;
    NSString     *_subheadingAlignAnswer;
    NSInteger    _mainSizeAnswer;
	NSString     *_mainColorAnswer;
    NSString     *_mainAlignAnswer;
    NSInteger    _subSizeAnswer;
	NSString     *_subColorAnswer;
    NSString     *_subAlignAnswer;
    
    NSMutableDictionary *_qDict;
    NSMutableDictionary *_aDict;
    
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
@property (nonatomic, strong) UISegmentedControl *segmentedControl;;


- (BOOL) checkCardEditable;
- (void) disableCardEdit;
- (void) enableCardEdit;

- (id) initWithFrame:(CGRect)frame defaultPack:(Pack *)pack defaultCard:(Card *) card;

- (void) refreshAll;

- (void) saveEdittedCard;

- (void)segmentAction:(id)sender;

- (UIImage *)captureWholeViewAsImage;

- (void) reSceenshotAll: (RescreenshotReason) why stringVal: (NSString *) val;  //Re-screenshot all cards under current pack

@end
