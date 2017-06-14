//
//  FlashCard.m
//  FFC
//
//  Created by Wang Bourne on 13/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

/* 一些重要的说明 （区别于已存在card的情况）
 * 1. 保存操作是写入到数据库，即[_currentCard save]
 * 2. 我们数据的参考对象是_currentCard，而不是界面上的view，所有要确保他们之间一致（a, 初始化时保持一致;b,view内容变化时，要及时更新_currentCard）
 */


#import "FlashCard.h"
#import "JSBadgeView.h"
#import "Pack.h"
#import "Question.h"
#import "Answer.h"
#import "Card.h"
#import "CSS.h"
#import "SimpleWebBrowserController.h"
#import "FileOperationHelper.h"
#import "UIImage+Scale.h"
#import "SelectTemplateTableViewController.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "EmoticonSelectionViewController.h"
#import "EmoticonHelper.h"
#import "Emoticon.h"
#import <AVFoundation/AVFoundation.h>
 #import <Photos/Photos.h>

#import "CreateSoundViewController.h"

#import "OpenUDID.h"

#import "KeyboardTopView.h"

#import "PECropViewController.h"

#import "AMPopTip.h"

#import "TipHelper.h"

#import "iConsole.h"

#import "UIButton+Extensions.h"

#import "DACircularProgressView.h"

#import "NSTimer+BlocksKit.h"

#import <BlocksKit/UIAlertView+BlocksKit.h>

#import "UIImageView+Extensions.h"

#import "UITextField+AutoResizeFont.h"

#import "MutipleTargetHelper.h"

#import "FLAnimatedImage.h"

#import "MultimediaView.h"
#import "MultimediaView+Extensions.h"

#import "UIView+FindUIViewController.h"

#import "SIAlertView.h"

#import "CreateCardViewController.h"

#import "Text2SpeechHelper.h"

extern BOOL isFromNewCreatedCard;

#define kSegmentLeftMarginForiPad 0.0
#define kQuestionViewTopMarginForiPad 10.0
#define kQuestionViewButtomMarginForiPad 80.0
#define kQuestionViewCornerRadiusForiPad 20.0

#define kSegmentLeftMarginForiPhone 0.0


#define kQuestionViewTopMarginForiPhone 5.0
#define kQuestionViewButtomMarginForiPhone 40.0
#define kQuestionViewCornerRadiusForiPhone 9.0


#define kTagSubheadingQuestion    100
#define kTagMainQuestion          101
#define kTagSubQuestion           102
#define kTagSubheadingAnswer      200
#define kTagMainAnswer            201
#define kTagSubAnswer             202

#define kTagTitleQuestion         301
#define kTagTitleAnser            302
#define kTagSidebar               303
#define kTagCreator               304
#define kTagJobTitle              305

#define k_Scale                   3.0

/**
 *  compared with edit mode, we make the play card bigger, so we need a compensation
 */
#define k_Y_Delta_For_Play          10.0
#define k_X_Delta_For_Play          5

#define KEYBOARD_ANIMATION_DURATION 0.25

typedef NS_ENUM(NSInteger, Resize_Accuracy_Type) {
    Resize_Accuracy_Type_Low,
    Resize_Accuracy_Type_High,
    Resize_Accuracy_Type_Extreme
};


typedef NS_ENUM(NSInteger, Type_Image_Source) {
    Type_Image_Source_Logo       = 0,//when clicking the logo
    Type_Image_Source_Image      = 1,//when clicking the image from card
    Type_Image_Source_Image2      = 3,//when clicking the image2 from card
    Type_Image_Source_Background = 2,//when trying to change card's background image (not template)
    Type_Image_Source_Unkown     = -1,
};

typedef NS_ENUM(NSInteger, Type_AlertView) {
    Type_AlertView_Unkown   = -1,
    Type_AlertView_LogoURL  = 0,
    Type_AlertView_VideoURL = 1,
    Type_AlertView_VideoURL2 = 3, //for image2
    Type_AlertView_BackgroundImage_Crop_Size = 2,
};

typedef NS_ENUM(NSInteger, Type_PopoverView) {
    Type_PopoverView_Unkown           = -1,
    Type_PopoverView_SelectImage      = 1,
    Type_PopoverView_SelectImage2      = 3,
    Type_PopoverView_SelectBackground = 2,
};



@interface FlashCard () <KeyboardTopViewDelegate,PECropViewControllerDelegate> {
    Type_Image_Source    _imageSourceType;
    AVAudioPlayer          *_audioPlayer;
    
    //_keyboardTopViewV2和_keyboardTopViewForInputViewV2内容一样的两份拷贝，
    //其中_keyboardTopViewV2是为setInputAccessoryView,而_keyboardTopViewForInputViewV2则是inputView的一部分
    KeyboardTopView        *_keyboardTopViewV2;
    KeyboardTopView        *_keyboardTopViewForInputViewV2;
    
    NSMutableArray         *_textToSpeechArray;
    
    UIButton                             *_recordingStopButton;
    UIButton                             *_recordingBackgroundMaskView;
    DACircularProgressView               *_recordingProgressView;
    NSTimer                              *_recordCountDownTimer;
    
    BOOL                                  flag_Subheading_ResizeFinished;
    BOOL                                  flag_Main_ResizeFinished;
    BOOL                                  flag_Sub_ResizeFinished;
    
    /**
     *  two cases to diff dismiss keyboard:
     *  by clicking "save" button on keyboard
     *  by click the built-in "hide" button on keyboard
     */
    BOOL                                 *_isDismissKeyboardViaSaveButtonFromKeyboard;
    
    
    FLAnimatedImageView                  *_fingerAnimationGifImageView;
    
}


@property (strong, nonatomic) UIButton *soundButton;
@property (strong, nonatomic) UIButton *muteButton;

/**
 *  Text to Speech function
 */
@property (strong, nonatomic) AVSpeechSynthesizer *synth;
@property (assign, nonatomic) int textToSpeechContentArrayIndex;

/**
 *  比较特殊，由于vertical alignment是通过改变contentOffset实现的，我们特地设立了这个值。
 */
@property (assign, nonatomic) CGFloat contentYOffsetForVerticalAlignment;


@end

@implementation FlashCard

- (id)initWithFrame:(CGRect)frame defaultPack:(Pack *)pack defaultCard:(Card *) card  {
    return [self initWithFrame:frame defaultPack:pack defaultCard:card isPlayingCard:NO];
}

- (id)initWithFrame:(CGRect)frame defaultPack:(Pack *)pack defaultCard:(Card *) card isPlayingCard:(BOOL)isPlayingCard
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(templateSelectedNotification:) name:TEMPLATE_SELECTED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasHidden:)
                                                     name:UIKeyboardDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(createSoundViewControllerDimissed_Notification:)
                                                     name:@"K_CreateSoundViewController_Dimissed_Notification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTooltipNotification:) name:SHOW_TOOLTIPS_NOTIFICATION object:nil];
        
        
        if ((card == nil) || (pack == nil)) {
            //[iConsole info:@"%s:Check your code, it could be possiblly an issue",__FUNCTION__];
        }
        
        self.isPlayingCard = isPlayingCard;
        self.currentPack = pack;
        self.currentCard = card;
        
        if (isUserInterfaceIdiomPhone) {
            [self loadQuestionAnswerViewForiPhone];
        } else {
            [self loadQuestionAnswerViewForiPad];
        }
        
        _fingerAnimationGifImageView = [[FLAnimatedImageView alloc] init];
        if (isUserInterfaceIdiomPhone) {
            _fingerAnimationGifImageView.frame = CGRectMake(CGRectGetWidth(self.frame)/2-50, CGRectGetHeight(self.frame)-120, 120, 120);
        } else {
            _fingerAnimationGifImageView.frame = CGRectMake(CGRectGetWidth(self.frame)/2-130, CGRectGetHeight(self.frame)-300, 260, 260);
        }
        
        //_fingerAnimationGifImageView.backgroundColor = [UIColor redColor];
        
        _fingerAnimationGifImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _fingerAnimationGifImageView.contentMode = UIViewContentModeScaleAspectFit;
        _fingerAnimationGifImageView.clipsToBounds = YES;
        _fingerAnimationGifImageView.isAllowAutoPlayWhenVisible = true;
        _fingerAnimationGifImageView.animationRepeatCount = 1;
        [self addSubview:_fingerAnimationGifImageView];
        
        [self initDefaultValue];
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            [self setupTextToSpeech];
        }
        
    }
    
    
    return self;
}



- (void) hideTransparentFullScreenView {
    
    _fingerAnimationGifImageView.animatedImage = nil;
    [_fingerAnimationGifImageView stopAnimating];
    
    _fingerAnimationGifImageView.hidden = true;
}

- (BOOL) isAllowShowTransparentFullScreenView {
    
    if (_isPlayingCard == false) {
        return false;
    }
    
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isFunctionPromptOff"];
    return b == false;
    
}

- (void) showTransparentFullScreenView {
    
    if ([self isAllowShowTransparentFullScreenView] == false) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    _fingerAnimationGifImageView.hidden = false;
    
    NSString *gif;
    if (_segmentedControl.selectedSegmentIndex == 0) {
        gif = @"question-gif";
    } else {
        gif = @"answer-gif";
    }
    
    NSString *gifPath =[[NSBundle mainBundle] pathForResource:gif ofType:@"gif"];
    _fingerAnimationGifImageView.animatedImage = [FLAnimatedImage animatedImageWithGIFData:[NSData dataWithContentsOfFile:gifPath]];
    _fingerAnimationGifImageView.loopCompletionBlock = ^(NSUInteger loopCountRemaining){
        [weakSelf hideTransparentFullScreenView];
    };
    
}

- (void) initDefaultValue {
    [iConsole info:@"%s",__FUNCTION__];
    _isUITextViewFocused = NO;
    
    _isAllCardsNeedToBeUpdateForNewCardOnly = NO;
    _isTextFieldsChanged = NO;
    _saveButtonPressed = NO;
    _templateBackgroundImageName = @"card_background_blue.png";
    _logoLinkURL = @"http://www.";
    _logoImageFullPath = @"";
    
    _subheadingSizeQuestion = 40;
    _subheadingColorQuestion = @"Black";
    _subheadingAlignQuestion = @"Right";
    _subheadingAlignVerticalQuestion = @"";
    _subheadingText2SpeechQuestion = @"";
    _mainSizeQuestion = 40;
    _mainColorQuestion = @"Black";
    _mainAlignQuestion = @"Center";
    _mainAlignVerticalQuestion = @"";
    _mainText2SpeechQuestion = @"";
    _subSizeQuestion = 40;
    _subColorQuestion = @"Black";
    _subAlignQuestion = @"Center";
    _subAlignVerticalQuestion = @"";
    _subText2SpeechQuestion = @"";
    
    _subheadingSizeAnswer = 40;
    _subheadingColorAnswer = @"Black";
    _subheadingAlignAnswer = @"Right";
    _subheadingAlignVerticalAnswer = @"";
    _subheadingText2SpeechAnswer = @"";
    _mainSizeAnswer = 40;
    _mainColorAnswer = @"Black";
    _mainAlignAnswer = @"Center";
    _mainAlignVerticalAnswer = @"";
    _mainText2SpeechAnswer = @"";
    _subSizeAnswer = 40;
    _subColorAnswer = @"Black";
    _subAlignAnswer = @"Center";
    _subAlignVerticalAnswer = @"";
    _subText2SpeechAnswer = @"";
    
    _keyboardShown = FALSE;
    
    //background image
    _questionBackgroundImageFullPath = @"";
    _answerBackgroundImageFullPath = @"";
    
    //movie or video
    _answerMovieFullPath = @"";
    _answerMovieFullPath2 = @"";
    _questionMovieFullPath = @"";
    _questionMovieFullPath2 = @"";
    
    //audio
    _answerRecordedSoundFullPath = @"";
    _questionRecordedSoundFullPath = @"";
    
    //font
    _subheadingFontAnswer = @"";
    _subheadingFontQuestion = @"";
    _mainFontAnswer = @"";
    _mainFontQuestion = @"";
    _subFontAnswer = @"";
    _subFontQuestion = @"";
    
    _isDismissKeyboardViaSaveButtonFromKeyboard = false;
    
    [self setUpInputView];
    [self setUpInputAccessoryView];
    
    _keyboardSwitchButtonType = KeyboardSwitchButtonTypeSystem;
    
    self.backgroundColor = [UIColor clearColor];
    
}



#pragma mark -
#pragma mark - Layout view

- (void) loadQuestionAnswerViewForiPad {
    [iConsole info:@"%s",__FUNCTION__];
    if (_templateBackgroundImageView == nil) {
        if (_templateBackgroundImageName) {
           _templateBackgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:_templateBackgroundImageName]];
        } else {
            _templateBackgroundImageView = [[UIImageView alloc] init];
        }
        
        _templateBackgroundImageView.contentMode = UIViewContentModeScaleToFill;
        _templateBackgroundImageView.frame = CGRectMake(0, 0, 800, kFlashCardViewHeight_Detail_iPad_Pure);
        _templateBackgroundImageView.backgroundColor = [UIColor clearColor];
        _templateBackgroundImageView.userInteractionEnabled = NO;
        _templateBackgroundImageView.layer.masksToBounds = YES;
        _templateBackgroundImageView.layer.cornerRadius = 35;
        [self addSubview:_templateBackgroundImageView];
    }
    
    
    if (_questionBackgroundImageView == nil) {
        _questionBackgroundImageView = [[UIImageView alloc] init];
        _questionBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _questionBackgroundImageView.frame = CGRectMake(kFlashCardViewSidebarWidth_Detail_iPad, kFlashCardViewHeaderHeight_Detail_iPad, CGRectGetWidth(_templateBackgroundImageView.frame) - kFlashCardViewSidebarWidth_Detail_iPad, CGRectGetHeight(_templateBackgroundImageView.frame) - kFlashCardViewHeaderHeight_Detail_iPad);
        _questionBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _questionBackgroundImageView.backgroundColor = [UIColor whiteColor];
        _questionBackgroundImageView.userInteractionEnabled = NO;
        _questionBackgroundImageView.layer.masksToBounds = YES;
        
        CAShapeLayer *styleLayer = [CAShapeLayer layer];
        
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:_questionBackgroundImageView.bounds byRoundingCorners:(UIRectCornerBottomRight) cornerRadii:CGSizeMake(35, 35.0)];
        
        styleLayer.path = shadowPath.CGPath;
        
        _questionBackgroundImageView.layer.mask = styleLayer;
        
        
        [self addSubview:_questionBackgroundImageView];
        [self bringSubviewToFront:_templateBackgroundImageView];
    }
    
    
    
    if (_answerBackgroundImageView == nil) {
        _answerBackgroundImageView = [[UIImageView alloc] init];
        _answerBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _answerBackgroundImageView.frame = CGRectMake(kFlashCardViewSidebarWidth_Detail_iPad, kFlashCardViewHeaderHeight_Detail_iPad, CGRectGetWidth(_templateBackgroundImageView.frame) - kFlashCardViewSidebarWidth_Detail_iPad, CGRectGetHeight(_templateBackgroundImageView.frame) - kFlashCardViewHeaderHeight_Detail_iPad);;
        _answerBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _answerBackgroundImageView.backgroundColor = [UIColor whiteColor];
        _answerBackgroundImageView.userInteractionEnabled = NO;
        _answerBackgroundImageView.layer.masksToBounds = YES;
        CAShapeLayer * maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: _answerBackgroundImageView.bounds byRoundingCorners: UIRectCornerBottomRight cornerRadii: (CGSize){35, 35.}].CGPath;
        _answerBackgroundImageView.layer.mask = maskLayer;
        [self addSubview:_answerBackgroundImageView];
        [self bringSubviewToFront:_templateBackgroundImageView];
    }
    
    if (_questionTitle == nil) {
        _questionTitle = [[UITextField alloc]init];
        _questionTitle.frame = CGRectMake(81, 60, 400, 52);
        _questionTitle.backgroundColor = [UIColor clearColor];
        _questionTitle.font =[UIFont systemFontOfSize:40];
        _questionTitle.textAlignment = NSTextAlignmentLeft;
        _questionTitle.text =NSLocalizedString(@"ToolbarItem_Question",nil);
        _questionTitle.userInteractionEnabled = FALSE;
        _questionTitle.layer.shadowColor = [[UIColor whiteColor] CGColor];
        _questionTitle.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        _questionTitle.layer.shadowOpacity = 1.0f;
        _questionTitle.layer.shadowRadius = 4.5f;
        _questionTitle.layer.masksToBounds = NO;
        _questionTitle.textColor = [UIColor blueColor];
        _questionTitle.delegate = self;
        _questionTitle.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _questionTitle.keyboardType = UIKeyboardAppearanceDefault;
        _questionTitle.returnKeyType = UIReturnKeyDone;
        _questionTitle.tag = kTagTitleQuestion;
        [self addSubview:_questionTitle];
    }
    
    
    if (_answerTitle == nil) {
        _answerTitle = [[UITextField alloc]init];
        _answerTitle.frame = CGRectMake(81, 60, 400, 52);
        _answerTitle.backgroundColor = [UIColor clearColor];
        _answerTitle.font =[UIFont systemFontOfSize:40];
        _answerTitle.textAlignment = NSTextAlignmentLeft;
        _answerTitle.text =NSLocalizedString(@"ToolbarItem_Question",nil);
        _answerTitle.userInteractionEnabled = FALSE;
        _answerTitle.layer.shadowColor = [[UIColor whiteColor] CGColor];
        _answerTitle.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        _answerTitle.layer.shadowOpacity = 1.0f;
        _answerTitle.layer.shadowRadius = 4.5f;
        _answerTitle.layer.masksToBounds = NO;
        _answerTitle.textColor = [UIColor redColor];
        _answerTitle.delegate = self;
        _answerTitle.keyboardType = UIKeyboardAppearanceDefault;
        _answerTitle.returnKeyType = UIReturnKeyDone;
        _answerTitle.tag = kTagTitleAnser;
        _answerTitle.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [self addSubview:_answerTitle];
    }
    
    
    
    
    
    if (_verticalScrollView == nil) {
        _verticalScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(60, 110, 740, 440)];
        _verticalScrollView.contentSize = _verticalScrollView.frame.size;
        _verticalScrollView.backgroundColor = [UIColor clearColor];
        _verticalScrollView.scrollEnabled = TRUE;
        [self addSubview:_verticalScrollView];
    }
    
    
    if (_imageQuestion == nil) {
        _imageQuestion= [[MultimediaView  alloc] init];
        [_imageQuestion setMultimediaType:ImageView];
        [_verticalScrollView addSubview:_imageQuestion];

    }
    
    if (_imageQuestion2 == nil) {
        _imageQuestion2= [[MultimediaView  alloc] init];
        [_imageQuestion2 setMultimediaType:ImageView];
        [_verticalScrollView addSubview:_imageQuestion2];

    }
    
    if (_subheadingQuestion == nil) {
        _subheadingQuestion = [[UITextView alloc]init];
        _subheadingQuestion.tag = kTagSubheadingQuestion;
        
        _subheadingQuestion.textContainerInset = UIEdgeInsetsZero;  //很关键
        
        if (_subheadingFontQuestion.length == 0) {
            _subheadingQuestion.font =[UIFont boldSystemFontOfSize:28];
        } else {
            _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:28];
        }
        _subheadingQuestion.userInteractionEnabled = FALSE;
        _subheadingQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _subheadingQuestion.returnKeyType = UIReturnKeyDefault;
        _subheadingQuestion.delegate = self;
        _subheadingQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _subheadingQuestion.backgroundColor = [UIColor clearColor];
        _subheadingQuestion.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _subheadingQuestion.autoresizingMask = UIViewAutoresizingNone;
        _subheadingQuestion.contentOffset = CGPointZero;
        _subheadingQuestion.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_subheadingQuestion];
        
        [_subheadingQuestion addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    
    if (_mainQuestion == nil) {
        _mainQuestion = [[UITextView alloc]init];
        _mainQuestion.tag = kTagMainQuestion;
        
        _mainQuestion.textContainerInset = UIEdgeInsetsZero; //很关键
        
        if (_mainFontQuestion.length == 0) {
            _mainQuestion.font =[UIFont boldSystemFontOfSize:28];
        } else {
            _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:28];
        }
        
        _mainQuestion.userInteractionEnabled = FALSE;
        _mainQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _mainQuestion.returnKeyType = UIReturnKeyDefault;
        _mainQuestion.delegate = self;
        _mainQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _mainQuestion.backgroundColor = [UIColor clearColor];
        _mainQuestion.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _mainQuestion.autoresizingMask = UIViewAutoresizingNone;
        _mainQuestion.contentOffset = CGPointZero;
        _mainQuestion.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_mainQuestion];
        
        [_mainQuestion addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    
    
    if (_subQuestion == nil) {
        _subQuestion = [[UITextView alloc]init];
        _subQuestion.tag = kTagSubQuestion;
        
        _subQuestion.textContainerInset = UIEdgeInsetsZero; //很关键
        
        if (_subFontQuestion.length == 0) {
            _subQuestion.font =[UIFont boldSystemFontOfSize:28];
        } else {
            _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:28];
        }
        
        _subQuestion.userInteractionEnabled = FALSE;
        _subQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _subQuestion.returnKeyType = UIReturnKeyDefault;
        _subQuestion.delegate = self;
        _subQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _subQuestion.backgroundColor = [UIColor clearColor];
        _subQuestion.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _subQuestion.autoresizingMask = UIViewAutoresizingNone;
        _subQuestion.contentOffset = CGPointZero;
        _subQuestion.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_subQuestion];
        
        [_subQuestion addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    
    if (_imageAnswer == nil) {
        _imageAnswer= [[MultimediaView  alloc] init];
        [_imageAnswer setMultimediaType:ImageView];
        [_verticalScrollView addSubview:_imageAnswer];
    }
    
    if (_imageAnswer2 == nil) {
        _imageAnswer2= [[MultimediaView  alloc] init];
        [_imageAnswer2 setMultimediaType:ImageView];
        [_verticalScrollView addSubview:_imageAnswer2];

    }
    
    _imageAnswer.hidden = YES;
    _imageAnswer2.hidden = YES;
    
    if (_subheadingAnswer == nil) {
        _subheadingAnswer = [[UITextView alloc]init];
        _subheadingAnswer.tag = kTagSubheadingAnswer;
        
        _subheadingAnswer.textContainerInset = UIEdgeInsetsZero; //很关键
        
        if (_subheadingFontAnswer.length == 0) {
            _subheadingAnswer.font =[UIFont boldSystemFontOfSize:28];
        } else {
            _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:28];
        }
        
        _subheadingAnswer.userInteractionEnabled = FALSE;
        _subheadingAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _subheadingAnswer.returnKeyType = UIReturnKeyDefault;
        _subheadingAnswer.delegate = self;
        _subheadingAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _subheadingAnswer.backgroundColor = [UIColor clearColor];
        _subheadingAnswer.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _subheadingAnswer.autoresizingMask = UIViewAutoresizingNone;
        _subheadingAnswer.contentOffset = CGPointZero;
        _subheadingAnswer.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_subheadingAnswer];
        
        [_subheadingAnswer addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    _subheadingAnswer.hidden = TRUE;
    
    if (_mainAnswer == nil) {
        _mainAnswer = [[UITextView alloc]init];
        _mainAnswer.tag = kTagMainAnswer;
        
        _mainAnswer.textContainerInset = UIEdgeInsetsZero; //很关键
        
        if (_mainFontAnswer.length == 0) {
            _mainAnswer.font =[UIFont boldSystemFontOfSize:28];
        } else {
            _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:28];
        }
        
        _mainAnswer.userInteractionEnabled = FALSE;
        _mainAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _mainAnswer.returnKeyType = UIReturnKeyDefault;
        _mainAnswer.delegate = self;
        _mainAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _mainAnswer.backgroundColor = [UIColor clearColor];
        _mainAnswer.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _mainAnswer.autoresizingMask = UIViewAutoresizingNone;
        _mainAnswer.contentOffset = CGPointZero;
        _mainAnswer.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_mainAnswer];
        
        [_mainAnswer addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    _mainAnswer.hidden = TRUE;
    
    
    if (_subAnswer == nil) {
        _subAnswer = [[UITextView alloc]init];
        _subAnswer.tag = kTagSubAnswer;
        
        _subAnswer.textContainerInset = UIEdgeInsetsZero; //很关键
        
        if (_subFontAnswer.length == 0) {
            _subAnswer.font =[UIFont boldSystemFontOfSize:28];
        } else {
            _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:28];
        }
        
        _subAnswer.userInteractionEnabled = FALSE;
        _subAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _subAnswer.returnKeyType = UIReturnKeyDefault;
        _subAnswer.delegate = self;
        _subAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _subAnswer.backgroundColor = [UIColor clearColor];
        _subAnswer.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _subAnswer.autoresizingMask = UIViewAutoresizingNone;
        _subAnswer.contentOffset = CGPointZero;
        _subAnswer.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_subAnswer];
        
        [_subAnswer addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    _subAnswer.hidden = TRUE;
    
    if (_sidebarTitle == nil) {
        _sidebarTitle = [[UITextField alloc] init];
        _sidebarTitle.frame = CGRectMake(0, 0, 400, kFlashCardViewSidebarWidth_Detail_iPad);
        [_sidebarTitle setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _sidebarTitle.center = CGPointMake(30, 275);
        } else {
            _sidebarTitle.center = CGPointMake(50, 275);
        }
        
        _sidebarTitle.textAlignment = NSTextAlignmentCenter;
        _sidebarTitle.backgroundColor = [UIColor clearColor];
        _sidebarTitle.font = [UIFont systemFontOfSize:20];
        _sidebarTitle.textColor = [UIColor whiteColor];
        _sidebarTitle.delegate = self;
        _sidebarTitle.keyboardType = UIKeyboardAppearanceDefault;
        _sidebarTitle.returnKeyType = UIReturnKeyDone;
        _sidebarTitle.tag = kTagSidebar;
        _sidebarTitle.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        
        _sidebarTitle.minimumFontSize = 6;
        
        [self addSubview:_sidebarTitle];
    }
    
    
    if (_cardSNText == nil) {
        CGPoint point = CGPointMake(30, kQuestionViewTopMarginForiPad+25);
        if (self.isPlayingCard) {
            point.x = (point.x) * kFlashCardViewProporation_iPhone;
            point.y = (point.y) * kFlashCardViewProporation_iPhone;
        }
        _cardSNText = [[JSBadgeView alloc] initWithParentView:self offset:point];
        _cardSNText.badgeTextColor = [UIColor whiteColor];
        
        
    }
    
    if (_segmentedControl == nil) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                             @[NSLocalizedString(@"ToolbarItem_Question",nil),
                               NSLocalizedString(@"ToolbarItem_Answer",nil)]];
        
        
        CGRect frame = CGRectMake(kSegmentLeftMarginForiPad,
                                  self.bounds.size.height-kSegmentHeightForiPad-kSegmentButtomMarginForiPad,
                                  300,
                                  kSegmentHeightForiPad);
        _segmentedControl.frame = frame;
        [_segmentedControl addTarget:self action:@selector(segmentedControlQAClicked:) forControlEvents:UIControlEventValueChanged];
        _segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
        _segmentedControl.selectedSegmentIndex = 0;
        [self addSubview:_segmentedControl];
    }
    
    
    if (_logoImage == nil) {
        _logoImage = [[UIImageView  alloc] init];
        _logoImage.contentMode = UIViewContentModeScaleAspectFit;
        _logoImage.frame = CGRectMake(670, 10, 100, 100);
        _logoImage.clipsToBounds = YES;
        _logoImage.backgroundColor = [UIColor whiteColor];
        _logoImage.userInteractionEnabled = TRUE; //alway true
//        CAShapeLayer *styleLayer = [CAShapeLayer layer];
//        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:_logoImage.bounds byRoundingCorners:(UIRectCornerBottomRight|UIRectCornerBottomLeft|UIRectCornerTopRight|UIRectCornerTopLeft) cornerRadii:CGSizeMake(25, 25.0)];
//        styleLayer.path = shadowPath.CGPath;
//        _logoImage.layer.mask = styleLayer;
        
        [self addSubview:_logoImage];
        //Default logic
        UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
        [_logoImage addGestureRecognizer:logoSingeTap];
        
        
    }
    
    if (_logoLinkageButton == nil) {
        _logoLinkageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _logoLinkageButton.frame = CGRectMake(630, 85, 25, 25);
        [_logoLinkageButton setBackgroundImage:[UIImage imageNamed:@"edit_link_button.png"] forState:UIControlStateNormal];
        [_logoLinkageButton addTarget:self action:@selector(editLogoLinkageURL:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:_logoLinkageButton];
    }
    
    if (_creatorText == nil) {
        
        _creatorText = [[UITextField alloc] init];
        _creatorText.frame = CGRectMake(490, 30, 90, 20);
        _creatorText.textAlignment = NSTextAlignmentLeft;
        _creatorText.backgroundColor = [UIColor clearColor];
        _creatorText.font = [UIFont systemFontOfSize:12];
        _creatorText.textColor = [UIColor grayColor];
        _creatorText.userInteractionEnabled = FALSE;
        _creatorText.delegate = self;
        _creatorText.keyboardType = UIKeyboardAppearanceDefault;
        _creatorText.returnKeyType = UIReturnKeyDone;
        _creatorText.tag = kTagCreator;
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            _creatorText.tintColor = [UIColor blackColor];
        }
        if (_isPlayingCard == false) {
            _creatorText.placeholder = NSLocalizedString(@"Label_Creator_Hint",@"");
            _creatorText.layer.borderColor = [UIColor lightGrayColor].CGColor;
            _creatorText.layer.borderWidth = 1;
        }
        _creatorText.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _creatorText.minimumFontSize = 6;
        [self addSubview:_creatorText];
        
        _jobTitleText = [[UITextField alloc] init];
        _jobTitleText.frame = CGRectMake(490, 55, 90, 20);
        _jobTitleText.textAlignment = NSTextAlignmentLeft;
        _jobTitleText.backgroundColor = [UIColor clearColor];
        _jobTitleText.font = [UIFont systemFontOfSize:12];
        _jobTitleText.textColor = [UIColor grayColor];
        _jobTitleText.userInteractionEnabled = FALSE;
        _jobTitleText.delegate = self;
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            _jobTitleText.tintColor = [UIColor blackColor];
        }
        if (_isPlayingCard == false) {
            _jobTitleText.placeholder = NSLocalizedString(@"Label_Job_Title",@"");
            _jobTitleText.layer.borderColor = [UIColor lightGrayColor].CGColor;
            _jobTitleText.layer.borderWidth = 1;
        }
        _jobTitleText.keyboardType = UIKeyboardAppearanceDefault;
        _jobTitleText.returnKeyType = UIReturnKeyDone;
        _jobTitleText.tag = kTagJobTitle;
        _jobTitleText.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _jobTitleText.minimumFontSize = 6;
        [self addSubview:_jobTitleText];
    }
    
    //------- begin _functionAreaView
    
    if (_isPlayingCard == NO) {
        if (_functionAreaView == nil) {
            _functionAreaView = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 150, CGRectGetMinY(_segmentedControl.frame), 150, CGRectGetHeight(_segmentedControl.frame)-0.5)];
            _functionAreaView.backgroundColor = [UIColor colorWithRed:43.0/255 green:43.0/255 blue:43.0/255 alpha:1];
            _functionAreaView.layer.borderColor = [[UIColor grayColor]CGColor];
            _functionAreaView.layer.borderWidth = 0;
            _functionAreaView.layer.cornerRadius =3;
            _functionAreaView.layer.masksToBounds = YES;
            [self addSubview:_functionAreaView];
        }
        
        if (_soundButton == nil) {
            _soundButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _soundButton.frame = CGRectMake(108, 9, 24, 24);
            [_soundButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
            [_soundButton setImage:[UIImage imageNamed:@"record_button"] forState:UIControlStateNormal];
            [_soundButton addTarget:self action:@selector(soundRecordButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            _soundButton.backgroundColor = [UIColor clearColor];
            _soundButton.showsTouchWhenHighlighted = YES;
            [_functionAreaView addSubview:_soundButton];
        }
        
        if (_backgroundImageSelectButton == nil) {
            _backgroundImageSelectButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _backgroundImageSelectButton.showsTouchWhenHighlighted = YES;
            [_backgroundImageSelectButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
            _backgroundImageSelectButton.frame = CGRectMake(66.5, 9, 24, 24);
            [_backgroundImageSelectButton setBackgroundImage:[UIImage imageNamed:@"change_card_background_image_button"] forState:UIControlStateNormal];
            [_functionAreaView addSubview:_backgroundImageSelectButton];
            UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundImageSelectButtonClicked:)];
            [_backgroundImageSelectButton addGestureRecognizer:logoSingeTap];
            _backgroundImageSelectButton.showsTouchWhenHighlighted = YES;
        }
        
        
        if (_changeTemplateButton == nil) {
            _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _changeTemplateButton.frame = CGRectMake(21, 9, 24, 24);
            [_changeTemplateButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
            _changeTemplateButton.showsTouchWhenHighlighted = YES;
            [_changeTemplateButton setImage:[UIImage imageNamed:@"change_card_layout_template"] forState:UIControlStateNormal];
            [_functionAreaView addSubview:_changeTemplateButton];
            [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
            _changeTemplateButton.showsTouchWhenHighlighted = YES;
        }
    
        
        
        if (_previewButton == nil) {
            _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _previewButton.frame = CGRectMake(CGRectGetMinX(_functionAreaView.frame) - 160, CGRectGetMinY(_functionAreaView.frame), 70, CGRectGetHeight(_functionAreaView.frame));
            _previewButton.layer.borderColor = [UIColor whiteColor].CGColor;
            _previewButton.layer.borderWidth = 1;
            _previewButton.showsTouchWhenHighlighted = YES;
            [_previewButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
            [_previewButton setTitle:NSLocalizedString(@"Functional_Panel_Preview",@"") forState:UIControlStateNormal];
            [_previewButton addTarget:self action:@selector(previewButtonClick:) forControlEvents:UIControlEventTouchDown];
            _previewButton.showsTouchWhenHighlighted = YES;
            
            [self addSubview:_previewButton];
        }
        
        if (_saveButton == nil) {
            _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _saveButton.frame = CGRectMake(CGRectGetMinX(_functionAreaView.frame) - 80, CGRectGetMinY(_functionAreaView.frame), 70, CGRectGetHeight(_functionAreaView.frame));
            _saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
            _saveButton.layer.borderWidth = 1;
            _saveButton.showsTouchWhenHighlighted = YES;
            [_saveButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
            [_saveButton setTitle:NSLocalizedString(@"Functional_Panel_Save",@"") forState:UIControlStateNormal];
            [_saveButton addTarget:self action:@selector(saveButtonClick:) forControlEvents:UIControlEventTouchDown];
            _saveButton.showsTouchWhenHighlighted = YES;
            
            [self addSubview:_saveButton];
        }
        
    }
    
    
    //------- end _functionAreaView
    
    
}


- (void) loadQuestionAnswerViewForiPhone {
    [iConsole info:@"%s",__FUNCTION__];
    if (_templateBackgroundImageView == nil) {
        if (_templateBackgroundImageName) {
          _templateBackgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:_templateBackgroundImageName]];
        } else {
            _templateBackgroundImageView = [[UIImageView alloc] init];
        }
        _templateBackgroundImageView.contentMode = UIViewContentModeScaleToFill;
        _templateBackgroundImageView.backgroundColor = [UIColor clearColor];
        _templateBackgroundImageView.frame = CGRectMake(0, 0, kFlashCardViewWidth_Detail_iPhone, kFlashCardViewHeight_Detail_iPhone_Pure);
        if (self.isPlayingCard) {
            _templateBackgroundImageView.frame = [Common getScaledViewRect:_templateBackgroundImageView withProportion:kFlashCardViewProporation_iPhone];
        }
        _templateBackgroundImageView.userInteractionEnabled = NO;
        _templateBackgroundImageView.layer.masksToBounds = YES;
        _templateBackgroundImageView.layer.cornerRadius = 15;
        [self addSubview:_templateBackgroundImageView];
    }
    
    if (_questionBackgroundImageView == nil) {
        _questionBackgroundImageView = [[UIImageView alloc] init];
        _questionBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;

        if (_isPlayingCard) {
            _questionBackgroundImageView.frame = CGRectMake(kFlashCardSidebarWidth_iPhone + k_X_Delta_For_Play, kFlashCardHeaderHeight_iPhone + k_Y_Delta_For_Play, CGRectGetWidth(_templateBackgroundImageView.frame) - kFlashCardSidebarWidth_iPhone - k_X_Delta_For_Play, CGRectGetHeight(_templateBackgroundImageView.frame) - kFlashCardHeaderHeight_iPhone - k_Y_Delta_For_Play);;
        } else {
            _questionBackgroundImageView.frame = CGRectMake(kFlashCardSidebarWidth_iPhone, kFlashCardHeaderHeight_iPhone, CGRectGetWidth(_templateBackgroundImageView.frame) - kFlashCardSidebarWidth_iPhone, CGRectGetHeight(_templateBackgroundImageView.frame) - kFlashCardHeaderHeight_iPhone);;
        }
        
        _questionBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _questionBackgroundImageView.backgroundColor = [UIColor whiteColor];
        _questionBackgroundImageView.userInteractionEnabled = NO;
        _questionBackgroundImageView.layer.masksToBounds = YES;
        CAShapeLayer * maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: _questionBackgroundImageView.bounds byRoundingCorners: UIRectCornerBottomRight cornerRadii: (CGSize){15, 15.}].CGPath;
        _questionBackgroundImageView.layer.mask = maskLayer;
        [self addSubview:_questionBackgroundImageView];
        [self bringSubviewToFront:_templateBackgroundImageView];
    }
    
    if (_answerBackgroundImageView == nil) {
        _answerBackgroundImageView = [[UIImageView alloc] init];
        _answerBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
 
        if (_isPlayingCard) {
            _answerBackgroundImageView.frame = CGRectMake(kFlashCardSidebarWidth_iPhone + k_X_Delta_For_Play, kFlashCardHeaderHeight_iPhone + k_Y_Delta_For_Play, CGRectGetWidth(_templateBackgroundImageView.frame) - kFlashCardSidebarWidth_iPhone - k_X_Delta_For_Play, CGRectGetHeight(_templateBackgroundImageView.frame) - kFlashCardHeaderHeight_iPhone - k_Y_Delta_For_Play);
        } else {
            _answerBackgroundImageView.frame = CGRectMake(kFlashCardSidebarWidth_iPhone, kFlashCardHeaderHeight_iPhone, CGRectGetWidth(_templateBackgroundImageView.frame) - kFlashCardSidebarWidth_iPhone, CGRectGetHeight(_templateBackgroundImageView.frame) - kFlashCardHeaderHeight_iPhone);
        }
        
        _answerBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _answerBackgroundImageView.backgroundColor = [UIColor whiteColor];
        _answerBackgroundImageView.userInteractionEnabled = NO;
        _answerBackgroundImageView.layer.masksToBounds = YES;
        CAShapeLayer * maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: _answerBackgroundImageView.bounds byRoundingCorners: UIRectCornerBottomRight cornerRadii: (CGSize){15, 15.}].CGPath;
        _answerBackgroundImageView.layer.mask = maskLayer;
        [self addSubview:_answerBackgroundImageView];
        [self bringSubviewToFront:_templateBackgroundImageView];
    }
    
    
    if (_questionTitle == nil) {
        _questionTitle = [[UITextField alloc]init];
        _questionTitle.frame = CGRectMake(kFlashCardSidebarWidth_iPhone + 5, 25, 200, 23);
        if (self.isPlayingCard) {
            _questionTitle.frame = [Common getScaledViewRect:_questionTitle withProportion:kFlashCardViewProporation_iPhone];
        }
        _questionTitle.text =NSLocalizedString(@"ToolbarItem_Question",nil);
        _questionTitle.font =[UIFont systemFontOfSize:18];
        if (self.isPlayingCard) {
            _questionTitle.font =[UIFont systemFontOfSize:18*kFlashCardViewProporation_iPhone];
        }
        _questionTitle.textAlignment = NSTextAlignmentLeft;
        _questionTitle.backgroundColor = [UIColor clearColor];
        _questionTitle.userInteractionEnabled = FALSE;
        _questionTitle.layer.shadowColor = [[UIColor whiteColor] CGColor];
        _questionTitle.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _questionTitle.layer.shadowOpacity = 1.0f;
        _questionTitle.layer.shadowRadius = 4.5f;
        _questionTitle.layer.masksToBounds = NO;
        _questionTitle.textColor = [UIColor blueColor];
        _questionTitle.delegate = self;
        _questionTitle.keyboardType = UIKeyboardAppearanceDefault;
        _questionTitle.returnKeyType = UIReturnKeyDone;
        _questionTitle.tag = kTagTitleQuestion;
        _questionTitle.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [self addSubview:_questionTitle];
    }
    
    if (_answerTitle == nil) {
        _answerTitle = [[UITextField alloc]init];
        _answerTitle.frame = CGRectMake(kFlashCardSidebarWidth_iPhone + 5, 25, 200, 23);
        if (self.isPlayingCard) {
            _answerTitle.frame = [Common getScaledViewRect:_answerTitle withProportion:kFlashCardViewProporation_iPhone];
        }
        _answerTitle.text =NSLocalizedString(@"ToolbarItem_Question",nil);
        _answerTitle.font =[UIFont systemFontOfSize:18];
        if (self.isPlayingCard) {
            _answerTitle.font =[UIFont systemFontOfSize:18*kFlashCardViewProporation_iPhone];
        }
        _answerTitle.textAlignment = NSTextAlignmentLeft;
        _answerTitle.backgroundColor = [UIColor clearColor];
        _answerTitle.userInteractionEnabled = FALSE;
        _answerTitle.layer.shadowColor = [[UIColor whiteColor] CGColor];
        _answerTitle.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _answerTitle.layer.shadowOpacity = 1.0f;
        _answerTitle.layer.shadowRadius = 4.5f;
        _answerTitle.layer.masksToBounds = NO;
        _answerTitle.textColor = [UIColor redColor];
        _answerTitle.delegate = self;
        _answerTitle.keyboardType = UIKeyboardAppearanceDefault;
        _answerTitle.returnKeyType = UIReturnKeyDone;
        _answerTitle.tag = kTagTitleAnser;
        _answerTitle.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [self addSubview:_answerTitle];
    }
    
    
    
    if (_verticalScrollView == nil) {
        _verticalScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kFlashCardSidebarWidth_iPhone, kFlashCardHeaderHeight_iPhone, kFlashCardViewWidth_Detail_iPhone - kFlashCardSidebarWidth_iPhone, (kFlashCardViewHeight_Detail_iPhone_Pure - kFlashCardHeaderHeight_iPhone))];
        if (self.isPlayingCard) {
            _verticalScrollView.frame = [Common getScaledViewRect:_verticalScrollView withProportion:kFlashCardViewProporation_iPhone];
        }
        
        _verticalScrollView.contentSize = _verticalScrollView.frame.size;
        //_verticalScrollView.backgroundColor = [UIColor blueColor];
        _verticalScrollView.scrollEnabled = TRUE;
        [self addSubview:_verticalScrollView];
        
    }
    
    
    if (_sidebarTitle ==  nil) {
        _sidebarTitle = [[UITextField alloc] init];
        _sidebarTitle.frame = CGRectMake(0, 0, 180, kFlashCardSidebarWidth_iPhone);
        [_sidebarTitle setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _sidebarTitle.center = CGPointMake(kFlashCardSidebarWidth_iPhone/2, 122);
        } else {
            _sidebarTitle.center = CGPointMake(kFlashCardSidebarWidth_iPhone/2, 122);
        }
        if (self.isPlayingCard) {
            _sidebarTitle.frame = [Common getScaledViewRect:_sidebarTitle withProportion:kFlashCardViewProporation_iPhone];
        }
        _sidebarTitle.textAlignment = NSTextAlignmentCenter;
        _sidebarTitle.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _sidebarTitle.backgroundColor = [UIColor clearColor];
        _sidebarTitle.font = [UIFont systemFontOfSize:12];
        _sidebarTitle.textColor = [UIColor whiteColor];
        _sidebarTitle.delegate = self;
        _sidebarTitle.keyboardType = UIKeyboardAppearanceDefault;
        _sidebarTitle.returnKeyType = UIReturnKeyDone;
        _sidebarTitle.tag = kTagSidebar;
        
        _sidebarTitle.minimumFontSize = 6;
        
        [self addSubview:_sidebarTitle];
    }
    
    
    
    //Step3: Common
    if (_cardSNText == nil) {
        CGPoint point = CGPointMake(kFlashCardSidebarWidth_iPhone/2, kFlashCardSidebarWidth_iPhone/2);
        if (self.isPlayingCard) {
            point.x = point.x * kFlashCardViewProporation_iPhone;
            point.y = point.y * kFlashCardViewProporation_iPhone;
        }
        _cardSNText = [[JSBadgeView alloc] initWithParentView:self offset:point];
        
        _cardSNText.badgeTextColor = [UIColor whiteColor];
        
    }
    
    
    if (_imageQuestion ==  nil) {
        _imageQuestion= [[MultimediaView  alloc] init];
        _imageQuestion.userInteractionEnabled = true;
        _imageQuestion.contentMode = UIViewContentModeScaleAspectFit;
        _imageQuestion.clipsToBounds = YES;
        _imageQuestion.backgroundColor = [UIColor clearColor];
        _imageQuestion.tag = 1;
        _imageQuestion.layer.cornerRadius = 10;
        _imageQuestion.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageQuestion];
    }
    
    if (_imageQuestion2 ==  nil) {
        _imageQuestion2= [[MultimediaView  alloc] init];
        _imageQuestion2.userInteractionEnabled = true;
        _imageQuestion2.contentMode = UIViewContentModeScaleAspectFit;
        _imageQuestion2.clipsToBounds = YES;
        _imageQuestion2.backgroundColor = [UIColor clearColor];
        _imageQuestion2.tag = 1;
        _imageQuestion2.layer.cornerRadius = 10;
        _imageQuestion2.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageQuestion2];
    }
    
    if (_subheadingQuestion ==  nil) {
        _subheadingQuestion = [[UITextView alloc]init];
        _subheadingQuestion.tag = kTagSubheadingQuestion;
        
        _subheadingQuestion.textContainerInset = UIEdgeInsetsZero; //很关键
        
        _subheadingQuestion.userInteractionEnabled = FALSE;
        _subheadingQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _subheadingQuestion.returnKeyType = UIReturnKeyDefault;
        _subheadingQuestion.delegate = self;
        _subheadingQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _subheadingQuestion.backgroundColor = [UIColor clearColor];
        _subheadingQuestion.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _subheadingQuestion.autoresizingMask = UIViewAutoresizingNone;
        _subheadingQuestion.contentOffset = CGPointZero;
        _subheadingQuestion.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_subheadingQuestion];
        
        [_subheadingQuestion addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    
    if (_mainQuestion ==  nil) {
        _mainQuestion = [[UITextView alloc]init];
        _mainQuestion.tag = kTagMainQuestion;
        
        _mainQuestion.textContainerInset = UIEdgeInsetsZero; //很关键
        
        _mainQuestion.userInteractionEnabled = FALSE;
        _mainQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _mainQuestion.returnKeyType = UIReturnKeyDefault;
        _mainQuestion.delegate = self;
        _mainQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _mainQuestion.backgroundColor = [UIColor clearColor];
        _mainQuestion.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _mainQuestion.autoresizingMask = UIViewAutoresizingNone;
        _mainQuestion.contentOffset = CGPointZero;
        _mainQuestion.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_mainQuestion];
        
        [_mainQuestion addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    
    
    if (_subQuestion ==  nil) {
        _subQuestion = [[UITextView alloc]init];
        _subQuestion.tag = kTagSubQuestion;
        
        _subQuestion.textContainerInset = UIEdgeInsetsZero; //很关键
        
        _subQuestion.userInteractionEnabled = FALSE;
        _subQuestion.contentMode = UIViewContentModeScaleAspectFit;
        _subQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _subQuestion.returnKeyType = UIReturnKeyDefault;
        _subQuestion.delegate = self;
        _subQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _subQuestion.backgroundColor = [UIColor clearColor];
        _subQuestion.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _subQuestion.autoresizingMask = UIViewAutoresizingNone;
        _subQuestion.contentOffset = CGPointZero;
        _subQuestion.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_subQuestion];
        
        [_subQuestion addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    
    if (_imageAnswer ==  nil) {
        _imageAnswer= [[MultimediaView  alloc] init];
        _imageAnswer.userInteractionEnabled = true;
        _imageAnswer.contentMode = UIViewContentModeScaleAspectFit;
        _imageAnswer.clipsToBounds = YES;
        _imageAnswer.backgroundColor = [UIColor clearColor];
        _imageAnswer.tag = 1;
        _imageAnswer.layer.cornerRadius = 10;
        _imageAnswer.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageAnswer];
    }
    _imageAnswer.hidden = YES;
    
    if (_imageAnswer2 ==  nil) {
        _imageAnswer2= [[MultimediaView  alloc] init];
        _imageAnswer2.userInteractionEnabled = true;
        _imageAnswer2.contentMode = UIViewContentModeScaleAspectFit;
        _imageAnswer2.clipsToBounds = YES;
        _imageAnswer2.backgroundColor = [UIColor clearColor];
        _imageAnswer2.tag = 1;
        _imageAnswer2.layer.cornerRadius = 10;
        _imageAnswer2.layer.masksToBounds = YES;
        _imageAnswer2.contentMode = UIViewContentModeScaleAspectFit;
        [_verticalScrollView addSubview:_imageAnswer2];
    }
    _imageAnswer2.hidden = YES;
    
    
    if (_subheadingAnswer ==  nil) {
        _subheadingAnswer = [[UITextView alloc]init];
        _subheadingAnswer.tag = kTagSubheadingAnswer;
        
        _subheadingAnswer.textContainerInset = UIEdgeInsetsZero; //很关键
        
        _subheadingAnswer.userInteractionEnabled = FALSE;
        _subheadingAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _subheadingAnswer.returnKeyType = UIReturnKeyDefault;
        _subheadingAnswer.delegate = self;
        _subheadingAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _subheadingAnswer.backgroundColor = [UIColor clearColor];
        _subheadingAnswer.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _subheadingAnswer.autoresizingMask = UIViewAutoresizingNone;
        _subheadingAnswer.contentOffset = CGPointZero;
        _subheadingAnswer.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_subheadingAnswer];
        
        [_subheadingAnswer addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    _subheadingAnswer.hidden = YES;
    
    if (_mainAnswer ==  nil) {
        _mainAnswer = [[UITextView alloc]init];
        
        _mainAnswer.textContainerInset = UIEdgeInsetsZero; //很关键
        
        _mainAnswer.tag = kTagMainAnswer;
        _mainAnswer.userInteractionEnabled = FALSE;
        _mainAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _mainAnswer.returnKeyType = UIReturnKeyDefault;
        _mainAnswer.delegate = self;
        _mainAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _mainAnswer.backgroundColor = [UIColor clearColor];
        _mainAnswer.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _mainAnswer.autoresizingMask = UIViewAutoresizingNone;
        _mainAnswer.contentOffset = CGPointZero;
        _mainAnswer.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_mainAnswer];
        
        [_mainAnswer addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    _mainAnswer.hidden = YES;
    
    if (_subAnswer ==  nil) {
        _subAnswer = [[UITextView alloc]init];
        _subAnswer.tag = kTagSubAnswer;
        
        _subAnswer.textContainerInset = UIEdgeInsetsZero; //很关键
        
        _subAnswer.userInteractionEnabled = FALSE;
        _subAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _subAnswer.returnKeyType = UIReturnKeyDefault;
        _subAnswer.delegate = self;
        _subAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _subAnswer.backgroundColor = [UIColor clearColor];
        _subAnswer.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _subAnswer.autoresizingMask = UIViewAutoresizingNone;
        _subAnswer.contentOffset = CGPointZero;
        _subAnswer.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [_verticalScrollView addSubview:_subAnswer];
        
        [_subAnswer addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    _subAnswer.hidden = YES;
    
    if (_segmentedControl == nil) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                             @[NSLocalizedString(@"ToolbarItem_Question",nil),
                               NSLocalizedString(@"ToolbarItem_Answer",nil)]];
        
        CGRect frame = CGRectMake(kSegmentLeftMarginForiPhone,
                                  self.bounds.size.height-kSegmentHeightForiPhone-kSegmentButtomMarginForiPhone,
                                  130,
                                  kSegmentHeightForiPhone);
        _segmentedControl.frame = frame;
        [_segmentedControl addTarget:self action:@selector(segmentedControlQAClicked:) forControlEvents:UIControlEventValueChanged];
        _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        _segmentedControl.selectedSegmentIndex = 0;
        NSDictionary *attributesNormal = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIFont systemFontOfSize:10], NSFontAttributeName,
                                    [UIColor whiteColor], NSForegroundColorAttributeName,
                                    nil];
        NSDictionary *attributesSelected = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont systemFontOfSize:10], NSFontAttributeName,
                                          [UIColor blackColor], NSForegroundColorAttributeName,
                                          nil];
        [_segmentedControl setTitleTextAttributes:attributesNormal
                                        forState:UIControlStateNormal];
        [_segmentedControl setTitleTextAttributes:attributesSelected
                                         forState:UIControlStateSelected];
        [_segmentedControl setTitleTextAttributes:attributesSelected
                                         forState:UIControlStateHighlighted];
        [self addSubview:_segmentedControl];
    }
    
    
    
    
    if (_logoImage == nil){
        _logoImage = [[UIImageView  alloc] init];
        _logoImage.contentMode = UIViewContentModeScaleAspectFit;
        _logoImage.frame = CGRectMake(kFlashCardViewWidth_Detail_iPhone - 59, 5, 54, 30);
        if (self.isPlayingCard) {
            _logoImage.frame = [Common getScaledViewRect:_logoImage withProportion:kFlashCardViewProporation_iPhone];
        }
        _logoImage.backgroundColor = [UIColor whiteColor];
//        
//        CAShapeLayer *styleLayer = [CAShapeLayer layer];
//        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:_logoImage.bounds byRoundingCorners:(UIRectCornerBottomRight|UIRectCornerBottomLeft|UIRectCornerTopRight|UIRectCornerTopLeft) cornerRadii:CGSizeMake(15, 15.0)];
//        styleLayer.path = shadowPath.CGPath;
//        _logoImage.layer.mask = styleLayer;
        
        _logoImage.userInteractionEnabled = TRUE;
        _logoImage.tag = 0;
        _logoImage.layer.cornerRadius = 5;
        _logoImage.layer.masksToBounds = YES;
        [self addSubview:_logoImage];
        
        //Default logic
        UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
        [_logoImage addGestureRecognizer:logoSingeTap];
        
    }
    
    if (_logoLinkageButton == nil) {
        _logoLinkageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _logoLinkageButton.frame = CGRectMake(kFlashCardViewWidth_Detail_iPhone - 54 - 30, 24, 12, 12);
        if (self.isPlayingCard) {
            _logoLinkageButton.frame = [Common getScaledViewRect:_logoLinkageButton withProportion:kFlashCardViewProporation_iPhone];
        }
        [_logoLinkageButton setBackgroundImage:[UIImage imageNamed:@"edit_link_button.png"] forState:UIControlStateNormal];
        [_logoLinkageButton addTarget:self action:@selector(editLogoLinkageURL:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:_logoLinkageButton];
    }
    
    if (_creatorText == nil) {

        _creatorText = [[UITextField alloc] init];
        _creatorText.frame = CGRectMake(190, 8, 60, 14);
        if (self.isPlayingCard) {
            _creatorText.frame = [Common getScaledViewRect:_creatorText withProportion:kFlashCardViewProporation_iPhone];
        }
        _creatorText.textAlignment = NSTextAlignmentLeft;
        _creatorText.backgroundColor = [UIColor clearColor];
        _creatorText.font = [UIFont systemFontOfSize:8];
        if (self.isPlayingCard) {
            _creatorText.font =[UIFont systemFontOfSize:8*kFlashCardViewProporation_iPhone];
        } else {
            _creatorText.placeholder = NSLocalizedString(@"Label_Creator_Hint",@"");
            _creatorText.layer.borderColor = [UIColor lightGrayColor].CGColor;
            _creatorText.layer.borderWidth = 1;
        }
        
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            _creatorText.tintColor = [UIColor blackColor];
        }
        _creatorText.textColor = [UIColor grayColor];
        _creatorText.userInteractionEnabled = FALSE;
        _creatorText.delegate = self;
        _creatorText.keyboardType = UIKeyboardAppearanceDefault;
        _creatorText.returnKeyType = UIReturnKeyDone;
        _creatorText.tag = kTagCreator;
        _creatorText.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _creatorText.minimumFontSize = 6;
        [self addSubview:_creatorText];
        
        _jobTitleText = [[UITextField alloc] init];
        _jobTitleText.frame = CGRectMake(190, 25, 60, 14);
        if (self.isPlayingCard) {
            _jobTitleText.frame = [Common getScaledViewRect:_jobTitleText withProportion:kFlashCardViewProporation_iPhone];
        }
        _jobTitleText.textAlignment = NSTextAlignmentLeft;
        _jobTitleText.backgroundColor = [UIColor clearColor];
        _jobTitleText.font = [UIFont systemFontOfSize:8];
        if (self.isPlayingCard) {
            _jobTitleText.font =[UIFont systemFontOfSize:8*kFlashCardViewProporation_iPhone];
        } else {
            _jobTitleText.placeholder = NSLocalizedString(@"Label_Job_Title",@"");
            _jobTitleText.layer.borderColor = [UIColor lightGrayColor].CGColor;
            _jobTitleText.layer.borderWidth = 1;
        }
        
        _jobTitleText.textColor = [UIColor grayColor];
        _jobTitleText.userInteractionEnabled = FALSE;
        _jobTitleText.delegate = self;
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            _jobTitleText.tintColor = [UIColor blackColor];
        }
        _jobTitleText.keyboardType = UIKeyboardAppearanceDefault;
        _jobTitleText.returnKeyType = UIReturnKeyDone;
        _jobTitleText.tag = kTagJobTitle;
        _jobTitleText.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _jobTitleText.minimumFontSize = 6;
        [self addSubview:_jobTitleText];
    }
    
    //------- begin _functionAreaView
    
    if (_isPlayingCard == NO) {
        if (_functionAreaView == nil) {
            _functionAreaView = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 100, CGRectGetMinY(_segmentedControl.frame), 100, CGRectGetHeight(_segmentedControl.frame))];
            _functionAreaView.backgroundColor = [UIColor darkGrayColor];
            _functionAreaView.layer.borderColor = [[UIColor grayColor]CGColor];
            _functionAreaView.layer.borderWidth = 0;
            _functionAreaView.layer.cornerRadius =3;
            _functionAreaView.layer.masksToBounds = YES;
            [self addSubview:_functionAreaView];
        }
        
        if (_soundButton == nil) {
            _soundButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _soundButton.frame = CGRectMake(75, 4, 20, 20);
            [_soundButton setImage:[UIImage imageNamed:@"record_button"] forState:UIControlStateNormal];
            [_soundButton addTarget:self action:@selector(soundRecordButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            _soundButton.backgroundColor = [UIColor clearColor];
            [_functionAreaView addSubview:_soundButton];
            _soundButton.showsTouchWhenHighlighted = YES;
        }
        
        if (_backgroundImageSelectButton == nil) {
            _backgroundImageSelectButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _backgroundImageSelectButton.showsTouchWhenHighlighted = YES;
            _backgroundImageSelectButton.frame = CGRectMake(40, 4, 20, 20);
            [_backgroundImageSelectButton setBackgroundImage:[UIImage imageNamed:@"change_card_background_image_button"] forState:UIControlStateNormal];
            [_functionAreaView addSubview:_backgroundImageSelectButton];
            UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundImageSelectButtonClicked:)];
            [_backgroundImageSelectButton addGestureRecognizer:logoSingeTap];
            _backgroundImageSelectButton.showsTouchWhenHighlighted = YES;
        }
        
        
        if (_changeTemplateButton == nil) {
            _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _changeTemplateButton.frame = CGRectMake(5, 4, 20, 20);
            _changeTemplateButton.showsTouchWhenHighlighted = YES;
            [_changeTemplateButton setImage:[UIImage imageNamed:@"change_card_layout_template"] forState:UIControlStateNormal];
            [_functionAreaView addSubview:_changeTemplateButton];
            [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
            _changeTemplateButton.showsTouchWhenHighlighted = YES;
        }
        
        if (_isPlayingCard) {
            _functionAreaView.hidden = YES;
            
            _saveButton.hidden = YES;
            _previewButton.hidden = YES;
        }
    
        
        
        if (_previewButton == nil) {
            _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _previewButton.frame = CGRectMake(CGRectGetMinX(_functionAreaView.frame) - 90, CGRectGetMinY(_functionAreaView.frame), 42, CGRectGetHeight(_functionAreaView.frame));
            _previewButton.layer.borderColor = [UIColor whiteColor].CGColor;
            _previewButton.layer.borderWidth = 1;
            _previewButton.showsTouchWhenHighlighted = YES;
            [_previewButton.titleLabel setFont:[UIFont systemFontOfSize:10]];
            [_previewButton setTitle:NSLocalizedString(@"Functional_Panel_Preview",@"") forState:UIControlStateNormal];
            [_previewButton addTarget:self action:@selector(previewButtonClick:) forControlEvents:UIControlEventTouchDown];
            _previewButton.showsTouchWhenHighlighted = YES;
            
            [self addSubview:_previewButton];
        }
        
        if (_saveButton == nil) {
            _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _saveButton.frame = CGRectMake(CGRectGetMinX(_functionAreaView.frame) - 45, CGRectGetMinY(_functionAreaView.frame), 42, CGRectGetHeight(_functionAreaView.frame));
            _saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
            _saveButton.layer.borderWidth = 1;
            _saveButton.showsTouchWhenHighlighted = YES;
            [_saveButton.titleLabel setFont:[UIFont systemFontOfSize:10]];
            [_saveButton setTitle:NSLocalizedString(@"Functional_Panel_Save",@"") forState:UIControlStateNormal];
            [_saveButton addTarget:self action:@selector(saveButtonClick:) forControlEvents:UIControlEventTouchDown];
            _saveButton.showsTouchWhenHighlighted = YES;
            
            [self addSubview:_saveButton];
        }
    }
    
    //------- end _functionAreaView
    
    
}

- (long) setTextViewTopPadding: (int) fontSize {
    
    long val = 0;
    
    if (val < 40) {
        val = -(fontSize/6) -1;
    } else {
        val = -(fontSize/7) + 2;
    }
    
    
    return val;
}


#pragma mark -
#pragma mark - Editable related
- (BOOL)checkCardEditable {
    
    [iConsole info:@"%s",__FUNCTION__];
    BOOL result;
    if ([Common isOwner:_currentPack]) {
        result = YES;
    } else {
        result = NO;
    }
    return result;
    
}

- (void) disableCardEdit{
    [iConsole info:@"%s",__FUNCTION__];
    _logoLinkageButton.hidden = TRUE;
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWebviewViaLogoURL:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    
    {
        while (_imageQuestion.gestureRecognizers.count) {
            [_imageQuestion removeGestureRecognizer:[_imageQuestion.gestureRecognizers objectAtIndex:0]];
        }
        
        if ([Common isValidYoutubeLinkage:_currentCard.question.movieFullPath]) {
            
            UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
            [_imageQuestion addGestureRecognizer:imageSingeTap];
            
        }
    }
    
    
    {
        while (_imageQuestion2.gestureRecognizers.count) {
            [_imageQuestion2 removeGestureRecognizer:[_imageQuestion2.gestureRecognizers objectAtIndex:0]];
        }
        
        if ([Common isValidYoutubeLinkage:_currentCard.question.movieFullPath2]) {
            
            UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped2:)];
            [_imageQuestion2 addGestureRecognizer:imageSingeTap];
            
        }
    }
    
    _imageQuestion.layer.borderWidth = 0;
    _imageQuestion2.layer.borderWidth = 0;
    _mainQuestion.userInteractionEnabled         = FALSE;
    _mainQuestion.layer.borderWidth = 0;
    _subQuestion.userInteractionEnabled          = FALSE;
    _subQuestion.layer.borderWidth = 0;
    _subheadingQuestion.userInteractionEnabled   = FALSE;
    _subheadingQuestion.layer.borderWidth = 0;
    
    {
        while (_imageAnswer.gestureRecognizers.count) {
            [_imageAnswer removeGestureRecognizer:[_imageAnswer.gestureRecognizers objectAtIndex:0]];
        }
        
        if ([Common isValidYoutubeLinkage:_currentCard.answer.movieFullPath]) {
            
            UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
            [_imageAnswer addGestureRecognizer:imageSingeTap];
            
        }
    }
    
    
    {
        while (_imageAnswer2.gestureRecognizers.count) {
            [_imageAnswer2 removeGestureRecognizer:[_imageAnswer2.gestureRecognizers objectAtIndex:0]];
        }
        
        if ([Common isValidYoutubeLinkage:_currentCard.answer.movieFullPath2]) {
            
            UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped2:)];
            [_imageAnswer2 addGestureRecognizer:imageSingeTap];
            
        }
    }
    
    _imageAnswer.layer.borderWidth = 0;
    _imageAnswer2.layer.borderWidth = 0;
    _mainAnswer.userInteractionEnabled         = FALSE;
    _mainAnswer.layer.borderWidth = 0;
    _subAnswer.userInteractionEnabled          = FALSE;
    _subAnswer.layer.borderWidth = 0;
    _subheadingAnswer.userInteractionEnabled   = FALSE;
    _subheadingAnswer.layer.borderWidth = 0;
    
    _questionTitle.userInteractionEnabled = FALSE;
    _answerTitle.userInteractionEnabled = FALSE;
    
    _sidebarTitle.userInteractionEnabled = FALSE;
    
    if (_isPlayingCard) {
        _creatorText.userInteractionEnabled = TRUE;
        UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWebviewViaLogoURL:)];
        [_creatorText addGestureRecognizer:logoSingeTap];
    } else {
        _creatorText.userInteractionEnabled = FALSE;
    }
    
    _jobTitleText.userInteractionEnabled = NO;
    _creatorText.userInteractionEnabled = NO;
}

- (void) enableCardEdit{
    [iConsole info:@"%s",__FUNCTION__];
    _logoLinkageButton.hidden = FALSE;
    
    int scale = [[UIScreen mainScreen] scale];
    
    
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    _imageQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _imageQuestion.layer.borderWidth = k_Scale/scale;
    
    _imageQuestion2.userInteractionEnabled        = TRUE;
    _imageQuestion2.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _imageQuestion2.layer.borderWidth = k_Scale/scale;
    
    
    _mainQuestion.userInteractionEnabled         = TRUE;
    _mainQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _mainQuestion.layer.borderWidth = k_Scale/scale;
    
    _subQuestion.userInteractionEnabled          = TRUE;
    _subQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _subQuestion.layer.borderWidth = k_Scale/scale;
    
    _subheadingQuestion.userInteractionEnabled   = TRUE;
    _subheadingQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _subheadingQuestion.layer.borderWidth = k_Scale/scale;
    
    _imageAnswer.userInteractionEnabled        = TRUE;
    _imageAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _imageAnswer.layer.borderWidth = k_Scale/scale;
    
    _imageAnswer2.userInteractionEnabled        = TRUE;
    _imageAnswer2.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _imageAnswer2.layer.borderWidth = k_Scale/scale;
    
    _mainAnswer.userInteractionEnabled         = TRUE;
    _mainAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _mainAnswer.layer.borderWidth = k_Scale/scale;
    
    _subAnswer.userInteractionEnabled          = TRUE;
    _subAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _subAnswer.layer.borderWidth = k_Scale/scale;
    
    _subheadingAnswer.userInteractionEnabled   = TRUE;
    _subheadingAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    _subheadingAnswer.layer.borderWidth = k_Scale/scale;
    
    _changeTemplateButton.userInteractionEnabled = YES;
    
    _questionTitle.userInteractionEnabled = YES;
    _answerTitle.userInteractionEnabled = YES;
    
    _sidebarTitle.userInteractionEnabled = YES;
    _creatorText.userInteractionEnabled = YES;
    _jobTitleText.userInteractionEnabled = YES;
    
    
    {
        while (_imageQuestion.gestureRecognizers.count) {
            [_imageQuestion removeGestureRecognizer:[_imageQuestion.gestureRecognizers objectAtIndex:0]];
        }
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
        [_imageQuestion addGestureRecognizer:imageSingeTap];
    }
    
    {
        while (_imageQuestion2.gestureRecognizers.count) {
            [_imageQuestion2 removeGestureRecognizer:[_imageQuestion2.gestureRecognizers objectAtIndex:0]];
        }
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped2:)];
        [_imageQuestion2 addGestureRecognizer:imageSingeTap];
    }
    
    {
        while (_imageAnswer.gestureRecognizers.count) {
            [_imageAnswer removeGestureRecognizer:[_imageAnswer.gestureRecognizers objectAtIndex:0]];
        }
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
        [_imageAnswer addGestureRecognizer:imageSingeTap];
    }
    
    {
        while (_imageAnswer2.gestureRecognizers.count) {
            [_imageAnswer2 removeGestureRecognizer:[_imageAnswer2.gestureRecognizers objectAtIndex:0]];
        }
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped2:)];
        [_imageAnswer2 addGestureRecognizer:imageSingeTap];
    }
    
}



#pragma mark -
#pragma mark - Refresh


- (void) refreshAll {
    [iConsole info:@"%s",__FUNCTION__];
    [self refreshAll:NO withIndexPlaying:-1];
    
}

- (void) refreshAllFromSegmentSwitch {
    [iConsole info:@"%s",__FUNCTION__];
    [self refreshAll:NO withIndexPlaying:-1 isFromSegmentSwitch:true];
    
}

- (void) refreshAll:(BOOL) isDisableAutoResize withIndexPlaying: (int) indexPlaying {
    [self refreshAll:isDisableAutoResize withIndexPlaying:indexPlaying isFromSegmentSwitch:false];
}

/**
 *  刷新操作，考虑：
 *  1. play mode和 edit mode下的scroll view
 *  2. 卡片可编辑，或不可编辑
 *  @param isDisableAutoResize 如果为NO，满足下面的条件执行
 *  @param indexPlaying        indexPlaying =0时，表明为第一个card，这时如果已经被缓存过（isDisableAutoResize = YES），则不会执行
  *  @param isFromSegmentSwitch
 */
- (void) refreshAll:(BOOL) isDisableAutoResize withIndexPlaying: (int) indexPlaying isFromSegmentSwitch:(BOOL) isFromSegmentSwitch {
    [iConsole info:@"%s",__FUNCTION__];
    
    //we don't reset if it's only a segmented switch operation
    if (isFromSegmentSwitch == false) {
        _subQuestion.alpha = 1;
        _subheadingQuestion.alpha = 1;
        _mainQuestion.alpha = 1;
        
        _subAnswer.alpha = 1;
        _subheadingAnswer.alpha = 1;
        _mainAnswer.alpha = 1;
    }
    
    [self pauseEmbeddedVideoAndGif];
    [self resetVerticalScrollViewOffset];
    [self showQuestionOrAnswer];
    [self updateQuestionOrAnswerTemplate];
    if (_isPlayingCard == FALSE) {
        //在playingCard时，如果执行这个逻辑会引起布局的稍微扰动，会影响体验。这主要是默认的padding不是零，而我们reset成了0.这在edit card时没什么问题，但是play的时候就会影响体验。后续可以改进：resetUITextViewPadding设置成默认的padding，而不是一刀切为0
        [self resetUITextViewPadding];//由于我们在切换card时，不是重新创建cardview,所以需要重置所有的参数，包括padding
    }
    [self updateQuestionAndAnswerCSS]; // need to be careful, since two properties (color/size) will replace with those in updateQuestionAndAnswerTemplate
    [self refreshQuestionAndAnswerContent];
    if ([self checkCardEditable] == YES) {
        [self enableCardEdit];
    } else {
        [self disableCardEdit];
    }
    
    //we don't want to edit title during new card
    if (self.tag == NEW_FLASHCARDVIEW_TAG) {
        _questionTitle.userInteractionEnabled = false;
        _answerTitle.userInteractionEnabled = false;
        //_functionAreaView.hidden = YES;
        
//        _previewButton.hidden = true;
//        _saveButton.hidden = true;
    }
    
    if (0) {
        //deprecated logic
        if (_segmentedControl.selectedSegmentIndex == 1) {
            [self adjustAllTextViewsToFitIfNecessary];
        } else {
            if ([Common isOwner:_currentPack] == FALSE) {
                //几种情况
                //1. 如果是刚进入play mode，显示第一个card，这时indexPlaying = 0， isDisableAutoResize = NO；
                //2. 其它情况下，我们不直接渲染第一个card，而是通过previous/next card进行提前渲染
                if (((self.tag != CURRENT_FLASHCARDVIEW_TAG) && (isDisableAutoResize == NO))
                    || ((indexPlaying == 0) && (isDisableAutoResize == NO))){
                    
                    [self adjustAllTextViewsToFitIfNecessary];
                }
            } else {
                [self adjustAllTextViewsToFitIfNecessary];
            }
        }
    } else {
        [self adjustAllTextViewsToFitIfNecessary];

    }
    
    [self hideAllSemiTransparentTextViews];

    
    [self updateQuestionAnswerAllTextViewVeriticalAlignment];//由于此方法的执行跟内容相关，一般放在最后
    
    if ([_synth isSpeaking]) {
        [_synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    
    BOOL val2 = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_Help_Tip_Has_Been_Showed];
    
    if (APP_DELEGATE.isAllowToShowTooltip && val2) {
        double delayInSeconds = 0.2;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        __weak __typeof(&*self)weakSelf = self;
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:K_Tooltip_FlashCard_Not_Allow];
            if (val == FALSE) {
                [weakSelf showTooltips];
            }
        });
    }
    
    
}


- (void) resetVerticalScrollViewOffset {
    [iConsole info:@"%s",__FUNCTION__];
    
    //reset offset
    CGPoint offset = _verticalScrollView.contentOffset;
    offset.y = 0;
    [_verticalScrollView setContentOffset:offset animated:YES];
    
    if (self.isPlayingCard || [Common isOwner:self.currentPack] == FALSE) {
        _verticalScrollView.scrollEnabled = FALSE;
    } else {
        _verticalScrollView.scrollEnabled = TRUE;
    }
}



- (void) resetUITextViewPadding {
    [iConsole info:@"%s",__FUNCTION__];
    _subheadingQuestion.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subheadingSizeQuestion], 0, 0, 0.0);
    _subheadingAnswer.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subheadingSizeAnswer], 0, 0, 0.0);
    _mainQuestion.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_mainSizeQuestion], 0, 0, 0.0);
    _mainAnswer.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_mainSizeAnswer], 0, 0, 0.0);
    _subQuestion.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subSizeQuestion], 0, 0, 0.0);
    _subAnswer.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subSizeAnswer], 0, 0, 0.0);
}


- (void) refreshQuestionAndAnswerContent {
    [iConsole info:@"%s",__FUNCTION__];
    
    _templateBackgroundImageName = _currentCard.templateBackgroundName;
    
    [self refreshQuestionContent];
    [self refreshAnswerContent];
    
    _cardSNText.badgeText= [NSString stringWithFormat:@"%ld",_currentCard.cardSN];
    
    //it's quite strange logic below, but it indeed
    if (isUserInterfaceIdiomPhone) {
        _sidebarTitle.font = [UIFont systemFontOfSize:12];
    } else {
        _sidebarTitle.font = [UIFont systemFontOfSize:20];
    }
    if ((_currentPack.sidebarTitle.length == 0) || ([_currentPack.sidebarTitle rangeOfString:@"null"].length != 0)) {
        _sidebarTitle.text = _currentPack.packName;
    } else {
        _sidebarTitle.text = _currentPack.sidebarTitle;
    }

    [_sidebarTitle adjustFontSizeToFitVertically:YES];
    _templateBackgroundImageView.image = [UIImage imageNamed:_templateBackgroundImageName];
    
    
    NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.backgroundImageFullPath lastPathComponent]];
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:path];
    if (imageTemp) {
        _questionBackgroundImageView.image = imageTemp;
    } else {
        //do nothing
    }
    
    if (_currentCard.question.movieFullPath.length >0) {
        if ([Common isValidYoutubeLinkage:_currentCard.question.movieFullPath]) {
            _questionMovieFullPath = _currentCard.question.movieFullPath;
        } else {
            path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.movieFullPath lastPathComponent]];
            _questionMovieFullPath = path;
        }
        
    }
    
    if (_currentCard.question.movieFullPath2.length >0) {
        if ([Common isValidYoutubeLinkage:_currentCard.question.movieFullPath2]) {
            _questionMovieFullPath2 = _currentCard.question.movieFullPath2;
        } else {
            path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.movieFullPath2 lastPathComponent]];
            _questionMovieFullPath2 = path;
        }
        
    }
    
    if (_currentCard.question.recordedSoundFullPath.length > 0) {
        path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.recordedSoundFullPath lastPathComponent]];
        _questionRecordedSoundFullPath = path;
    }
    
    //是否显示soundButton的逻辑
    if ([MutipleTargetHelper isFullVersion]) {
        
        if (_segmentedControl.selectedSegmentIndex == 0) {
            
            if (_isPlayingCard) {
                if (_currentCard.question.recordedSoundFullPath.length > 0) {
                    self.functionAreaView.hidden = NO;
                } else {
                    self.functionAreaView.hidden = YES;
                }
            } else {
                self.functionAreaView.hidden = NO;
            }
            
        } else {
            if (_isPlayingCard) {
                if (_currentCard.answer.recordedSoundFullPath.length > 0) {
                    self.functionAreaView.hidden = NO;
                } else {
                    self.functionAreaView.hidden = YES;
                }
            } else {
                self.functionAreaView.hidden = NO;
            }
        }
    } else {
        
        self.functionAreaView.hidden = YES;
    }
    
    if ([MutipleTargetHelper isFullVersion] && _isPlayingCard == false) {
        _segmentedControl.hidden = NO;
    } else {
        _segmentedControl.hidden = YES;
    }
    
    if (isUserInterfaceIdiomPhone) {
        _creatorText.font = [UIFont systemFontOfSize:8];
    } else {
        _creatorText.font = [UIFont systemFontOfSize:12];
    }
    if (checkNullOrEmptyOrNullStr(_currentPack.creatorNickName)) {
        _creatorText.text = @"";
    } else {
        _creatorText.text = [NSString stringWithFormat:@"%@",_currentPack.creatorNickName];
        [_creatorText adjustFontSizeToFit];
    }
    
    if (_isPlayingCard) {
        if ([_creatorText.text isEqualToString:NSLocalizedString(@"Label_Creator", nil)]) {
            _creatorText.text = @"";
        }
    }
    
    if (isUserInterfaceIdiomPhone) {
        _jobTitleText.font = [UIFont systemFontOfSize:8];
    } else {
        _jobTitleText.font = [UIFont systemFontOfSize:12];
    }
    if (checkNullOrEmptyOrNullStr(_currentPack.jobTitle)) {
        _jobTitleText.text = @"";
    } else {
        _jobTitleText.text = [NSString stringWithFormat:@"%@",_currentPack.jobTitle];
        [_jobTitleText adjustFontSizeToFit];
    }
    
    if (_isPlayingCard) {
        if ([_jobTitleText.text isEqualToString:NSLocalizedString(@"Label_Job_Title", nil)]) {
            _jobTitleText.text = @"";
        }
    }
    
    
    NSString *logoFullPath = _currentCard.question.logoFullPath;
    if (((logoFullPath.length == 0) || ([logoFullPath rangeOfString:@"placeholder"].location != NSNotFound)) && (_isPlayingCard == true)) {
        _logoImage.hidden = true;
    } else {
        _logoImage.hidden = false;
    }
    
    
    
}

- (void) refreshAnswerContent {
    [iConsole info:@"%s",__FUNCTION__];
    
    {
        _answerMovieFullPath = _currentCard.answer.movieFullPath;
        _answerMovieFullPath2 = _currentCard.answer.movieFullPath2;
        
        _answerImageFullPath = _currentCard.answer.imageFullPath;
        _answerImageFullPath2 = _currentCard.answer.imageFullPath2;
        
        _answerTitle.text = _currentCard.answer.title;
        _answerTitle.textColor = [self colorForAnswerTitle];
        _answerTitle.layer.shadowColor = [self colorForAnswerTitleShadowColor];
        _cardSNText.badgeBackgroundColor = [self colorForCardSNBackgroundTemplateID];
        
        
        _subheadingAnswer.text = _currentCard.answer.subheading;
        _mainAnswer.text =_currentCard.answer.main;
        _subAnswer.text =_currentCard.answer.sub;
    }
    
    {
        BOOL isVideo = [self isLocalVideo:_answerMovieFullPath];
        
        if (isVideo) {
            
            [_imageAnswer setMultimediaType:Video];
            [_imageAnswer setVideoURL:[NSURL fileURLWithPath:_answerMovieFullPath]];
            
        } else {
            
            [_imageAnswer setMultimediaType:ImageView];
            
            UIImage *imageTemp = nil;
            FLAnimatedImage *gifImageTemp = nil;
            [iConsole info:@"%s,_currentCard.answer.imageFullPath = %@",__FUNCTION__,_currentCard.answer.imageFullPath];
            BOOL isGif = [self isGif:_currentCard.answer.imageFullPath];
            if ([_answerImageFullPath lastPathComponent].length != 0) {
                if (isGif) {
                    gifImageTemp = [FLAnimatedImage animatedImageWithGIFData:[NSData dataWithContentsOfFile:_answerImageFullPath]];
                } else {
                    imageTemp = [UIImage imageWithContentsOfFile:_answerImageFullPath];
                }
            }

            if (imageTemp) {
                _imageAnswer.animtableImageView.image = imageTemp;
            } else if (gifImageTemp) {
                _imageAnswer.animtableImageView.animatedImage = gifImageTemp;
            } else {
                _imageAnswer.animtableImageView.image = [UIImage imageNamed:@"answer_placeholder_content"];
                
                if (_isPlayingCard) {
                    _imageAnswer.hidden = YES;
                } else {
                }
            }
        }
        
        
        
        //客户要求，touch的范围必须在icon内，而不是在imageview frame内
        if ([_currentCard.answer.movieFullPath.lowercaseString rangeOfString:@"youtube"].location != NSNotFound &&
            _isPlayingCard) {
            float width = CGRectGetWidth(_imageAnswer.frame);
            float height = CGRectGetHeight(_imageAnswer.frame);
            _imageAnswer.bypassTransparentColor = YES;
            [_imageAnswer setHitTestEdgeInsets:UIEdgeInsetsMake(height*0.4, width*0.4, height*0.4, width*0.4)];
        }
    }
    
    {
        
        BOOL isVideo = [self isLocalVideo:_answerMovieFullPath2];
        
        if (isVideo) {
            
            [_imageAnswer2 setMultimediaType:Video];
            [_imageAnswer2 setVideoURL:[NSURL fileURLWithPath:_answerMovieFullPath2]];

            
        } else {
            
            [_imageAnswer2 setMultimediaType:ImageView];
            
            UIImage *imageTemp = nil;
            FLAnimatedImage *gifImageTemp = nil;
            
            [iConsole info:@"%s,_currentCard.answer.imageFullPath2 = %@",__FUNCTION__,_currentCard.answer.imageFullPath2];
            BOOL isGif = [self isGif:_currentCard.answer.imageFullPath2];
            if ([_answerImageFullPath2 lastPathComponent].length != 0) {
                if (isGif) {
                    gifImageTemp = [FLAnimatedImage animatedImageWithGIFData:[NSData dataWithContentsOfFile:_answerImageFullPath2]];
                } else {
                    imageTemp = [UIImage imageWithContentsOfFile:_answerImageFullPath2];
                }
            }
            
            if (imageTemp) {
                _imageAnswer2.animtableImageView.image = imageTemp;
            } else if (gifImageTemp) {
                _imageAnswer2.animtableImageView.animatedImage = gifImageTemp;
            } else {
                _imageAnswer2.animtableImageView.image = [UIImage imageNamed:@"answer_placeholder_content"];
                
                if (_isPlayingCard) {
                    _imageAnswer2.hidden = YES;
                } else {
                }
            }
        }
    
        
        //客户要求，touch的范围必须在icon内，而不是在imageview frame内
        if ([_currentCard.answer.movieFullPath2.lowercaseString rangeOfString:@"youtube"].location != NSNotFound &&
            _isPlayingCard) {
            float width = CGRectGetWidth(_imageAnswer2.frame);
            float height = CGRectGetHeight(_imageAnswer2.frame);
            _imageAnswer2.bypassTransparentColor = YES;
            [_imageAnswer2 setHitTestEdgeInsets:UIEdgeInsetsMake(height*0.4, width*0.4, height*0.4, width*0.4)];
        }
    }
    
    {
        UIImage *imageTemp = nil;
        NSString *path = @"";
        [iConsole info:@"%s,_currentCard.answer.backgroundImageFullPath = %@",__FUNCTION__,_currentCard.answer.backgroundImageFullPath];
        if ([_currentCard.answer.backgroundImageFullPath lastPathComponent].length != 0) {
            path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.backgroundImageFullPath lastPathComponent]];
            imageTemp = [UIImage imageWithContentsOfFile:path];
        }
        
        _answerBackgroundImageFullPath = path;
        if (imageTemp) {
            _answerBackgroundImageView.image = imageTemp;
        } else {
            _answerBackgroundImageView.image = nil;
        }
    }
    
    
    {
        if (_currentCard.answer.recordedSoundFullPath.length > 0) {
            NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.recordedSoundFullPath lastPathComponent]];
            _answerRecordedSoundFullPath = path;
        } else {
            _answerRecordedSoundFullPath = @"";
        }
    }
    
}


- (void) refreshQuestionContent {
    [iConsole info:@"%s",__FUNCTION__];
    
    {
        _questionMovieFullPath = _currentCard.question.movieFullPath;
        _questionMovieFullPath2 = _currentCard.question.movieFullPath2;
        
        _questionImageFullPath = _currentCard.question.imageFullPath;
        _questionImageFullPath2 = _currentCard.question.imageFullPath2;
        
        
        _questionTitle.text = _currentCard.question.title;
        _questionTitle.textColor = [self colorForQuestionTitle];
        _questionTitle.layer.shadowColor = [self colorForQuestionTitleShadowColor];
        _cardSNText.badgeBackgroundColor = [self colorForCardSNBackgroundTemplateID];
        
        _subheadingQuestion.text = _currentCard.question.subheading;
        _mainQuestion.text =_currentCard.question.main;
        _subQuestion.text =_currentCard.question.sub;
    }
    
    
    //_currentCard.question 1
    {
        BOOL isVideo = [self isLocalVideo:_questionMovieFullPath];
        
        if (isVideo) {
            
            [_imageQuestion setMultimediaType:Video];
            [_imageQuestion setVideoURL:[NSURL fileURLWithPath:_questionMovieFullPath]];
            

            
        } else {
            
            [_imageQuestion setMultimediaType:ImageView];
            
            UIImage *imageTemp = nil;
            FLAnimatedImage *gifImageTemp = nil;

            BOOL isGif = [self isGif:_questionImageFullPath];
            
            
            if ([_questionImageFullPath lastPathComponent].length != 0) {
                
                if (isGif) {
                    gifImageTemp = [FLAnimatedImage animatedImageWithGIFData:[NSData dataWithContentsOfFile:_questionImageFullPath]];
                } else {
                    imageTemp = [UIImage imageWithContentsOfFile:_questionImageFullPath];
                }
                
            }
            
            if (imageTemp) {
                _imageQuestion.animtableImageView.image = imageTemp;
            } else if (gifImageTemp) {
                _imageQuestion.animtableImageView.animatedImage = gifImageTemp;
            }else {
                _imageQuestion.animtableImageView.image = [UIImage imageNamed:@"question_placeholder_content"];
                
                if (_isPlayingCard) {
                    _imageQuestion.hidden = YES;
                } else {
                }
                
            }
        }
        
        
        //客户要求，touch的范围必须在icon内，而不是在imageview frame内
        if ([_currentCard.question.movieFullPath.lowercaseString rangeOfString:@"youtube"].location != NSNotFound &&
            _isPlayingCard) {
            float width = CGRectGetWidth(_imageQuestion.frame);
            float height = CGRectGetHeight(_imageQuestion.frame);
            _imageQuestion.bypassTransparentColor = YES;
            [_imageQuestion setHitTestEdgeInsets:UIEdgeInsetsMake(height*0.4, width*0.4, height*0.4, width*0.4)];
        }
    }
    
    //_currentCard.question 2
    {
        BOOL isVideo = [self isLocalVideo:_questionMovieFullPath2];
        
        if (isVideo) {
            
            [_imageQuestion2 setMultimediaType:Video];
            [_imageQuestion2 setVideoURL:[NSURL fileURLWithPath:_questionMovieFullPath2]];
            
        } else {
            
            [_imageQuestion2 setMultimediaType:ImageView];
            
            UIImage *imageTemp = nil;
            FLAnimatedImage *gifImageTemp = nil;
            
            BOOL isGif = [self isGif:_questionImageFullPath2];
            [iConsole info:@"%s,_currentCard.question.imageFullPath2 = %@",__FUNCTION__,_currentCard.question.imageFullPath2];
            if ([_questionImageFullPath2 lastPathComponent].length != 0) {
                if (isGif) {
                    gifImageTemp = [FLAnimatedImage animatedImageWithGIFData:[NSData dataWithContentsOfFile:_questionImageFullPath2]];
                } else {
                    imageTemp = [UIImage imageWithContentsOfFile:_questionImageFullPath2];
                }
            }
            if (imageTemp) {
                _imageQuestion2.animtableImageView.image = imageTemp;
            } else if (gifImageTemp) {
                _imageQuestion2.animtableImageView.animatedImage = gifImageTemp;
            } else {
                _imageQuestion2.animtableImageView.image = [UIImage imageNamed:@"question_placeholder_content"];
                
                if (_isPlayingCard) {
                    _imageQuestion2.hidden = YES;
                } else {
                }
                
            }
        }
        
        //客户要求，touch的范围必须在icon内，而不是在imageview frame内
        if ([_currentCard.question.movieFullPath2.lowercaseString rangeOfString:@"youtube"].location != NSNotFound &&
            _isPlayingCard) {
            float width = CGRectGetWidth(_imageQuestion2.frame);
            float height = CGRectGetHeight(_imageQuestion2.frame);
            _imageQuestion2.bypassTransparentColor = YES;
            [_imageQuestion2 setHitTestEdgeInsets:UIEdgeInsetsMake(height*0.4, width*0.4, height*0.4, width*0.4)];
        }
    }
    
    //logo
    {
        UIImage *imageTemp = nil;
        NSString *path = @"";
        
        [iConsole info:@"%s,_currentCard.question.logoFullPath = %@",__FUNCTION__,_currentCard.question.logoFullPath];
        if ([_currentCard.question.logoFullPath lastPathComponent].length != 0) {
            path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.logoFullPath lastPathComponent]];
            imageTemp = [UIImage imageWithContentsOfFile:path];
        }
        
        _logoImageFullPath = path;
        if (imageTemp) {
            _logoImage.image = imageTemp;
        } else {
            _logoImage.image = [UIImage imageNamed:@"question_placeholder_logo"];
            
            if (_isPlayingCard) {
                _logoImage.hidden = YES;
            } else {
            }
        }
        
    }
    
    //background
    {
        UIImage *imageTemp = nil;
        NSString *path = @"";
        [iConsole info:@"%s,_currentCard.question.backgroundImageFullPath = %@",__FUNCTION__,_currentCard.question.backgroundImageFullPath];
        if ([_currentCard.question.backgroundImageFullPath lastPathComponent].length != 0) {
            path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.backgroundImageFullPath lastPathComponent]];
            imageTemp = [UIImage imageWithContentsOfFile:path];
        }
        
        _questionBackgroundImageFullPath = path;
        if (imageTemp) {
            _questionBackgroundImageView.image = imageTemp;
        } else {
            _questionBackgroundImageView.image = nil;
        }
    }
    
    //recorded sound
    {
        if (_currentCard.question.recordedSoundFullPath.length > 0) {
            NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.recordedSoundFullPath lastPathComponent]];
            _questionRecordedSoundFullPath = path;
        } else {
            _questionRecordedSoundFullPath = @"";
        }
        
    }
    
}

- (UIColor *) colorForQuestionTitle {
    
    return [UIColor blueColor];
    
    //_templateBackgroundImageName
    NSString *str = _currentCard.templateBackgroundName.lowercaseString;
    if ([str rangeOfString:@"red"].location != NSNotFound) {
        return [UIColor whiteColor];
    }else if ([str rangeOfString:@"purple"].location != NSNotFound) {
        return [UIColor whiteColor];
    }else if ([str rangeOfString:@"blue"].location != NSNotFound) {
        return [UIColor whiteColor];
    }else if ([str rangeOfString:@"coffee"].location != NSNotFound) {
        return [UIColor whiteColor];
    }else if ([str rangeOfString:@"gray"].location != NSNotFound) {
        return [UIColor whiteColor];
    }else {
        return [UIColor blueColor];
    }
    
}

- (UIColor *) colorForAnswerTitle {
    
    return [UIColor redColor];
}

- (CGColorRef) colorForQuestionTitleShadowColor {
    
    return [UIColor whiteColor].CGColor;//to clive: if you need to control the glow color for each template,comment out this
    
    
    
    //_templateBackgroundImageName
    NSString *str = _currentCard.templateBackgroundName.lowercaseString;
    if ([str rangeOfString:@"red"].location != NSNotFound) {
        return [UIColor colorWithRed:102.0/255 green:0 blue:0 alpha:1].CGColor;
    }else if ([str rangeOfString:@"purple"].location != NSNotFound) {
        return [UIColor colorWithRed:51.0/255 green:0 blue:25.0/255 alpha:1].CGColor;
    }else if ([str rangeOfString:@"blue"].location != NSNotFound) {
        return [UIColor colorWithRed:0 green:0 blue:51.0/255 alpha:1].CGColor;
    }else if ([str rangeOfString:@"coffee"].location != NSNotFound) {
        return [UIColor colorWithRed:25.0/255 green:0 blue:51.0/255 alpha:1].CGColor;
    }else if ([str rangeOfString:@"gray"].location != NSNotFound) {
        return [UIColor blackColor].CGColor;
    }else {
        return [UIColor blueColor].CGColor;
    }
    
}


- (CGColorRef) colorForAnswerTitleShadowColor {
    
    return [UIColor whiteColor].CGColor;//to clive: if you need to control the glow color for each template,comment out this
    
    
    
    //_templateBackgroundImageName
    NSString *str = _currentCard.templateBackgroundName.lowercaseString;
    if ([str rangeOfString:@"red"].location != NSNotFound) {
        return [UIColor colorWithRed:102.0/255 green:0 blue:0 alpha:1].CGColor;
    }else if ([str rangeOfString:@"purple"].location != NSNotFound) {
        return [UIColor colorWithRed:51.0/255 green:0 blue:25.0/255 alpha:1].CGColor;
    }else if ([str rangeOfString:@"blue"].location != NSNotFound) {
        return [UIColor colorWithRed:0 green:0 blue:51.0/255 alpha:1].CGColor;
    }else if ([str rangeOfString:@"coffee"].location != NSNotFound) {
        return [UIColor colorWithRed:25.0/255 green:0 blue:51.0/255 alpha:1].CGColor;
    }else if ([str rangeOfString:@"gray"].location != NSNotFound) {
        return [UIColor blackColor].CGColor;
    }else {
        return [UIColor blueColor].CGColor;
    }
    
}


- (UIColor *) colorForCardSNBackgroundTemplateID{
    
    //_templateBackgroundImageName
    NSString *str = _currentCard.templateBackgroundName.lowercaseString;
    if ([str rangeOfString:@"red"].location != NSNotFound) {
        return [UIColor redColor];
    }else if ([str rangeOfString:@"purple"].location != NSNotFound) {
        return [UIColor purpleColor];
    }else if ([str rangeOfString:@"blue"].location != NSNotFound) {
        return [UIColor blueColor];
    }else if ([str rangeOfString:@"coffee"].location != NSNotFound) {
        return [UIColor colorWithRed:128.0/255 green:0 blue:0 alpha:1];
    }else if ([str rangeOfString:@"gray"].location != NSNotFound) {
        return [UIColor colorWithRed:40.0/255 green:40.0/255 blue:40.0/255 alpha:1];
    }else {
        return [UIColor blueColor];
    }
    
}

- (UIColor *) colorFromColorCSSString:(NSString *) colorStr {
    
    NSString *str = colorStr.lowercaseString;
    
    if ([str isEqualToString:@"blue"]) {
        return [UIColor blueColor];
    } else if ([str isEqualToString:@"red"]) {
        return [UIColor redColor];
    } else if ([str isEqualToString:@"yellow"]) {
        return [UIColor yellowColor];
    } else if ([str isEqualToString:@"black"]) {
        return [UIColor blackColor];
    } else if ([str isEqualToString:@"green"]) {
        return [UIColor greenColor];
    } else if ([str isEqualToString:@"white"]) {
        return [UIColor whiteColor];
    } else {
        return [UIColor blackColor];
    }
}

#pragma mark -
#pragma mark Segment callback

- (void) showQuestionOrAnswer {
    [iConsole info:@"%s",__FUNCTION__];
    if (_segmentedControl.selectedSegmentIndex == 0) {
        _imageQuestion.hidden = NO;
        _imageQuestion2.hidden = NO;
        
        _subheadingQuestion.hidden = NO;
        _mainQuestion.hidden = NO;
        _subQuestion.hidden = NO;
        
        _imageAnswer.hidden = YES;
        _imageAnswer2.hidden = YES;
        _subheadingAnswer.hidden = YES;
        _mainAnswer.hidden = YES;
        _subAnswer.hidden = YES;
        
        _questionTitle.hidden = NO;
        _answerTitle.hidden = YES;
        
        _questionBackgroundImageView.hidden = NO;
        _answerBackgroundImageView.hidden = YES;
        
        
    } else {
        _imageQuestion.hidden = YES;
        _imageQuestion2.hidden = YES;
        
        _subheadingQuestion.hidden = YES;
        _mainQuestion.hidden = YES;
        _subQuestion.hidden = YES;
        
        _imageAnswer.hidden = NO;
        _imageAnswer2.hidden = NO;
        
        _subheadingAnswer.hidden = NO;
        _mainAnswer.hidden = NO;
        _subAnswer.hidden = NO;
        
        _questionTitle.hidden = YES;
        _answerTitle.hidden = NO;
        
        _questionBackgroundImageView.hidden = YES;
        _answerBackgroundImageView.hidden = NO;
    }
}


- (void)segmentedControlQAClicked:(id)sender
{
    
    //This is very important.In this case, the answer card is not still full inflated (correct templated ID is not assigned yet) and you can not caclucate line numbe correctly
    //it does not matter even we can not edit the card. (we don't save card in non-edittable card)
    if (sender != nil) {  //do it only when manually click segmented control
        if (_segmentedControl.selectedSegmentIndex == 1) { //我们将切换到answer，所以计算question的
            _currentCard.question.lineNoSubheading = [self lineNumberWithUITextView:_subheadingQuestion];
            _currentCard.question.lineNoMain = [self lineNumberWithUITextView:_mainQuestion];
            _currentCard.question.lineNoSub = [self lineNumberWithUITextView:_subQuestion];
        } else {
            _currentCard.answer.lineNoSubheading = [self lineNumberWithUITextView:_subheadingAnswer];
            _currentCard.answer.lineNoMain = [self lineNumberWithUITextView:_mainAnswer];
            _currentCard.answer.lineNoSub = [self lineNumberWithUITextView:_subAnswer];
        }
    }
    
    [self refreshAllFromSegmentSwitch];
}

- (void) backgroundImageSelectButtonClicked:(UITapGestureRecognizer *)sender {
    
    
    [iConsole info:@"%s",__FUNCTION__];
    
    if ([Common isOwner:_currentPack] == FALSE) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
        return;
        
    }
    
    BOOL isAllowUndo;
    
    NSString *backgroundImagePath;
    NSDictionary *cardDict = [self getUndoDictForCardBackgroundImage:_currentPack.packID withCardId:_currentCard.cardID];
    if (_segmentedControl.selectedSegmentIndex == 0) {
        backgroundImagePath =  _currentCard.question.backgroundImageFullPath;
        isAllowUndo = [[cardDict objectForKey:@"K_Is_Allow_Undo_Question_Background_Image"] boolValue];
    } else {
        backgroundImagePath =  _currentCard.answer.backgroundImageFullPath;
        isAllowUndo = [[cardDict objectForKey:@"K_Is_Allow_Undo_Answer_Background_Image"] boolValue];
    }
    
    if (backgroundImagePath.length == 0) {
        
        __weak __typeof(&*self)weakSelf = self;
        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_BACKGROUND_IMAGE_SELECTION",@"") message:NSLocalizedString(@"Title_Image_Copyright",@"") cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"DIALOG_SELECT_FROM_LIBRARY",@""), nil] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            
            if (buttonIndex == 1) {
                [weakSelf selectFromImageLibraryByBackgroundSelectButton:sender];
            }
            
        }];
        
    } else {

        if (isAllowUndo) {
            __weak __typeof(&*self)weakSelf = self;
            [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_BACKGROUND_IMAGE_SELECTION",@"") message:NSLocalizedString(@"Title_Image_Copyright",@"") cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Optional_Remove_Background_Image",@""), NSLocalizedString(@"Optional_Change_Background_Image",@""),NSLocalizedString(@"Optional_Undo_Last_Operation",@""), nil] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                
                [weakSelf backgroundImageSelectAlertViewClickedAtIndex: buttonIndex];
                
            }];
        } else {
            __weak __typeof(&*self)weakSelf = self;
            [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_BACKGROUND_IMAGE_SELECTION",@"") message:NSLocalizedString(@"Title_Image_Copyright",@"") cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Optional_Remove_Background_Image",@""), NSLocalizedString(@"Optional_Change_Background_Image",@""), nil] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                
                [weakSelf backgroundImageSelectAlertViewClickedAtIndex: buttonIndex];
                
            }];
        
        }
        
    }
    
}

/**
 *  不是保存到数据库中，而是保存到_currentCard中。主要场景用在create new card
 *  无比保持同commitQuestionAndAnswerData一致（除了pack部分）
 */
- (Card *) copyCurrentUnsavedCardForPreview {
    [iConsole info:@"%s",__FUNCTION__];
    
    Card *card = [self.currentCard copy];;
    
    card.answer.title = _answerTitle.text;
    card.answer.subheading = _subheadingAnswer.text;
    card.answer.main = _mainAnswer.text;
    card.answer.sub = _subAnswer.text;
    card.answer.imageFullPath = _answerImageFullPath;
    card.answer.imageFullPath2 = _answerImageFullPath2;
    
    card.answer.backgroundImageFullPath = _answerBackgroundImageFullPath;
    
    card.answer.movieFullPath = _answerMovieFullPath;
    card.answer.movieFullPath2 = _answerMovieFullPath2;
    
    //we do nothing here since it's already in CreateSoundViewController
//    card.answer.recordedSoundFullPath = _answerRecordedSoundFullPath;
//    card.question.recordedSoundFullPath = _questionRecordedSoundFullPath;
    
    
    card.answer.css.subheadingAlign = _subheadingAlignAnswer;
    card.answer.css.subheadingColor = _subheadingColorAnswer;
    card.answer.css.subheadingText2SpeechSound = _subheadingText2SpeechAnswer;
    card.answer.css.subheadingSize = _subheadingSizeAnswer;
    card.answer.css.mainAlign = _mainAlignAnswer;
    card.answer.css.mainColor = _mainColorAnswer;
    card.answer.css.mainSize = _mainSizeAnswer;
    card.answer.css.mainText2SpeechSound = _mainText2SpeechAnswer;
    card.answer.css.subAlign = _subAlignAnswer;
    card.answer.css.subColor = _subColorAnswer;
    card.answer.css.subSize = _subSizeAnswer;
    card.answer.css.subheadingText2SpeechSound = _subText2SpeechAnswer;
    
    card.answer.css.subheadingAlignVertical = _subheadingAlignVerticalAnswer;
    card.answer.css.mainAlignVertical = _mainAlignVerticalAnswer;
    card.answer.css.subAlignVertical = _subAlignVerticalAnswer;
    
    card.answer.css.subheadingFont = _subheadingFontAnswer;
    card.answer.css.mainFont = _mainFontAnswer;
    card.answer.css.subFont = _subFontAnswer;
    
    card.answer.css.subheadingSemiTransparent = (_subheadingAnswer.alpha == 0.5) || (_subheadingAnswer.textColor == [UIColor clearColor]);
    card.answer.css.mainSemiTransparent       = (_mainAnswer.alpha == 0.5) || (_mainAnswer.textColor == [UIColor clearColor]);
    card.answer.css.subSemiTransparent        = (_subAnswer.alpha == 0.5) || (_subAnswer.textColor == [UIColor clearColor]);
    
    card.question.title = _questionTitle.text;
    card.question.subheading = _subheadingQuestion.text;
    card.question.main = _mainQuestion.text;
    card.question.sub = _subQuestion.text;
    card.question.imageFullPath = _questionImageFullPath;
    card.question.imageFullPath2 = _questionImageFullPath2;
    
    card.question.logoURLLinkage = _logoLinkURL;
    
    card.question.backgroundImageFullPath = _questionBackgroundImageFullPath;
    
    card.question.movieFullPath = _questionMovieFullPath;
    card.question.movieFullPath2 = _questionMovieFullPath2;
    
    card.question.css.subheadingAlign = _subheadingAlignQuestion;
    card.question.css.subheadingColor = _subheadingColorQuestion;
    card.question.css.subheadingSize = _subheadingSizeQuestion;
    card.question.css.subheadingText2SpeechSound = _subheadingText2SpeechQuestion;
    card.question.css.mainAlign = _mainAlignQuestion;
    card.question.css.mainColor = _mainColorQuestion;
    card.question.css.mainSize = _mainSizeQuestion;
    card.question.css.mainText2SpeechSound = _mainText2SpeechQuestion;
    card.question.css.subAlign = _subAlignQuestion;
    card.question.css.subColor = _subColorQuestion;
    card.question.css.subSize = _subSizeQuestion;
    card.question.css.subText2SpeechSound = _subText2SpeechQuestion;
    
    card.question.css.subheadingAlignVertical = _subheadingAlignVerticalQuestion;
    card.question.css.mainAlignVertical = _mainAlignVerticalQuestion;
    card.question.css.subAlignVertical = _subAlignVerticalQuestion;
    
    card.question.css.subheadingFont = _subheadingFontQuestion;
    card.question.css.mainFont = _mainFontQuestion;
    card.question.css.subFont = _subFontQuestion;
    
    card.question.css.subheadingSemiTransparent = (_subheadingQuestion.alpha == 0.5) || (_subheadingQuestion.textColor == [UIColor clearColor]);
    card.question.css.mainSemiTransparent       = (_mainQuestion.alpha == 0.5) || (_mainQuestion.textColor == [UIColor clearColor]);
    card.question.css.subSemiTransparent        = (_subQuestion.alpha == 0.5) || (_subQuestion.textColor == [UIColor clearColor]);
    
    
    //This is very important.In this case, the answer card is not still full inflated (correct templated ID is not assigned yet) and you can not caclucate line numbe correctly
    //we did this when:
    //1. manually click segmented control to switch QA  (we have to do this since users could switch QA without saving content, so we need to cache it.
    //AND 2. save cards
    if (_segmentedControl.selectedSegmentIndex == 0) {
        card.question.lineNoSubheading = [self lineNumberWithUITextView:_subheadingQuestion];
        card.question.lineNoMain = [self lineNumberWithUITextView:_mainQuestion];
        card.question.lineNoSub = [self lineNumberWithUITextView:_subQuestion];
    } else {
        card.answer.lineNoSubheading = [self lineNumberWithUITextView:_subheadingAnswer];
        card.answer.lineNoMain = [self lineNumberWithUITextView:_mainAnswer];
        card.answer.lineNoSub = [self lineNumberWithUITextView:_subAnswer];
    }
    
    return card;
    
}


/**
 *  不是保存到数据库中，而是保存到_currentCard中。主要场景用在create new card
 */
- (void) commitQuestionAndAnswerData {
    [iConsole info:@"%s",__FUNCTION__];
    _currentCard.answer.title = _answerTitle.text;
    _currentCard.answer.subheading = _subheadingAnswer.text;
    _currentCard.answer.main = _mainAnswer.text;
    _currentCard.answer.sub = _subAnswer.text;
    _currentCard.answer.imageFullPath = _answerImageFullPath;
    _currentCard.answer.imageFullPath2 = _answerImageFullPath2;
    
    _currentCard.answer.backgroundImageFullPath = _answerBackgroundImageFullPath;
    
    _currentCard.answer.movieFullPath = _answerMovieFullPath;
    _currentCard.answer.movieFullPath2 = _answerMovieFullPath2;
    
    if (isFromNewCreatedCard) {
        //我们不做什么，因为已经在CreateSoundViewController中进行commit了
    } else {
        _currentCard.answer.recordedSoundFullPath = _answerRecordedSoundFullPath;
        _currentCard.question.recordedSoundFullPath = _questionRecordedSoundFullPath;
    }
    
    
    _currentCard.answer.css.subheadingAlign = _subheadingAlignAnswer;
    _currentCard.answer.css.subheadingColor = _subheadingColorAnswer;
    _currentCard.answer.css.subheadingSize = _subheadingSizeAnswer;
    _currentCard.answer.css.subheadingText2SpeechSound = _subheadingText2SpeechAnswer;
    _currentCard.answer.css.mainAlign = _mainAlignAnswer;
    _currentCard.answer.css.mainColor = _mainColorAnswer;
    _currentCard.answer.css.mainSize = _mainSizeAnswer;
    _currentCard.answer.css.mainText2SpeechSound = _mainText2SpeechAnswer;
    _currentCard.answer.css.subAlign = _subAlignAnswer;
    _currentCard.answer.css.subColor = _subColorAnswer;
    _currentCard.answer.css.subSize = _subSizeAnswer;
    _currentCard.answer.css.subText2SpeechSound = _subText2SpeechAnswer;
    
    _currentCard.answer.css.subheadingAlignVertical = _subheadingAlignVerticalAnswer;
    _currentCard.answer.css.mainAlignVertical = _mainAlignVerticalAnswer;
    _currentCard.answer.css.subAlignVertical = _subAlignVerticalAnswer;
    
    _currentCard.answer.css.subheadingFont = _subheadingFontAnswer;
    _currentCard.answer.css.mainFont = _mainFontAnswer;
    _currentCard.answer.css.subFont = _subFontAnswer;
    
    _currentCard.answer.css.subheadingSemiTransparent = (_subheadingAnswer.alpha == 0.5);
    _currentCard.answer.css.mainSemiTransparent       = (_mainAnswer.alpha == 0.5);
    _currentCard.answer.css.subSemiTransparent        = (_subAnswer.alpha == 0.5);
    
    _currentCard.question.title = _questionTitle.text;
    _currentCard.question.subheading = _subheadingQuestion.text;
    _currentCard.question.main = _mainQuestion.text;
    _currentCard.question.sub = _subQuestion.text;
    _currentCard.question.imageFullPath = _questionImageFullPath;
    _currentCard.question.imageFullPath2 = _questionImageFullPath2;
    
    _currentCard.question.backgroundImageFullPath = _questionBackgroundImageFullPath;
    
    _currentCard.question.movieFullPath = _questionMovieFullPath;
    _currentCard.question.movieFullPath2 = _questionMovieFullPath2;
    
    _currentCard.question.css.subheadingAlign = _subheadingAlignQuestion;
    _currentCard.question.css.subheadingColor = _subheadingColorQuestion;
    _currentCard.question.css.subheadingSize = _subheadingSizeQuestion;
    _currentCard.question.css.subheadingText2SpeechSound = _subheadingText2SpeechQuestion;
    _currentCard.question.css.mainAlign = _mainAlignQuestion;
    _currentCard.question.css.mainColor = _mainColorQuestion;
    _currentCard.question.css.mainSize = _mainSizeQuestion;
    _currentCard.question.css.mainText2SpeechSound = _mainText2SpeechQuestion;
    _currentCard.question.css.subAlign = _subAlignQuestion;
    _currentCard.question.css.subColor = _subColorQuestion;
    _currentCard.question.css.subSize = _subSizeQuestion;
    _currentCard.question.css.subText2SpeechSound = _subText2SpeechQuestion;
    
    _currentCard.question.css.subheadingAlignVertical = _subheadingAlignVerticalQuestion;
    _currentCard.question.css.mainAlignVertical = _mainAlignVerticalQuestion;
    _currentCard.question.css.subAlignVertical = _subAlignVerticalQuestion;
    
    _currentCard.question.css.subheadingFont = _subheadingFontQuestion;
    _currentCard.question.css.mainFont = _mainFontQuestion;
    _currentCard.question.css.subFont = _subFontQuestion;
    
    _currentCard.question.css.subheadingSemiTransparent = (_subheadingQuestion.alpha == 0.5);
    _currentCard.question.css.mainSemiTransparent       = (_mainQuestion.alpha == 0.5);
    _currentCard.question.css.subSemiTransparent        = (_subQuestion.alpha == 0.5);
    
    
    //This is very important.In this case, the answer card is not still full inflated (correct templated ID is not assigned yet) and you can not caclucate line numbe correctly
    //we did this when:
    //1. manually click segmented control to switch QA  (we have to do this since users could switch QA without saving content, so we need to cache it.
    //AND 2. save cards
    if (_segmentedControl.selectedSegmentIndex == 0) {
        _currentCard.question.lineNoSubheading = [self lineNumberWithUITextView:_subheadingQuestion];
        _currentCard.question.lineNoMain = [self lineNumberWithUITextView:_mainQuestion];
        _currentCard.question.lineNoSub = [self lineNumberWithUITextView:_subQuestion];
    } else {
        _currentCard.answer.lineNoSubheading = [self lineNumberWithUITextView:_subheadingAnswer];
        _currentCard.answer.lineNoMain = [self lineNumberWithUITextView:_mainAnswer];
        _currentCard.answer.lineNoSub = [self lineNumberWithUITextView:_subAnswer];
    }
    
//debug code
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"lineNoSubheading,lineNoMain,lineNoSub for Q/A" message:[NSString stringWithFormat:@"%d,%d,%d;%d,%d,%d",
//                _currentCard.question.lineNoSubheading,_currentCard.question.lineNoMain,_currentCard.question.lineNoSub,
//                _currentCard.answer.lineNoSubheading,_currentCard.answer.lineNoMain,_currentCard.answer.lineNoSub] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//    [alertView show];
    
    _currentPack.creatorNickName = _creatorText.text;
    _currentPack.jobTitle = _jobTitleText.text;
    _currentPack.sidebarTitle = _sidebarTitle.text;
}

- (int) lineNumberWithUITextView:(UITextView *) textView
{
    
    float textHeight = [self getTextSizeHeight:textView];
    float lineHeight = textView.font.lineHeight;
    
    
    //实际中，你会看到numLines是一个非常接近整数的数值。比如如下
    //2.030135 ---- 2
    //3.008099 ---- 3
    //在从2行到3行的逐渐变化中，numLines起先是在2.02附近；然后一旦到了3行，则突然跳跃到3.00附近。
    //也就是说numLines永远不可能是一个3.5， 3.9的数，而是一个非常接近round的数
    //以下一个真实的debug数据：
    //font size= 24.600000,numLines = 4.019534, textHeight = 118.000000, lineHeight = 29.356640 with TextView = {{3, 29}, {304.5, 153}}
    //font size= 24.500000,numLines = 3.009853, textHeight = 88.000000, lineHeight = 29.237305 with TextView = {{3, 29}, {304.5, 153}}
    
    CGFloat numLines = textHeight / lineHeight;
    
    int returnVal = round(numLines);
    
//    NSLog(@"font size= %f,numLines = %f, textHeight = %f, lineHeight = %f with TextView = %@",textView.font.pointSize
//          ,numLines, textHeight,lineHeight,NSStringFromCGRect(textView.frame));

    
    return returnVal;
}

#pragma mark -
#pragma mark - Update CSS (only CSS)

//CSS part which is included in three main parts: CSS, template(position) and content
- (void) updateQuestionAndAnswerCSS {
    [iConsole info:@"%s",__FUNCTION__];
    if (_currentCard == nil) {
        [Common alertViewCommon:@"Need to set currentCard beforehand"];
    }
    
    _subheadingFontAnswer = _currentCard.answer.css.subheadingFont;
    _mainFontAnswer = _currentCard.answer.css.mainFont;
    _subFontAnswer = _currentCard.answer.css.subFont;
    
    _subheadingFontQuestion = _currentCard.question.css.subheadingFont;
    _mainFontQuestion = _currentCard.question.css.mainFont;
    _subFontQuestion = _currentCard.question.css.subFont;
    
    //PartA: Question
    CSS *css = _currentCard.question.css;
    //1. subheading
    //during creating a new card, we used default value
    
    if (_subheadingFontQuestion.length == 0) {
        _subheadingQuestion.font =[UIFont boldSystemFontOfSize:css.subheadingSize];
    } else {
        _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:css.subheadingSize];
    }
    
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        if (_subheadingFontQuestion.length == 0) {
            _subheadingQuestion.font =[UIFont boldSystemFontOfSize:css.subheadingSize*kFlashCardViewProporation_iPhone];
        } else {
            _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:css.subheadingSize*kFlashCardViewProporation_iPhone];
        }
    }
    _subheadingSizeQuestion = css.subheadingSize;
    
    if ([css.subheadingColor isEqualToString:@"Blue"]) {
        _subheadingQuestion.textColor = [UIColor blueColor];
        _subheadingColorQuestion = @"Blue";
    } else if ([css.subheadingColor isEqualToString:@"Red"]) {
        _subheadingQuestion.textColor = [UIColor redColor];
        _subheadingColorQuestion = @"Red";
    } else if ([css.subheadingColor isEqualToString:@"Yellow"]) {
        _subheadingQuestion.textColor = [UIColor yellowColor];
        _subheadingColorQuestion = @"Yellow";
    } else if ([css.subheadingColor isEqualToString:@"Black"]) {
        _subheadingQuestion.textColor = [UIColor blackColor];
        _subheadingColorQuestion = @"Black";
    } else if ([css.subheadingColor isEqualToString:@"Green"]) {
        _subheadingQuestion.textColor = [UIColor greenColor];
        _subheadingColorQuestion = @"Green";
    } else if ([css.subheadingColor isEqualToString:@"White"]) {
        _subheadingQuestion.textColor = [UIColor whiteColor];
        _subheadingColorQuestion = @"White";
    }
    
    if ([css.subheadingAlign isEqualToString:@"Left"]) {
        _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
        _subheadingAlignQuestion = @"Left";
    } else if ([css.subheadingAlign isEqualToString:@"Center"]) {
        _subheadingQuestion.textAlignment = NSTextAlignmentCenter;
        _subheadingAlignQuestion = @"Center";
    }else if ([css.subheadingAlign isEqualToString:@"Right"]) {
        _subheadingQuestion.textAlignment = NSTextAlignmentRight;
        _subheadingAlignQuestion = @"Right";
    }else if ([css.subheadingAlign isEqualToString:@"Justify"]) {
        _subheadingQuestion.textAlignment = NSTextAlignmentJustified;
        _subheadingAlignQuestion = @"Justify";
    }
    
    _subheadingText2SpeechQuestion = css.subheadingText2SpeechSound;
    
    //2. main
    //during creating a new card, we used default value
    if (_mainFontQuestion.length == 0) {
        _mainQuestion.font =[UIFont boldSystemFontOfSize:css.mainSize];
    } else {
        _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:css.mainSize];
    }
    
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        if (_mainFontQuestion.length == 0) {
            _mainQuestion.font =[UIFont boldSystemFontOfSize:css.mainSize*kFlashCardViewProporation_iPhone];
        } else {
            _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:css.mainSize*kFlashCardViewProporation_iPhone];
        }
    }
    _mainSizeQuestion = css.mainSize;
    
    if ([css.mainColor isEqualToString:@"Blue"]) {
        _mainQuestion.textColor = [UIColor blueColor];
        _mainColorQuestion = @"Blue";
    } else if ([css.mainColor isEqualToString:@"Red"]) {
        _mainQuestion.textColor = [UIColor redColor];
        _mainColorQuestion = @"Red";
    } else if ([css.mainColor isEqualToString:@"Yellow"]) {
        _mainQuestion.textColor = [UIColor yellowColor];
        _mainColorQuestion = @"Yellow";
    } else if ([css.mainColor isEqualToString:@"Black"]) {
        _mainQuestion.textColor = [UIColor blackColor];
        _mainColorQuestion = @"Black";
    } else if ([css.mainColor isEqualToString:@"Green"]) {
        _mainQuestion.textColor = [UIColor greenColor];
        _mainColorQuestion = @"Green";
    }  else if ([css.mainColor isEqualToString:@"White"]) {
        _mainQuestion.textColor = [UIColor whiteColor];
        _mainColorQuestion = @"White";
    }
    
    if ([css.mainAlign isEqualToString:@"Left"]) {
        _mainQuestion.textAlignment = NSTextAlignmentLeft;
        _mainAlignQuestion = @"Left";
    } else if ([css.mainAlign isEqualToString:@"Center"]) {
        _mainQuestion.textAlignment = NSTextAlignmentCenter;
        _mainAlignQuestion = @"Center";
    }else if ([css.mainAlign isEqualToString:@"Right"]) {
        _mainQuestion.textAlignment = NSTextAlignmentRight;
        _mainAlignQuestion = @"Right";
    }else if ([css.mainAlign isEqualToString:@"Justify"]) {
        _mainQuestion.textAlignment = NSTextAlignmentJustified;
        _mainAlignQuestion = @"Justify";
    }
    
    _mainText2SpeechQuestion = css.mainText2SpeechSound;
    
    //3. sub
    //during creating a new card, we used default value
    if (_subFontQuestion.length == 0) {
        _subQuestion.font =[UIFont boldSystemFontOfSize:css.subSize];
    } else {
        _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:css.subSize];
    }
    
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        if (_subFontQuestion.length == 0) {
            _subQuestion.font =[UIFont boldSystemFontOfSize:css.subSize*kFlashCardViewProporation_iPhone];
        } else {
            _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:css.subSize*kFlashCardViewProporation_iPhone];
        }
    }
    _subSizeQuestion = css.subSize;
    
    if ([css.subColor isEqualToString:@"Blue"]) {
        _subQuestion.textColor = [UIColor blueColor];
        _subColorQuestion = @"Blue";
    } else if ([css.subColor isEqualToString:@"Red"]) {
        _subQuestion.textColor = [UIColor redColor];
        _subColorQuestion = @"Red";
    } else if ([css.subColor isEqualToString:@"Yellow"]) {
        _subQuestion.textColor = [UIColor yellowColor];
        _subColorQuestion = @"Yellow";
    } else if ([css.subColor isEqualToString:@"Black"]) {
        _subQuestion.textColor = [UIColor blackColor];
        _subColorQuestion = @"Black";
    } else if ([css.subColor isEqualToString:@"Green"]) {
        _subQuestion.textColor = [UIColor greenColor];
        _subColorQuestion = @"Green";
    } else if ([css.subColor isEqualToString:@"White"]) {
        _subQuestion.textColor = [UIColor whiteColor];
        _subColorQuestion = @"White";
    }
    
    if ([css.subAlign isEqualToString:@"Left"]) {
        _subQuestion.textAlignment = NSTextAlignmentLeft;
        _subAlignQuestion = @"Left";
    } else if ([css.subAlign isEqualToString:@"Center"]) {
        _subQuestion.textAlignment = NSTextAlignmentCenter;
        _subAlignQuestion = @"Center";
    }else if ([css.subAlign isEqualToString:@"Right"]) {
        _subQuestion.textAlignment = NSTextAlignmentRight;
        _subAlignQuestion = @"Right";
    }else if ([css.subAlign isEqualToString:@"Justify"]) {
        _subQuestion.textAlignment = NSTextAlignmentJustified;
        _subAlignQuestion = @"Justify";
    }
    
    _subText2SpeechQuestion = css.subText2SpeechSound;
    
    //PartB: Answer
    css= _currentCard.answer.css;
    //1. subheading
    //during creating a new card, we used default value
    if (_subheadingFontAnswer.length == 0) {
        _subheadingAnswer.font =[UIFont boldSystemFontOfSize:css.subheadingSize];
    } else {
        _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:css.subheadingSize];
    }
    
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        if (_subheadingFontAnswer.length == 0) {
            _subheadingAnswer.font =[UIFont boldSystemFontOfSize:css.subheadingSize*kFlashCardViewProporation_iPhone];
        } else {
            _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:css.subheadingSize*kFlashCardViewProporation_iPhone];
        }
    }
    _subheadingSizeAnswer = css.subheadingSize;
    
    if ([css.subheadingColor isEqualToString:@"Blue"]) {
        _subheadingAnswer.textColor = [UIColor blueColor];
        _subheadingColorAnswer = @"Blue";
    } else if ([css.subheadingColor isEqualToString:@"Red"]) {
        _subheadingAnswer.textColor = [UIColor redColor];
        _subheadingColorAnswer = @"Red";
    } else if ([css.subheadingColor isEqualToString:@"Yellow"]) {
        _subheadingAnswer.textColor = [UIColor yellowColor];
        _subheadingColorAnswer = @"Yellow";
    } else if ([css.subheadingColor isEqualToString:@"Black"]) {
        _subheadingAnswer.textColor = [UIColor blackColor];
        _subheadingColorAnswer = @"Black";
    } else if ([css.subheadingColor isEqualToString:@"Green"]) {
        _subheadingAnswer.textColor = [UIColor greenColor];
        _subheadingColorAnswer = @"Green";
    } else if ([css.subheadingColor isEqualToString:@"White"]) {
        _subheadingAnswer.textColor = [UIColor whiteColor];
        _subheadingColorAnswer = @"White";
    }
    
    
    if ([css.subheadingAlign isEqualToString:@"Left"]) {
        _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
        _subheadingAlignAnswer = @"Left";
    } else if ([css.subheadingAlign isEqualToString:@"Center"]) {
        _subheadingAnswer.textAlignment = NSTextAlignmentCenter;
        _subheadingAlignAnswer = @"Center";
    }else if ([css.subheadingAlign isEqualToString:@"Right"]) {
        _subheadingAnswer.textAlignment = NSTextAlignmentRight;
        _subheadingAlignAnswer = @"Right";
    }else if ([css.subheadingAlign isEqualToString:@"Justify"]) {
        _subheadingAnswer.textAlignment = NSTextAlignmentJustified;
        _subheadingAlignAnswer = @"Justify";
    }
    
    _subheadingText2SpeechAnswer = css.subheadingText2SpeechSound;
    
    
    //2. main
    //during creating a new card, we used default value
    if (_mainFontAnswer.length == 0) {
        _mainAnswer.font =[UIFont boldSystemFontOfSize:css.mainSize];
    } else {
        _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:css.mainSize];
    }
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        if (_mainFontAnswer.length == 0) {
            _mainAnswer.font =[UIFont boldSystemFontOfSize:css.mainSize*kFlashCardViewProporation_iPhone];
        } else {
            _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:css.mainSize*kFlashCardViewProporation_iPhone];
        }
    }
    _mainSizeAnswer = css.mainSize;
    
    if ([css.mainColor isEqualToString:@"Blue"]) {
        _mainAnswer.textColor = [UIColor blueColor];
        _mainColorAnswer = @"Blue";
    } else if ([css.mainColor isEqualToString:@"Red"]) {
        _mainAnswer.textColor = [UIColor redColor];
        _mainColorAnswer = @"Red";
    } else if ([css.mainColor isEqualToString:@"Yellow"]) {
        _mainAnswer.textColor = [UIColor yellowColor];
        _mainColorAnswer = @"Yellow";
    } else if ([css.mainColor isEqualToString:@"Black"]) {
        _mainAnswer.textColor = [UIColor blackColor];
        _mainColorAnswer = @"Black";
    } else if ([css.mainColor isEqualToString:@"Green"]) {
        _mainAnswer.textColor = [UIColor greenColor];
        _mainColorAnswer = @"Green";
    } else if ([css.mainColor isEqualToString:@"White"]) {
        _mainAnswer.textColor = [UIColor whiteColor];
        _mainColorAnswer = @"White";
    }
    
    if ([css.mainAlign isEqualToString:@"Left"]) {
        _mainAnswer.textAlignment = NSTextAlignmentLeft;
        _mainAlignAnswer = @"Left";
    } else if ([css.mainAlign isEqualToString:@"Center"]) {
        _mainAnswer.textAlignment = NSTextAlignmentCenter;
        _mainAlignAnswer = @"Center";
    }else if ([css.mainAlign isEqualToString:@"Right"]) {
        _mainAnswer.textAlignment = NSTextAlignmentRight;
        _mainAlignAnswer = @"Right";
    }else if ([css.mainAlign isEqualToString:@"Justify"]) {
        _mainAnswer.textAlignment = NSTextAlignmentJustified;
        _mainAlignAnswer = @"Justify";
    }
    
    _mainText2SpeechAnswer = css.mainText2SpeechSound;
    
    //3. sub
    //during creating a new card, we used default value
    if (_subFontAnswer.length == 0) {
        _subAnswer.font =[UIFont boldSystemFontOfSize:css.subSize];
    } else {
        _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:css.subSize];
    }
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        if (_subFontAnswer.length == 0) {
            _subAnswer.font =[UIFont boldSystemFontOfSize:css.subSize*kFlashCardViewProporation_iPhone];
        } else {
            _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:css.subSize*kFlashCardViewProporation_iPhone];
        }
    }
    _subSizeAnswer = css.subSize;
    
    if ([css.subColor isEqualToString:@"Blue"]) {
        _subAnswer.textColor = [UIColor blueColor];
        _subColorAnswer = @"Blue";
    } else if ([css.subColor isEqualToString:@"Red"]) {
        _subAnswer.textColor = [UIColor redColor];
        _subColorAnswer = @"Red";
    } else if ([css.subColor isEqualToString:@"Yellow"]) {
        _subAnswer.textColor = [UIColor yellowColor];
        _subColorAnswer = @"Yellow";
    } else if ([css.subColor isEqualToString:@"Black"]) {
        _subAnswer.textColor = [UIColor blackColor];
        _subColorAnswer = @"Black";
    } else if ([css.subColor isEqualToString:@"Green"]) {
        _subAnswer.textColor = [UIColor greenColor];
        _subColorAnswer = @"Green";
    } else if ([css.subColor isEqualToString:@"White"]) {
        _subAnswer.textColor = [UIColor whiteColor];
        _subColorAnswer = @"White";
    }
    
    if ([css.subAlign isEqualToString:@"Left"]) {
        _subAnswer.textAlignment = NSTextAlignmentLeft;
        _subAlignAnswer = @"Left";
    } else if ([css.subAlign isEqualToString:@"Center"]) {
        _subAnswer.textAlignment = NSTextAlignmentCenter;
        _subAlignAnswer = @"Center";
    }else if ([css.subAlign isEqualToString:@"Right"]) {
        _subAnswer.textAlignment = NSTextAlignmentRight;
        _subAlignAnswer = @"Right";
    }else if ([css.subAlign isEqualToString:@"Justify"]) {
        _subAnswer.textAlignment = NSTextAlignmentJustified;
        _subAlignAnswer = @"Justify";
    }
    
    _subText2SpeechAnswer = css.subText2SpeechSound;
    
    
    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark - Update template (postion and css, but css will be rewrited by updateCSS)

/**
 *  规定，所有UITextView默认（正常）contentSize = 0
 */
- (void) resetAllUITextViewContentOffset {
    [iConsole info:@"%s",__FUNCTION__];
    _mainQuestion.contentOffset = CGPointZero;
    _subheadingQuestion.contentOffset = CGPointZero;
    _subQuestion.contentOffset = CGPointZero;
    
    _mainAnswer.contentOffset = CGPointZero;
    _subheadingAnswer.contentOffset = CGPointZero;
    _subAnswer.contentOffset = CGPointZero;
}

- (void) updateQuestionOrAnswerTemplate {
    [iConsole info:@"%s",__FUNCTION__];
    if (isUserInterfaceIdiomPhone) {
        if (_segmentedControl.selectedSegmentIndex == 0) {
            [self updateQuestionViewTemplateForiPhone];
        } else {
            [self updateAnswerViewTemplateForiPhone];
        }
    }
    else {
        if (_segmentedControl.selectedSegmentIndex == 0) {
            [self updateQuestionViewTemplateForiPad];
        }else {
            [self updateAnswerViewTemplateForiPad];
        }
    }
    
    //之所以加上这个，主要是在.frame 时，contentOffset会莫名其妙的改变
    [self resetAllUITextViewContentOffset];
}

- (void) updateQuestionAndAnswerTemplate {
    [iConsole info:@"%s",__FUNCTION__];
    if (isUserInterfaceIdiomPhone) {
        [self updateQuestionViewTemplateForiPhone];
        [self updateAnswerViewTemplateForiPhone];
    }
    else {
        [self updateQuestionViewTemplateForiPad];
        [self updateAnswerViewTemplateForiPad];
    }
    
    //之所以加上这个，主要是在.frame 时，contentOffset会莫名其妙的改变
    [self resetAllUITextViewContentOffset];
}

//postion part which is included in three main parts: CSS, template(position) and content
- (void) updateAnswerViewTemplateForiPhone {
    [iConsole info:@"%s",__FUNCTION__];
    int index = _currentCard.answer.templateID;
    
    switch (index) {
        case 10:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 5, 304, 22);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 29, 304.5, 153);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = TRUE;
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 8: //Template 1
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 4, 218.75, 23);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 29, 304.5, 79);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(3, 110, 304.5, 70);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            _imageAnswer.hidden = TRUE;
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 7: //Template 2
        {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 5, 304.5, 129);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(3, 138, 304.5, 47);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentCenter;
            _subAlignAnswer = @"Center";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            _imageAnswer.hidden = TRUE;
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 6: //Template 3
        {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 5, 304.5, 90);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(3, 98, 304.5, 86);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            _imageAnswer.hidden = TRUE;
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 3: //Template 4
        {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 8, 304.5, 174.5);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:14];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:14];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:14*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:14*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 14;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = TRUE;
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 5: //Template 5
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = TRUE;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(3, 5, 304.5, 180);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 0:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 156, 29);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 34, 156, 148);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(161, 15, 152, 152);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 4:
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 3, 157, 183);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(162, 10, 153, 153);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 1:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 304.5, 27);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 32, 156, 127);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(3, 162, 156, 24);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(164, 33.5, 143, 141.5);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 11:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 156, 30);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = YES;
            _subAnswer.hidden = TRUE;
            
            _imageAnswer2.hidden = FALSE;
            _imageAnswer2.frame = CGRectMake(5, 35, 152, 152);
            if (self.isPlayingCard) {
                _imageAnswer2.frame = [Common getScaledViewRect:_imageAnswer2 withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(160, 3, 152, 184);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            break;
        }
            
        case 2:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 156, 88);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 92.5, 156, 89);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(163, 15, 152, 152);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 9:
        {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(5, 6, 151, 175);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            //
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(158, 6, 148, 175);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            _imageAnswer.hidden = YES;
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 12:
        {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(5, 6, 64.5, 177);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            //
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(71, 6, 237, 177);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            _imageAnswer.hidden = YES;
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 13:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 157, 153.5);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 157, 157, 27);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(162, 3, 152, 181);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 14:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 156, 47);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(3, 52, 156, 85);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            //dfdsfsdfsdfdsdsf
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(3, 139, 156, 46);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(162, 3, 152, 181);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
            
        case 15:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 150, 144, 28);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(158, 150, 144, 28);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 20;
            
            
            
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer2.hidden = FALSE;
            _imageAnswer2.frame = CGRectMake(10, 8, 143, 141);
            if (self.isPlayingCard) {
                _imageAnswer2.frame = [Common getScaledViewRect:_imageAnswer2 withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(159, 8, 143, 141);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            break;
        }
            
            
        case 16:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(158, 3, 154, 47);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontAnswer.length == 0) {
                    _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(158, 52, 154, 85);
            if (self.isPlayingCard) {
                _mainAnswer.frame = [Common getScaledViewRect:_mainAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontAnswer.length == 0) {
                    _mainAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            //dfdsfsdfsdfdsdsf
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(158, 139, 154, 46);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(3, 15, 152, 152);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 17: {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = YES;
            
            _subAnswer.hidden = NO;
            _subAnswer.frame = CGRectMake(3, 138, 304.5, 47);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentCenter;
            _subAlignAnswer = @"Center";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(80, 10, 152, 120);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
            
        default:
        {
            [iConsole info:@"%s:No template is selected",__FUNCTION__];
            break;
        }
            
    }
    
    
    
    
    _subheadingAnswer.contentOffset = CGPointZero;
    _mainAnswer.contentOffset = CGPointZero;
    _subAnswer.contentOffset = CGPointZero;
}

- (void) updateAnswerViewTemplateForiPad {
    [iConsole info:@"%s",__FUNCTION__];
    long index = _currentCard.answer.templateID;
    
    switch (index) {
        case 10: //Template 0
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 710, 52);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:30];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:30];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 30;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 65, 710, 362);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:38];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:38];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 38;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = TRUE;
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 8: //Template 1
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 500, 54);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:34];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 34;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 67, 710, 192);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:38];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:38];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 38;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(10, 261, 710, 171);
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:30];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:30];
            }
            
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentCenter;
            _subAlignAnswer = @"Center";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 30;
            
            _imageAnswer.hidden = TRUE;
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 7: //Template 2
        {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 10, 710, 305);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:42];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 42;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(10, 320, 710, 110);
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:34];
            }
            
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentCenter;
            _subAlignAnswer = @"Center";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 34;
            
            _imageAnswer.hidden = TRUE;
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 6: //Template 3
        {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 10, 710, 215);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:42];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 42;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(10, 230, 710, 205);
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:34];
            }
            
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 34;
            
            
            _imageAnswer.hidden = TRUE;
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 3: //Template 4
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 10, 710, 417);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:42];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 42;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = TRUE;
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 5: //Template 5
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = TRUE;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(10, 20, 710, 410);
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 0:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 363, 70);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:42];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 83, 363, 355);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:34];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 34;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 40, 350, 350);
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 4:
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 10, 365, 425);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:34];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 34;
            
            _subAnswer.hidden = YES;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 40, 350, 350);
            
            _imageAnswer2.hidden = TRUE;
            
            
            break;
        }
        case 1:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 710, 62);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:42];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 75, 358, 298);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:38];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:38];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 38;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(10, 375, 358, 50);
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:38];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:38];
            }
            
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Red";
            _subSizeAnswer = 38;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 80, 330, 330);
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 11:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 8, 360, 70);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:42];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = YES;
            _subAnswer.hidden = TRUE;
            
            _imageAnswer2.hidden = FALSE;
            _imageAnswer2.frame = CGRectMake(13, 83, 354, 354);;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(375, 8, 350, 75 + 354);
            
            
            break;
        }
        case 2:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 368, 210);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:42];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 225, 368, 210);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:34];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 34;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 40, 350, 350);
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 9:
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 20, 355, 413);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:42];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 42;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(368, 20, 345, 413);
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:42];
            }
            
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentCenter;
            _subAlignAnswer = @"Center";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 42;
            
            _imageAnswer.hidden = TRUE;
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 12:
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 10, 146, 412);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:42];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 42;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(160, 10, 555, 412);
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:42];
            }
            
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentCenter;
            _subAlignAnswer = @"Center";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 42;
            
            _imageAnswer.hidden = TRUE;
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 13:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 365, 360);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:42];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 370, 360, 60);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:34];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 34;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 10, 350, 420);
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
            
        case 14:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 365, 110);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:42];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 125, 365, 198);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:34];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 34;
            
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(10, 325, 365, 112);
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:34];
            }
            
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 34;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 10, 350, 420);
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
            
        case 15:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(20, 350, 328, 65);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:42];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(360, 350, 328, 65);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:42];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 42;
            
            
            
            _subAnswer.hidden = TRUE;
            
            
            _imageAnswer2.hidden = FALSE;
            _imageAnswer2.frame = CGRectMake(20, 20, 328, 328);
            
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(360, 20, 328, 328);
            
            
            break;
        }
            
            
        case 16:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(370, 10, 355, 105);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:42];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            
            _subheadingAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subheadingAnswer];
            
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(370, 120, 355, 197);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:34];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            
            _mainAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_mainAnswer];
            
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 34;
            
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(370, 320, 355, 113);
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:34];
            }
            
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            
            _subAlignVerticalAnswer = @"";
            [self resetVerticalAlignment:_subAnswer];
            
            _subColorAnswer = @"Black";
            _subSizeAnswer = 34;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(10, 40, 358, 350);
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 17: {
            
            {
                _subheadingAnswer.hidden = YES;
                
                _mainAnswer.hidden = YES;
                
                _subAnswer.hidden = FALSE;
                _subAnswer.frame = CGRectMake(10, 320, 710, 110);
                
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:34];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:34];
                }
                
                _subAnswer.textColor = [UIColor blackColor];
                _subAnswer.textAlignment = NSTextAlignmentCenter;
                _subAlignAnswer = @"Center";
                
                _subAlignVerticalAnswer = @"";
                [self resetVerticalAlignment:_subAnswer];
                
                _imageAnswer.hidden = FALSE;
                _imageAnswer.frame = CGRectMake(200, 40, 320, 250);
                
                
                _imageAnswer2.hidden = TRUE;
                
                break;
            }
        }
            
            
        default:
        {
            [iConsole info:@"%s:No template is selected",__FUNCTION__];
            break;
        }
            
    }
    
    _subheadingAnswer.contentOffset = CGPointZero;
    _mainAnswer.contentOffset = CGPointZero;
    _subAnswer.contentOffset = CGPointZero;
}


//postion part which is included in three main parts: CSS, template(position) and content
- (void) updateQuestionViewTemplateForiPad {
    [iConsole info:@"%s",__FUNCTION__];
    long index = _currentCard.question.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 10, 710, 52);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:30];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:30];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 30;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 65, 710, 362);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:38];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:38];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 38;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = TRUE;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 10, 500, 54);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:34];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 34;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 67, 710, 192);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:38];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:38];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 38;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(10, 261, 710, 171);
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:30];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:30];
            }
            
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentCenter;
            _subAlignQuestion = @"Center";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 30;
            
            _imageQuestion.hidden = TRUE;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 2: //Template 2
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 10, 710, 305);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:42];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 42;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(10, 320, 710, 110);
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:34];
            }
            
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentCenter;
            _subAlignQuestion = @"Center";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 34;
            
            _imageQuestion.hidden = TRUE;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 10, 710, 215);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:42];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 42;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(10, 230, 710, 205);
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:34];
            }
            
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 34;
            
            
            _imageQuestion.hidden = TRUE;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 4: //Template 4
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 10, 710, 417);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:42];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 42;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = TRUE;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 5: //Template 5
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = TRUE;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(10, 20, 710, 410);
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 6:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 10, 363, 70);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:42];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 42;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 83, 363, 355);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:34];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 34;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(380, 40, 350, 350);
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 7:
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 10, 365, 425);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:34];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 34;
            
            _subQuestion.hidden = YES;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(380, 40, 350, 350);
            
            _imageQuestion2.hidden = TRUE;
            
            
            break;
        }
        case 8:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 10, 710, 62);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:42];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 42;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 75, 358, 298);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:38];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:38];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 38;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(10, 375, 358, 50);
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:38];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:38];
            }
            
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Red";
            _subSizeQuestion = 38;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(380, 80, 330, 330);
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 9:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 8, 360, 70);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:42];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 42;
            
            _mainQuestion.hidden = TRUE;
            _subQuestion.hidden = TRUE;
            
            
            _imageQuestion2.hidden = FALSE;
            _imageQuestion2.frame = CGRectMake(13, 83, 354, 354);
            
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(375, 8, 350, 75 + 354);
            
            
            break;
        }
            
        case 10:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 10, 368, 210);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:42];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 42;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 225, 368, 210);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:34];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 34;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(380, 40, 350, 350);
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 11:
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 20, 355, 413);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:42];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 42;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(368, 20, 345, 413);
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:42];
            }
            
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentCenter;
            _subAlignQuestion = @"Center";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 42;
            
            _imageQuestion.hidden = TRUE;
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 12:
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 10, 146, 412);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:42];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 42;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(160, 10, 555, 412);
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:42];
            }
            
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentCenter;
            _subAlignQuestion = @"Center";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 42;
            
            _imageQuestion.hidden = TRUE;
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 13:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 10, 365, 360);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:42];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 42;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 370, 360, 60);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:34];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 34;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(380, 10, 350, 420);
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
            
        case 14:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 10, 365, 110);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:42];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 42;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 125, 365, 198);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:34];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 34;
            
     
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(10, 325, 365, 112);
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:34];
            }
            
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 34;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(380, 10, 350, 420);
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        
        case 15:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(20, 350, 328, 65);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:42];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 42;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(360, 350, 328, 65);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:42];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 42;
            
            
            
            _subQuestion.hidden = TRUE;
            
            
            _imageQuestion2.hidden = FALSE;
            _imageQuestion2.frame = CGRectMake(20, 20, 328, 328);
            
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(360, 20, 328, 328);
            
            
            break;
        }
            
            
        case 16:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(370, 10, 355, 105);
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:42];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:42];
            }
            
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 42;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(370, 120, 355, 197);
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:34];
            }
            
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 34;
            
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(370, 320, 355, 113);
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:34];
            }
            
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 34;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(10, 40, 358, 350);
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 17: {
            
            {
                _subheadingQuestion.hidden = YES;
                
                _mainQuestion.hidden = YES;
                
                _subQuestion.hidden = FALSE;
                _subQuestion.frame = CGRectMake(10, 320, 710, 110);
                
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:34];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:34];
                }
                
                _subQuestion.textColor = [UIColor blackColor];
                _subQuestion.textAlignment = NSTextAlignmentCenter;
                _subAlignQuestion = @"Center";
                
                _subAlignVerticalQuestion = @"";
                [self resetVerticalAlignment:_subQuestion];
            
                _imageQuestion.hidden = FALSE;
                _imageQuestion.frame = CGRectMake(200, 40, 320, 250);
                
                
                _imageQuestion2.hidden = TRUE;
                
                break;
            }
        }
            
        default:
        {
            [iConsole info:@"%s:No template is selected",__FUNCTION__];
            break;
        }
            
    }
    
    _subheadingQuestion.contentOffset = CGPointZero;
    _mainQuestion.contentOffset = CGPointZero;
    _subQuestion.contentOffset = CGPointZero;
}

- (void) updateQuestionViewTemplateForiPhone {
    [iConsole info:@"%s",__FUNCTION__];
    long index = _currentCard.question.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 5, 304, 22);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 29, 304.5, 153);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = TRUE;
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 4, 218.75, 23);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 29, 304.5, 79);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(3, 110, 304.5, 70);
            if (self.isPlayingCard) {
                _subQuestion.frame = [Common getScaledViewRect:_subQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            _imageQuestion.hidden = TRUE;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 2: //Template 2
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 5, 304.5, 129);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(3, 138, 304.5, 47);
            if (self.isPlayingCard) {
                _subQuestion.frame = [Common getScaledViewRect:_subQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentCenter;
            _subAlignQuestion = @"Center";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            _imageQuestion.hidden = TRUE;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 5, 304.5, 90);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(3, 98, 304.5, 86);
            if (self.isPlayingCard) {
                _subQuestion.frame = [Common getScaledViewRect:_subQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            
            _imageQuestion.hidden = TRUE;
            _imageQuestion2.hidden = TRUE;
            
            
            break;
        }
        case 4: //Template 4
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 8, 304.5, 174.5);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:14];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:14];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:14*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:14*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 14;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = TRUE;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 5: //Template 5
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = TRUE;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(3, 5, 304.5, 180);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 6:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 3, 156, 29);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 34, 156, 148);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(161, 15, 152, 152);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 7:
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 3, 157, 183);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(162, 10, 153, 153);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            
            break;
        }
        case 8:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 3, 304.5, 27);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 32, 156, 127);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(3, 162, 156, 24);
            if (self.isPlayingCard) {
                _subQuestion.frame = [Common getScaledViewRect:_subQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(164, 33.5, 143, 141.5);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 9:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 3, 156, 30);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = YES;
            _subQuestion.hidden = TRUE;
            
            _imageQuestion2.hidden = FALSE;
            _imageQuestion2.frame = CGRectMake(5, 35, 152, 152);
            if (self.isPlayingCard) {
                _imageQuestion2.frame = [Common getScaledViewRect:_imageQuestion2 withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(160, 3, 152, 184);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            break;
        }
            
        case 10:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 3, 156, 88);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 92.5, 156, 89);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(163, 15, 152, 152);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
        case 11:
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(5, 6, 151, 175);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            //
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(158, 6, 148, 175);
            if (self.isPlayingCard) {
                _subQuestion.frame = [Common getScaledViewRect:_subQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            _imageQuestion.hidden = YES;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 12:
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(5, 6, 64.5, 177);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            //
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(71, 6, 237, 177);
            if (self.isPlayingCard) {
                _subQuestion.frame = [Common getScaledViewRect:_subQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            _imageQuestion.hidden = YES;
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 13:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 3, 157, 153.5);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 157, 157, 27);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(162, 3, 152, 181);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
            
        case 14:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 3, 156, 47);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(3, 52, 156, 85);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            //dfdsfsdfsdfdsdsf
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(3, 139, 156, 46);
            if (self.isPlayingCard) {
                _subQuestion.frame = [Common getScaledViewRect:_subQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(162, 3, 152, 181);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
            
        case 15:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 150, 144, 28);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            

            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(158, 150, 144, 28);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 20;
            
            
            
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion2.hidden = FALSE;
            _imageQuestion2.frame = CGRectMake(10, 8, 143, 141);
            if (self.isPlayingCard) {
                _imageQuestion2.frame = [Common getScaledViewRect:_imageQuestion2 withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(159, 8, 143, 141);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            break;
        }

        case 16:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(158, 3, 154, 47);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subheadingFontQuestion.length == 0) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20];
            } else {
                _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20];
            }
            if (self.isPlayingCard) {
                if (_subheadingFontQuestion.length == 0) {
                    _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
                } else {
                    _subheadingQuestion.font =[UIFont fontWithName:_subheadingFontQuestion size:20*kFlashCardViewProporation_iPhone];
                }
            }
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            
            _subheadingAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subheadingQuestion];
            
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(158, 52, 154, 85);
            if (self.isPlayingCard) {
                _mainQuestion.frame = [Common getScaledViewRect:_mainQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_mainFontQuestion.length == 0) {
                _mainQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_mainFontQuestion.length == 0) {
                    _mainQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _mainQuestion.font =[UIFont fontWithName:_mainFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentLeft;
            _mainAlignQuestion = @"Left";
            
            _mainAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_mainQuestion];
            
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            //dfdsfsdfsdfdsdsf
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(158, 139, 154, 46);
            if (self.isPlayingCard) {
                _subQuestion.frame = [Common getScaledViewRect:_subQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentLeft;
            _subAlignQuestion = @"Left";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(3, 15, 152, 152);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 17: {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = YES;
            
            _subQuestion.hidden = NO;
            _subQuestion.frame = CGRectMake(3, 138, 304.5, 47);
            if (self.isPlayingCard) {
                _subQuestion.frame = [Common getScaledViewRect:_subQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            if (_subFontQuestion.length == 0) {
                _subQuestion.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16];
            }
            if (self.isPlayingCard) {
                if (_subFontQuestion.length == 0) {
                    _subQuestion.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subQuestion.font =[UIFont fontWithName:_subFontQuestion size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subQuestion.textColor = [UIColor blackColor];
            _subQuestion.textAlignment = NSTextAlignmentCenter;
            _subAlignQuestion = @"Center";
            
            _subAlignVerticalQuestion = @"";
            [self resetVerticalAlignment:_subQuestion];
            
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(80, 10, 152, 120);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        default:
        {
            [iConsole info:@"%s:No template is selected",__FUNCTION__];
            break;
        }
            
    }
    
    _subheadingQuestion.contentOffset = CGPointZero;
    _mainQuestion.contentOffset = CGPointZero;
    _subQuestion.contentOffset = CGPointZero;
}

#pragma mark -
#pragma mark - Keyboard Notification and related

- (void)keyboardWillHide:(NSNotification*)aNotification {
    [iConsole info:@"%s",__FUNCTION__];
    //we only deal with current card and new created card
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        return;
    }
    
    if (_isDismissKeyboardViaSaveButtonFromKeyboard) {
        //if true,dismissKeyBoard is called directly in "save button" action
    } else {
        //in this case, keyboard is closed by clicking "built-in hide button" on keyboard. Moreover, it's only an action of keyboard close, no coming save action
        
        [self dismissKeyBoard:nil withSaveComing:false];
        
    }
    
    _isDismissKeyboardViaSaveButtonFromKeyboard = false;
    
    
}


- (void)keyboardWillShow:(NSNotification*)aNotification {
    [iConsole info:@"%s",__FUNCTION__];
    //step1: we only deal with current card and new created card
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        return;
    }
    
    //only repsonde to UITextView
    if (_isUITextViewFocused) {
        
        //step1: bring out the _keyboardTopView
        CGRect keyboardBounds;
        [[aNotification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            _keyboardHeight = keyboardBounds.size.width;
        } else {
            _keyboardHeight = keyboardBounds.size.height;
        }
        
    }
    
    
    if (isUserInterfaceIdiomPhone) {
        //we don't need to hide navigation bar on ipAD
        [[NSNotificationCenter defaultCenter] postNotificationName:HIDE_NAVIGATION_BAR_NOTIFICATION object:nil];
    }
    
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
    [iConsole info:@"%s",__FUNCTION__];
    
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        return;
    }
    
    if (_isUITextViewFocused == FALSE) {
        return;
    }
    
    //Step1: Get cursor Y value relative to view
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    if (responderTextView.text.length == 0) {
        NSRange range;
        range.location = 0;
        range.length = 0;
        responderTextView.selectedRange = range;
    }
    CGFloat cursorY = [responderTextView caretRectForPosition:responderTextView.selectedTextRange.start].origin.y + responderTextView.font.lineHeight;
    //[iConsole info:@"Y position for current cursorY is %f",cursorY);
    
    if (cursorY > CGRectGetHeight(responderTextView.frame)) {
        cursorY = CGRectGetHeight(responderTextView.frame);
    }
    
    //Step2: Get view's Y value relative to screen
    CGFloat yInScrren;
    if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)){
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].y;
        } else {
            yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].x;
        }
    } else {
        //Since we convert to point based on UIWindow
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if (isUserInterfaceIdiomPhone) {
                yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].y;
            } else {
                yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].y;
            }
        } else {
            if (isUserInterfaceIdiomPhone) {
                yInScrren = IPHONE_UI_HEIGHT - [responderTextView convertPoint:CGPointZero toView:nil].x;
            } else {
                yInScrren = IPAD_UI_HEIGHT -[responderTextView convertPoint:CGPointZero toView:nil].x;
            }
        }
        
    }
    
    //Step3: calculate the offset and gap value
    CGPoint offset = _verticalScrollView.contentOffset;
    CGFloat gap;
    if (isUserInterfaceIdiomPhone) {
        gap = _keyboardHeight -(IPHONE_UI_HEIGHT - yInScrren - cursorY);
    } else {
        gap = _keyboardHeight -(IPAD_UI_HEIGHT - yInScrren - cursorY);
    }
    
    if (gap >0)
        offset.y = gap;
    
    
    //Step4: set contentSize which is used by user for manually scroll up/down
    CGFloat scrollableOffset = responderTextView.frame.size.height - cursorY;
    CGSize size = _verticalScrollView.contentSize;
    if (gap > 0) {
        if (isUserInterfaceIdiomPhone ) {
            size.height =size.height + fabs(scrollableOffset) + gap;
        } else {
            size.height =size.height + fabs(scrollableOffset) + gap;
        }
        
    } else {
        size.height =size.height + fabs(scrollableOffset) - fabs(gap);
    }
    _verticalScrollView.contentSize = size;
    
    //Step5: move scrollview
    [_verticalScrollView setContentOffset:offset animated:YES];
    
    
    if (_keyboardShown)
        return;
    
    _keyboardShown = YES;
    
}




- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    
    [iConsole info:@"%s",__FUNCTION__];
    
    
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        return;
    }
    
    
    _dismissKeyboardFromEmotionSwitch = FALSE;
    
    if ((_isUITextViewFocused == FALSE) && (isUserInterfaceIdiomPhone)) {
        //we don't need to hide navigation bar on iPad
        //we don't need to do this in UITextView since we will do that at DissmissKeyboard
        [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NAVIGATION_BAR_NOTIFICATION object:nil];
    }
    _keyboardShown = NO;
    
    if (_saveButtonPressed == YES) {
        _saveButtonPressed = NO;
        
        if (self.tag == NEW_FLASHCARDVIEW_TAG) {
            //we will save until after we press the save button
            [self commitQuestionAndAnswerData];
            [self hideAllSemiTransparentTextViews];
            [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_NEW_CREATED_CARD_NOTIFICATION object:nil];
        } else {
            __weak __typeof(&*self)weakSelf = self;
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [weakSelf saveEdittedCard];
                [weakSelf hideAllSemiTransparentTextViews];
            });
        }
    } else {
        //只是关闭键盘
        //每当只是关闭键盘时，这时如果是NEW_FLASHCARDVIEW_TAG，我们需要把数据暂存一下，以免segement QA切换会引起数据丢失
        if (self.tag == NEW_FLASHCARDVIEW_TAG) {
            [self commitQuestionAndAnswerData];
            [self hideAllSemiTransparentTextViews];
        }
        
    }
    
    if ([self isVerticalAlignment:_lastBecomeFirstRespondTextView]) {
        [self setVerticalAlignment:_lastBecomeFirstRespondTextView];
    }
    
    
    
}


- (void) setUpInputView {
    [iConsole info:@"%s",__FUNCTION__];
    
    int columnCount;
    int rowCount;
    int emotionViewHeight;
    int cssToolbarHeight;
    if (isUserInterfaceIdiomPhone) {
        columnCount = DEFAULT_COLUMN_COUNT_IPHONE;
        rowCount = DEFAULT_ROW_COUNT_IPHONE;
        cssToolbarHeight = IPHONE_UI_TOOL_BAR_HEIGHT;
        emotionViewHeight = CSS_EMOTION_VIEW_HEIGHT_IPHONE;
    } else {
        columnCount = DEFAULT_COLUMN_COUNT_IPAD;
        rowCount = DEFAULT_ROW_COUNT_IPAD;
        emotionViewHeight = CSS_EMOTION_VIEW_HEIGHT_IPAD;
        cssToolbarHeight = IPAD_UI_TOOL_BAR_HEIGHT;
    }
    
    //background view
    if (_keyboardInputBaseView == nil) {
        _keyboardInputBaseView = [[UIView alloc] initWithFrame:CGRectMake(0, [Common getScreenHeightInLandscape], [Common getScreenWidthInLandscape], (cssToolbarHeight + emotionViewHeight))];
        [_keyboardInputBaseView setBackgroundColor:[UIColor clearColor]];
        
    }
    
    
    //Emotion view
    
    if (_emoticonSelectionViewController == nil) {
        _emoticonSelectionViewController = [[EmoticonSelectionViewController alloc] initWithEmoticons:[EmoticonHelper defaultEmoticons] rowCount:rowCount columnCount:columnCount];
        _emoticonSelectionViewController.delegate = self;
        _emoticonSelectionViewController.view.frame = CGRectMake(0, cssToolbarHeight, [Common getScreenWidthInLandscape], emotionViewHeight);
        [_emoticonSelectionViewController layoutEmotions];
        
        [_keyboardInputBaseView addSubview:_emoticonSelectionViewController.view];
    }
    
    
    if (_keyboardTopViewForInputViewV2 == nil) {
        _keyboardTopViewForInputViewV2 = [[KeyboardTopView alloc]initWithFrame:CGRectMake(0, 0, [Common getScreenWidthInLandscape], cssToolbarHeight)];
    }
    _keyboardTopViewForInputViewV2.delegate = self;
    _keyboardTopViewForInputViewV2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [_keyboardTopViewForInputViewV2 setupSummaryArray];
    [_keyboardInputBaseView addSubview:_keyboardTopViewForInputViewV2];
    [_keyboardInputBaseView bringSubviewToFront:_keyboardTopViewForInputViewV2];
    
    
}

- (void) setUpInputAccessoryView {
    [iConsole info:@"%s",__FUNCTION__];
    
    int columnCount;
    int rowCount;
    int emotionViewHeight;
    int cssToolbarHeight;
    if (isUserInterfaceIdiomPhone) {
        columnCount = DEFAULT_COLUMN_COUNT_IPHONE;
        rowCount = DEFAULT_ROW_COUNT_IPHONE;
        cssToolbarHeight = IPHONE_UI_TOOL_BAR_HEIGHT;
        emotionViewHeight = CSS_EMOTION_VIEW_HEIGHT_IPHONE;
    } else {
        columnCount = DEFAULT_COLUMN_COUNT_IPAD;
        rowCount = DEFAULT_ROW_COUNT_IPAD;
        emotionViewHeight = CSS_EMOTION_VIEW_HEIGHT_IPAD;
        cssToolbarHeight = IPAD_UI_TOOL_BAR_HEIGHT;
    }
    
    if (_keyboardTopViewV2 == nil) {
        _keyboardTopViewV2 = [[KeyboardTopView alloc]initWithFrame:CGRectMake(0, 0, [Common getScreenWidthInLandscape], cssToolbarHeight)];
    }
    _keyboardTopViewV2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [_keyboardTopViewV2 setupSummaryArray];
    _keyboardTopViewV2.delegate = self;
    
    //default input method
    [_subheadingQuestion setInputAccessoryView:_keyboardTopViewV2];
    [_mainQuestion setInputAccessoryView:_keyboardTopViewV2];
    [_subQuestion setInputAccessoryView:_keyboardTopViewV2];
    [_subheadingAnswer setInputAccessoryView:_keyboardTopViewV2];
    [_mainAnswer setInputAccessoryView:_keyboardTopViewV2];
    [_subAnswer setInputAccessoryView:_keyboardTopViewV2];
    
}


-(void)dismissKeyBoard:(id) sender withSaveComing:(BOOL) isGoingToSave
{
    [iConsole info:@"%s",__FUNCTION__];
    if (isUserInterfaceIdiomPhone) {
        //we don't need to hide navigation bar on iPad
        [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NAVIGATION_BAR_NOTIFICATION object:nil];
    }
    
    //step1:close keyboard and related view
    _keyboardSwitchButtonType = KeyboardSwitchButtonTypeSystem;
    [_lastBecomeFirstRespondTextView setInputAccessoryView:_keyboardTopViewV2];
    [_lastBecomeFirstRespondTextView setInputView:nil];
    
    //step2:
    _isUITextViewFocused = NO;
    [_lastBecomeFirstRespondTextView resignFirstResponder];  //这个必须在前面，因为resignFirstResponder会导致调用shouldChangeTextInRange
    
    //reset contentSize which is used by user for manually scroll up/down
    CGSize size = _verticalScrollView.contentSize;
    size.height = _verticalScrollView.frame.size.height;
    _verticalScrollView.contentSize = size;
    
    //reset offset
    [self resetVerticalScrollViewOffset];
    
    __weak __typeof(&*self)weakSelf = self;
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([weakSelf isVerticalAlignment:_lastBecomeFirstRespondTextView]) {
            //由于vertical center是通过改变contentOffSet改变的，所以不能重置为CGPointMake(0, 0)
            [_lastBecomeFirstRespondTextView setContentOffset:CGPointMake(0, self.contentYOffsetForVerticalAlignment) animated:YES];
        } else {
            [_lastBecomeFirstRespondTextView setContentOffset:CGPointMake(0, 0) animated:YES];
        }
    });
    
    if (isGoingToSave) {
        //Step3: save data in keyboardWasHidden
        _saveButtonPressed = YES;
    } else {
        _saveButtonPressed = NO;
    }
}


/**
 *  isVerticalAlignment的状态值存储于_mainAlignVerticalQuestion等变量中
 */
- (BOOL) isVerticalAlignment:(UITextView *) textView {
    BOOL result = FALSE;
    
    if (textView == nil) {
        return FALSE;
    }
    
    if (textView.tag == kTagSubheadingQuestion) {
        result =  [_subheadingAlignVerticalQuestion isEqualToString:@"Vertical"];
    } else if (textView.tag == kTagMainQuestion) {
        result = [_mainAlignVerticalQuestion isEqualToString:@"Vertical"];
    } else if (textView.tag == kTagSubQuestion) {
        result = [_subAlignVerticalQuestion isEqualToString:@"Vertical"];
    } else if (textView.tag == kTagSubheadingAnswer) {
        result = [_subheadingAlignVerticalAnswer isEqualToString:@"Vertical"];
    } else if (textView.tag == kTagMainAnswer) {
        result = [_mainAlignVerticalAnswer isEqualToString:@"Vertical"];
    } else if (textView.tag == kTagSubAnswer) {
        result = [_subAlignVerticalAnswer isEqualToString:@"Vertical"];
    }
    
    return result;
}


#pragma mark -
#pragma mark - UIImagePickerController related

- (void) selectFromImageLibraryByBackgroundSelectButton:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    if ([Common isOwner:_currentPack] == FALSE) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
        return;
        
    }
    
    _imageSourceType = Type_Image_Source_Background;
    [self selectFromImageLibrary:[sender view] withPopoverArrowUp:NO  supportMov:NO];
}



- (void)selectFromImageLibraryByLogo:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    _imageSourceType = Type_Image_Source_Logo;
    

    __weak __typeof(&*self)weakSelf = self;
    
    [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_LOGO_IMAGE_SELECTION",@"") message:NSLocalizedString(@"Title_Image_Copyright",@"") cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"DIALOG_SELECT_FROM_LIBRARY",@""),NSLocalizedString(@"DIALOG_REMOVE_LOGO_IMAGE",@""), nil] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
        if (buttonIndex == 1) {
            [weakSelf selectFromImageLibrary:_logoImage withPopoverArrowUp:YES  supportMov:NO];
        } else if (buttonIndex == 2) {
            
            if (([_logoImageFullPath rangeOfString:@"placeholder"].location == NSNotFound) &&
                (_logoImageFullPath.length > 0)) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_logoImageFullPath
                                                                error:&error])
                {
                    NSLog(@"[Error] %@ (%@)", error, _logoImageFullPath);
                } else {
                    _logoImageFullPath = @"";
                    [_logoImage setImage:[UIImage imageNamed:@"question_placeholder_logo"]];
                    
                    _currentCard.question.logoFullPath = _logoImageFullPath;
                    if (isFromNewCreatedCard) {
                        //we don't do save operation now but need to tell to save all cards' logo when we click "save button"
                        _isAllCardsNeedToBeUpdateForNewCardOnly = YES;
                    } else {
                        //do save operation and update all others
                        
                        if (!_HUD) {
                            _HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
                        }
                        [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
                        [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
                        
                        _HUD.mode = MBProgressHUDModeIndeterminate;
                        [_HUD show:YES];
                        _HUD.labelText = NSLocalizedString(@"DIALOG_APPLY_TO_ALL_CARD",@"");
                        [self performSelector:@selector(execUpdatelogoImageForAllCards:) withObject:_logoImageFullPath afterDelay:0.01];
                    }
                    
                }
            }
            
        }
        
    }];
    
    
    
}

- (void)imageViewTapped:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    //1. play mode
    if (_isPlayingCard) {
        
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if (_currentCard.question.movieFullPath.length > 0) {
                
                [self playYoutubeVideo:_currentCard.question.movieFullPath];
                
            }
            
        } else {
            if (_currentCard.answer.movieFullPath.length > 0) {
                [self playYoutubeVideo:_currentCard.answer.movieFullPath];
            }
        }
        
    } else {
        //2. edit mode, and have video, but not own the pack
        NSString *targetStr;
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            targetStr = _currentCard.question.movieFullPath;
        } else {
            targetStr = _currentCard.answer.movieFullPath;
        }
        if (([self checkCardEditable] == FALSE) && (targetStr.length >0)) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_VIDEO_PLAY_ONLY_AVAILABLE_IN_PLAY",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
        
        __weak __typeof(&*self)weakSelf = self;
        
//        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_IMAGE_VIDEO_SELECTION",@"") message:NSLocalizedString(@"Title_Image_Copyright",@"") cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"DIALOG_INSERT_YOUTUBE_URL",@""), NSLocalizedString(@"DIALOG_SELECT_FROM_LIBRARY",@""),NSLocalizedString(@"DIALOG_REMOVE_VIDEO_IMAGE",@""), nil] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
//            
//            [weakSelf imageSelectAlertViewClickedAtIndex: buttonIndex];
//            
//        }];
        
        //show dialog
        {
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_IMAGE_VIDEO_SELECTION",@"") andMessage:NSLocalizedString(@"Title_Image_Copyright",@"")];
            [alertView addButtonWithTitle:NSLocalizedString(@"DIALOG_INSERT_YOUTUBE_URL",@"")
                                     type:SIAlertViewButtonTypeDefault
                                  handler:^(SIAlertView *alertView) {
                                      [weakSelf imageSelectAlertViewClickedAtIndex: 1];
                             
                                  }];
            [alertView addButtonWithTitle:NSLocalizedString(@"DIALOG_SELECT_FROM_LIBRARY",@"")
                                     type:SIAlertViewButtonTypeDefault
                                  handler:^(SIAlertView *alertView) {
                                      [weakSelf imageSelectAlertViewClickedAtIndex: 2];
                                  }];
            [alertView addButtonWithTitle:NSLocalizedString(@"DIALOG_REMOVE_VIDEO_IMAGE",@"")
                                     type:SIAlertViewButtonTypeDefault
                                  handler:^(SIAlertView *alertView) {
                                      [weakSelf imageSelectAlertViewClickedAtIndex: 3];
                                   
                                  }];
            
            [alertView addButtonWithTitle:NSLocalizedString(@"DIALOG_CANCEL",@"")
                                     type:SIAlertViewButtonTypeCancel
                                  handler:^(SIAlertView *alertView) {
                                   
                                  }];
            alertView.titleColor = [UIColor blackColor];
            alertView.viewBackgroundColor = [UIColor colorWithRed:249.0/255 green:249.0/255 blue:249.0/255 alpha:1];
            alertView.messageColor = [UIColor blackColor];
            alertView.buttonsListStyle = SIAlertViewButtonsListStyleNormal;
            [alertView setButtonColor:[UIColor blackColor]];
            [alertView setDefaultButtonImage:nil forState:UIControlStateNormal];
            [alertView setCancelButtonImage:nil forState:UIControlStateNormal];
            alertView.cancelButtonColor = [UIColor colorWithRed:20.0/255 green:119.0/255 blue:237.0/255 alpha:1];
            alertView.buttonColor = [UIColor colorWithRed:20.0/255 green:119.0/255 blue:237.0/255 alpha:1];
            alertView.cornerRadius = 10;
            alertView.buttonFont = [UIFont boldSystemFontOfSize:12];
            alertView.transitionStyle = SIAlertViewTransitionStyleFade;
            
            [alertView show];
            
        }
        
        
        

    }

    
}


- (void)imageViewTapped2:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    //1. play mode
    if (_isPlayingCard) {
        
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if (_currentCard.question.movieFullPath2.length > 0) {
                
                [self playYoutubeVideo:_currentCard.question.movieFullPath2];
                
            }
            
        } else {
            if (_currentCard.answer.movieFullPath2.length > 0) {
                [self playYoutubeVideo:_currentCard.answer.movieFullPath2];
            }
        }
        
    } else {
        //2. edit mode, and have video, but not own the pack
        NSString *targetStr;
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            targetStr = _currentCard.question.movieFullPath2;
        } else {
            targetStr = _currentCard.answer.movieFullPath2;
        }
        if (([self checkCardEditable] == FALSE) && (targetStr.length >0)) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_VIDEO_PLAY_ONLY_AVAILABLE_IN_PLAY",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
        
        __weak __typeof(&*self)weakSelf = self;
//        UIAlertView *alertView = [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_IMAGE_VIDEO_SELECTION",@"") message:NSLocalizedString(@"Title_Image_Copyright",@"") cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"DIALOG_INSERT_YOUTUBE_URL",@""), NSLocalizedString(@"DIALOG_SELECT_FROM_LIBRARY",@""),NSLocalizedString(@"DIALOG_REMOVE_VIDEO_IMAGE",@""), nil] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
//            
//            [weakSelf image2SelectAlertViewClickedAtIndex: buttonIndex];
//            
//        }];
        
        //show dialog
        {
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_IMAGE_VIDEO_SELECTION",@"") andMessage:NSLocalizedString(@"Title_Image_Copyright",@"")];
            [alertView addButtonWithTitle:NSLocalizedString(@"DIALOG_INSERT_YOUTUBE_URL",@"")
                                     type:SIAlertViewButtonTypeDefault
                                  handler:^(SIAlertView *alertView) {
                                      [weakSelf image2SelectAlertViewClickedAtIndex: 1];
                                      
                                  }];
            [alertView addButtonWithTitle:NSLocalizedString(@"DIALOG_SELECT_FROM_LIBRARY",@"")
                                     type:SIAlertViewButtonTypeDefault
                                  handler:^(SIAlertView *alertView) {
                                      [weakSelf image2SelectAlertViewClickedAtIndex: 2];
                                      
                                  }];
            [alertView addButtonWithTitle:NSLocalizedString(@"DIALOG_REMOVE_VIDEO_IMAGE",@"")
                                     type:SIAlertViewButtonTypeDefault
                                  handler:^(SIAlertView *alertView) {
                                      [weakSelf image2SelectAlertViewClickedAtIndex: 3];
                                      
                                  }];
            
            [alertView addButtonWithTitle:NSLocalizedString(@"DIALOG_CANCEL",@"")
                                     type:SIAlertViewButtonTypeCancel
                                  handler:^(SIAlertView *alertView) {
                                      
                                  }];
            alertView.titleColor = [UIColor blackColor];
            alertView.viewBackgroundColor = [UIColor colorWithRed:249.0/255 green:249.0/255 blue:249.0/255 alpha:1];
            alertView.messageColor = [UIColor blackColor];
            alertView.buttonsListStyle = SIAlertViewButtonsListStyleNormal;
            [alertView setButtonColor:[UIColor blackColor]];
            [alertView setDefaultButtonImage:nil forState:UIControlStateNormal];
            [alertView setCancelButtonImage:nil forState:UIControlStateNormal];
            alertView.cancelButtonColor = [UIColor colorWithRed:20.0/255 green:119.0/255 blue:237.0/255 alpha:1];
            alertView.buttonColor = [UIColor colorWithRed:20.0/255 green:119.0/255 blue:237.0/255 alpha:1];
            alertView.cornerRadius = 10;
            alertView.buttonFont = [UIFont boldSystemFontOfSize:12];
            alertView.transitionStyle = SIAlertViewTransitionStyleFade;
            
            [alertView show];
            
        }
        
    }
    
}

- (void)selectImageOrVideoFromLibraryWithImageType:(Type_PopoverView) sourceType{
    [iConsole info:@"%s",__FUNCTION__];
    
    if (sourceType == Type_PopoverView_SelectImage) {
        _imageSourceType = Type_Image_Source_Image;
    } else {
        _imageSourceType = Type_Image_Source_Image2;
    }
    
    
    if ([Common isOwner:_currentPack]) {
        [self selectFromImageLibrary:nil withPopoverArrowUp:YES supportMov:YES];
    } else {
        if (sourceType == Type_PopoverView_SelectImage) {
            if (_segmentedControl.selectedSegmentIndex == 0) {
                if ([_currentCard.question.movieFullPath hasSuffix:@".3gp"]) {
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:@"Video play is only supported in play mode." delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                    [alertView show];
                    
                }
                
            } else {
                if ([_currentCard.answer.movieFullPath hasSuffix:@".3gp"]) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:@"Video play is only supported in play mode." delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                    [alertView show];
                }
            }
        } else {
            if (_segmentedControl.selectedSegmentIndex == 0) {
                if ([_currentCard.question.movieFullPath2 hasSuffix:@".3gp"]) {
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:@"Video play is only supported in play mode." delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                    [alertView show];
                    
                }
                
            } else {
                if ([_currentCard.answer.movieFullPath2 hasSuffix:@".3gp"]) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:@"Video play is only supported in play mode." delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                    [alertView show];
                }
            }
        }
    }
    
}


- (void) stopAudio {
    
    if ([_audioPlayer isPlaying]) {
        [_audioPlayer stop];
    }
    
}

- (void) muteAudio {
    _audioPlayer.volume = 0.0;
}

- (void) unMuteAudio {
    _audioPlayer.volume = 1.0;
}

- (void) playAudioWithManualClick:(BOOL) isManualClicked withMute:(BOOL)isMute {
    [iConsole info:@"%s",__FUNCTION__];
    
    
    NSError *error;
    //不能声明为局部变量，否则无法播放
    NSString *normalizedPath;
    if (_segmentedControl.selectedSegmentIndex == 0) {
        normalizedPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.recordedSoundFullPath lastPathComponent]];
    } else {
        normalizedPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.recordedSoundFullPath lastPathComponent]];
    }
    
    NSURL *audioURL;
    BOOL isDirectory;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:normalizedPath isDirectory:&isDirectory];
    if (isExist && (isDirectory == FALSE)) {
        audioURL = [NSURL fileURLWithPath:normalizedPath];
        
        [_audioPlayer stop];
        
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&error];
        
        if (isMute) {
            _audioPlayer.volume = 0.0;
        } else {
            _audioPlayer.volume = 1.0;
        }
        
        _audioPlayer.numberOfLoops = 0;
        _audioPlayer.delegate = self;
        [_audioPlayer prepareToPlay];
        
        if (_audioPlayer == nil)
            [iConsole error:@"%s:%@,audio file:%@",__FUNCTION__,[error description],audioURL];
        else {
            [_audioPlayer play];
        }
        
    } else {
        [iConsole info:@"%s:no audio file:%@",__FUNCTION__,audioURL];
        
        if (isManualClicked) {
            NSString *msg;
            if (_segmentedControl.selectedSegmentIndex == 0) {
                
                msg = NSLocalizedString(@"DIALOG_NO_AUDIO_ON_QUESTION_CARD",@"");
            } else {
                msg = NSLocalizedString(@"DIALOG_NO_AUDIO_ON_ANSWER_CARD",@"");
            }
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}


- (void) pauseEmbeddedVideoAndGif {
    
    [_imageQuestion pauseVideoAndGif];
    [_imageQuestion2 pauseVideoAndGif];
    
    [_imageAnswer pauseVideoAndGif];
    [_imageAnswer2 pauseVideoAndGif];
    
    
}


- (void) cleanMultimediaViews {
    
    [_imageQuestion clean];
    [_imageQuestion2 clean];
    
    [_imageAnswer clean];
    [_imageAnswer2 clean];
}

/**
 *  todo: later this part of logic should  be moved to MultimediaView, which will be consistent with other function.
 */
- (void) playYoutubeVideo:(NSString *) urlStr {
    [iConsole info:@"%s",__FUNCTION__];
    
    if ([Common isValidYoutubeLinkage:urlStr]) {
        //http://www.youtube.com/watch?v=gzsrooteAZw
        NSString *finalURLStr = [Common embeddedYoutubeURL:urlStr];
        SimpleWebBrowserController *playerViewController = [[SimpleWebBrowserController alloc] initWithURL:[NSURL URLWithString:finalURLStr]];
        playerViewController.hidesToolbar = NO;
        
        if (_calledViewController) {
            //means this is called from play mode
            //iPad
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [_calledViewController presentModalViewController:playerViewController animated:YES];
        } else {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:playerViewController animated:YES];
        }
        
    }
    
    
}


/**
 *  Common function for select image from library
 *
 *  @param sender    必须是UITapGestureRecognizer
 *  @param isArrowUp _imagePickerPopover剪头方向
 */
- (void)selectFromImageLibrary:(UIView *)sender withPopoverArrowUp:(BOOL) isArrowUp supportMov:(BOOL) isSupportMovie {
    [iConsole info:@"%s",__FUNCTION__];
    
    APP_DELEGATE.isAllowToShowPackList = NO;
    
    if (_imagePickerController != nil) {
        _imagePickerPopover = nil;
    }
    
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if (isSupportMovie) {
        _imagePickerController.mediaTypes = [NSArray arrayWithObjects:(NSString *) kUTTypeMovie, (NSString *) kUTTypeImage,nil];
    }
    _imagePickerController.navigationBar.barStyle = UIBarStyleBlack;
    _imagePickerController.contentSizeForViewInPopover = CGSizeMake(320, 400);
    _imagePickerController.delegate = self;
    
    if (isUserInterfaceIdiomPhone) {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:_imagePickerController animated:YES];
    } else {
        
        UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        
        CGPoint point;
        if (sender == nil) {
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                if (_imageSourceType == Type_Image_Source_Image) {
                    point = _imageQuestion.center;
                    point = [_imageQuestion.superview convertPoint:point toView:rootView];
                } else {
                    point = _imageQuestion2.center;
                    point = [_imageQuestion2.superview convertPoint:point toView:rootView];
                }
            } else {
                if (_imageSourceType == Type_Image_Source_Image) {
                    point = _imageAnswer.center;
                    point = [_imageAnswer.superview convertPoint:point toView:rootView];
                } else {
                    point = _imageAnswer2.center;
                    point = [_imageAnswer2.superview convertPoint:point toView:rootView];
                }
            }
        }else {
            point = CGPointMake((CGRectGetMaxX(sender.frame) + CGRectGetMinX(sender.frame))/2 - 25, 2);
            point = [sender.superview convertPoint:point toView:rootView];
        }
        
        
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        
        if (_imagePickerPopover != nil) {
            [_imagePickerPopover dismissPopoverAnimated:YES];
            _imagePickerPopover=nil;
        }
        
        _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_imagePickerController];
        _imagePickerPopover.delegate = self;
        if (isArrowUp) {
            [_imagePickerPopover presentPopoverFromRect:rect inView:rootView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        } else {
            [_imagePickerPopover presentPopoverFromRect:rect inView:rootView permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        }
        
    }
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [iConsole info:@"%s",__FUNCTION__];
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    //remove current file
    if (_imageSourceType == Type_Image_Source_Image) {
        
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if (_questionMovieFullPath.length != 0) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_questionMovieFullPath
                                                                error:&error])
                {
                    [iConsole info:@"[Error] %@ (%@)", error, _questionMovieFullPath];
                }
                
                _questionMovieFullPath = @"";
                
            }
            
            {
                BOOL isPlaceHolder = [Common isPlaceholderFilePathOrDirectory:_questionImageFullPath];
                NSError *error = nil;
                if (isPlaceHolder == false) {
                    if (![[NSFileManager defaultManager] removeItemAtPath:_questionImageFullPath
                                                                    error:&error])
                    {
                        [iConsole info:@"[Error] %@ (%@)", error, _questionImageFullPath];
                    }
                    
                    _questionImageFullPath = @"";
                    
                }
            }
            
        } else {
            
            if (_answerMovieFullPath.length != 0) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_answerMovieFullPath
                                                                error:&error])
                {
                    [iConsole info:@"[Error] %@ (%@)", error, _answerMovieFullPath];
                }
                
                _answerMovieFullPath = @"";
                
            }
            
            {
                BOOL isPlaceHolder = [Common isPlaceholderFilePathOrDirectory:_answerImageFullPath];
                NSError *error = nil;
                if (isPlaceHolder == false) {
                    if (![[NSFileManager defaultManager] removeItemAtPath:_answerImageFullPath
                                                                    error:&error])
                    {
                        [iConsole info:@"[Error] %@ (%@)", error, _answerImageFullPath];
                    }
                    
                    _answerImageFullPath = @"";
                }
                
            }
        }
    } else {
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if (_questionMovieFullPath2.length != 0) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_questionMovieFullPath2
                                                                error:&error])
                {
                    [iConsole info:@"[Error] %@ (%@)", error, _questionMovieFullPath2];
                }
                
                _questionMovieFullPath2 = @"";
            }
            
            {
                BOOL isPlaceHolder = [Common isPlaceholderFilePathOrDirectory:_questionImageFullPath2];
                NSError *error = nil;
                if (isPlaceHolder == false) {
                    if (![[NSFileManager defaultManager] removeItemAtPath:_questionImageFullPath2
                                                                    error:&error])
                    {
                        [iConsole info:@"[Error] %@ (%@)", error, _questionImageFullPath2];
                    }
                    
                    _questionImageFullPath2 = @"";
                }
                
            }
            
        } else {
            if (_answerMovieFullPath2.length != 0) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_answerMovieFullPath2
                                                                error:&error])
                {
                    [iConsole info:@"[Error] %@ (%@)", error, _answerMovieFullPath2];
                }
                
                _answerMovieFullPath2 = @"";
            }
            
            {
                BOOL isPlaceHolder = [Common isPlaceholderFilePathOrDirectory:_answerImageFullPath2];
                NSError *error = nil;
                if (isPlaceHolder == false) {
                    if (![[NSFileManager defaultManager] removeItemAtPath:_answerImageFullPath2
                                                                    error:&error])
                    {
                        [iConsole info:@"[Error] %@ (%@)", error, _answerImageFullPath2];
                    }
                    
                    _answerImageFullPath2 = @"";
                }
                
            }
        }
    }
    
    if ([mediaType isEqualToString:@"public.movie"]){
        
        NSURL *movieURL = [info objectForKey:UIImagePickerControllerMediaURL];
        [iConsole info:@"found a movie %@", movieURL];
        
        //check video lenght
        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
        CMTime duration = sourceAsset.duration;
        float seconds = CMTimeGetSeconds(duration);
        if (seconds > 30) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:@"Max 30 seconds of video duration is support" delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
        
        
        //save movie info
        NSString *destPath;
        NSString *thumbnailDestPath;
        if (_imageSourceType == Type_Image_Source_Image) {
            
            if (_segmentedControl.selectedSegmentIndex == 0) {
                _questionMovieFullPath = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                destPath = _questionMovieFullPath;
                
                _questionImageFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                thumbnailDestPath = _questionImageFullPath;
                
            } else {
                
                _answerMovieFullPath = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                destPath = _answerMovieFullPath;
                
                _answerImageFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                thumbnailDestPath = _answerImageFullPath;
            }
        } else {
            if (_segmentedControl.selectedSegmentIndex == 0) {
                _questionMovieFullPath2 = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                destPath = _questionMovieFullPath2;
                
                _questionImageFullPath2 = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                thumbnailDestPath = _questionImageFullPath2;
                
            } else {
                _answerMovieFullPath2 = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                destPath = _answerMovieFullPath2;
                
                _answerImageFullPath2 = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                thumbnailDestPath = _answerImageFullPath2;
            }
        }
        
        AVAsset *video = [AVAsset assetWithURL:movieURL];
        
        //thumbnail
        if (thumbnailDestPath) {
            AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:video];
            imageGenerator.appliesPreferredTrackTransform = YES;
            CMTime time = [video duration];
            time.value = 0;
            CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
            UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
            [UIImagePNGRepresentation(thumbnail) writeToFile:thumbnailDestPath atomically:YES];
        }
        
        //export video file
        if (destPath) {
            AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:video presetName:AVAssetExportPresetPassthrough];
            exportSession.shouldOptimizeForNetworkUse = YES;
            exportSession.outputFileType = AVFileType3GPP;
            exportSession.outputURL = [NSURL fileURLWithPath:destPath];
            __weak __typeof(&*self)weakSelf = self;
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                
                //check file size for test purpose
                NSDictionary *fileDictionary = [[NSFileManager defaultManager] fileAttributesAtPath:destPath traverseLink:YES];
                long fileSize = [fileDictionary fileSize];
                [iConsole info:@"%s:Done and converted 3gp size is:%ld",__FUNCTION__,fileSize];
                
                [weakSelf switchToVideoModeAndPlayWithImageSource:_imageSourceType];
            }];
        }
        
        
        
        if (self.tag == NEW_FLASHCARDVIEW_TAG) {
            //we will save until after we press the save button
            if (_imageSourceType == Type_Image_Source_Image) {
                if (_segmentedControl.selectedSegmentIndex == 0) {
                    _currentCard.question.imageFullPath = _questionImageFullPath;
                    _currentCard.question.movieFullPath = _questionMovieFullPath;
                    
                } else {
                    _currentCard.answer.imageFullPath = _answerImageFullPath;
                    _currentCard.answer.movieFullPath = _answerMovieFullPath;
                    
                }
            } else {
                if (_segmentedControl.selectedSegmentIndex == 0) {
                    _currentCard.question.imageFullPath2 = _questionImageFullPath2;
                    _currentCard.question.movieFullPath2 = _questionMovieFullPath2;
                    
                } else {
                    _currentCard.answer.imageFullPath2 = _answerImageFullPath2;
                    _currentCard.answer.movieFullPath2 = _answerMovieFullPath2;
                }
            }
        } else {
            [self saveEdittedCard];
        }
        
        
        
    } else if ([mediaType isEqualToString:@"public.image"]) {
        
        NSURL *assetURL = info[UIImagePickerControllerReferenceURL];
        NSString *extension = [assetURL pathExtension];
        CFStringRef imageUTI = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)extension , NULL));
        if (UTTypeConformsTo(imageUTI, kUTTypeGIF))
        {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
            __block NSData *imageData = nil;
            PHAsset * asset = [[PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil] lastObject];
            if (asset) {
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.synchronous = YES;
                options.networkAccessAllowed = NO;
                options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable data, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    NSNumber * isError = [info objectForKey:PHImageErrorKey];
                    NSNumber * isCloud = [info objectForKey:PHImageResultIsInCloudKey];
                    if ([isError boolValue] || [isCloud boolValue] || ! data) {
                        // fail
                    } else {
                        // success
                        imageData = data;
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            
            if (isUserInterfaceIdiomPhone) {
                [picker dismissModalViewControllerAnimated:YES];
                picker = nil;
            } else {
                //        picker = nil;
                [_imagePickerPopover dismissPopoverAnimated:YES];
                _imagePickerPopover = nil;
            }
            
            if (_imageSourceType == Type_Image_Source_Image) {
                
                if (_segmentedControl.selectedSegmentIndex == 0) {
                    _questionImageFullPath = [FileOperationHelper generateUniqueGIFImageFilePathUnderImagesFolder];
                    [imageData writeToFile:_questionImageFullPath atomically:YES];
                    [_imageQuestion setMultimediaType:ImageView];
                    _imageQuestion.animtableImageView.animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
                } else {
                    _answerImageFullPath = [FileOperationHelper generateUniqueGIFImageFilePathUnderImagesFolder];
                    [imageData writeToFile:_answerImageFullPath atomically:YES];
                    [_imageAnswer setMultimediaType:ImageView];
                    _imageAnswer.animtableImageView.animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
                }
                
                if (self.tag == NEW_FLASHCARDVIEW_TAG) {
                    //we will save until after we press the save button
                    if (_segmentedControl.selectedSegmentIndex == 0) {
                        _currentCard.question.imageFullPath = _questionImageFullPath;
                    } else {
                        _currentCard.answer.imageFullPath = _answerImageFullPath;
                    }
                } else {
                    [self saveEdittedCard];
                }
            } else if (_imageSourceType == Type_Image_Source_Image2) {
                
                if (_segmentedControl.selectedSegmentIndex == 0) {
                    _questionImageFullPath2 = [FileOperationHelper generateUniqueGIFImageFilePathUnderImagesFolder];
                    [imageData writeToFile:_questionImageFullPath2 atomically:YES];
                    [_imageQuestion2 setMultimediaType:ImageView];
                    _imageQuestion2.animtableImageView.animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
                } else {
                    _answerImageFullPath2 = [FileOperationHelper generateUniqueGIFImageFilePathUnderImagesFolder];
                    [imageData writeToFile:_answerImageFullPath2 atomically:YES];
                    [_imageAnswer2 setMultimediaType:ImageView];
                    _imageAnswer2.animtableImageView.animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
                }
                
                if (self.tag == NEW_FLASHCARDVIEW_TAG) {
                    //we will save until after we press the save button
                    if (_segmentedControl.selectedSegmentIndex == 0) {
                        _currentCard.question.imageFullPath2 = _questionImageFullPath2;
                    } else {
                        _currentCard.answer.imageFullPath2 = _answerImageFullPath2;
                    }
                } else {
                    [self saveEdittedCard];
                }
            }
            
            
        } else {
            
            
            UIImage *origialmage = [info objectForKey:UIImagePickerControllerOriginalImage];
            
            NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
            
            if (isUserInterfaceIdiomPhone) {
                [picker dismissModalViewControllerAnimated:YES];
                picker = nil;
            } else {
                //        picker = nil;
                [_imagePickerPopover dismissPopoverAnimated:YES];
                _imagePickerPopover = nil;
            }
            
            if (_imageSourceType == Type_Image_Source_Logo) {
                
                _logoImageFullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.logoFullPath lastPathComponent]];
                if ([Common isPlaceholderFilePathOrDirectory:_logoImageFullPath]) {
                    _logoImageFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                }
                
                [imageData writeToFile:_logoImageFullPath atomically:YES];
                _logoImage.image = [UIImage imageWithData:imageData];
                
                _currentCard.question.logoFullPath = _logoImageFullPath;
                if (isFromNewCreatedCard) {
                    //we don't do save operation now but need to tell to save all cards' logo when we click "save button"
                    _isAllCardsNeedToBeUpdateForNewCardOnly = YES;
                } else {
                    //do save operation and update all others
                    
                    if (!_HUD) {
                        _HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
                    }
                    [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
                    [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
                    
                    _HUD.mode = MBProgressHUDModeIndeterminate;
                    [_HUD show:YES];
                    _HUD.labelText = NSLocalizedString(@"DIALOG_APPLY_TO_ALL_CARD",@"");
                    [self performSelector:@selector(execUpdatelogoImageForAllCards:) withObject:_logoImageFullPath afterDelay:0.01];
                }
                
            } else if (_imageSourceType == Type_Image_Source_Image) {
                
                if (_segmentedControl.selectedSegmentIndex == 0) {
                    if ([Common isPlaceholderFilePathOrDirectory:_questionImageFullPath]) {
                        _questionImageFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                    }
                    [imageData writeToFile:_questionImageFullPath atomically:YES];
                    [_imageQuestion setMultimediaType:ImageView];
                    _imageQuestion.animtableImageView.image = [UIImage imageWithData:imageData];
                } else {
                    if ([Common isPlaceholderFilePathOrDirectory:_answerImageFullPath]) {
                        _answerImageFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                    }
                    [imageData writeToFile:_answerImageFullPath atomically:YES];
                    [_imageAnswer setMultimediaType:ImageView];
                    _imageAnswer.animtableImageView.image = [UIImage imageWithData:imageData];
                }
                
                if (self.tag == NEW_FLASHCARDVIEW_TAG) {
                    //we will save until after we press the save button
                    if (_segmentedControl.selectedSegmentIndex == 0) {
                        _currentCard.question.imageFullPath = _questionImageFullPath;
                    } else {
                        _currentCard.answer.imageFullPath = _answerImageFullPath;
                    }
                } else {
                    [self saveEdittedCard];
                }
            } else if (_imageSourceType == Type_Image_Source_Image2) {
                
                if (_segmentedControl.selectedSegmentIndex == 0) {
                    if ([Common isPlaceholderFilePathOrDirectory:_questionImageFullPath2]) {
                        _questionImageFullPath2 = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                    }
                    [imageData writeToFile:_questionImageFullPath2 atomically:YES];
                    [_imageQuestion2 setMultimediaType:ImageView];
                    _imageQuestion2.animtableImageView.image = [UIImage imageWithData:imageData];
                } else {
                    if ([Common isPlaceholderFilePathOrDirectory:_answerImageFullPath2]) {
                        _answerImageFullPath2 = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                    }
                    [imageData writeToFile:_answerImageFullPath2 atomically:YES];
                    [_imageAnswer2 setMultimediaType:ImageView];
                    _imageAnswer2.animtableImageView.image = [UIImage imageWithData:imageData];
                }
                
                if (self.tag == NEW_FLASHCARDVIEW_TAG) {
                    //we will save until after we press the save button
                    if (_segmentedControl.selectedSegmentIndex == 0) {
                        _currentCard.question.imageFullPath2 = _questionImageFullPath2;
                    } else {
                        _currentCard.answer.imageFullPath2 = _answerImageFullPath2;
                    }
                } else {
                    [self saveEdittedCard];
                }
            } else if (_imageSourceType == Type_Image_Source_Background)  {
                
                if (isUserInterfaceIdiomPhone) {
                    [picker dismissModalViewControllerAnimated:YES];
                    
                } else {
                    [_imagePickerPopover dismissPopoverAnimated:YES];
                }
                
                __weak __typeof(&*self)weakSelf = self;
                double delayInSeconds = 0.6;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [weakSelf openEditor:origialmage];
                });
            }
            
            
        }
        
    }
    
    if (_imageSourceType != Type_Image_Source_Background) {
        if (isUserInterfaceIdiomPhone) {
            [picker dismissModalViewControllerAnimated:YES];
        } else {
            [_imagePickerPopover dismissPopoverAnimated:YES];
        }
        
    }
    
    APP_DELEGATE.isAllowToShowPackList = YES;
    
    
}

- (void) execUpdatelogoImageForAllCards:(NSString *)logoImageFullPath {
    [iConsole info:@"%s",__FUNCTION__];
    [self updatelogoImageForAllCards:logoImageFullPath];
    [_HUD removeFromSuperview];
    _HUD = nil;
}



- (UIImage *)captureWholeViewAsImage {
    [iConsole info:@"%s",__FUNCTION__];
    
    [[TipHelper defaultHelper] hideEverything];
    
    bool switchSegment = NO;
    if (_segmentedControl.selectedSegmentIndex == 1) {
        _segmentedControl.selectedSegmentIndex = 0;
        [self refreshAll];
        switchSegment = YES;
    }
    
    BOOL subHeadingQuestionAlphaRevertNeeded = false;
    BOOL mainQuestionAlphaRevertNeeded = false;
    BOOL subQuestionAlphaRevertNeeded = false;
    
    BOOL isEditable = [self checkCardEditable];
    if (isEditable == YES) {
        [self disableCardEdit];
        _segmentedControl.hidden = YES;
        
        if ((_currentCard.question.logoFullPath.length == 0) || ([_currentCard.question.logoFullPath rangeOfString:@"placeholder"].location != NSNotFound)) {
            _logoImage.hidden = true;
        } else {
            _logoImage.hidden = false;
        }
        
        if ([self isLocalVideo:_currentCard.question.movieFullPath]) {
            
            [_imageQuestion setMultimediaType:ImageView];
            [_imageQuestion.animtableImageView setImage:[UIImage imageWithContentsOfFile:_currentCard.question.imageFullPath]];
        }
        
        if ([self isLocalVideo:_currentCard.question.movieFullPath2]) {
            
            [_imageQuestion2 setMultimediaType:ImageView];
            [_imageQuestion2.animtableImageView setImage:[UIImage imageWithContentsOfFile:_currentCard.question.imageFullPath2]];
            
        }
        
        if (_subheadingQuestion.alpha == 0.5) {
            subHeadingQuestionAlphaRevertNeeded = true;
            _subheadingQuestion.alpha = 0;
        }
        
        if (_mainQuestion.alpha == 0.5) {
            mainQuestionAlphaRevertNeeded = true;
            _mainQuestion.alpha = 0;
        }
        
        if (_subQuestion.alpha == 0.5) {
            subQuestionAlphaRevertNeeded = true;
            _subQuestion.alpha = 0;
        }
        
    }
    
    if (_keyboardShown) {
        [self endEditing:YES];
        usleep(400000);
        [self endEditing:FALSE];
    }
    
    CGRect screenRect = self.bounds;
    if (isUserInterfaceIdiomPhone) {
        screenRect.size.height = kFlashCardViewHeight_Detail_iPhone_Pure;
    } else {
        screenRect.size.height = kFlashCardViewHeight_Detail_iPad_Pure;
    }
    UIGraphicsBeginImageContextWithOptions(screenRect.size, NO, 0.3);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self.backgroundColor set];
    CGContextFillRect(ctx, screenRect);
    [self.layer renderInContext:ctx];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (isEditable == YES) {
        [self enableCardEdit];
        _segmentedControl.hidden = NO;
        _logoImage.hidden = NO;
        
        if ([self isLocalVideo:_currentCard.question.movieFullPath]) {
            
            [_imageQuestion setMultimediaType:Video];
            [_imageQuestion setVideoURL:[NSURL fileURLWithPath:_questionMovieFullPath]];
            
        }
        
        if ([self isLocalVideo:_currentCard.question.movieFullPath2]) {
            
            [_imageQuestion2 setMultimediaType:Video];
            [_imageQuestion2 setVideoURL:[NSURL fileURLWithPath:_questionMovieFullPath2]];
            
        }
        
        if (subHeadingQuestionAlphaRevertNeeded) {
            subHeadingQuestionAlphaRevertNeeded = false;
            _subheadingQuestion.alpha = 0.5;
        }
        
        if (mainQuestionAlphaRevertNeeded) {
            mainQuestionAlphaRevertNeeded = false;
            _mainQuestion.alpha = 0.5;
        }
        
        if (subQuestionAlphaRevertNeeded) {
            subQuestionAlphaRevertNeeded = false;
            _subQuestion.alpha = 0.5;
        }
        
    }
    
    if (switchSegment == YES) {
        _segmentedControl.selectedSegmentIndex = 1;
        
        [self refreshAll];
    } else {
        
    }
    
    return newImage;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [iConsole info:@"%s",__FUNCTION__];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}


#pragma mark -
#pragma mark - Text edit function


- (void) symbolAndKeyboardSwitch:(id) sender {
    [iConsole info:@"%s",__FUNCTION__];
    [_lastBecomeFirstRespondTextView resignFirstResponder];
    
    if (_lastBecomeFirstRespondTextView.inputView == nil) {
        
        if ((_lastBecomeFirstRespondTextView.text.length == 0)
            || [Common isIncludedInRecommendedFonts:_lastBecomeFirstRespondTextView.font.fontName] == FALSE) {
            //do nothing
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_SYMBOL_NOT_SUPPORTED_BY_FONT",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
            [alertView show];
        }
        
        [_emotionButtonForInputView setTitle:NSLocalizedString(@"ToolbarItem_Keyboard",nil)];
        _dismissKeyboardFromEmotionSwitch = TRUE;
        _isUITextViewFocused = FALSE;
        _keyboardSwitchButtonType = KeyboardSwitchButtonTypeEmoticon;
        _lastBecomeFirstRespondTextView.inputAccessoryView = nil;
        _lastBecomeFirstRespondTextView.inputView = _keyboardInputBaseView;
    } else {
        
        
        _isUITextViewFocused = TRUE;
        [_emotionButton setTitle:NSLocalizedString(@"ToolbarItem_Symbol",nil)];
        _keyboardSwitchButtonType = KeyboardSwitchButtonTypeSystem;
        _lastBecomeFirstRespondTextView.inputAccessoryView = _keyboardTopViewV2;
        _lastBecomeFirstRespondTextView.inputView = nil;
        
    }
    
    [_lastBecomeFirstRespondTextView becomeFirstResponder];
    
    
}


- (void) changeFontTypeBarButtonItemClicked:(id) sender{
    [iConsole info:@"%s",__FUNCTION__];
    NSString *title = ((UIButton *) sender).titleLabel.text;
    
    if ([title isEqualToString:@"Futura"]) {
        title = @"Futura-Medium";
    } else if ([title isEqualToString:@"Chalkboard"]) {
        title = @"ChalkboardSE-Bold";
    }
    
    
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    
    CGFloat size = responderTextView.font.pointSize;
    
    if ([[title lowercaseString] isEqualToString:@"default"]) {
        [responderTextView setFont:[UIFont boldSystemFontOfSize:size]];
        title = @"";//default value
    } else {
        [responderTextView setFont:[UIFont fontWithName:title size:size]];
    }
    
    if (responderTextView.tag == kTagSubheadingQuestion){
        _subheadingFontQuestion= title;
    } else if (responderTextView.tag == kTagMainQuestion) {
        _mainFontQuestion = title;
    } else if (responderTextView.tag == kTagSubQuestion) {
        _subFontQuestion = title;
    } else if (responderTextView.tag == kTagSubheadingAnswer) {
        _subheadingFontAnswer = title;
    } else if (responderTextView.tag == kTagMainAnswer) {
        _mainFontAnswer = title;
    } else if (responderTextView.tag == kTagSubAnswer) {
        _subFontAnswer = title;
    }
    
}


- (void) changeFontSizeBarButtonItemClicked:(id) sender{
    [iConsole info:@"%s",__FUNCTION__];
    
    long index = ((UIButton *) sender).tag;
    
    NSArray *realFontSizeArray = _keyboardTopViewV2.realSizeArray;
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    
    NSUInteger selectFontSize = [realFontSizeArray [index] integerValue];
    [responderTextView setFont:[responderTextView.font fontWithSize:selectFontSize]];
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        [responderTextView setFont:[responderTextView.font fontWithSize:selectFontSize*kFlashCardViewProporation_iPhone]];
    }
    
    if (responderTextView.tag == kTagSubheadingQuestion){
        _subheadingSizeQuestion = selectFontSize;
    } else if (responderTextView.tag == kTagMainQuestion) {
        _mainSizeQuestion = selectFontSize;
    } else if (responderTextView.tag == kTagSubQuestion) {
        _subSizeQuestion = selectFontSize;
    } else if (responderTextView.tag == kTagSubheadingAnswer) {
        _subheadingSizeAnswer = selectFontSize;
    } else if (responderTextView.tag == kTagMainAnswer) {
        _mainSizeAnswer = selectFontSize;
    } else if (responderTextView.tag == kTagSubAnswer) {
        _subSizeAnswer = selectFontSize;
    }
    
    responderTextView.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:selectFontSize], 0, 0, 0.0);
}

- (void) changeAlignBarButtonItemClicked:(id) sender{
    [iConsole info:@"%s",__FUNCTION__];
    NSString *selectAlignStr = nil;
    
    NSString *title = ((UIButton *) sender).titleLabel.text;;
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    NSRange range = responderTextView.selectedRange;
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Left",nil)]) {
        responderTextView.textAlignment = NSTextAlignmentLeft;
        selectAlignStr = @"Left";
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Center",nil)]) {
        responderTextView.textAlignment = NSTextAlignmentCenter;
        selectAlignStr = @"Center";
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Right",nil)]) {
        responderTextView.textAlignment = NSTextAlignmentRight;
        selectAlignStr = @"Right";
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Justify",nil)]) {
        responderTextView.textAlignment = NSTextAlignmentJustified;
        selectAlignStr = @"Justify";
    }
    
    //Vertical barbutton item实际上当作一个switch，选中或没有选中
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Vertical",nil)]) {
        if ([self isVerticalAlignment:responderTextView]) {
            [self resetVerticalAlignment:responderTextView];
            selectAlignStr = @"";
        } else {
            [self setVerticalAlignment:responderTextView];
            selectAlignStr = @"Vertical";
            [responderTextView resignFirstResponder];
            [responderTextView becomeFirstResponder];
        }
        
        [self updateVerticalAlignmentBarButtonStatus];
        
    }
    
    
    responderTextView.selectedRange = range;  // to restore cursor position
    
    if ([selectAlignStr isEqualToString:@"Vertical"]) {
        if (responderTextView.tag == kTagSubheadingQuestion){
            _subheadingAlignVerticalQuestion = selectAlignStr;
        } else if (responderTextView.tag == kTagMainQuestion) {
            _mainAlignVerticalQuestion = selectAlignStr;
        } else if (responderTextView.tag == kTagSubQuestion) {
            _subAlignVerticalQuestion = selectAlignStr;
        } else if (responderTextView.tag == kTagSubheadingAnswer) {
            _subheadingAlignVerticalAnswer = selectAlignStr;
        } else if (responderTextView.tag == kTagMainAnswer) {
            _mainAlignVerticalAnswer = selectAlignStr;
        } else if (responderTextView.tag == kTagSubAnswer) {
            _subAlignVerticalAnswer = selectAlignStr;
        }
    } else {
        if (responderTextView.tag == kTagSubheadingQuestion){
            _subheadingAlignQuestion = selectAlignStr;
        } else if (responderTextView.tag == kTagMainQuestion) {
            _mainAlignQuestion = selectAlignStr;
        } else if (responderTextView.tag == kTagSubQuestion) {
            _subAlignQuestion = selectAlignStr;
        } else if (responderTextView.tag == kTagSubheadingAnswer) {
            _subheadingAlignAnswer = selectAlignStr;
        } else if (responderTextView.tag == kTagMainAnswer) {
            _mainAlignAnswer = selectAlignStr;
        } else if (responderTextView.tag == kTagSubAnswer) {
            _subAlignAnswer = selectAlignStr;
        }
    }
}

- (void) changeColorBarButtonItemClicked:(id) sender{
    [iConsole info:@"%s",__FUNCTION__];
    NSString *selectColorStr = nil;
    
    NSString *title = ((UIButton *) sender).titleLabel.text;;
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    
    
    
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Invisible",nil)]) {
        
        if (responderTextView.alpha == 0.5) {
            responderTextView.alpha = 1;
        } else {
            responderTextView.alpha = 0.5;  //只有两种情况会成为0.5，另外一种是键盘出现
        }
        
    } else {
        
        if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Black",nil)]) {
            responderTextView.textColor = [UIColor blackColor];
            selectColorStr = @"Black";
        } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Yellow",nil)]) {
            responderTextView.textColor = [UIColor yellowColor];
            selectColorStr = @"Yellow";
        } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Blue",nil)]) {
            responderTextView.textColor = [UIColor blueColor];
            selectColorStr = @"Blue";
        } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Red",nil)]) {
            responderTextView.textColor = [UIColor redColor];
            selectColorStr = @"Red";
        } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Green",nil)]) {
            responderTextView.textColor = [UIColor greenColor];
            selectColorStr = @"Green";
        } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_White",nil)]) {
            responderTextView.textColor = [UIColor whiteColor];
            selectColorStr = @"White";
        }
        
        if (responderTextView.tag == kTagSubheadingQuestion){
            _subheadingColorQuestion = selectColorStr;
        } else if (responderTextView.tag == kTagMainQuestion) {
            _mainColorQuestion = selectColorStr;
        } else if (responderTextView.tag == kTagSubQuestion) {
            _subColorQuestion = selectColorStr;
        } else if (responderTextView.tag == kTagSubheadingAnswer) {
            _subheadingColorAnswer = selectColorStr;
        } else if (responderTextView.tag == kTagMainAnswer) {
            _mainColorAnswer = selectColorStr;
        } else if (responderTextView.tag == kTagSubAnswer) {
            _subColorAnswer = selectColorStr;
        }
    }
}

- (void) changeText2SpeechBarButtonItemClicked:(id) sender{
    
    [iConsole info:@"%s",__FUNCTION__];
    
    int selectedIndex = ((UIButton *)sender).tag;
    AVSpeechSynthesisVoice *selectedVoice = [Text2SpeechHelper getAllAvailableAVSpeechSynthesisVoiceArray][selectedIndex];
    NSString *selectText2SpeechStr = selectedVoice.language;
    
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    
    if (responderTextView.tag == kTagSubheadingQuestion){
        _subheadingText2SpeechQuestion = selectText2SpeechStr;
    } else if (responderTextView.tag == kTagMainQuestion) {
        _mainText2SpeechQuestion = selectText2SpeechStr;
    } else if (responderTextView.tag == kTagSubQuestion) {
        _subText2SpeechQuestion = selectText2SpeechStr;
    } else if (responderTextView.tag == kTagSubheadingAnswer) {
        _subheadingText2SpeechAnswer = selectText2SpeechStr;
    } else if (responderTextView.tag == kTagMainAnswer) {
        _mainText2SpeechAnswer = selectText2SpeechStr;
    } else if (responderTextView.tag == kTagSubAnswer) {
        _subText2SpeechAnswer = selectText2SpeechStr;
    }
    
}


#pragma mark -
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [iConsole info:@"%s",__FUNCTION__];
    [textField resignFirstResponder];
    
    return YES;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [iConsole info:@"%s",__FUNCTION__];
    _isUITextViewFocused = FALSE;
    _keyboardInputBaseView.hidden = TRUE;
    [_emotionButton setTitle:NSLocalizedString(@"ToolbarItem_Symbol",@"")];
    
    [_lastBecomeFirstRespondTextView setInputAccessoryView:_keyboardTopViewV2];
    [_lastBecomeFirstRespondTextView setInputView:nil];
    _keyboardSwitchButtonType = KeyboardSwitchButtonTypeSystem;
    
    return TRUE;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [iConsole info:@"%s",__FUNCTION__];
    _isTextFieldsChanged = YES;
    
    if (textField.tag == kTagSidebar) {
        [textField adjustFontSizeToFitVertically:YES];
    } else {
        [textField adjustFontSizeToFit];
    }
    
    if (isFromNewCreatedCard) {
        if ((textField.tag == kTagSidebar) ||
              (textField.tag == kTagJobTitle) ||
                  (textField.tag == kTagCreator)){
            _isAllCardsNeedToBeUpdateForNewCardOnly = YES;
        }
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [iConsole info:@"%s",__FUNCTION__];
    [textField resignFirstResponder];
    
    if (_isTextFieldsChanged == NO) {
        return;
    }
    
    if (self.tag == NEW_FLASHCARDVIEW_TAG) {
        //we will save until after we press the save button
        [self commitQuestionAndAnswerData];
    } else {
        //[self saveEdittedCard];
        
        if (!_HUD) {
            _HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
        }
        [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
        [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
        
        _HUD.mode = MBProgressHUDModeIndeterminate;
        [_HUD show:YES];
        _HUD.labelText = NSLocalizedString(@"DIALOG_APPLY_TO_ALL_CARD",@"");
        [self performSelector:@selector(execTextFieldDidEndEditingTask:) withObject:textField afterDelay:0.01];
        
    }
    
    _isTextFieldsChanged = NO;
    
}

- (void) execTextFieldDidEndEditingTask:(UITextField *)textField  {
    [iConsole info:@"%s",__FUNCTION__];
    if (textField.tag == kTagTitleQuestion) {
        [self reSceenshotAll:kReasonQuestionTitleChangeEnum withStringVal:textField.text];
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    } else if (textField.tag == kTagTitleAnser) {
        [self reSceenshotAll:kReasonAnswerTitleChangeEnum withStringVal:textField.text];
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    } else if (textField.tag == kTagSidebar) {
        [self reSceenshotAll:kReasonSidebarTitleChangeEnum withStringVal:textField.text];
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    } else if (textField.tag == kTagCreator) {
        [self reSceenshotAll:kReasonCreatorTitleChaneEnum withStringVal:textField.text];
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    } else if (textField.tag == kTagJobTitle) {
        [self reSceenshotAll:kReasonJobTitleChaneEnum withStringVal:textField.text];
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    }else {
        [iConsole info:@"%s:Error",__FUNCTION__];
    }
    
    [_HUD removeFromSuperview];
    _HUD = nil;
}




#pragma mark -
#pragma mark - UITextViewDelegate
//只要内容一改变，就会call
- (void)textViewDidChange:(UITextView *)textView {
    [iConsole info:@"%s",__FUNCTION__];
    //    CGRect frame = textView.frame;
    //    frame.size.height = textView.contentSize.height;
    //    textView.frame = frame;
    
    
    
    
}

//当点击，并还没有开始改变内容时
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [iConsole info:@"%s",__FUNCTION__];
    
    
    /*
     * Clear text color is used UNIQUELY in the app to specify those "semi texts" that should be hidden
     * since we can not use the hidden propery, which could make touch out of response
     * Never use clear color for text color everywhere else
     */
    if ([textView.textColor isEqual:[UIColor clearColor]] == true) {
        
        UIColor *textColor;
        if (textView.tag == kTagSubheadingQuestion){
            textColor = [self colorFromColorCSSString:_currentCard.question.css.subheadingColor];
        } else if (textView.tag == kTagMainQuestion) {
            textColor = [self colorFromColorCSSString:_currentCard.question.css.mainColor];
        } else if (textView.tag == kTagSubQuestion) {
            textColor = [self colorFromColorCSSString:_currentCard.question.css.subColor];
        } else if (textView.tag == kTagSubheadingAnswer) {
            textColor = [self colorFromColorCSSString:_currentCard.answer.css.subheadingColor];
        } else if (textView.tag == kTagMainAnswer) {
            textColor = [self colorFromColorCSSString:_currentCard.answer.css.mainColor];
        } else if (textView.tag == kTagSubAnswer) {
            textColor = [self colorFromColorCSSString:_currentCard.answer.css.subColor];
        } else {
            textColor = [UIColor blackColor];
        }
        
        textView.textColor = textColor;
        textView.alpha = 0.5; //只有两种情况会成为0.5，另外一种是点击"make visible按钮"
    }
    
    _lastBecomeFirstRespondTextView = textView;
    _isUITextViewFocused = TRUE;
    _keyboardInputBaseView.hidden = FALSE;
    [_emotionButton setTitle:NSLocalizedString(@"ToolbarItem_Symbol",@"")];
    
    switch (_keyboardTopViewV2.toolbarState) {
        case Type_Toolbar_State_Main:
            break;
        case Type_Toolbar_State_Font:
            [self updateFontButtonsStatus:nil];
            break;
        case Type_Toolbar_State_Size:
            [self updateSizeButtonsStatus:nil];
            break;
        case Type_Toolbar_State_Align:
            [self updateAlignButtonsStatus:nil];
            break;
        case Type_Toolbar_State_Color:
            [self updateColorButtonsStatus:nil];
            break;
        case Type_Toolbar_State_Text2Speech:
            [self updateText2SpeechButtonsStatus:nil];
            break;
        case Type_Toolbar_State_Unkown:
            break;
            
        default:
            break;
    }
    
    return TRUE;
}

//是否允许更改
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [iConsole info:@"%s",__FUNCTION__];
    
    static CGFloat height = 0;
    static long tag = -1;
    
    if (tag != textView.tag) {
        height = 0;
    }
    
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    CGFloat cursorY = [responderTextView caretRectForPosition:responderTextView.selectedTextRange.start].origin.y + responderTextView.font.lineHeight;
    
    CGFloat yInScrren;
    
    if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)){
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].y;
        } else {
            yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].x;
        }
    } else {
        //Since we convert to point based on UIWindow
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if (isUserInterfaceIdiomPhone) {
                yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].y;
            } else {
                yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].y;
            }
        } else {
            if (isUserInterfaceIdiomPhone) {
                yInScrren = IPHONE_UI_HEIGHT - [responderTextView convertPoint:CGPointZero toView:nil].x;
            } else {
                yInScrren = IPAD_UI_HEIGHT -[responderTextView convertPoint:CGPointZero toView:nil].x;
            }
        }
        
    }
    
    CGPoint offset = _verticalScrollView.contentOffset;
    float gap;  //
    if (isUserInterfaceIdiomPhone) {
        gap = _keyboardHeight -(IPHONE_UI_HEIGHT - yInScrren - cursorY);
    } else {
        gap = _keyboardHeight -(IPAD_UI_HEIGHT - yInScrren - cursorY);
    }
    
    BOOL couldTriggerToResetContentOffset = FALSE;
    
    //这时实际中可能因为键盘输入速度太快，导致无法及时完成setContentOffset，所以需要包含：textView.contentSize.height == height
    if ([text isEqualToString:@""] == FALSE) {
        if ((textView.contentSize.height >= height) && (height != 0)) { //增加行数（增加文字）
            if (gap > 0) {
                offset.y = offset.y + gap;
                [_verticalScrollView setContentOffset:offset animated:YES];
                couldTriggerToResetContentOffset = YES;
            }
        }
        
    } else {
        if ((textView.contentSize.height <= height)&& (height != 0)) { //删除行（减少文字）
            if (gap < 0) {
                offset.y = offset.y - fabsf(gap);
                [_verticalScrollView setContentOffset:offset animated:YES];
                couldTriggerToResetContentOffset = YES;
                
            }
        }
    }
    
    if ((offset.y <= 0) && couldTriggerToResetContentOffset) {  //因为offset永远是大于0的
        offset.y = 0;
        [_verticalScrollView setContentOffset:offset animated:YES];
        couldTriggerToResetContentOffset = FALSE;
    }
    
    [iConsole info:@"lineHeight = %f, height = %f, cursorY = %f",responderTextView.font.lineHeight,height,cursorY];
    
    height= textView.contentSize.height;
    tag = textView.tag;
    
    [self adjustFontToFit:textView withHighAccuracy:Resize_Accuracy_Type_Low];
    
    return YES;
    
}

#pragma mark -
#pragma mark - Add logo linkage relate

- (void) editLogoLinkageURL:(id) sender {
    [iConsole info:@"%s",__FUNCTION__];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:[NSString stringWithFormat:NSLocalizedString(@"DIALOG_ENTER_VALID_URL",@"")
                                                             ]
                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Cancel",@"")
                                          otherButtonTitles:NSLocalizedString(@"Keyboard_Done",@""), nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    if ([[_currentPack cards] count]  >0) {
        _logoLinkURL = ((Card *)[_currentPack cards][0]).question.logoURLLinkage;
    }
    [alert textFieldAtIndex:0].text = _logoLinkURL;
    alert.tag = Type_AlertView_LogoURL;
    alert.delegate = self;
    [alert show];
    
    APP_DELEGATE.isAllowToShowPackList = NO;
}



- (void)openWebviewViaLogoURL:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    NSString *str = _currentCard.question.logoURLLinkage;
    if ([Common validateUrl:str] && [str hasPrefix:@"http://www."] && str.length > 12) {
        
        NSURL *url = [NSURL URLWithString:_currentCard.question.logoURLLinkage];
        SimpleWebBrowserController *webViewController = [[SimpleWebBrowserController alloc] initWithURL:url];
        webViewController.hidesToolbar = NO;
        
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        if (_calledViewController) {
            //means this is called from play mode
            [_calledViewController presentModalViewController:navController animated:YES];
        } else {
            [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navController animated:YES];
        }
        
    } else if ([str rangeOfString:@"@"].location != NSNotFound) {
        
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
            mailer.mailComposeDelegate = self;
            mailer.navigationBar.tintColor = [UIColor whiteColor];
            NSArray *sendTo = [[NSArray alloc] initWithObjects:str, nil];
            [mailer setToRecipients:sendTo];
            [mailer setSubject:@"Hello"];
            //[mailer setMessageBody:[NSString stringWithFormat:@"<html><head></head><body><br><br><br>%@</body></html>", [self supportText]] isHTML:YES];
            if (_calledViewController) {
                //means this is called from play mode
                [_calledViewController presentModalViewController:mailer animated:YES];
            } else {
                [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:mailer animated:YES];
            }
        } else {
            [Common alertViewCommon:NSLocalizedString(@"DIALOG_SET_MAIL_ADDRESS",@"")];
        }
        
        
    } else {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_INCORRECT_URL_OR_EMAIL",@"")];
    }
}

#pragma mark -
#pragma mark - MFMailComposeViewController delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
    [iConsole info:@"%s",__FUNCTION__];
    [controller dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark - BaseViewDelegate

- (void) updatelogoURLForAllCards:(NSString *)urlString {
    [iConsole info:@"%s",__FUNCTION__];
    for (Card *card in [_currentPack cards]) {
        card.question.logoURLLinkage =urlString;
        [card save];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
}

- (void) updatelogoImageForAllCards:(NSString *) imagePath {
    [iConsole info:@"%s",__FUNCTION__];
    if ((self.tag != CURRENT_FLASHCARDVIEW_TAG) && (self.tag != NEW_FLASHCARDVIEW_TAG)) {
        return;
    }
    
    //    for (Card *card in [_currentPack cards]) {
    //        card.question.logoFullPath =imagePath;
    //        [card save];
    //    }
    
    [self reSceenshotAll:kReasonLogoImageChangeEnum withStringVal:imagePath];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
}



/**
 *  第一步
 *  1.先确保在frame里面（减小字体大小）
 *  maxLineNo的唯一作用是传递给triggerResizeTextToSameLineNo
 */
- (BOOL) triggerResizeTextToFitFrame:(UITextView *) textView withMaxLineNumber: (long) maxLineNo{
    
    __weak __typeof(&*self)weakSelf = self;
    
    if ((textView.contentSize.height > CGRectGetHeight(textView.frame) )
            &&(textView.contentSize.height >0)
                  &&(textView.font.pointSize >0)
                       &&(textView.text.length >0)) {
        
        float targetLineNoFloat = CGRectGetHeight(textView.frame) / textView.font.lineHeight;
        
        float delta;
        
        if (isUserInterfaceIdiomPhone == YES) {
            //TODO:虽然这个逻辑也适合iPad，但是在接近releae状态下，我们不想冒这个风险。将来再仔细验证
            delta = [self getAbsDifferenceForResizingText:textView withTargetLineNo:targetLineNoFloat];
        } else {
            if (textView.contentSize.height > CGRectGetHeight(textView.frame) +  3* textView.font.lineHeight) {
                delta = 2;
            } else if (textView.contentSize.height > CGRectGetHeight(textView.frame) +  2* textView.font.lineHeight) {
                delta = 1;
            } else if (textView.contentSize.height > CGRectGetHeight(textView.frame) +  textView.font.lineHeight) {
                delta = 0.5;
            } else {
                delta = 0.3;
            }
        }
        
        NSLog(@"triggerResizeTextToFitFrame: font size = %f on text = %@ with delta = %f",textView.font.pointSize,textView.text, delta);
        
        
        [textView setFont:[textView.font fontWithSize:(textView.font.pointSize  - delta)]];  //是异步更新的，即如果这时去拿text height等参数时，不正确（实际中，发现即便使用setNeedDisplay, setNeedLayout,甚至layoutifneeded也不行），所以需要通过disptach到下一个runloop中去
        
        double delayInSeconds = 0.02;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf triggerResizeTextToFitFrame:textView withMaxLineNumber:maxLineNo];
        });
        
        return NO;
        
    } else {
        
        //最终出口
        
        double delayInSeconds = 0.04;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf triggerResizeTextToSameLineNo_Bigger:textView withMaxLineNumber:maxLineNo];
        });
        
        return YES;
    }
    
}


/**
 *  用于resize的decrease/increase的differnce
 *  返回永远是正数（永远不会是0）。如果目标行数与现有一致或者本身文本为空，则返回0.15
 */
- (float) getAbsDifferenceForResizingText:(UITextView *) textView withTargetLineNo:(float) targetLineNoFloat {
    
    if (textView.text.length == 0) {
        return 0.15;
    }
    
    float fontSize = textView.font.pointSize;
    float lineHeight = textView.font.lineHeight;
    float textHeight = [self getTrustableTextHeight:textView];
    int   lineNo     = round(textHeight/lineHeight); //textHeight/lineHeight一定是一个接近于整数的数值，这个由getTrustableTextHeight保证
    
    
    //如何得到以下公式：测试发现，当行数希望达到原来的一倍时，这时字体的大小大约为1.8-2.2之间，为了安全期间，我们设定为1.5-2.5之间。
    float delta = fabsf(targetLineNoFloat - lineNo)/lineNo * fontSize  *0.5;
    
    NSLog(@"getAbsDifferenceForResizingText: targetLineNoFloat =%f,lineNo =%d,fontSize = %f, delta = %f on textView = %@",targetLineNoFloat,lineNo,fontSize,delta,textView.text);
    
    if (delta < 0.15) {  //为了避免无休止的循环或迭代次数太多，比如有可能delta = 0.0001
        delta = 0.15;
    }
    
    return delta;
    
}


/**
 *  返回是一个float，这个需要注意，因为这个在只有一行的情况下很重要，比如如果只有一行，则int就有可能为0
 *  计算文本高度有4种（http://stackoverflow.com/questions/34207289/4-alternative-ways-to-calculate-text-height-in-a-uitextview-ios7-but-which-o?noredirect=1#comment56160153_34207289), 里面提到了以下的两种方法，但是没有一种是完全可靠的，但是有个规律，如下。
 *  值得注意的是，最近发现sizeThatFits可能是最佳答案，因为这个方法不需要经过run loop就能更新，但是为了安全起见，我们还是使用老的。将来如果发现问题，则
 *   我们还没有把这种计算方法应用到全部中，因为我们没有100%的把握（虽然已经有了99%），后续会全部运用。
 */
- (float) getTrustableTextHeight:(UITextView *) textView {
    
    if (textView.text.length == 0) {
        return 0;
    }
    
    float lineHeight = textView.font.lineHeight;
    
    CGFloat textHeight;
    
    //第一种方法，实践中，我们发现，当textHeight/lineHeight足够接近一个整数时，才可以信任
    textHeight = textView.contentSize.height;
    if (fabs(textHeight/lineHeight - round(textHeight/lineHeight)) < 0.1) {
        return textHeight;
    } else {
        NSLog(@"Untrustable textHeight calculation = %f, we will use another way",textHeight/lineHeight);
    }
    
    //如果第一种方法不行，则使用第二种方法
    float fudgeFactor = [self getTextViewLeftMargin:textView];
    CGSize tallerSize = CGSizeMake(textView.frame.size.width-fudgeFactor*2,999);
    
    CGSize stringSize;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        stringSize = [textView.text sizeWithFont:textView.font constrainedToSize:tallerSize lineBreakMode:NSLineBreakByWordWrapping];
    } else {
        stringSize = [textView.text sizeWithFont:textView.font constrainedToSize:tallerSize lineBreakMode:UILineBreakModeWordWrap];
    }
    
    textHeight = stringSize.height;
    return textHeight;

}

/**
 *  第二步
 *  如果行数太少1，则增大字体大小 （注意，这时需要加上：(textView.contentSize.height <= CGRectGetHeight(textView.frame) )）
 *  先执行：triggerResizeTextToFitFrame，然后再执行triggerResizeTextToSameLineNo
 */
- (BOOL) triggerResizeTextToSameLineNo_Bigger:(UITextView *) textView withMaxLineNumber: (long) maxLineNo {
    
    __weak __typeof(&*self)weakSelf = self;
    
    __block int lineNumber = [self lineNumberWithUITextView:textView];
    
    //Debug purpose, leave here in case we need more adjust
    if ([textView.text rangeOfString:@"Which gas law "].location != NSNotFound) {
        
    }
    
    if ((maxLineNo > lineNumber) && (maxLineNo != 0) && (lineNumber > 0)
              && (textView.contentSize.height <= CGRectGetHeight(textView.frame))
                     && (textView.text.length >0)) {  //文字不超过frame,这个很重要
        
    
        
        float delta;
        if (isUserInterfaceIdiomPhone == YES) {
            //TODO:虽然这个逻辑也适合iPad，但是在接近releae状态下，我们不想冒这个风险。将来再仔细验证
            delta = [self getAbsDifferenceForResizingText:textView withTargetLineNo:maxLineNo];
        } else {
            if (maxLineNo > lineNumber + 3) {
                delta = 3;
            } else if (maxLineNo > lineNumber + 2) {
                delta = 2;
            } else if (maxLineNo > lineNumber + 1) {
                delta = 1;
            } else {
                delta = 0.3;
            }
        }
        
        NSLog(@"triggerResizeTextToSameLineNo_Bigger: font size = %f on text = %@ with delta = %f",textView.font.pointSize, textView.text,delta);
        
        
        [textView setFont:[textView.font fontWithSize:(textView.font.pointSize  + delta)]];
        
        double delayInSeconds = 0.02;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf triggerResizeTextToSameLineNo_Bigger:textView withMaxLineNumber:maxLineNo];
        });
        
        return NO;
        
    } else {
        
        double delayInSeconds = 0.04;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf triggerResizeTextToSameLineNo_Smaller:textView withMaxLineNumber:maxLineNo];
        });
        
        return YES;
    }
    
}

/**
 *  第三步。
 *  3. 再， 如果字体有点大，则缩小。
 *  路径：
 *  a. 有可能是先经过第一步resize，然后第二步resize，最后到这里;
 *  b. 也有可能是直接调用
 *  c. 也有可能是先经过第一步的resize，然后到这里
 */
- (BOOL) triggerResizeTextToSameLineNo_Smaller:(UITextView *) textView withMaxLineNumber: (long) maxLineNo {
    
    
    //Debug purpose, leave here in case we need more adjust
    if ([textView.text rangeOfString:@"When the"].location != NSNotFound) {
        
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    __block int lineNumber = [self lineNumberWithUITextView:textView];
    
    
    
    if (((maxLineNo < lineNumber) && (maxLineNo != 0) && (lineNumber > 0)
                && (textView.text.length >0)) || (textView.contentSize.height > CGRectGetHeight(textView.frame) && (textView.text.length >0))) {
        
        
        float delta;
        
        if (isUserInterfaceIdiomPhone == YES) {
            //TODO:虽然这个逻辑也适合iPad，但是在接近releae状态下，我们不想冒这个风险。将来再仔细验证
            delta = [self getAbsDifferenceForResizingText:textView withTargetLineNo:maxLineNo];
        } else {
            if (maxLineNo > lineNumber + 3) {
                delta = 3;
            } else if (maxLineNo > lineNumber + 2) {
                delta = 2;
            } else if (maxLineNo > lineNumber + 1) {
                delta = 1;
            } else {
                delta = 0.3;
            }
        }
        
        NSLog(@"triggerResizeTextToSameLineNo_Smaller: font size = %f  on text = %@ with delta = %f",textView.font.pointSize, textView.text, delta);
        
        [textView setFont:[textView.font fontWithSize:(textView.font.pointSize  - delta)]];
        
        double delayInSeconds = 0.020;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [weakSelf triggerResizeTextToSameLineNo_Smaller:textView withMaxLineNumber:maxLineNo];
        });
        
        return NO;
        
    } else {
        
        //最终出口
        double delayInSeconds = 0.02;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [weakSelf didFinishResizeText:textView];
        });
        
        return YES;
    }
    
}

/**
 *  最终出口
 */
- (void) didFinishResizeText:(UITextView *) textView {
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        
        if (textView.tag == kTagSubheadingQuestion) {
            flag_Subheading_ResizeFinished = YES;
        } else if (textView.tag == kTagMainQuestion) {
            flag_Main_ResizeFinished = YES;
        } else if (textView.tag == kTagSubQuestion) {
            flag_Sub_ResizeFinished = YES;
        }
        
        
    } else {
        
        if (textView.tag == kTagSubheadingAnswer) {
            flag_Subheading_ResizeFinished = YES;
        } else if (textView.tag == kTagMainAnswer) {
            flag_Main_ResizeFinished = YES;
        } else if (textView.tag == kTagSubAnswer) {
            flag_Sub_ResizeFinished = YES;
        }
        
    }
    
//    [self setVerticalAlignment:textView];
    
    if (flag_Subheading_ResizeFinished && flag_Main_ResizeFinished && flag_Sub_ResizeFinished) {
        
        [self updateQuestionAnswerAllTextViewVeriticalAlignment];
        
        double delayInSeconds = 0.04;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            _verticalScrollView.hidden = NO;
        });
        
    }
    
}


- (void) adjustAllTextViewsToFitIfNecessary {
    [iConsole info:@"%s",__FUNCTION__];
    
    
    
    if ([self checkCardEditable]) {
        return;
    }
    
    //There's an error in original pack, so we need a patch here
    if ([_currentCard.answer.main rangeOfString:@"Knee how"].location != NSNotFound) {
        _currentCard.answer.lineNoMain = 5;
    }
    
    if (([self.currentPack.platform isEqualToString:@"iPhone"] && (isUserInterfaceIdiomPhone)) ||
        ([self.currentPack.platform isEqualToString:@"iPad"] && (isUserInterfaceIdiomPhone == false))){
        return;
    }
    
    if (([self.currentPack.platform isEqualToString:@"iPhone"] && (isUserInterfaceIdiomPhone)) ||
        ([self.currentPack.platform isEqualToString:@"iPad"] && (isUserInterfaceIdiomPhone == false))){
        return;
    }
    
    flag_Subheading_ResizeFinished = NO;
    flag_Main_ResizeFinished = NO;
    flag_Sub_ResizeFinished = NO;
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        
        if (_subheadingQuestion.hidden && _mainQuestion.hidden && _subQuestion.hidden) {
            // _verticalScrollView is hidden when resizing process. if no text, we don't do this
        } else {
            _verticalScrollView.hidden = YES;
        }
        
        
        if (_subheadingQuestion.hidden == false) {
            [self triggerResizeTextToFitFrame:_subheadingQuestion withMaxLineNumber:_currentCard.question.lineNoSubheading];
        } else {
            flag_Subheading_ResizeFinished = true;
        }
        
        if (_mainQuestion.hidden == false) {
            [self triggerResizeTextToFitFrame:_mainQuestion withMaxLineNumber:_currentCard.question.lineNoMain];
        } else {
            flag_Main_ResizeFinished = true;
        }
        
        if (_subQuestion.hidden == false) {
            [self triggerResizeTextToFitFrame:_subQuestion withMaxLineNumber:_currentCard.question.lineNoSub];
        } else {
            flag_Sub_ResizeFinished = true;
        }
        
    } else {
        
        if (_subheadingAnswer.hidden && _mainAnswer.hidden && _subAnswer.hidden) {
            // _verticalScrollView is hidden when resizing process. if no text, we don't do this
        } else {
            _verticalScrollView.hidden = YES;
        }
        
        if (_subheadingAnswer.hidden == false) {
            [self triggerResizeTextToFitFrame:_subheadingAnswer withMaxLineNumber:_currentCard.answer.lineNoSubheading];
        } else {
            flag_Subheading_ResizeFinished = true;
        }
        
        if (_mainAnswer.hidden == false) {
            [self triggerResizeTextToFitFrame:_mainAnswer withMaxLineNumber:_currentCard.answer.lineNoMain];
        } else {
            flag_Main_ResizeFinished = true;
        }
        
        if (_subAnswer.hidden == false) {
            [self triggerResizeTextToFitFrame:_subAnswer withMaxLineNumber:_currentCard.answer.lineNoSub];
        } else {
            flag_Sub_ResizeFinished = true;
        }
        
    }
}

/** 
 *  Deprecated*******不再使用
 */
- (BOOL) adjustAllTextViewsToFitIfNecessary_Old {
    
    if (([self.currentPack.platform isEqualToString:@"iPhone"] && (isUserInterfaceIdiomPhone)) ||
           ([self.currentPack.platform isEqualToString:@"iPad"] && (isUserInterfaceIdiomPhone == false))){
        return false;
    }
    
    
    [iConsole info:@"%s",__FUNCTION__];
    BOOL result = NO;
    
    int i = 0;
    int kMax = 40;
    int lineNumber;
    
//    if ([_currentCard.question.main rangeOfString:@"Life is great"].location != NSNotFound) {
//        _currentCard.question.lineNoMain = 6;
//    }
    
    
    //Debug code only
    if ([_mainQuestion.text rangeOfString:@"What is the percentage"].location != NSNotFound) {
        
    }
    
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        
        
        //------行数不一致时，增大字体 （初调，步长大）-------
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
        while ((_currentCard.question.lineNoSubheading > lineNumber) && (_currentCard.question.lineNoSubheading != 0) && (i<kMax) && (lineNumber > 0)) {
            [_subheadingQuestion setFont:[_subheadingQuestion.font fontWithSize:(_subheadingQuestion.font.pointSize *1.1)]];
            lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
            //[iConsole info:@"%s:_currentCard.question.lineNoSubheading= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSubheading,lineNumber];
            i++;
            usleep(1000);
        }
        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_mainQuestion];
        while ((_currentCard.question.lineNoMain > lineNumber) && (_currentCard.question.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
            [_mainQuestion setFont:[_mainQuestion.font fontWithSize:(_mainQuestion.font.pointSize *1.1)]];
            lineNumber = [self lineNumberWithUITextView:_mainQuestion];
            //[iConsole info:@"%s:_currentCard.question.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoMain,lineNumber];
            i++;
            usleep(1000);
        }
        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subQuestion];
        while ((_currentCard.question.lineNoSub > lineNumber)&& (_currentCard.question.lineNoSub >= 0)&& (i<kMax)&& (lineNumber > 0)) {
            [_subQuestion setFont:[_subQuestion.font fontWithSize:(_subQuestion.font.pointSize *1.1)]];
            lineNumber = [self lineNumberWithUITextView:_subQuestion];
            //[iConsole info:@"%s:_currentCard.question.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSub,lineNumber];
            i++;
            usleep(1000);
        }
        
        
        //------粗粒度的调整）-------
        
        if ([self adjustFontToFit:_subheadingQuestion withHighAccuracy:Resize_Accuracy_Type_Low]){
            result= YES;
        }
        if ([self adjustFontToFit:_mainQuestion withHighAccuracy:Resize_Accuracy_Type_Low]){
            
            result= YES;
        }
        if ([self adjustFontToFit:_subQuestion withHighAccuracy:Resize_Accuracy_Type_Low]){
            result= YES;
        }
        

        //-----行数太小时，增大字体 （还是用粗粒度，通过最后的adjustFontToFit进行保证），这种做法的原因是lineNumberWithUITextView精度无法保证-----
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
        while ((_currentCard.question.lineNoSubheading > lineNumber) && (_currentCard.question.lineNoSubheading != 0) && (i<kMax) && (lineNumber > 0)) {
            [_subheadingQuestion setFont:[_subheadingQuestion.font fontWithSize:(_subheadingQuestion.font.pointSize  + 1)]];
            lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
            //[iConsole info:@"%s:_currentCard.question.lineNoSubheading= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSubheading,lineNumber];
            i++;
            usleep(1000);
        }
        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_mainQuestion];
        while ((_currentCard.question.lineNoMain > lineNumber) && (_currentCard.question.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
            [_mainQuestion setFont:[_mainQuestion.font fontWithSize:(_mainQuestion.font.pointSize  + 1)]];
            lineNumber = [self lineNumberWithUITextView:_mainQuestion];
            //[iConsole info:@"%s:_currentCard.question.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoMain,lineNumber];
            i++;
            usleep(1000);
        }
        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subQuestion];
        while ((_currentCard.question.lineNoSub > lineNumber)&& (_currentCard.question.lineNoSub >= 0)&& (i<kMax)&& (lineNumber > 0)) {
            [_subQuestion setFont:[_subQuestion.font fontWithSize:(_subQuestion.font.pointSize  + 1)]];
            lineNumber = [self lineNumberWithUITextView:_subQuestion];
            //[iConsole info:@"%s:_currentCard.question.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSub,lineNumber];
            i++;
            usleep(1000);
        }
        
        //------减少字体大小（精细，步长小）-------
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
        while ((_currentCard.question.lineNoSubheading < lineNumber) && (_currentCard.question.lineNoSubheading != 0) && (i<kMax) && (lineNumber > 0)) {
            [_subheadingQuestion setFont:[_subheadingQuestion.font fontWithSize:(_subheadingQuestion.font.pointSize -0.2)]];
            lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
            //[iConsole info:@"%s:_currentCard.question.lineNoSubheading= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSubheading,lineNumber];
            i++;
            usleep(1000);
        }
        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_mainQuestion];
        while ((_currentCard.question.lineNoMain < lineNumber) && (_currentCard.question.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
            [_mainQuestion setFont:[_mainQuestion.font fontWithSize:(_mainQuestion.font.pointSize -0.1)]];
            lineNumber = [self lineNumberWithUITextView:_mainQuestion];
            //[iConsole info:@"%s:_currentCard.question.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoMain,lineNumber];
            i++;
            usleep(1000);
        }
        
        i = 0;
        
        lineNumber = [self lineNumberWithUITextView:_subQuestion];
        while ((_currentCard.question.lineNoSub < lineNumber)&& (_currentCard.question.lineNoSub >= 0)&& (i<kMax)&& (lineNumber > 0)) {
            [_subQuestion setFont:[_subQuestion.font fontWithSize:(_subQuestion.font.pointSize -0.2)]];
            lineNumber = [self lineNumberWithUITextView:_subQuestion];
            //[iConsole info:@"%s:_currentCard.question.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSub,lineNumber];
            i++;
            usleep(1000);
        }
        
        
        //------以防万一，我们需要再做一次高粒度的fit------
        if ([self adjustFontToFit:_subheadingQuestion withHighAccuracy:Resize_Accuracy_Type_Extreme]){
            result= YES;
        }
        if ([self adjustFontToFit:_mainQuestion withHighAccuracy:Resize_Accuracy_Type_Extreme]){
            
            result= YES;
        }
        if ([self adjustFontToFit:_subQuestion withHighAccuracy:Resize_Accuracy_Type_Extreme]){
            result= YES;
        }
    
        
        
//        //这样下次就不会进行autoresize操作了 （除非切换到另外一个pack或fore to restart。此autoresizeFlag字段不会写入数据库）
//        if (result == YES) {
//            _currentCard.question.autoresizeFlag = 0;
//        }
        
        
        
        
    } else {
        
        
        //-------行数太小时，增大字体 （粗调，步长大）-------
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
        while ((_currentCard.answer.lineNoSubheading > lineNumber)&& (_currentCard.answer.lineNoSubheading != 0)&& (i<kMax)&& (lineNumber > 0)) {
        
            
            [_subheadingAnswer setFont:[_subheadingAnswer.font fontWithSize:(_subheadingAnswer.font.pointSize*1.1)]];
            lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
            //[iConsole info:@"%s:_currentCard.answer.lineNoSubheading = %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSubheading ,lineNumber];
            i++;
            usleep(5000);
        }
        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_mainAnswer];
        while ((_currentCard.answer.lineNoMain > lineNumber)&& (_currentCard.answer.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
        
            
            [_mainAnswer setFont:[_mainAnswer.font fontWithSize:(_mainAnswer.font.pointSize*1.1)]];
            lineNumber = [self lineNumberWithUITextView:_mainAnswer];
            //[iConsole info:@"%s:_currentCard.answer.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoMain,lineNumber];
            i++;
            usleep(5000);
        }

        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subAnswer];
        while ((_currentCard.answer.lineNoSub > lineNumber)&& (_currentCard.answer.lineNoSub != 0)&& (i<kMax)&& (lineNumber > 0)) {
            
            [_subAnswer setFont:[_subAnswer.font fontWithSize:(_subAnswer.font.pointSize*1.1)]];
            lineNumber = [self lineNumberWithUITextView:_subAnswer];
            //[iConsole info:@"%s:_currentCard.answer.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSub,lineNumber];
            i++;
            usleep(5000);
        }

        
        //---- 粗粒度的调整----
        
        if ([self adjustFontToFit:_subheadingAnswer withHighAccuracy:Resize_Accuracy_Type_Low]){
            
            result= YES;
        }
        if ([self adjustFontToFit:_mainAnswer withHighAccuracy:Resize_Accuracy_Type_Low]){
            result= YES;
        }
        if ([self adjustFontToFit:_subAnswer withHighAccuracy:Resize_Accuracy_Type_Low]){
            result= YES;
        }

        
        //----------行数太小时，增大字体 （还是用粗粒度，通过最后的adjustFontToFit进行保证），这种做法的原因是lineNumberWithUITextView精度无法保证-----
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
        while ((_currentCard.answer.lineNoSubheading > lineNumber)&& (_currentCard.answer.lineNoSubheading != 0)&& (i<kMax)&& (lineNumber > 0)) {
            
            [_subheadingAnswer setFont:[_subheadingAnswer.font fontWithSize:(_subheadingAnswer.font.pointSize + 1)]];
            lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
            //[iConsole info:@"%s:_currentCard.answer.lineNoSubheading = %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSubheading ,lineNumber];
            i++;
            usleep(1000);
        }
 
        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_mainAnswer];
        while ((_currentCard.answer.lineNoMain > lineNumber)&& (_currentCard.answer.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {

            [_mainAnswer setFont:[_mainAnswer.font fontWithSize:(_mainAnswer.font.pointSize + 1)]];
            lineNumber = [self lineNumberWithUITextView:_mainAnswer];
            //[iConsole info:@"%s:_currentCard.answer.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoMain,lineNumber];
            i++;
            usleep(1000);
        }

        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subAnswer];
        while ((_currentCard.answer.lineNoSub > lineNumber)&& (_currentCard.answer.lineNoSub != 0)&& (i<kMax)&& (lineNumber > 0)) {
            
            [_subAnswer setFont:[_subAnswer.font fontWithSize:(_subAnswer.font.pointSize + 1)]];
            lineNumber = [self lineNumberWithUITextView:_subAnswer];
            //[iConsole info:@"%s:_currentCard.answer.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSub,lineNumber];
            i++;
            usleep(5000);
        }

        
        //----行数太多，减少字体大小 （精调，步长小）-----
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
        while ((_currentCard.answer.lineNoSubheading < lineNumber)&& (_currentCard.answer.lineNoSubheading != 0)&& (i<kMax)&& (lineNumber > 0)) {
            
            [_subheadingAnswer setFont:[_subheadingAnswer.font fontWithSize:(_subheadingAnswer.font.pointSize - 0.1)]];
            lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
            //[iConsole info:@"%s:_currentCard.answer.lineNoSubheading = %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSubheading ,lineNumber];
            i++;
            usleep(5000);
        }

        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_mainAnswer];
        while ((_currentCard.answer.lineNoMain < lineNumber)&& (_currentCard.answer.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
            
            [_mainAnswer setFont:[_mainAnswer.font fontWithSize:(_mainAnswer.font.pointSize - 0.1)]];
            lineNumber = [self lineNumberWithUITextView:_mainAnswer];
            //[iConsole info:@"%s:_currentCard.answer.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoMain,lineNumber];
            i++;
            usleep(5000);
        }

        
        i = 0;
        lineNumber = [self lineNumberWithUITextView:_subAnswer];
        while ((_currentCard.answer.lineNoSub < lineNumber)&& (_currentCard.answer.lineNoSub != 0)&& (i<kMax)&& (lineNumber > 0)) {
            
            [_subAnswer setFont:[_subAnswer.font fontWithSize:(_subAnswer.font.pointSize - 0.1)]];
            lineNumber = [self lineNumberWithUITextView:_subAnswer];
            //[iConsole info:@"%s:_currentCard.answer.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSub,lineNumber];
            i++;
            usleep(5000);
        }

        
        //---- 以防万一，我们需要再做一次高粒度的fit----
        
        if ([self adjustFontToFit:_subheadingAnswer withHighAccuracy:Resize_Accuracy_Type_Extreme]){
            result= YES;
        }
        if ([self adjustFontToFit:_mainAnswer withHighAccuracy:Resize_Accuracy_Type_Extreme]){
            result= YES;
        }
        if ([self adjustFontToFit:_subAnswer withHighAccuracy:Resize_Accuracy_Type_Extreme]){
            result= YES;
        }
        
        
        
        //这样下次就不会进行autoresize操作了。除非切换到另外一个pack或fore to restart。此autoresizeFlag字段不会写入数据库）
//        if (result == YES) {
//            _currentCard.answer.autoresizeFlag = 0;
//        }
    }

    
    
    return result;
}


/**
 *  这只是一个经验值，经过仔细的样本采集
 */
- (float) getTextViewLeftMargin:(UITextView *) textView {
    
    return 0.0;  //最新逻辑. 因为我们已经设置了textContainerInset ＝ UIEdgeInsetsZero;

    int delta = 3;  //delta引入是让计算更保守，让行数的计算结果宁可比实际多，也不要少，有机会让程序通过最后的adjustFontToFit来完成
    
    float size = textView.font.pointSize;
    
    if (size <=15) {
        return 4 - delta;
    } else if (size < 20) {
        return 5.25 - delta + 0.1 * (size - 10);
    } else if (size < 30) {
        return 6.25 -delta + 0.1 * (size - 20);
    } else if (size < 40) {
        return 7.25 -delta + 0.05 * (size - 30);
    } else if (size < 50) {
        return 7.75 -delta + 0.075 * (size - 40);
    } else if (size < 60) {
        return 8.5 -delta + 0.075 * (size - 50);
    } else if (size < 70) {
        return 9.25 -delta + 0.1 * (size - 60);
    } else if (size < 80) {
        return 10.25 -delta + 0.075 * (size - 70);
    } else if (size < 90) {
        return 11 -delta + 0.075 * (size - 80);
    }else {
        return 11.75 -delta + 0.075 * (size - 90);
    }
    
}

/**
 * 用于计算行数
 */
- (float) getTextSizeHeight:(UITextView *) textView{
    
    
    if (TRUE) { //这是正确的做法******
        
        //最终我们是通过这种方法计算行数的： float rawLineNumber = (_textView.contentSize.height - _textView.textContainerInset.top - _textView.textContainerInset.bottom) / _textView.font.lineHeight;
        //则这里需要直接返回textView.contentSize.height
        
        return textView.contentSize.height;
        
    } else {
        
        //这是错误的计算方法****
        //实践中发现，这种方法在计算行数时，会造成突变，比如从font size = 25.8到25.7这么小的一个变化时，行高会突然从120到100。这是不可接受的
        
        //[iConsole info:@"%s",__FUNCTION__];
        float fudgeFactor = [self getTextViewLeftMargin:textView];
        CGSize tallerSize = CGSizeMake(textView.frame.size.width-fudgeFactor*2,999);
        
        if (TRUE) {
            //this is old way
            CGSize stringSize;
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                stringSize = [textView.text sizeWithFont:textView.font constrainedToSize:tallerSize lineBreakMode:NSLineBreakByWordWrapping];
            } else {
                stringSize = [textView.text sizeWithFont:textView.font constrainedToSize:tallerSize lineBreakMode:UILineBreakModeWordWrap];
            }
            
            CGFloat textHeight = stringSize.height; //textView.contentSize.height不准确
            return textHeight;
            
        } else {
            //this is the new way, but we need to verify later
            NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine |
            NSStringDrawingUsesLineFragmentOrigin;
            NSDictionary *attr = @{NSFontAttributeName: textView.font};
            CGRect labelBounds = [textView.text boundingRectWithSize:tallerSize
                                                             options:options
                                                          attributes:attr
                                                             context:nil];
            
            CGFloat textHeight = labelBounds.size.height; //textView.contentSize.height不准确
            return textHeight;
        }
    }

    
}





/**
 *  当字体太大时，自动调整font size以适合textView frame]。同时为了不让字体过小，也设置了下限
 *  有几个前提条件（同时满足下）触发这个方法
 *  1. 必须是不可编辑的卡片
 *  2. textview必须有内容
 *  3. 文字高度超出了[textView frame]。当文字很小，导致高度很小时，我们不作调整，而是默认为10号字体
 */
- (BOOL) adjustFontToFit:(UITextView *) textView withHighAccuracy:(Resize_Accuracy_Type) accuracyType {
    [iConsole info:@"%s",__FUNCTION__];
    BOOL result = NO;
    
    //we don't do this in edit mode
    if ([Common isOwner:_currentPack]) {
        result = NO;
        return result;
    }
    
    if ((textView == NULL) || (textView.text.length ==0)) {
        result = NO;
        return result;
    }
    
    
    [textView layoutSubviews]; //否则textHeight可能为<0
    CGFloat frameHeight = textView.frame.size.height;
    CGFloat textHeight = [self getTextSizeHeight:textView];
    
    CGFloat originalTextHeight = textHeight;
    BOOL outputFlag = FALSE;
    
    //it could be possible。实际情况中发生了，具体原因不明
    while (textHeight <0) {
        
        [iConsole error:@"%s:......Fuck textHeight <0",__FUNCTION__];
        
        if (textView.font.pointSize <10) {
            break;
        }
        
        [textView setFont:[textView.font fontWithSize:(textView.font.pointSize -1)]];
        [textView layoutSubviews];
        
        textHeight = [self getTextSizeHeight:textView];
        usleep(5000);
    }
    
    //设定最小字体
    if (textView.font.pointSize < 10) {
        [textView setFont:[textView.font fontWithSize:(10)]];
        [iConsole error:@"%s:......textView.font.pointSize < 10:%@",__FUNCTION__,textView.text];
    }
    
    float orginalFontSize = textView.font.pointSize;
    
    //为了防止字体太小而设立
    int gate;
    if (_isPlayingCard) {
        gate = 10;
    } else {
        gate = 8;
    }
    
    
    /**
     *  以下逻辑关键是提前设置了textview.textContainerInset ＝ UIEdgeInsetsZero;
     *  最早我们使用了一个经验值作为inset.top和inset.bottom的数值（frameHeight/5）
     *  但是后来我们发现，如果没有设置UIEdgeInsetsZero（默认是top/bottom margin = 8)，当高度小（比如＜40），文本可容纳的高度 != textHeight + inset.top + inset.bottom。只有在高度达到一定成都时，才成立。
     *  最终，我们发现设置UIEdgeInsetsZero会完美解决这个问题，因为我们在任何情况以下都成立:文本可容纳的高度 ＝ textHeight
     */
    
    
    
    
    while ((textHeight > frameHeight )&&(textHeight >0)&&(textView.font.pointSize >0)) {
        outputFlag = TRUE;
        result = YES;
        
        CGFloat pointSize = textView.font.pointSize;
        
        if (pointSize <=gate) {
            //字体越小，size变化越明显
            [iConsole warn:@"%s:......textView.font.pointSize <gate:%@",__FUNCTION__,textView.text];
            break;
        }
        float delta  = 0;
        if (accuracyType == Resize_Accuracy_Type_High) {
            
            [iConsole info:@"withHighAccuracy adjustment = YES"];
            
            if (pointSize < 10.0) {
                delta = 0.15;
            } else if (pointSize < 12.0) {
                delta = 0.4;
            } else if (pointSize < 30.0) {
                delta = 0.6;
            } else if (pointSize < 50.0){
                delta = 0.8;
            } else if (pointSize < 100.0){
                delta = 1;
            }else {
                delta = 1.2;
            }
            
        } else if  (accuracyType == Resize_Accuracy_Type_Low) {
            if (pointSize < 10.0) {
                delta = 0.3;
            } else if (pointSize < 12.0) {
                delta = 0.6;
            } else if (pointSize < 50.0){
                delta = 1.2;
            } else if (pointSize < 100.0){
                delta = 1.8;
            }else {
                delta = 2.4;
            }
            
        } else if (accuracyType == Resize_Accuracy_Type_Extreme) {
            
            //设置成与Resize_Accuracy_Type_High一致，在实际中发现，如果粒度太小，会耗费时间（甚至模拟器上可能会花费>2秒时间）
            if (pointSize < 10.0) {
                delta = 0.15;
            } else if (pointSize < 12.0) {
                delta = 0.4;
            } else if (pointSize < 30.0) {
                delta = 0.6;
            } else if (pointSize < 50.0){
                delta = 0.8;
            } else if (pointSize < 100.0){
                delta = 1;
            }else {
                delta = 1.2;
            }
        } else {
            delta = 1;
            [iConsole error:@"Resize_Accuracy_Type out of range, should not be here"];
        }
        
        [textView setFont:[textView.font fontWithSize:(textView.font.pointSize -delta)]];
        [textView layoutSubviews];
        usleep(5000);
        textHeight = [self getTextSizeHeight:textView];
        
    }
    
    
    if ([self checkCardEditable]) { //只有当Edittable才有这个必要
        
        //必须把auto resize的最终字体大小限制在离散值内
        //_keyboardTopViewV2和_keyboardTopViewForInputViewV2返回一样的sizeArray，任取一都可以
        if (textView.font.pointSize > [[_keyboardTopViewV2.realSizeArray firstObject] intValue]) {
            
            int index = [Common nearestIndexForStringArray:_keyboardTopViewV2.realSizeArray withElement:textView.font.pointSize];
            if (index == - 1) {
                [iConsole error:@"%s:return - 1 when execut [Common nearestIndexForStringArray:_keyboardTopViewV2.realSizeArray withElement:textView.font.pointSize]",__FUNCTION__];
            } else {
                [textView.font fontWithSize:[[_keyboardTopViewV2.realSizeArray objectAtIndex:index] integerValue]];
            }
            
        } else {
            [textView.font fontWithSize:(int)textView.font.pointSize];
        }
    }
    
    
    if (outputFlag) {
        [iConsole info:@"CardSN %ld:text(%@).\n---Original value: height(%f), font size(%f);\n---Final value:height(%f), font size(%f)",_currentCard.cardSN,textView.text,originalTextHeight, orginalFontSize,textView.contentSize.height, textView.font.pointSize];
    }
    
    
    
    return result;
}



- (void) saveEdittedCard {
    //we only deal with current card and new created card
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        [iConsole info:@"%s, return because of ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG))",__FUNCTION__];
        return;
    }
    
    if (_currentPack == nil) {
        [Common alertViewCommon:@"Error to create new card, since _currentPack is nil"];
        return;
    }
    
    _currentCard.templateBackgroundName = _templateBackgroundImageName;
    
    _currentCard.packID = _currentPack.packID;
    
    [self commitQuestionAndAnswerData];
    
    //在操作后，我们不需要返回之前的现场，因为我们是在new card save操作(窗口将被关闭）
    if ((self.tag == NEW_FLASHCARDVIEW_TAG) && (_segmentedControl.selectedSegmentIndex == 1)) {
        [_segmentedControl setSelectedSegmentIndex:0];
        [self refreshAll];
        
    }
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        UIImage *origialmage = [self captureWholeViewAsImage];
        NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
        if ([Common isPlaceholderFilePathOrDirectory:_currentCard.coverImageURL]) {
            NSString *savedFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            [imageData writeToFile:savedFullPath atomically:YES];
            _currentCard.coverImageURL = savedFullPath;
        } else {
            [imageData writeToFile:_currentCard.coverImageURL atomically:YES];
        }
    }
    
    if (self.tag == NEW_FLASHCARDVIEW_TAG) {
        [iConsole info:@"%s:(self.tag == NEW_FLASHCARDVIEW_TAG)",__FUNCTION__];
        [_currentPack addCard:_currentCard];
    } else {
        [_currentCard save];
    }
    
    //only applicable when creating new card
    if (_isAllCardsNeedToBeUpdateForNewCardOnly == YES && isFromNewCreatedCard) {
        
        if (!_HUD) {
            _HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
        }
        [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
        [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
        
        _HUD.mode = MBProgressHUDModeIndeterminate;
        [_HUD show:YES];
        _HUD.labelText = NSLocalizedString(@"DIALOG_APPLY_TO_ALL_CARD",@"");
        
        
        //在creating view中，execUpdatelogoImageForAllCards适用于:job title,name, sidebar, logo引起的需要全部更新sidebar thumbnail情况。TODO:未来需要重构这段逻辑
        [self performSelector:@selector(execUpdatelogoImageForAllCards:) withObject:_logoImageFullPath afterDelay:0.01];
        
        _isAllCardsNeedToBeUpdateForNewCardOnly = NO;
        
        
    }
    
    //update_date info
    NSString *updateDate = [FileOperationHelper getTodayString];
    NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
    [dict setObject:updateDate forKey:@"update_date"];
    
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:_currentPack.packName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Send notification
    if (self.tag == NEW_FLASHCARDVIEW_TAG){
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:@"SENT_FROM_NEW_CARD"];
        [iConsole info:@"%s:postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION",__FUNCTION__];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
        [iConsole info:@"%s:postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION",__FUNCTION__];
    }
    
    
    
}


#pragma mark – K_CreateSoundViewController_Dimissed_Notification
- (void) createSoundViewControllerDimissed_Notification:(NSNotification *)notification {
    
    if (self.tag != CURRENT_FLASHCARDVIEW_TAG && self.tag != NEW_FLASHCARDVIEW_TAG) {
        return;
    }
    
    if (isFromNewCreatedCard) {
        if (self.tag == CURRENT_FLASHCARDVIEW_TAG) {
            return;
        }
    }

    
    NSDictionary *dict = [notification object];
    BOOL isToRecording = [[dict objectForKey:@"is_to_recording"] boolValue];
    
    if (isToRecording == false) {
        
        if (_recordingBackgroundMaskView.superview) {
            [_recordingBackgroundMaskView removeFromSuperview];
        }
        _recordingBackgroundMaskView = nil;
        
        if ([APP_DELEGATE.recorder isRecording]) {
            [APP_DELEGATE.recorder stop];
        }
        
    } else {
        if ([self isPlayingCard] == false) {
            if (_recordingBackgroundMaskView == nil) {
                
                _recordingBackgroundMaskView = [UIButton buttonWithType:UIButtonTypeCustom];
                _recordingBackgroundMaskView.frame = [UIApplication sharedApplication].keyWindow.rootViewController.view.frame;
                _recordingBackgroundMaskView.backgroundColor = [UIColor clearColor];
                _recordingBackgroundMaskView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
                
                _recordingStopButton = [UIButton buttonWithType:UIButtonTypeCustom];
                if (isUserInterfaceIdiomPhone == FALSE) {
                    _recordingStopButton.frame = CGRectMake(CGRectGetWidth([UIApplication sharedApplication].keyWindow.rootViewController.view.frame)- 80, CGRectGetHeight([UIApplication sharedApplication].keyWindow.rootViewController.view.frame) - 180, 60, 60);
                } else {
                    _recordingStopButton.frame = CGRectMake(CGRectGetWidth([UIApplication sharedApplication].keyWindow.rootViewController.view.frame)- 80, CGRectGetHeight([UIApplication sharedApplication].keyWindow.rootViewController.view.frame) - 80, 60, 60);
                }
                _recordingStopButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
                [_recordingStopButton titleLabel].font = [UIFont systemFontOfSize:16];
                [_recordingStopButton setTitle:NSLocalizedString(@"Title_Record_Stop",@"") forState:UIControlStateNormal];
                _recordingStopButton.layer.cornerRadius = 30;
                _recordingStopButton.layer.masksToBounds = YES;
                _recordingStopButton.backgroundColor = [UIColor redColor];
                [_recordingStopButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [_recordingStopButton addTarget:self action:@selector(recordingStopButtonClicked) forControlEvents:UIControlEventTouchDown];
            
                [_recordingBackgroundMaskView addSubview:_recordingStopButton];
                
                
                _recordingProgressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(CGRectGetMinX(_recordingStopButton.frame)- 4, CGRectGetMinY(_recordingStopButton.frame)- 4, CGRectGetWidth(_recordingStopButton.frame)+ 8, CGRectGetWidth(_recordingStopButton.frame)+ 8)];
                _recordingProgressView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
                _recordingProgressView.roundedCorners = YES;
                _recordingProgressView.thicknessRatio = 0.13;
                _recordingProgressView.trackTintColor = [UIColor orangeColor];
                [_recordingBackgroundMaskView addSubview:_recordingProgressView];
                
                [_recordingBackgroundMaskView bringSubviewToFront:_recordingStopButton];
                
                _recordingBackgroundMaskView.alpha = 0;
                [UIView animateWithDuration:0.6 animations:^{
                    _recordingBackgroundMaskView.alpha = 1;
                }];
            }
            
            if (_recordingBackgroundMaskView.superview) {
                [_recordingBackgroundMaskView removeFromSuperview];
            }
            
            
            
            [[UIApplication sharedApplication].keyWindow.rootViewController.view addSubview:_recordingBackgroundMaskView];
            
            __block int COUNTDOWN_SECOND_FOR_RECORDING = 30;
            __block int COUNTDOWN_SECOND_FOR_PREPARE = 5;
            [_recordingStopButton setTitle:[NSString stringWithFormat:@"%d",COUNTDOWN_SECOND_FOR_PREPARE] forState:UIControlStateNormal];
            
            [_recordCountDownTimer invalidate];
            _recordCountDownTimer = nil;
            
            _recordCountDownTimer = [NSTimer bk_scheduledTimerWithTimeInterval:1 block:^(NSTimer *timer) {
                
                if (COUNTDOWN_SECOND_FOR_PREPARE == 1) {
                    
                    [_recordingStopButton setTitle:@"Stop" forState:UIControlStateNormal];
                    [APP_DELEGATE.recorder record];
                    
                    
                    COUNTDOWN_SECOND_FOR_RECORDING = COUNTDOWN_SECOND_FOR_RECORDING-1;
                    [_recordingProgressView setProgress:(30-COUNTDOWN_SECOND_FOR_RECORDING)/30.0f];
                    if (COUNTDOWN_SECOND_FOR_RECORDING <= 0) {
                        [APP_DELEGATE.recorder stop];
                        [_recordCountDownTimer invalidate];
                        _recordCountDownTimer = nil;
                    }
                } else {
                    
                    COUNTDOWN_SECOND_FOR_PREPARE = COUNTDOWN_SECOND_FOR_PREPARE -1;
                    [_recordingStopButton setTitle:[NSString stringWithFormat:@"%d",COUNTDOWN_SECOND_FOR_PREPARE] forState:UIControlStateNormal];
                }
                
            } repeats:YES];
        }
    }
    
    
    
}

- (void) recordingStopButtonClicked {
    
    [_recordCountDownTimer invalidate];
    _recordCountDownTimer = nil;
    
    APP_DELEGATE.isRecordFinished = YES;
    [self showCreateSoundViewController];
    
    [_recordingBackgroundMaskView removeFromSuperview];
    _recordingBackgroundMaskView = nil;
}


- (void) soundRecordButtonClicked:(id)sender {
    [iConsole info:@"%s",__FUNCTION__];
    
    if ([Common isOwner:_currentPack]) {
        [self showCreateSoundViewController];
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_PLAY_ONLY_SUPPORTED_IN_PLAY",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
    }
    
}

- (void) showCreateSoundViewController {
    CreateSoundViewController *createSoundViewController = [[CreateSoundViewController alloc] initWithNibName:nil bundle:nil];
    createSoundViewController.isOnQuestion = (_segmentedControl.selectedSegmentIndex == 0);
    createSoundViewController.card = _currentCard;
    createSoundViewController.pack = _currentPack;
    
    if (isFromNewCreatedCard) {
        createSoundViewController.isFromNewCreatedCard = YES;
    } else {
        createSoundViewController.isFromNewCreatedCard = NO;
    }
    
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:createSoundViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navController animated:YES];
}


/**
 *  There're two save
 *  1. save from "save button" on keyboard
 *  2. save from "save button",right side of "functioinal panel"
 *  here, refer to 2
 */
- (void) saveButtonClick:(id)sender {
    
    if ([self checkCardEditable] == false) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:NSLocalizedString(@"SAVE_NOT_AVAILABLE_THAT_IS_NOT_YOU",@"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        
        return;
    }
    
    //same logic as navigation bar right "save button" itemm
    if (isFromNewCreatedCard) {
        CreateCardViewController *controller = (CreateCardViewController *)[self firstAvailableUIViewController];
        [controller saveAndCloseCreateCardView];
        return;
        
    }
    
    
    [self saveEdittedCard];
    
    
    
}

- (void) previewButtonClick:(id)sender {
    
    Card *screnshotCard = [self copyCurrentUnsavedCardForPreview];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:[NSNumber numberWithBool:true] forKey:@"preview_only"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLAY_NOTIFICATION object:screnshotCard userInfo:dict];
    
}

- (void) changeTemplateButtonClick:(id)sender {
    [iConsole info:@"%s",__FUNCTION__];
    
    if ([Common isOwner:_currentPack] == FALSE) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_YOU_CAN_NOT_CHANGE_TEMPLATE_BACKGROUND",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
        return;
        
    }
    
    SelectTemplateTableViewController *selectTemplateTableViewController = [[SelectTemplateTableViewController alloc] initWithStyle:UITableViewStylePlain];
    selectTemplateTableViewController.isQuestionShowing = (_segmentedControl.selectedSegmentIndex == 0)?YES:NO;
    
    if (isUserInterfaceIdiomPhone) {
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:selectTemplateTableViewController];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navController animated:YES];
    } else {
        
        _selectTemplatePopoverController = [[UIPopoverController alloc] initWithContentViewController:selectTemplateTableViewController];
        _selectTemplatePopoverController.delegate = self;
        _selectTemplatePopoverController.popoverContentSize = CGSizeMake(250, 95*5);
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            _selectTemplatePopoverController.backgroundColor = [UIColor colorWithRed:63.0/255 green:63.0/255 blue:63.0/255 alpha:0.3];
        }
        [_selectTemplatePopoverController setContentViewController:selectTemplateTableViewController];
        
        CGPoint point = [sender convertPoint:CGPointMake(0, 0) toView:self];
        CGRect rect = CGRectMake(point.x, point.y, 24, 24);
        
        [_selectTemplatePopoverController presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        
    }
}

- (void) dismissSelectTemplatePopoverController {
    [iConsole info:@"%s",__FUNCTION__];
    [_selectTemplatePopoverController dismissPopoverAnimated:YES];
    _selectTemplatePopoverController = nil;
    
}

- (void) templateSelectedNotification: (NSNotification *) notification {
    
    //  We don't want to accept when there's create card action now
    if (((isFromNewCreatedCard == YES) && (self.tag == CURRENT_FLASHCARDVIEW_TAG))
        ||
        ((self.tag != CURRENT_FLASHCARDVIEW_TAG) && (self.tag != NEW_FLASHCARDVIEW_TAG))){
        return;
    }
    
    [self performSelector:@selector(dismissSelectTemplatePopoverController) withObject:nil afterDelay:0.1];
    
    
    NSString *templateIDString = (NSString *)[notification object];
    if (_segmentedControl.selectedSegmentIndex == 0) {
        _currentCard.question.templateID = [templateIDString integerValue];
    } else {
        _currentCard.answer.templateID = [templateIDString integerValue];
    }
    
    [iConsole info:@"%s,tag = %ld,selected templateID = %@",__FUNCTION__,self.tag, templateIDString];
    
    [self updateQuestionOrAnswerTemplate];//we will do other side's update when clicking segment
    
    // we put all the save operations only when click the "save button"
    if (!isFromNewCreatedCard) {
        [self saveEdittedCard];
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    } else {
        [self commitQuestionAndAnswerData];
    }
    
}


- (void) switchToVideoModeAndPlayWithImageSource:(Type_Image_Source) imageSoucrType {
    [iConsole info:@"%s",__FUNCTION__];
    
    MultimediaView *targetMultiMediaView = nil;
    NSURL *targetURL = nil;
    if (imageSoucrType == Type_Image_Source_Image) {
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            targetMultiMediaView = _imageQuestion;
            targetURL = [NSURL fileURLWithPath:_questionMovieFullPath];
        } else {
            targetMultiMediaView = _imageAnswer;
            targetURL = [NSURL fileURLWithPath:_answerMovieFullPath];
        }
    } else if (imageSoucrType == Type_Image_Source_Image2) {
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            targetMultiMediaView = _imageQuestion2;
            targetURL = [NSURL fileURLWithPath:_questionMovieFullPath2];
        } else {
            targetMultiMediaView = _imageAnswer2;
            targetURL = [NSURL fileURLWithPath:_answerMovieFullPath2];
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:@"Error on switchToVideoModeAndPlayWithImageSource" delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    __weak __typeof(&*self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (targetMultiMediaView && targetURL) {
            [targetMultiMediaView setMultimediaType:Video];
            [targetMultiMediaView setVideoURL:targetURL];
        }
    });
    
    
}



/**
 *  Get thumbnail image from an URL
 *
 *  @param url youtube url or local video library
 */
- (void) thumbnailImageFromURL:(NSURL *) url withImageSource:(Type_Image_Source) imageSoucrType {
    [iConsole info:@"%s",__FUNCTION__];
    UIImageView *pickerImageView;
    
    
    if (imageSoucrType == Type_Image_Source_Image) {
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            pickerImageView = _imageQuestion.animtableImageView;
        } else {
            pickerImageView = _imageAnswer.animtableImageView;
        }
    } else if (imageSoucrType == Type_Image_Source_Image2) {
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            pickerImageView = _imageQuestion2.animtableImageView;
        } else {
            pickerImageView = _imageAnswer2.animtableImageView;
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:@"Error on thumbnailImageFromURL" delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    MPMoviePlayerController *theMovie = [[MPMoviePlayerController alloc] initWithContentURL:url];
    theMovie.view.frame = CGRectMake(0, 0, CGRectGetWidth(pickerImageView.frame) * 2, CGRectGetHeight(pickerImageView.frame) * 2);
    theMovie.controlStyle = MPMovieControlStyleNone;
    theMovie.shouldAutoplay=NO;
    UIImage *thumbnail;
    if ([[url absoluteString].lowercaseString rangeOfString:@"http"].location == 0) {
        // it's a http format web video. Considering performance/cost to fetch online content, we skip it.
    } else {
        //it's a local video
        thumbnail = [theMovie thumbnailImageAtTime:0 timeOption:MPMovieTimeOptionExact];
    }
    if (thumbnail == nil) {
        thumbnail = [UIImage imageNamed:@"video_default"];
    }
    
    UIImage *playImage = [UIImage imageNamed:@"play_with_video_link"];
    
    UIGraphicsBeginImageContext(thumbnail.size);
    [thumbnail drawInRect:CGRectMake(0, 0, thumbnail.size.width, thumbnail.size.height)];
    
    [playImage drawInRect:CGRectMake(thumbnail.size.width *0.42, thumbnail.size.height *0.4, thumbnail.size.width *0.16, thumbnail.size.width *0.2)];
    
    UIImage *compositeThumbNail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (imageSoucrType == Type_Image_Source_Image) {
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if ([Common isPlaceholderFilePathOrDirectory:_questionImageFullPath]) {
                _questionImageFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            }
            [UIImagePNGRepresentation(compositeThumbNail) writeToFile:_questionImageFullPath atomically:YES];
            _imageQuestion.animtableImageView.image = compositeThumbNail;
        } else {
            if ([Common isPlaceholderFilePathOrDirectory:_answerImageFullPath]) {
                _answerImageFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            }
            [UIImagePNGRepresentation(compositeThumbNail) writeToFile:_answerImageFullPath atomically:YES];
            _imageAnswer.animtableImageView.image = compositeThumbNail;
        }
    } else if (imageSoucrType == Type_Image_Source_Image2) {
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if ([Common isPlaceholderFilePathOrDirectory:_questionImageFullPath2]) {
                _questionImageFullPath2 = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            }
            [UIImagePNGRepresentation(compositeThumbNail) writeToFile:_questionImageFullPath2 atomically:YES];
            _imageQuestion2.animtableImageView.image = compositeThumbNail;
        } else {
            if ([Common isPlaceholderFilePathOrDirectory:_answerImageFullPath2]) {
                _answerImageFullPath2 = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
            }
            [UIImagePNGRepresentation(compositeThumbNail) writeToFile:_answerImageFullPath2 atomically:YES];
            _imageAnswer2.animtableImageView.image = compositeThumbNail;
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:@"Error on thumbnailImageFromURL2" delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
    }
    
}

#pragma mark – UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [iConsole info:@"%s",__FUNCTION__];
    [popoverController dismissPopoverAnimated:YES];
    popoverController = nil;
    
}


#pragma mark -
#pragma mark - Re-screenshot all cards under current pack
- (void) reSceenshotAll: (RescreenshotReason) why withStringVal: (NSString *) val{
    [iConsole info:@"%s",__FUNCTION__];
    float flashCardYPositionInScrollView;
    FlashCard *tempCardView;
    if (isUserInterfaceIdiomPhone) {
        flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPhone)/2; //Since it's horizontal movement, so this is a constant value
        tempCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone) defaultPack:_currentPack defaultCard:_currentCard];
        
    } else {
        flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPad)/2; //Since it's horizontal movement, so this is a constant value
        tempCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad) defaultPack:_currentPack defaultCard:_currentCard];
        
    }
    
    if (why == kReasonSidebarTitleChangeEnum) {
        _currentPack.sidebarTitle = val;
        [_currentPack save];
    } else if (why == kReasonCreatorTitleChaneEnum) {
        _currentPack.creatorNickName = val;
        [_currentPack save];
    } else if (why == kReasonJobTitleChaneEnum) {
        _currentPack.jobTitle = val;
        [_currentPack save];
    } else if (why == kReasonTemplateBackgroundChangeEnum) {
        _templateBackgroundImageName = val;
    }
    
    for (Card *card in [_currentPack cards]) {
        
        @autoreleasepool {
            if (why == kReasonTemplateBackgroundChangeEnum) {
                card.templateBackgroundName = val;
            } else if (why == kReasonLogoImageChangeEnum) {
                card.question.logoFullPath = val;
            } else if (why == kReasonQuestionTitleChangeEnum) {
                card.question.title = val;
            } else if (why == kReasonAnswerTitleChangeEnum) {
                card.answer.title = val;
            }
            
            tempCardView.currentCard = card;
            tempCardView.segmentedControl.selectedSegmentIndex = 0;
            [tempCardView refreshAll];
            
            UIImage *origialmage = [tempCardView captureWholeViewAsImage];
            NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
            if ([Common isPlaceholderFilePathOrDirectory:card.coverImageURL]) {
                NSString *savedFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
                [imageData writeToFile:savedFullPath atomically:YES];
                card.coverImageURL = savedFullPath;
            } else {
                [imageData writeToFile:card.coverImageURL atomically:YES];
            }
            
            [card save];
        }
    }
    
    tempCardView = nil;
}

#pragma mark -
#pragma mark - EmoticonSelectionViewControllerDelegate
- (void) emoticonSelectionViewController:(EmoticonSelectionViewController *)emoticonSelectionViewController didSelectEmoticon:(Emoticon *)emoticon {
    [iConsole info:@"%s",__FUNCTION__];
    
    long  location =_lastBecomeFirstRespondTextView.selectedRange.location;
    NSString *beforeStr = @"";
    NSString *afterStr = @"";
    
    beforeStr = [_lastBecomeFirstRespondTextView.text substringToIndex:location];
    afterStr = [_lastBecomeFirstRespondTextView.text substringFromIndex:location];
    
    NSString *newValue;
    if (_lastBecomeFirstRespondTextView.text == NULL) {
        _lastBecomeFirstRespondTextView.text = @"";
    }
    
    if ([emoticon.code.lowercaseString isEqualToString:K_Delete.lowercaseString]) {
        
        if (beforeStr.length >= 1) {
            beforeStr = [beforeStr substringToIndex:beforeStr.length-1];
        }
        
        newValue = [NSString stringWithFormat:@"%@%@",beforeStr,afterStr];
        
        _lastBecomeFirstRespondTextView.text = newValue;
        
        NSRange range = _lastBecomeFirstRespondTextView.selectedRange;
        range.location = beforeStr.length;
        [_lastBecomeFirstRespondTextView setSelectedRange:range];
        
    } else {
        NSString *insertVal;
        if ([emoticon.code.lowercaseString isEqualToString:K_Space_Bar.lowercaseString]) {
            insertVal = @" ";
        } else if ([emoticon.code.lowercaseString isEqualToString:K_Line_Break.lowercaseString]) {
            insertVal = @"\r";
        }else {
            insertVal = emoticon.code;
        }
        
        newValue = [NSString stringWithFormat:@"%@%@%@",beforeStr,insertVal,afterStr];
        
        _lastBecomeFirstRespondTextView.text = newValue;
        
        long symbolLength = insertVal.length;
        NSRange range = _lastBecomeFirstRespondTextView.selectedRange;
        range.location = location + symbolLength;
        [_lastBecomeFirstRespondTextView setSelectedRange:range];
    }
    
    
}

#pragma mark – AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [iConsole info:@"%s",__FUNCTION__];
    player = nil;
}

#pragma mark – UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [iConsole info:@"%s",__FUNCTION__];
    switch (alertView.tag) {
        case Type_AlertView_LogoURL:
            if (buttonIndex ==1) {
                NSString *temp = [alertView textFieldAtIndex:0].text;
                
                if (![temp isEqualToString:_logoLinkURL]) {
                    _logoLinkURL = temp;
                    _currentCard.question.logoURLLinkage = temp;
                    
                    [self updatelogoURLForAllCards:temp];
                    
                }
            }
            break;
        case Type_AlertView_VideoURL:
            if (buttonIndex ==0) {
                NSString *youtbueLinkage = [alertView textFieldAtIndex:0].text;
                if (![Common isValidYoutubeLinkage:youtbueLinkage]) {
                    [iConsole info:@"%s:unvalid url adress",__FUNCTION__];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:NSLocalizedString(@"DIALOG_INVALID_YOUTUBE_URL",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                    [alertView show];
                } else {
                    
                    [self thumbnailImageFromURL:[NSURL URLWithString:[Common embeddedYoutubeURL:youtbueLinkage]] withImageSource:Type_Image_Source_Image];
                    
                    if (self.segmentedControl.selectedSegmentIndex == 0) {
                        _questionMovieFullPath = youtbueLinkage;
                        
                    } else {
                        _answerMovieFullPath = youtbueLinkage;
                    }
                    
                    if (self.tag == NEW_FLASHCARDVIEW_TAG) {
                        //we will save until after we press the save button
                        if (_segmentedControl.selectedSegmentIndex == 0) {
                            _currentCard.question.imageFullPath = _questionImageFullPath;
                            _currentCard.question.movieFullPath = _questionMovieFullPath;
                        } else {
                            _currentCard.answer.imageFullPath = _answerImageFullPath;
                            _currentCard.answer.movieFullPath = _answerMovieFullPath;
                        }
                    } else {
                        [self saveEdittedCard];
                    }
                }
                
                
                
            }
            break;
        case Type_AlertView_VideoURL2:
            if (buttonIndex ==0) {
                NSString *youtbueLinkage = [alertView textFieldAtIndex:0].text;
                if (![Common isValidYoutubeLinkage:youtbueLinkage]) {
                    [iConsole info:@"%s:unvalid url adress",__FUNCTION__];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:NSLocalizedString(@"DIALOG_INVALID_YOUTUBE_URL",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                    [alertView show];
                } else {
                    
                    [self thumbnailImageFromURL:[NSURL URLWithString:[Common embeddedYoutubeURL:youtbueLinkage]] withImageSource:Type_Image_Source_Image2];
                    
                    if (self.segmentedControl.selectedSegmentIndex == 0) {
                        _questionMovieFullPath2 = youtbueLinkage;
                        
                    } else {
                        _answerMovieFullPath2 = youtbueLinkage;
                    }
                    
                    if (self.tag == NEW_FLASHCARDVIEW_TAG) {
                        //we will save until after we press the save button
                        if (_segmentedControl.selectedSegmentIndex == 0) {
                            _currentCard.question.imageFullPath2 = _questionImageFullPath2;
                            _currentCard.question.movieFullPath2 = _questionMovieFullPath2;
                        } else {
                            _currentCard.answer.imageFullPath2 = _answerImageFullPath2;
                            _currentCard.answer.movieFullPath2 = _answerMovieFullPath2;
                        }
                    } else {
                        [self saveEdittedCard];
                    }
                }
                
                
                
            }
            break;
        case Type_AlertView_BackgroundImage_Crop_Size:
            if (buttonIndex == 0) {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES  forKey:@"K_Not_Show_Saved_Background_Image_Size_Dialog"];
                [defaults synchronize];
            }
            break;
        default:
            break;
    }
    
    APP_DELEGATE.isAllowToShowPackList = YES;
}


#pragma mark – Undo

/**
 *  We put undo info in NSUserDefaults rather than DB
 */
- (NSDictionary *) getUndoDictForCardBackgroundImage:(NSInteger) packId withCardId :(NSInteger) cardID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *array = [defaults objectForKey:@"K_Undo_Dictionary"];
    if (array) {
        
        for (NSDictionary *cardDict in array) {
            if (([[cardDict objectForKey:@"packId"] integerValue] == packId) &&
                ([[cardDict objectForKey:@"cardId"] integerValue] == cardID)){
                return cardDict;
            }
        }
        
        return nil;
        
        
        
    } else {
        return  nil;
    }
    
    
}


/**
 *  We put undo info in NSUserDefaults rather than DB
 */
- (void) setUndoForCardBackgroundImage:(NSMutableDictionary *) cardDict {
    
    NSNumber *packId = [cardDict objectForKey:@"packId"];
    NSAssert(packId, @"dict needs to include packId");
    
    NSNumber *cardId = [cardDict objectForKey:@"cardId"];
    NSAssert(cardId, @"dict needs to include cardId");
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *array = [defaults objectForKey:@"K_Undo_Dictionary"];
    NSMutableArray *mutableArray;
    if (array) {
        mutableArray = [NSMutableArray arrayWithArray:array];
    } else {
        mutableArray = [NSMutableArray array];
    }
    
    
    for (NSDictionary *cardDict in mutableArray) {
        if (([[cardDict objectForKey:@"packId"] integerValue] == [packId integerValue]) &&
            ([[cardDict objectForKey:@"cardId"] integerValue] == [cardId integerValue])){
            [mutableArray removeObject:cardDict];
            break;
        }
    }
    
    [mutableArray addObject:cardDict];
    
    [defaults setObject:mutableArray forKey:@"K_Undo_Dictionary"];
    
    [defaults synchronize];
    
    
    
    
    
    
    
    
}



#pragma mark – Hittest

/**
 *  适用于iphone且playmode下。
 *  在playmode下，playsoundbutton和mutebutton由于在Flashcard的frame外面，导致它们无法接收touch事件，所以需要重写hitTest
 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (isUserInterfaceIdiomPhone && _isPlayingCard) {
        if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
            for (UIView *subview in self.subviews.reverseObjectEnumerator) {
                CGPoint subPoint = [subview convertPoint:point fromView:self];
                UIView *result = [subview hitTest:subPoint withEvent:event];
                if (result != nil) {
                    return result;
                }
            }
        }
        
        return nil;
    } else {
        return [super hitTest:point withEvent:event];
    }
}


#pragma mark – Text-To-Speech function

- (void) setupTextToSpeech {
    
    
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"7.0")) {
        [iConsole info:@"%s,we don't support <iOS7",__FUNCTION__];
        return ;
    }
    
    if (_synth == nil) {
        
        self.synth = [[AVSpeechSynthesizer alloc] init];
        self.synth.delegate = self;
        
    }
}

- (BOOL) isTextToSpeeching {
    if ([_synth isSpeaking]) {
        return YES;
    } else {
        return NO;
    }
}

- (void) stopTextToSpeechNow {
    if ([_synth isSpeaking]) {
        [_synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    _textToSpeechArray = nil;
}

- (void) textToSpeechAllContentNow {
    
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"7.0")) {
        [iConsole info:@"%s,we don't support <iOS7",__FUNCTION__];
        return ;
    }
    
    
    if ([_synth isSpeaking]) {
        [self.synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    
    [iConsole info:@"%s",__FUNCTION__];
    _textToSpeechArray = [self textToSpeechContentArray];
    if ([_textToSpeechArray count] > 0) {
        
        NSDictionary *dict = _textToSpeechArray[0];
        NSString *content = [[dict allValues] firstObject];
        
        AVSpeechUtterance *utterance = [AVSpeechUtterance
                                        speechUtteranceWithString:content];
        utterance.rate = (AVSpeechUtteranceMinimumSpeechRate + AVSpeechUtteranceDefaultSpeechRate)*0.75;
        
        NSString *targetLanguage = @"";
        if ([dict objectForKey:@"subheadingQuestion"]){
            targetLanguage = _currentCard.question.css.subheadingText2SpeechSound;
        } else if ([dict objectForKey:@"mainQuestion"]){
            targetLanguage = _currentCard.question.css.mainText2SpeechSound;
        } else if ([dict objectForKey:@"subQuestion"]){
            targetLanguage = _currentCard.question.css.subText2SpeechSound;
        } else if ([dict objectForKey:@"subheadingAnswer"]){
            targetLanguage = _currentCard.answer.css.subheadingText2SpeechSound;
        } else if ([dict objectForKey:@"mainAnswer"]){
            targetLanguage = _currentCard.answer.css.mainText2SpeechSound;
        } else if ([dict objectForKey:@"subAnswer"]){
            targetLanguage = _currentCard.answer.css.subText2SpeechSound;
        }
        if (targetLanguage.length == 0) {
            targetLanguage = [Text2SpeechHelper getSelectedText2SpeechLanguageFromSetting];
        }

        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:targetLanguage];
        
        if (self.isMuteText2Speech) {
            [utterance setVolume:0];
        } else {
            [utterance setVolume:1];
        }
        
        self.textToSpeechContentArrayIndex = 0;
        [self.synth speakUtterance:utterance];
    } else {
        //[self playAudio]; //play audio after textspeech finished
    }
    
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    [iConsole info:@"%s",__FUNCTION__];
    self.textToSpeechContentArrayIndex ++;
    
    if ([_textToSpeechArray count] > self.textToSpeechContentArrayIndex) {
        
        NSDictionary *dict = _textToSpeechArray[self.textToSpeechContentArrayIndex];
        NSString *content = [[dict allValues] firstObject];
        
        AVSpeechUtterance *utterance = [AVSpeechUtterance
                                        speechUtteranceWithString:content];
        
        NSString *targetLanguage = @"";
        if ([dict objectForKey:@"subheadingQuestion"]){
            targetLanguage = _currentCard.question.css.subheadingText2SpeechSound;
        } else if ([dict objectForKey:@"mainQuestion"]){
            targetLanguage = _currentCard.question.css.mainText2SpeechSound;
        } else if ([dict objectForKey:@"subQuestion"]){
            targetLanguage = _currentCard.question.css.subText2SpeechSound;
        } else if ([dict objectForKey:@"subheadingAnswer"]){
            targetLanguage = _currentCard.answer.css.subheadingText2SpeechSound;
        } else if ([dict objectForKey:@"mainAnswer"]){
            targetLanguage = _currentCard.answer.css.mainText2SpeechSound;
        } else if ([dict objectForKey:@"subAnswer"]){
            targetLanguage = _currentCard.answer.css.subText2SpeechSound;
        }
        if (targetLanguage.length == 0) {
            targetLanguage = [Text2SpeechHelper getSelectedText2SpeechLanguageFromSetting];
        }
        
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:targetLanguage];
        
        utterance.rate = (AVSpeechUtteranceMinimumSpeechRate + AVSpeechUtteranceDefaultSpeechRate)*0.75;
        
        if (self.isMuteText2Speech) {
            [utterance setVolume:0];
        } else {
            [utterance setVolume:1];
        }
        
        //utterance.postUtteranceDelay = 0.3;
        
        
        if ([_textToSpeechArray count] > 0) {
            [self.synth speakUtterance:utterance];
        } else {
            [self.synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        }
        
    } else {
        if ([_textToSpeechArray count] > 0) {
            //all text-to-speechs are done
            if (self.calledViewController) {
                SEL selector = @selector(text2SpeechFinished:);
                if ([self.calledViewController respondsToSelector:selector]) {
                    BOOL isQuestionShowing = (_segmentedControl.selectedSegmentIndex == 0)?YES:NO;
                    [self.calledViewController performSelector:selector withObject:[NSNumber numberWithBool:isQuestionShowing]];
                } else {
                    [iConsole info:@"%s: can not repsonss to select text2SpeechFinished ",__FUNCTION__];
                }
                
            }
        }
    }
    
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    [iConsole info:@"%s",__FUNCTION__];
}


- (NSMutableArray *) textToSpeechContentArray  {
    NSMutableArray *myArray = [NSMutableArray array];
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        if ((_subheadingQuestion.text.length >0) && (_subheadingQuestion.hidden == NO)) {
            
            for (NSString *item in [self replaceBasicSymbol:_subheadingQuestion.text]) {
                [myArray addObject:[NSDictionary dictionaryWithObject:item forKey:@"subheadingQuestion"]];
            }
        }
        
        if ((_mainQuestion.text.length >0)&& (_mainQuestion.hidden == NO)) {
            
            for (NSString *item in [self replaceBasicSymbol:_mainQuestion.text]) {
                [myArray addObject:[NSDictionary dictionaryWithObject:item forKey:@"mainQuestion"]];
            }
        }
        
        if ((_subQuestion.text.length >0)&& (_subQuestion.hidden == NO)) {
            
            for (NSString *item in [self replaceBasicSymbol:_subQuestion.text]) {
                [myArray addObject:[NSDictionary dictionaryWithObject:item forKey:@"subQuestion"]];
            }
        }
    } else {
        if ((_subheadingAnswer.text.length >0)&& (_subheadingAnswer.hidden == NO)) {
            
            for (NSString *item in [self replaceBasicSymbol:_subheadingAnswer.text]) {
                [myArray addObject:[NSDictionary dictionaryWithObject:item forKey:@"subheadingAnswer"]];
            }
        }
        
        if ((_mainAnswer.text.length >0)&& (_mainAnswer.hidden == NO)) {
            
            for (NSString *item in [self replaceBasicSymbol:_mainAnswer.text]) {
                [myArray addObject:[NSDictionary dictionaryWithObject:item forKey:@"mainAnswer"]];
            }
        }
        
        if ((_subAnswer.text.length >0)&& (_subAnswer.hidden == NO)) {
            
            for (NSString *item in [self replaceBasicSymbol:_subAnswer.text]) {
                [myArray addObject:[NSDictionary dictionaryWithObject:item forKey:@"subAnswer"]];
            }
        }
    }
    
    if ([myArray count] == 0) {
        [myArray addObject:@"   "]; //需要有个默认的，否则在auto delay play时，如果当前卡片没有内容，则就无法回调到下一张卡片了
    }
    
    return myArray;
}

- (NSArray *) replaceBasicSymbol:(NSString *) str {
    NSString *resultStr;
    
    NSString *plusStr = @" Plus ";
    NSString *timesStr = @" Times ";
    NSString *dividedByStr = @" divided by ";
    NSString *minusStr = @" minus ";
    
    NSString *equalsStr = @" equals ";
    NSString *cubicMetresStr = @"  Cubic Metres ";
    NSString *squareMetresStr = @" Square Metres ";
    NSString *squareFeetStr = @" Square feet ";
    
    NSString *cubicFeetStr = @"  Cubic Feet ";
    NSString *squareInchesStr = @" Square Inches ";
    NSString *cubicInchesStr = @" Cubic Inches ";
    NSString *cubicCentimetresStr = @" Cubic Centi metres ";
    
    NSString *squareCentimetresStr = @" Square Centi metres ";
    NSString *cubicMillimetresStr = @" Cubic Milli metres ";
    NSString *squareMillimetresStr = @" Square milli metres ";
    NSString *degreesCelsiusStr = @" Degrees Celsius ";
    
    NSString *degreesFahrenheitStr = @"  Degrees Fahrenheit ";
    NSString *degreesRankinStr = @" Degrees Rankin ";
    NSString *degresssKelvinStr = @" Degrees Kelvin ";
    NSString *carbonDioxideStr = @" Carbon Dioxide ";
    
    NSString *nitrogenStr = @" Nitrogen ";
    NSString *oxygenStr = @" Oxygen ";
    NSString *pieStr = @" Pie ";
    NSString *squareRdiusStr = @" square radius ";
    
    NSString *OzoneStr = @"  Ozone ";
    NSString *perStr = @" per ";
    NSString *millibarStr = @" milli bar equals ";
    NSString *percentStr = @" percent ";
    
    NSString *radiusStr = @"  Radius equals ";
    NSString *diameterStr = @" Diameter equals ";
    NSString *greaterThenStr = @" Greater then ";
    NSString *lessThenStr = @" Less then ";
    
    NSString *squareRootStr = @" square root ";
    
    
    resultStr = [str stringByReplacingOccurrencesOfString:@"+" withString:plusStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"⨯" withString:timesStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"÷" withString:dividedByStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"−" withString:minusStr];
    
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"cm²" withString:squareCentimetresStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"mm³" withString:cubicMillimetresStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"mm²" withString:squareMillimetresStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"cm³" withString:cubicCentimetresStr];
    
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"m³" withString:cubicMetresStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"m²" withString:squareMetresStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"ft²" withString:squareFeetStr];
    
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"ft³" withString:cubicFeetStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"in²" withString:squareInchesStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"in³" withString:cubicInchesStr];
    
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"°C" withString:degreesCelsiusStr];
    
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"°F" withString:degreesFahrenheitStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"°R" withString:degreesRankinStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"°K" withString:degresssKelvinStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"CO₂" withString:carbonDioxideStr];
    
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"N₂" withString:nitrogenStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"O₂" withString:oxygenStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"π" withString:pieStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"r²" withString:squareRdiusStr];
    
    
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"O₃" withString:OzoneStr];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"∕" withString:perStr]; //unicode
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"/" withString:perStr]; //not unicode
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"mb=" withString:millibarStr]; ////// mb = millibar
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"mb =" withString:millibarStr]; ////// mb = millibar
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"%" withString:percentStr]; ///// not unicode
    
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"r=" withString:radiusStr]; //////// r
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"r =" withString:radiusStr]; //////// r
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"d=" withString:diameterStr]; /////// d
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"d =" withString:diameterStr]; /////// d
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@">" withString:greaterThenStr]; //// not unicode
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"<" withString:lessThenStr];///// not unicode
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"√" withString:squareRootStr];
    
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@" = " withString:equalsStr]; ////// , not unicode, need to be put last
    
    
    
    NSArray *returnArray = [resultStr componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    return returnArray;
    
}

#pragma mark – Vertical Alignment special logic

/**
 *  更新InputView中的Alignment中Veritcal barbutton item的状态（颜色）
 */
- (void) updateVerticalAlignmentBarButtonStatus {
    
    NSArray *targetButtonArray;
    if (_lastBecomeFirstRespondTextView.inputView == nil) {
        targetButtonArray = [_keyboardTopViewV2 getCurrentButtonArray];
    } else {
        targetButtonArray = [_keyboardTopViewForInputViewV2 getCurrentButtonArray];
    }
    
    
    if ([self isVerticalAlignment:_lastBecomeFirstRespondTextView]) {
        
        [[targetButtonArray lastObject] setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
        
    } else {
        
        [[targetButtonArray lastObject] setBackgroundImage:nil forState:UIControlStateNormal];
        
    }
}




- (void) updateSizeButtonsStatus:(id) sender {
    if (_lastBecomeFirstRespondTextView) {
        
        NSArray *targetButtonArray;
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            targetButtonArray = [_keyboardTopViewV2 getCurrentButtonArray];
        } else {
            targetButtonArray = [_keyboardTopViewForInputViewV2 getCurrentButtonArray];
        }
        
        NSInteger size = -1;
        if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingQuestion){
            size = _subheadingSizeQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagMainQuestion) {
            size = _mainSizeQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubQuestion) {
            size = _subSizeQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingAnswer) {
            size = _subheadingSizeAnswer;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagMainAnswer) {
            size = _mainSizeAnswer;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubAnswer) {
            size = _subSizeAnswer;
        } else {
            //
        }
        
        int nominalFontSize = [_keyboardTopViewV2 getNominalSizeFromRealSize:size]; //这里_keyboardTopViewV2和_keyboardTopViewForInputViewV2 其实是一样的
        int contentOffsetIndex = 0;
        for (int i = 0;i < [targetButtonArray count];i++) {
            UIButton *button = targetButtonArray[i];
            if ([button.titleLabel.text integerValue]  == nominalFontSize) {
                [button setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
                contentOffsetIndex = i;
            } else {
                [button setBackgroundImage:nil forState:UIControlStateNormal];
            }
            
        }
        
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            [_keyboardTopViewV2 scrollToButtonIndex:contentOffsetIndex];
        } else {
            [_keyboardTopViewForInputViewV2 scrollToButtonIndex:contentOffsetIndex];
        }
        
    }
}

- (void) updateColorButtonsStatus:(id)sender {
    
    if (_lastBecomeFirstRespondTextView) {
        
        NSArray *targetButtonArray;
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            targetButtonArray = [_keyboardTopViewV2 getCurrentButtonArray];
        } else {
            targetButtonArray = [_keyboardTopViewForInputViewV2 getCurrentButtonArray];
        }
        
        NSString *color;
        if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingQuestion){
            color = _subheadingColorQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagMainQuestion) {
            color = _mainColorQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubQuestion) {
            color = _subColorQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingAnswer) {
            color = _subheadingColorAnswer;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagMainAnswer) {
            color = _mainColorAnswer;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubAnswer) {
            color = _subColorAnswer;
        }
        
        BOOL isDefault = YES;
        
        int contentOffsetIndex = 0;
        for (int i = 0;i < [targetButtonArray count];i++) {
            UIButton *button = targetButtonArray[i];
            if ([button.titleLabel.text isEqualToString:color]) {
                [button setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
                contentOffsetIndex = i;
                isDefault= NO;
            } else {
                [button setBackgroundImage:nil forState:UIControlStateNormal];
            }
            
            contentOffsetIndex ++;
            
        }
        
        if (isDefault) {
            //第一个是back，所以需要index = 1开始
            [targetButtonArray[1] setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
        }
        
        
        //semi-transparent logic update
        //需要放在最后面
        BOOL isSemiTransparent = false;
        {
            if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingQuestion){
                isSemiTransparent = _subheadingQuestion.alpha == 0.5;
            } else if (_lastBecomeFirstRespondTextView.tag == kTagMainQuestion) {
                isSemiTransparent = _mainQuestion.alpha == 0.5;
            } else if (_lastBecomeFirstRespondTextView.tag == kTagSubQuestion) {
                isSemiTransparent = _subQuestion.alpha == 0.5;
            } else if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingAnswer) {
                isSemiTransparent = _subheadingAnswer.alpha == 0.5;
            } else if (_lastBecomeFirstRespondTextView.tag == kTagMainAnswer) {
                isSemiTransparent = _mainAnswer.alpha == 0.5;
            } else if (_lastBecomeFirstRespondTextView.tag == kTagSubAnswer) {
                isSemiTransparent = _subAnswer.alpha == 0.5;
            }
            
            if (isSemiTransparent) {
                [[targetButtonArray lastObject] setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
            }
            
            
        }
        
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            [_keyboardTopViewV2 scrollToButtonIndex:contentOffsetIndex];
        } else {
            [_keyboardTopViewForInputViewV2 scrollToButtonIndex:contentOffsetIndex];
        }
        
    }
    
}

- (void) updateFontButtonsStatus:(id) sender {
    if (_lastBecomeFirstRespondTextView) {
        
        NSArray *targetButtonArray;
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            targetButtonArray = [_keyboardTopViewV2 getCurrentButtonArray];
        } else {
            targetButtonArray = [_keyboardTopViewForInputViewV2 getCurrentButtonArray];
        }
        
        NSString *fontFamilyName;
        if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingQuestion){
            fontFamilyName = _subheadingFontQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagMainQuestion) {
            fontFamilyName = _mainFontQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubQuestion) {
            fontFamilyName = _subFontQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingAnswer) {
            fontFamilyName = _subheadingFontAnswer;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagMainAnswer) {
            fontFamilyName = _mainFontAnswer;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubAnswer) {
            fontFamilyName = _subFontAnswer;
        }
        
        if ([fontFamilyName isEqualToString:@"Futura-Medium"]) {
            fontFamilyName = @"Futura";
        } else if ([fontFamilyName isEqualToString:@"ChalkboardSE-Bold"]) {
            fontFamilyName = @"Chalkboard";
        }
        
        BOOL isDefault = YES;
        
        int contentOffsetIndex = 0;
        for (int i = 0;i < [targetButtonArray count];i++) {
            UIButton *button = targetButtonArray[i];
            if ([button.titleLabel.text isEqualToString:fontFamilyName]) {
                [button setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
                contentOffsetIndex = i;
                isDefault= NO;
            } else {
                [button setBackgroundImage:nil forState:UIControlStateNormal];
            }
            
            
        }
        
        if (isDefault) {
            //第一个是back，所以需要index = 1开始
            [targetButtonArray[0] setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
        }
        
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            [_keyboardTopViewV2 scrollToButtonIndex:contentOffsetIndex];
        } else {
            [_keyboardTopViewForInputViewV2 scrollToButtonIndex:contentOffsetIndex];
        }
        
    }
}

/**
 *  更新InputView中的Alignment中所有barbutton的状态,包括left, right, center,justify和veritcal
 
 */
- (void) updateAlignButtonsStatus:(id) sender {
    if (_lastBecomeFirstRespondTextView) {
        
        //step1: vertical alignment
        [self updateVerticalAlignmentBarButtonStatus];
        
        //step2: left, right, center, justify alignment
        NSArray *targetButtonArray;
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            targetButtonArray = [_keyboardTopViewV2 getCurrentButtonArray];
        } else {
            targetButtonArray = [_keyboardTopViewForInputViewV2 getCurrentButtonArray];
        }
        
        int contentOffsetIndex = 0;
        switch (_lastBecomeFirstRespondTextView.textAlignment) {
            case NSTextAlignmentLeft:
                contentOffsetIndex = 0;  //从1开始，因为第一个是backbutton
                [targetButtonArray[0] setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
                break;
            case NSTextAlignmentCenter:
                contentOffsetIndex = 1;
                [targetButtonArray[1] setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
                break;
            case NSTextAlignmentRight:
                contentOffsetIndex = 2;
                [targetButtonArray[2] setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
                break;
            case NSTextAlignmentJustified:
                contentOffsetIndex = 3;
                [targetButtonArray[3] setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
        
        for (int i =0; i<[targetButtonArray count] - 1; i++) {  //不包含最后一个Vertical，也不包含第一个backbutton
            if (i != contentOffsetIndex) {
                [targetButtonArray[i] setBackgroundImage:nil forState:UIControlStateNormal];
            }
        }
        
        
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            [_keyboardTopViewV2 scrollToButtonIndex:contentOffsetIndex];
        } else {
            [_keyboardTopViewForInputViewV2 scrollToButtonIndex:contentOffsetIndex];
        }
        
        
    }
    
    
    
}
    
- (void) updateText2SpeechButtonsStatus:(id) sender {
    if (_lastBecomeFirstRespondTextView) {
        
        NSArray *targetButtonArray;
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            targetButtonArray = [_keyboardTopViewV2 getCurrentButtonArray];
        } else {
            targetButtonArray = [_keyboardTopViewForInputViewV2 getCurrentButtonArray];
        }
        
        NSString *language;
        if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingQuestion){
            language = _subheadingText2SpeechQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagMainQuestion) {
            language = _mainText2SpeechQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubQuestion) {
            language = _subText2SpeechQuestion;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubheadingAnswer) {
            language = _subheadingText2SpeechAnswer;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagMainAnswer) {
            language = _mainText2SpeechAnswer;
        } else if (_lastBecomeFirstRespondTextView.tag == kTagSubAnswer) {
            language = _subText2SpeechAnswer;
        }
        
        if (language.length == 0) {
            language = [Text2SpeechHelper getDefaultText2SpeechVoiceLanguage];
        }
        
        NSString *text2SpeechDescriptionForDisplay = [Text2SpeechHelper getText2SpeechDescriptionForDisplayFromVoiceLanguage:language];
        
        BOOL isDefault = YES;
        
        int contentOffsetIndex = 0;
        for (int i = 0;i < [targetButtonArray count];i++) {
            UIButton *button = targetButtonArray[i];
            if ([button.titleLabel.text isEqualToString:text2SpeechDescriptionForDisplay]) {
                [button setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
                contentOffsetIndex = i;
                isDefault= NO;
            } else {
                [button setBackgroundImage:nil forState:UIControlStateNormal];
            }
            
            
        }
        
        if (isDefault) {
            //第一个是back，所以需要index = 1开始
            [targetButtonArray[0] setBackgroundImage:[UIImage imageNamed:@"circle_selected_button"] forState:UIControlStateNormal];
        }
        
        if (_lastBecomeFirstRespondTextView.inputView == nil) {
            [_keyboardTopViewV2 scrollToText2SpeechButtonIndex:contentOffsetIndex];
        } else {
            [_keyboardTopViewForInputViewV2 scrollToText2SpeechButtonIndex:contentOffsetIndex];
        }
        
    }
}

/**
 *  当选择了“vertical alignment”会执行这个
 */
- (void) setVerticalAlignment:(UITextView *) textView {
    
    if (textView == nil) {
        return;
    }
    
    CGSize textSize = [textView sizeThatFits:textView.frame.size];
    
    CGFloat topCorrect = ([textView bounds].size.height - textSize.height)/2.0;
    topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
    textView.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
    
    self.contentYOffsetForVerticalAlignment = textView.contentOffset.y;
    
    if (textView.tag == kTagSubheadingQuestion) {
        _subheadingAlignVerticalQuestion = @"Vertical";
    } else if (textView.tag == kTagMainQuestion) {
        _mainAlignVerticalQuestion = @"Vertical";
    } else if (textView.tag == kTagSubQuestion) {
        _subAlignVerticalQuestion = @"Vertical";
    } else if (textView.tag == kTagSubheadingAnswer) {
        _subheadingAlignVerticalAnswer = @"Vertical";
    } else if (textView.tag == kTagMainAnswer) {
        _mainAlignVerticalAnswer = @"Vertical";
    } else if (textView.tag == kTagSubAnswer) {
        _subAlignVerticalAnswer = @"Vertical";
    }
    
}

/**
 *  做两件事
 *  1. contentOff归零
 *  2. 赋值给_subheadingAlignVerticalAnswer， etc
 */
- (void) resetVerticalAlignment:(UITextView *) textView {
    
    if (textView == nil) {
        return;
    }
    
    
    textView.contentOffset = (CGPoint){.x = 0, .y = 0};
    
    if (textView.tag == kTagSubheadingQuestion) {
        _subheadingAlignVerticalQuestion = @"";
    } else if (textView.tag == kTagMainQuestion) {
        _mainAlignVerticalQuestion = @"";
    } else if (textView.tag == kTagSubQuestion) {
        _subAlignVerticalQuestion = @"";
    } else if (textView.tag == kTagSubheadingAnswer) {
        _subheadingAlignVerticalAnswer = @"";
    } else if (textView.tag == kTagMainAnswer) {
        _mainAlignVerticalAnswer = @"";
    } else if (textView.tag == kTagSubAnswer) {
        _subAlignVerticalAnswer = @"";
    }
    
}
 
/**
 *  KVO
 *  仅适用于[self isVerticalAlignment:tv] ＝ YES
 *  当内容改变时，自动进行vertical alignment调整
 */
-(void)observeValueForKeyPath:(NSString *)keyPath   ofObject:(id)object   change:(NSDictionary *)change   context:(void *)context
{
    if ([@"contentSize" isEqualToString:keyPath]) {
        
        UITextView *tv = object;
        
        if ([self isVerticalAlignment:tv]) {
            CGFloat topCorrect = ([tv bounds].size.height - [tv contentSize].height * [tv zoomScale])  / 2.0;
            topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
            tv.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
        }
        
    }
    
}


/**
 *  我们不能使用hidden属性，因为triggerResizeTextToFitFrame的中间过程中会局部hidden
 */
- (void) hideAllSemiTransparentTextViews {
    
    /*
     * Clear text color is used UNIQUELY in the app to specify those "semi texts" that should be hidden
     * since we can not use the hidden propery, which could make touch out of response
     * Never use clear color for text color everywhere else
    */
    
    if (self.currentCard.question.css.subheadingSemiTransparent || (_subheadingQuestion.alpha == 0.5)) {
        _subheadingQuestion.textColor = [UIColor clearColor];
    }
    
    if (self.currentCard.question.css.mainSemiTransparent || (_mainQuestion.alpha == 0.5)) {
        _mainQuestion.textColor = [UIColor clearColor];
    }
    
    if (self.currentCard.question.css.subSemiTransparent || (_subQuestion.alpha == 0.5)) {
        _subQuestion.textColor = [UIColor clearColor];
    }
    
    if (self.currentCard.answer.css.subheadingSemiTransparent || (_subheadingAnswer.alpha == 0.5)) {
        _subheadingAnswer.textColor = [UIColor clearColor];
    }
    
    if (self.currentCard.answer.css.mainSemiTransparent || (_mainAnswer.alpha == 0.5)) {
        _mainAnswer.textColor = [UIColor clearColor];
    }
    
    if (self.currentCard.answer.css.subSemiTransparent || (_subAnswer.alpha == 0.5)) {
        _subAnswer.textColor = [UIColor clearColor];
    }
    
    
}

/**
 *  注意，由于alignment跟内容相关，所以必须等到内容填充好后才允许执行
 */
- (void) updateQuestionAnswerAllTextViewVeriticalAlignment {
    
    //question part
    CSS *css= _currentCard.question.css;
    if ([css.subheadingAlignVertical isEqualToString:@"Vertical"]) {
        _subheadingAlignVerticalQuestion = @"Vertical";
        [self setVerticalAlignment:_subheadingQuestion];
    } else {
        _subheadingAlignVerticalQuestion = @"";
        [self resetVerticalAlignment:_subheadingQuestion];
    }
    
    
    if ([css.mainAlignVertical isEqualToString:@"Vertical"]) {
        [self setVerticalAlignment:_mainQuestion];
        _mainAlignVerticalQuestion = @"Vertical";
    } else {
        [self resetVerticalAlignment:_mainQuestion];
        _mainAlignVerticalQuestion = @"";
    }
    
    
    if ([css.subAlignVertical isEqualToString:@"Vertical"]) {
        [self setVerticalAlignment:_subQuestion];
        _subAlignVerticalQuestion = @"Vertical";
    } else {
        [self resetVerticalAlignment:_subQuestion];
        _subAlignVerticalQuestion = @"";
    }
    
    //answer part
    css= _currentCard.answer.css;
    
    if ([css.subheadingAlignVertical isEqualToString:@"Vertical"]) {
        [self setVerticalAlignment:_subheadingAnswer];
        _subheadingAlignVerticalAnswer = @"Vertical";
    } else {
        [self resetVerticalAlignment:_subheadingAnswer];
        _subheadingAlignVerticalAnswer = @"";
    }
    
    
    if ([css.mainAlignVertical isEqualToString:@"Vertical"]) {
        [self setVerticalAlignment:_mainAnswer];
        _mainAlignVerticalAnswer = @"Vertical";
    } else {
        [self resetVerticalAlignment:_mainAnswer];
        _mainAlignVerticalAnswer = @"";
    }
    
    
    if ([css.subAlignVertical isEqualToString:@"Vertical"]) {
        [self setVerticalAlignment:_subAnswer];
        _subAlignVerticalAnswer = @"Vertical";
    } else {
        [self resetVerticalAlignment:_subAnswer];
        _subAlignVerticalAnswer = @"";
    }
}

#pragma mark – KeyboardTopViewDelegate

- (void)keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedFontChangeButton:(id) sender {
    
    [self changeFontTypeBarButtonItemClicked:sender];
    [self updateFontButtonsStatus:sender];
    
    
}

- (void)keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedSizeChangeButton:(id) sender {
    [self changeFontSizeBarButtonItemClicked:sender];
    [self updateSizeButtonsStatus:sender];
    
}

- (void)keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedAlignChangeButton:(id) sender {
    [self changeAlignBarButtonItemClicked:sender];
    [self updateAlignButtonsStatus:sender];
    
}

- (void)keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedColorChangeButton:(id) sender {
    [self changeColorBarButtonItemClicked:sender];
    [self updateColorButtonsStatus:sender];
    
}
    
- (void)keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedText2SpeechChangeButton:(id) sender {
    [self changeText2SpeechBarButtonItemClicked:sender];
    [self updateText2SpeechButtonsStatus:sender];
    
}

- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedSaveButton:(id)sender {
    _isDismissKeyboardViaSaveButtonFromKeyboard = true;
    [self dismissKeyBoard:sender withSaveComing:true];
}


- (void)keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedMainButton:(id)sender {
    
    NSString *title = [(UIButton *)sender titleLabel].text;
    
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align",@"")]) {
        [self updateAlignButtonsStatus:sender];
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size",@"")]) {
        [self updateSizeButtonsStatus:sender];
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color",@"")]) {
        [self updateColorButtonsStatus:sender];
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Font",@"")]) {
        [self updateFontButtonsStatus:sender];
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Language",@"")]) {
        [self updateText2SpeechButtonsStatus:sender];
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Symbol",@"")] || [title isEqualToString:NSLocalizedString(@"ToolbarItem_Keyboard",@"")]){
        [self symbolAndKeyboardSwitch:sender];
    } else {
        //do nothing
    }
    
}

#pragma mark - PECropViewControllerDelegate methods

/*
 * Only question/card background  image will be cropped and call this delegate.
 */
- (void)cropViewController:(PECropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage
{
    float downScaleWidth = CGRectGetWidth(_questionBackgroundImageView.frame);
    float downScaleHeight = CGRectGetHeight(_questionBackgroundImageView.frame);
    
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    
    
    NSData *imageData = UIImageJPEGRepresentation([croppedImage scaleToSize:CGSizeMake(downScaleWidth *screenScale, downScaleHeight * screenScale)], kJPEGQualityFactor);
    
    [controller dismissViewControllerAnimated:YES completion:NULL];
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        if ([Common isPlaceholderFilePathOrDirectory:_questionBackgroundImageFullPath]) {
            //虽然最终保存的是JPG格式，但是我们统一以PNG作为后缀（整个Pack的所有图片资源的后缀都是PNG格式的）
            _questionBackgroundImageFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
        } else {
            //当之前已经有图片时，我们才操作
            //step1: 拷贝一份更改前的图片到undoCardBackGroundImageForQuestionPath
            NSError *error;
            NSString *undoCardBackGroundImageForQuestionPath = [FileOperationHelper undoCardBackGroundImageForQuestionPath];
            [[NSFileManager defaultManager] removeItemAtPath:undoCardBackGroundImageForQuestionPath error:nil];
            [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:_questionBackgroundImageFullPath] toURL:[NSURL fileURLWithPath:undoCardBackGroundImageForQuestionPath] error:&error];
            
            //step1: 写入文件，并置K_Is_Allow_Undo_Question_Background_Image，允许下次undo
            if (error) {
                [iConsole error:@"%s:Error when copyItem.%@",__FUNCTION__,[error description]];
            } else {
                
                NSDictionary *cardDict = [self getUndoDictForCardBackgroundImage:_currentPack.packID withCardId:_currentCard.cardID];
                NSMutableDictionary *cardMutableDict;
                if (cardDict) {
                    cardMutableDict = [NSMutableDictionary dictionaryWithDictionary:cardDict];
                } else {
                    cardMutableDict = [NSMutableDictionary dictionary];
                }
                [cardMutableDict setObject:[NSNumber numberWithInteger:_currentPack.packID] forKey:@"packId"];
                [cardMutableDict setObject:[NSNumber numberWithInteger:_currentCard.cardID] forKey:@"cardId"];
                
                [cardMutableDict setObject:undoCardBackGroundImageForQuestionPath forKey:@"K_Undo_Question_Background_Image_URL"];
                [cardMutableDict setObject:[NSNumber numberWithBool:YES] forKey:@"K_Is_Allow_Undo_Question_Background_Image"];
                [self setUndoForCardBackgroundImage:cardMutableDict];
                
                
                
                
            }
            
            
            
        }
        
        [imageData writeToFile:_questionBackgroundImageFullPath atomically:YES];
        _questionBackgroundImageView.image = [UIImage imageWithData:imageData];
    } else {
        if ([Common isPlaceholderFilePathOrDirectory:_answerBackgroundImageFullPath]) {
            //虽然最终保存的是JPG格式，但是我们统一以PNG作为后缀（整个Pack的所有图片资源的后缀都是PNG格式的）
            _answerBackgroundImageFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
        }else {
            
            NSError *error;
            NSString *undoCardBackGroundImageForAnswerPath = [FileOperationHelper undoCardBackGroundImageForAnswerPath];
            [[NSFileManager defaultManager] removeItemAtPath:undoCardBackGroundImageForAnswerPath error:nil];
            [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:_answerBackgroundImageFullPath] toURL:[NSURL fileURLWithPath:undoCardBackGroundImageForAnswerPath] error:&error];
            
            if (error) {
                [iConsole error:@"%s:Error when copyItem.%@",__FUNCTION__,[error description]];
            } else {
                
                NSDictionary *cardDict = [self getUndoDictForCardBackgroundImage:_currentPack.packID withCardId:_currentCard.cardID];
                NSMutableDictionary *cardMutableDict;
                if (cardDict) {
                    cardMutableDict = [NSMutableDictionary dictionaryWithDictionary:cardDict];
                } else {
                    cardMutableDict = [NSMutableDictionary dictionary];
                }
                [cardMutableDict setObject:[NSNumber numberWithInteger:_currentPack.packID] forKey:@"packId"];
                [cardMutableDict setObject:[NSNumber numberWithInteger:_currentCard.cardID] forKey:@"cardId"];
                
                [cardMutableDict setObject:undoCardBackGroundImageForAnswerPath forKey:@"K_Undo_Answer_Background_Image_URL"];
                [cardMutableDict setObject:[NSNumber numberWithBool:YES] forKey:@"K_Is_Allow_Undo_Answer_Background_Image"];
                [self setUndoForCardBackgroundImage:cardMutableDict];
            }
        }
        
        
        [imageData writeToFile:_answerBackgroundImageFullPath atomically:YES];
        _answerBackgroundImageView.image = [UIImage imageWithData:imageData];
    }
    
    if (self.tag == NEW_FLASHCARDVIEW_TAG) {
        //we will save until after we press the save button
        if (_segmentedControl.selectedSegmentIndex == 0) {
            _currentCard.question.backgroundImageFullPath = _questionBackgroundImageFullPath;
        } else {
            _currentCard.answer.backgroundImageFullPath = _answerBackgroundImageFullPath;
        }
    } else {
        [self saveEdittedCard];
    }
    
}

- (void)cropViewControllerDidCancel:(PECropViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:NULL];
}


- (void)openEditor:(UIImage *)origialmage
{
    PECropViewController *controller = [[PECropViewController alloc] init];
    controller.view.frame = [UIApplication sharedApplication].keyWindow.bounds;
    controller.delegate = self;
    controller.image = origialmage;
    
    //    UIImage *image = self.imageView.image;
    //    CGFloat width = image.size.width;
    //    CGFloat height = image.size.height;
    //    CGFloat length = MIN(width, height);
    //    controller.imageCropRect = CGRectMake((width - length) / 2,
    //                                          (height - length) / 2,
    //                                          length,
    //                                          length);
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:navigationController animated:YES completion:NULL];
}


#pragma mark – utilities

- (BOOL) isGif:(NSString *) path {
    if (path == nil || path.length == 0) {
        return false;
    }
    
    if ([path.lastPathComponent.lowercaseString containsString:@".gif"]) {
        return true;
    } else {
        return false;
    }
}

/*
 *  we already have converted to .3gp for any video format
 */
- (BOOL) isLocalVideo:(NSString *) path {
    if (path == nil || path.length == 0) {
        return false;
    }
    
    if ([path.lastPathComponent.lowercaseString containsString:@".3gp"]) {
        return true;
    } else {
        return false;
    }
}


#pragma mark -
#pragma mark - Memory management

- (void)dealloc {
    [iConsole info:@"%s,tag = %ld,question main = %@",__FUNCTION__,(long)self.tag,_mainQuestion.text];
    
    _synth = nil;
    
    [_recordCountDownTimer invalidate];
    _recordCountDownTimer = nil;
    
    _synth.delegate = nil;
    _questionTitle.delegate = nil;
    _answerTitle.delegate  = nil;
    _subheadingQuestion.delegate  = nil;
    _mainQuestion.delegate  = nil;
    _subQuestion.delegate  = nil;
    _subheadingAnswer.delegate  = nil;
    _mainAnswer.delegate  = nil;
    _subAnswer.delegate  = nil;
    _sidebarTitle.delegate  = nil;
    _creatorText.delegate  = nil;
    _jobTitleText.delegate  = nil;
    _emoticonSelectionViewController.delegate = nil;
    _imagePickerController.delegate = nil;
    _imagePickerPopover.delegate = nil;
    _selectTemplatePopoverController.delegate= nil;
    
    [_subheadingQuestion removeObserver:self forKeyPath:@"contentSize"];
    [_subheadingAnswer removeObserver:self forKeyPath:@"contentSize"];
    [_mainQuestion removeObserver:self forKeyPath:@"contentSize"];
    [_mainAnswer removeObserver:self forKeyPath:@"contentSize"];
    [_subQuestion removeObserver:self forKeyPath:@"contentSize"];
    [_subAnswer removeObserver:self forKeyPath:@"contentSize"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _imagePickerController = nil;
    _imagePickerPopover = nil;
    _selectTemplatePopoverController = nil;
    
    _audioPlayer = nil;
    
    
    
    
    [iConsole info:@"%s",__FUNCTION__];
}

#pragma mark – Tooltips

- (void) showTooltips {
    
    if ([MutipleTargetHelper isFullVersion] == false) {
        return;
    }
    
    if (self.tag != CURRENT_FLASHCARDVIEW_TAG) {
        return;
    }
    
    if (_isPlayingCard) {
        return;  //not allow to show tooltip
    }
    
    //1.
    CGRect rectLogo = [_logoImage  convertRect:CGRectMake(CGRectGetWidth(_logoImage.frame)/2, CGRectGetHeight(_logoImage.frame), 0, 0) toView:self];
    if (isUserInterfaceIdiomPhone == FALSE) {
        rectLogo = CGRectOffset(rectLogo, -38, -20);
    }
    [[TipHelper defaultHelper] showTipForLogoInView:self fromFrame:rectLogo];
    
    //2
    if (_imageQuestion.hidden == FALSE) {
        CGRect rectImage = [_imageQuestion  convertRect:CGRectMake(CGRectGetWidth(_imageQuestion.frame)/2, CGRectGetHeight(_imageQuestion.frame)/2, 0, 0) toView:self];
        [[TipHelper defaultHelper] showTipForImageInView:self fromFrame:rectImage];
    }
    
    //3
    CGRect rectTemplateButton = [_changeTemplateButton  convertRect:CGRectMake(CGRectGetWidth(_changeTemplateButton.frame)/2,0, 0, 0) toView:self];
    [[TipHelper defaultHelper] showTipForToolbarBottomRightChangeTemplateInView:self fromFrame:rectTemplateButton];
    
    CGRect rectBackgroundButton = [_backgroundImageSelectButton  convertRect:CGRectMake(CGRectGetWidth(_backgroundImageSelectButton.frame)/2,0, 0, 0) toView:self];
    [[TipHelper defaultHelper] showTipForToolbarBottomRightChangeBackgroundInView:self fromFrame:rectBackgroundButton];
    
    CGRect rectRecordButton = [_soundButton  convertRect:CGRectMake(CGRectGetWidth(_soundButton.frame)/2,0, 0, 0) toView:self];
    [[TipHelper defaultHelper] showTipForToolbarBottomRightRecordSoundInView:self fromFrame:rectRecordButton];
    
    
    //4
    CGRect recLinkButton = [_logoLinkageButton  convertRect:CGRectMake(CGRectGetWidth(_logoLinkageButton.frame)/3, CGRectGetHeight(_logoLinkageButton.frame)/4 + 5, 0, 0) toView:self];
    [[TipHelper defaultHelper] showTipForLinkButtonInView:self fromFrame:recLinkButton];
    
    
    //6
    CGRect rectSegmentQuestion = [_segmentedControl  convertRect:CGRectMake(CGRectGetWidth(_segmentedControl.frame)/4, 0, 0, 0) toView:self];
    [[TipHelper defaultHelper] showTipForSegmentQuestionInView:self fromFrame:rectSegmentQuestion];
    CGRect rectSegmentAnswer = [_segmentedControl  convertRect:CGRectMake(CGRectGetWidth(_segmentedControl.frame)/4*3, 0, 0, 0) toView:self];
    [[TipHelper defaultHelper] showTipForSegmentAnswerInView:self fromFrame:rectSegmentAnswer];
}


- (void) showTooltipNotification:(NSNotification *) notification {
    [self showTooltips];
}

- (BOOL) isQuestionShowing {
    if (_segmentedControl.selectedSegmentIndex == 0) {
        return YES;
    } else {
        return NO;
    }
}



- (float) durationForQuestionRecordedSound {
    
    NSString *audioFilePath = _currentCard.question.recordedSoundFullPath;;
    
    if (audioFilePath.length  == 0) {
        return 0;
    }
    
    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:audioFilePath] options:nil];
    NSArray *keys = [NSArray arrayWithObjects:@"duration", nil];
    __block bool loading = YES;
    [audioAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^(void) {
        loading = NO;
    }];
    
    while (loading) {
        usleep(10000);
    }
    
    
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    return audioDurationSeconds;
}

- (float) durationForAnswerRecordedSound {
    
    NSString *audioFilePath = _currentCard.answer.recordedSoundFullPath;
    
    if (audioFilePath.length  == 0) {
        return 0;
    }
    
    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:audioFilePath] options:nil];
    NSArray *keys = [NSArray arrayWithObjects:@"duration", nil];
    __block bool loading = YES;
    [audioAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^(void) {
        loading = NO;
    }];
    
    while (loading) {
        usleep(10000);
    }
    
    
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    return audioDurationSeconds;
}


- (void) imageSelectAlertViewClickedAtIndex:(NSInteger) buttonIndex {
    
    //index = 0 insert youtube
    //index = 1 select from library
    //index = 2 remove
    
    
    if (buttonIndex == 2) {
        [self selectImageOrVideoFromLibraryWithImageType:Type_PopoverView_SelectImage];
    } else if (buttonIndex == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_INSERT_YOUTUBE_URL",@"")
                                                        message:nil
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                              otherButtonTitles:NSLocalizedString(@"Keyboard_Cancel",@""), nil];
        alert.tag = Type_AlertView_VideoURL;
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alert textFieldAtIndex:0].text = @"";
        [alert textFieldAtIndex:0].placeholder = @"http://www.youtube.com/";
        alert.delegate = self;
        [alert show];
        
        APP_DELEGATE.isAllowToShowPackList = YES;
        
    } else if (buttonIndex == 3) {
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            
            if (([_questionImageFullPath rangeOfString:@"placeholder"].location == NSNotFound) &&
                (_questionImageFullPath.length > 0)) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_questionImageFullPath
                                                                error:&error])
                {
                    NSLog(@"[Error] %@ (%@)", error, _questionImageFullPath);
                }
                
                
            }
            
            if (([_questionMovieFullPath rangeOfString:@"placeholder"].location == NSNotFound) &&
                (_questionMovieFullPath.length > 0)) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_questionMovieFullPath
                                                                error:&error])
                {
                    NSLog(@"[Error] %@ (%@)", error, _questionMovieFullPath);
                }
                
            }
            
            _questionImageFullPath = @"";
            _questionMovieFullPath = @"";
            
            _currentCard.question.movieFullPath = @"";
            _currentCard.question.imageFullPath = @"";
            
            [_imageQuestion setMultimediaType:ImageView];
            [_imageQuestion.animtableImageView setImage:[UIImage imageNamed:@"question_placeholder_content"]];
            
            
        } else {
            
            if (([_answerImageFullPath rangeOfString:@"placeholder"].location == NSNotFound) &&
                (_answerImageFullPath.length > 0)) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_answerImageFullPath
                                                                error:&error])
                {
                    NSLog(@"[Error] %@ (%@)", error, _answerImageFullPath);
                }
            }
            
            if (([_answerMovieFullPath rangeOfString:@"placeholder"].location == NSNotFound) &&
                (_answerMovieFullPath.length > 0)) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_answerMovieFullPath
                                                                error:&error])
                {
                    NSLog(@"[Error] %@ (%@)", error, _answerMovieFullPath);
                }
            }
            
            _answerImageFullPath = @"";
            _answerMovieFullPath = @"";
            
            _currentCard.answer.movieFullPath = @"";
            _currentCard.answer.imageFullPath = @"";
            [_imageAnswer setMultimediaType:ImageView];
            [_imageAnswer.animtableImageView setImage:[UIImage imageNamed:@"answer_placeholder_content"]];
        }
        if (isFromNewCreatedCard == FALSE) {
            [self saveEdittedCard];
        }
    }
    
    
    
}


- (void) image2SelectAlertViewClickedAtIndex:(NSInteger) buttonIndex {
    if (buttonIndex == 2) {
        [self selectImageOrVideoFromLibraryWithImageType:Type_Image_Source_Image2];
    } else if (buttonIndex == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_INSERT_YOUTUBE_URL",@"")
                                                        message:nil
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                              otherButtonTitles:NSLocalizedString(@"Keyboard_Cancel",@""), nil];
        alert.tag = Type_AlertView_VideoURL2;
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alert textFieldAtIndex:0].text = @"";
        [alert textFieldAtIndex:0].placeholder = @"http://www.youtube.com/";
        alert.delegate = self;
        [alert show];
    } else if (buttonIndex == 3) {
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            
            if (([_questionImageFullPath2 rangeOfString:@"placeholder"].location == NSNotFound) &&
                (_questionImageFullPath2.length > 0)) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_questionImageFullPath2
                                                                error:&error])
                {
                    NSLog(@"[Error] %@ (%@)", error, _questionImageFullPath2);
                }
            }
            
            if (([_questionMovieFullPath2 rangeOfString:@"placeholder"].location == NSNotFound) &&
                (_questionMovieFullPath2.length > 0)) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_questionMovieFullPath2
                                                                error:&error])
                {
                    NSLog(@"[Error] %@ (%@)", error, _questionMovieFullPath2);
                }
            }
            
            _questionImageFullPath2 = @"";
            _questionMovieFullPath2 = @"";
            
            _currentCard.question.movieFullPath2 = @"";
            _currentCard.question.imageFullPath2 = @"";
            
            [_imageQuestion2 setMultimediaType:ImageView];
            [_imageQuestion2.animtableImageView setImage:[UIImage imageNamed:@"question_placeholder_content"]];
        } else {
            
            if (([_answerImageFullPath2 rangeOfString:@"placeholder"].location == NSNotFound) &&
                (_answerImageFullPath2.length > 0)) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_answerImageFullPath2
                                                                error:&error])
                {
                    NSLog(@"[Error] %@ (%@)", error, _answerImageFullPath2);
                }
            }
            
            if (([_answerMovieFullPath2 rangeOfString:@"placeholder"].location == NSNotFound) &&
                (_answerMovieFullPath2.length > 0)) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:_answerMovieFullPath2
                                                                error:&error])
                {
                    NSLog(@"[Error] %@ (%@)", error, _answerMovieFullPath2);
                }
            }
            
            _answerImageFullPath2 = @"";
            _answerMovieFullPath2 = @"";
            
            _currentCard.answer.movieFullPath2 = @"";
            _currentCard.answer.imageFullPath2 = @"";
            
            [_imageAnswer2 setMultimediaType:ImageView];
            [_imageAnswer2.animtableImageView setImage:[UIImage imageNamed:@"answer_placeholder_content"]];
        }
        if (isFromNewCreatedCard == FALSE) {
            [self saveEdittedCard];
        }
    }
}


- (void) backgroundImageSelectAlertViewClickedAtIndex:(NSInteger) buttonIndex {
    //change card background
    
    if (buttonIndex == 1) {
        
        if (_segmentedControl.selectedSegmentIndex == 0) {
            _questionBackgroundImageFullPath = @"";
            [_questionBackgroundImageView setImage:nil];
        } else {
            _answerBackgroundImageFullPath = @"";
            [_answerBackgroundImageView setImage:nil];
        }
        
        if (self.tag == NEW_FLASHCARDVIEW_TAG) {
            //we will save until after we press the save button
            if (_segmentedControl.selectedSegmentIndex == 0) {
                _currentCard.question.backgroundImageFullPath = _questionBackgroundImageFullPath;
            } else {
                _currentCard.answer.backgroundImageFullPath = _answerBackgroundImageFullPath;
            }
        } else {
            [self saveEdittedCard];
        }
        
        
        
    } else if (buttonIndex == 2) {
        _imageSourceType = Type_Image_Source_Background;
        [self selectFromImageLibrary:_backgroundImageSelectButton withPopoverArrowUp:NO  supportMov:NO];
    } else if (buttonIndex == 3) {
        
        NSString * undoFullPath;
        if (_segmentedControl.selectedSegmentIndex == 0) {
            
            //step1: 填充 _questionBackgroundImageView
            NSDictionary *cardDict = [self getUndoDictForCardBackgroundImage:_currentPack.packID withCardId:_currentCard.cardID];
            undoFullPath = [cardDict objectForKey:@"K_Undo_Question_Background_Image_URL"];
            [_questionBackgroundImageView setImage:[UIImage imageWithContentsOfFile:undoFullPath]];
            
            //step2: 把undoFullPath内容拷贝到_questionBackgroundImageFullPath
            if (undoFullPath.length >0) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:_questionBackgroundImageFullPath error:nil];
                [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:undoFullPath] toURL:[NSURL fileURLWithPath:_questionBackgroundImageFullPath] error:&error];
                if (error) {
                    [iConsole error:@"%s:Error when copyItem.%@",__FUNCTION__,[error description]];
                }
            }
            
            
            //step3: 我们不支持多级的undo，所以需要重置
            NSMutableDictionary *cardMutableDict;
            cardMutableDict = [NSMutableDictionary dictionaryWithDictionary:cardDict];
            
            [cardMutableDict setObject:[NSNumber numberWithInteger:_currentPack.packID] forKey:@"packId"];
            [cardMutableDict setObject:[NSNumber numberWithInteger:_currentCard.cardID] forKey:@"cardId"];
            [cardMutableDict setObject:[NSNumber numberWithBool:NO] forKey:@"K_Is_Allow_Undo_Question_Background_Image"];
            [self setUndoForCardBackgroundImage:cardMutableDict];
            
            
        } else {
            
            NSDictionary *cardDict = [self getUndoDictForCardBackgroundImage:_currentPack.packID withCardId:_currentCard.cardID];
            undoFullPath = [cardDict objectForKey:@"K_Undo_Answer_Background_Image_URL"];
            [_answerBackgroundImageView setImage:[UIImage imageWithContentsOfFile:undoFullPath]];
            
            if (undoFullPath.length >0) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:_answerBackgroundImageFullPath error:nil];
                [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:undoFullPath] toURL:[NSURL fileURLWithPath:_answerBackgroundImageFullPath] error:&error];
                if (error) {
                    [iConsole error:@"%s:Error when copyItem.%@",__FUNCTION__,[error description]];
                }
            }
            
            
            //我们不支持多级的undo，所以需要重置
            NSMutableDictionary *cardMutableDict;
            cardMutableDict = [NSMutableDictionary dictionaryWithDictionary:cardDict];
            
            [cardMutableDict setObject:[NSNumber numberWithInteger:_currentPack.packID] forKey:@"packId"];
            [cardMutableDict setObject:[NSNumber numberWithInteger:_currentCard.cardID] forKey:@"cardId"];
            [cardMutableDict setObject:[NSNumber numberWithBool:NO] forKey:@"K_Is_Allow_Undo_Question_Background_Image"];
            [self setUndoForCardBackgroundImage:cardMutableDict];
            
        }
        
        //step4: 保存
        if (self.tag == NEW_FLASHCARDVIEW_TAG) {
            //we will save until after we press the save button
            if (_segmentedControl.selectedSegmentIndex == 0) {
                
                _currentCard.question.backgroundImageFullPath = _questionBackgroundImageFullPath;
            } else {
                _currentCard.answer.backgroundImageFullPath = _answerBackgroundImageFullPath;
            }
        } else {
            [self saveEdittedCard];
        }
        
    }
}


@end
