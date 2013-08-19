//
//  FlashCard.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "EmoticonSelectionViewController.h"
#import "SimpleWebBrowserController.h"

typedef enum RescreenshotReason {
    kReasonTemplateBackgroundChangeEnum = 0,
    kReasonLogoImageChangeEnum = 1,
    kReasonQuestionTitleChangeEnum = 2,
    kReasonAnswerTitleChangeEnum = 3,
    kReasonSidebarTitleChangeEnum = 4,
    kReasonCreatorTitleChaneEnum = 5,
    
} RescreenshotReason;

typedef enum{
    KeyboardSwitchButtonTypeEmoticon, 
    KeyboardSwitchButtonTypeSystem   
} KeyboardSwitchButtonType;

@class Card;
@class Pack;
@class BadgeLabel;
@class MBProgressHUD;

@interface FlashCard : UIView <UITextViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate, UIAlertViewDelegate, UITextFieldDelegate,MFMailComposeViewControllerDelegate,EmoticonSelectionViewControllerDelegate> {
    BadgeLabel *_cardSNText;
    UIButton *_changeTemplateButton;
    
    UIImageView  *_backgroundImageView;
    NSString     *_backgroundImageName;
    UIImageView  *_logoImage;
    NSString     *_logoImageFullPath;
    NSString     *_logoLinkURL;
    UIButton     *_logoLinkageButton;
    UITextField  *_sidebarTitle;
    UITextField   *_creatorText;
    
    NSString     *_questionImageFullPath;
    NSString     *_answerImageFullPath;
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
    BOOL    _isUITextViewFocused; //used to diff better UITextView and UITextField
    BOOL    _dismissKeyboardFromEmotionSwitch;
    BOOL    _isTextFieldsChanged; // when no changes, don't need to do save operation
    BOOL    _doneButtonPressed;
    
    NSArray *_buttonArray;
    NSArray *_fontSizeArray;
    NSArray *_colorArray;
    NSArray *_alignArray;
    UIToolbar *_keyboardTopView;
    
    UIImagePickerController *_picker;
    UIPopoverController *_imagePickerPopover;
    UIPopoverController *_popoverController;
    
    MBProgressHUD *_HUD;
    
    KeyboardSwitchButtonType      _keyboardSwitchButtonType;
    
    EmoticonSelectionViewController *_emoticonSelectionViewController;
    
    UITextView   *_firstRespondTextView;
    
    NSNumber *_keyboardDuration;
    NSNumber *_keyboardCurve;
    CGFloat   _keyboardHeight;
    
    UIView  *_messageViewBackgroundView;
    
    UIBarButtonItem *_emotionButton;
    
    SimpleWebBrowserController *_webViewController;
    
}

@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, assign) BOOL isQuestionShowing;
@property (nonatomic, assign) BOOL isPlayingCard;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, strong) UITextField   *questionTitle;
@property (nonatomic, strong) UITextField   *answerTitle;

@property (nonatomic, strong) UIViewController *calledViewController;

- (BOOL) checkCardEditable;
- (void) disableCardEdit;
- (void) enableCardEdit;

- (id) initWithFrame:(CGRect)frame defaultPack:(Pack *)pack defaultCard:(Card *) card;

- (void) refreshAll;

- (void) saveEdittedCard;

- (void)segmentAction:(id)sender;

- (UIImage *)captureWholeViewAsImage;

- (void) reSceenshotAll: (RescreenshotReason) why withStringVal: (NSString *) val;  //Re-screenshot all cards under current pack

- (void) removeMessageView;
- (void) setUpMessageView;

@end
