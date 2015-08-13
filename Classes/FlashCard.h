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

#import <MediaPlayer/MediaPlayer.h>

#import <AVFoundation/AVFoundation.h>
#import "PopoverView.h"

typedef enum RescreenshotReason {
    kReasonTemplateBackgroundChangeEnum = 0,
    kReasonLogoImageChangeEnum = 1,
    kReasonQuestionTitleChangeEnum = 2,
    kReasonAnswerTitleChangeEnum = 3,
    kReasonSidebarTitleChangeEnum = 4,
    kReasonCreatorTitleChaneEnum = 5,
    kReasonJobTitleChaneEnum = 6,
    
} RescreenshotReason;

typedef enum{
    KeyboardSwitchButtonTypeEmoticon, 
    KeyboardSwitchButtonTypeSystem   
} KeyboardSwitchButtonType;

@class Card;
@class Pack;
@class MBProgressHUD;
@class JSBadgeView;

@interface FlashCard : UIView <UITextViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate, UIAlertViewDelegate, UITextFieldDelegate,MFMailComposeViewControllerDelegate,EmoticonSelectionViewControllerDelegate,UIPopoverControllerDelegate,AVAudioPlayerDelegate,PopoverViewDelegate,AVSpeechSynthesizerDelegate> {
    JSBadgeView *_cardSNText;
    
    //sound record related
    /**
     *  需要非常清楚的是，有两种情况，一种是youtube，一种是本地链接，这两种情况在interchangeability中非常不一样，前者可以直接赋值，后者需要记性lastPathComponent处理
     */
    NSString     *_questionRecordedSoundFullPath;
    
    /**
     *  需要非常清楚的是，有两种情况，一种是youtube，一种是本地链接，这两种情况在interchangeability中非常不一样，前者可以直接赋值，后者需要记性lastPathComponent处理
    */
    NSString     *_answerRecordedSoundFullPath;
    
    //background related
    UIButton     *_backgroundImageSelectButton;
    UIImageView  *_questionBackgroundImageView; //允许随便从library选择
    UIImageView  *_answerBackgroundImageView;//允许随便从library选择
    NSString     *_questionBackgroundImageFullPath;
    NSString     *_answerBackgroundImageFullPath;
    
    //template related
    UIButton     *_changeTemplateButton;
    UIImageView  *_templateBackgroundImageView; //存在于NSBundle,不允许随便从library选择
    NSString     *_templateBackgroundImageName;
    
    
    UIImageView  *_logoImage;
    NSString     *_logoImageFullPath;
    NSString     *_logoLinkURL;
    UIButton     *_logoLinkageButton;
    UITextField  *_sidebarTitle;
    UITextField   *_creatorText;
    UITextField   *_jobTitleText;
    
    //movie played related
    NSString     *_questionMovieFullPath;//youtube linkage or an local url
    NSString     *_questionMovieFullPath2;//youtube linkage or an local url
    NSString     *_answerMovieFullPath; //youtube linkage or an local url
    NSString     *_answerMovieFullPath2; //youtube linkage or an local url
    
    //image or thubmnail(video)
    NSString     *_questionImageFullPath; //如果播放的是mov，则是Mov的thumbnail
    NSString     *_questionImageFullPath2; //如果播放的是mov，则是Mov的thumbnail
    NSString     *_answerImageFullPath; //如果播放的是mov，则是Mov的thumbnail
    NSString     *_answerImageFullPath2; //如果播放的是mov，则是Mov的thumbnail
    
    UIScrollView *_verticalScrollView;
    
    
    UITextView   *_subheadingQuestion;
    UITextView   *_mainQuestion;
    UITextView   *_subQuestion;
    UIImageView  *_imageQuestion;
    UIImageView  *_imageQuestion2;
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
    UIImageView  *_imageAnswer2;
    NSInteger    _subheadingSizeAnswer;
	NSString     *_subheadingColorAnswer;
    NSString     *_subheadingAlignAnswer;
    NSInteger    _mainSizeAnswer;
	NSString     *_mainColorAnswer;
    NSString     *_mainAlignAnswer;
    NSInteger    _subSizeAnswer;
	NSString     *_subColorAnswer;
    NSString     *_subAlignAnswer;
    
    NSString     *_subheadingFontAnswer;
    NSString     *_subheadingFontQuestion;
    NSString     *_mainFontAnswer;
    NSString     *_mainFontQuestion;
    NSString     *_subFontAnswer;
    NSString     *_subFontQuestion;
    
    NSString     *_subheadingAlignVerticalQuestion;
    NSString     *_mainAlignVerticalQuestion;
    NSString     *_subAlignVerticalQuestion;
    NSString     *_subheadingAlignVerticalAnswer;
    NSString     *_mainAlignVerticalAnswer;
    NSString     *_subAlignVerticalAnswer;
    
    
    
    NSMutableDictionary *_qDict;
    NSMutableDictionary *_aDict;
    
    BOOL    _keyboardShown;
    BOOL    _isAllCardsLogoNeedToBeUpdate;
    BOOL    _dismissKeyboardFromEmotionSwitch;
    BOOL    _isTextFieldsChanged; // when no changes, don't need to do save operation
    BOOL    _saveButtonPressed;
    
    //keyboard related
    
    UIView                             *_keyboardInputBaseView; //for input view
    KeyboardSwitchButtonType            _keyboardSwitchButtonType;
    EmoticonSelectionViewController    *_emoticonSelectionViewController;
    CGFloat                             _keyboardHeight;
    UIBarButtonItem                    *_emotionButton;
    UIBarButtonItem                    *_emotionButtonForInputView;
    
    UIImagePickerController *_imagePickerController;
    UIPopoverController *_imagePickerPopover;
    UIPopoverController *_selectTemplatePopoverController;
    
    MBProgressHUD *_HUD;
    
    //when use, please use together
    UITextView   *_lastBecomeFirstRespondTextView; //
    BOOL          _isUITextViewFocused; //used to diff better UITextView and UITextField
}

@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, strong) Pack *currentPack;

@property (nonatomic, assign) BOOL isPlayingCard;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, assign) BOOL isMuteText2Speech; //if YES, still text to speech but mute

@property (nonatomic, strong) UIView *functionAreaView;

@property (nonatomic, strong) UITextField   *questionTitle;
@property (nonatomic, strong) UITextField   *answerTitle;

@property (nonatomic, weak) UIViewController *calledViewController;

- (BOOL) checkCardEditable;
- (void) disableCardEdit;
- (void) enableCardEdit;

- (id) initWithFrame:(CGRect)frame defaultPack:(Pack *)pack defaultCard:(Card *) card;
- (id)initWithFrame:(CGRect)frame defaultPack:(Pack *)pack defaultCard:(Card *) card isPlayingCard:(BOOL)isPlayingCard;

- (void) refreshAll;
- (void) refreshAll:(BOOL) isDisableAutoResize withIndexPlaying: (int) indexPlaying;

/**
 *  执行两个动作：
 *  1. commit所有相关的值到_currentCard
 *  2. 写入到数据库
 */
- (void) saveEdittedCard;

- (void)segmentedControlQAClicked:(id)sender;

- (UIImage *)captureWholeViewAsImage;

- (void) reSceenshotAll: (RescreenshotReason) why withStringVal: (NSString *) val;  //Re-screenshot all cards under current pack

/**
 *  @param isMute          只是用来set volume = 0
 */
- (void) playAudioWithManualClick:(BOOL) isManualClicked withMute:(BOOL)isMute;

- (void) stopAudio;
- (void) muteAudio;
- (void) unMuteAudio;

- (void) textToSpeechAllContentNow;
- (void) stopTextToSpeechNow;
- (BOOL) isTextToSpeeching;

- (void) updateQuestionAnswerAllTextViewVeriticalAlignment;

- (BOOL) isQuestionShowing;

- (float) durationForQuestionRecordedSound;
- (float) durationForAnswerRecordedSound;

@end
