//
//  FlashCard.m
//  FlashCardCreator
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

#import "CreateSoundViewController.h"

#import "OpenUDID.h"

#import "KeyboardTopView.h"

#import "PECropViewController.h"

#import "AMPopTip.h"

#import "TipHelper.h"

#import "iConsole.h"

#import "UIButton+Extensions.h"

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

#define KEYBOARD_ANIMATION_DURATION 0.25


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
        
        [self initDefaultValue];
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            [self setupTextToSpeech];
        }
        
        //Vertical alignment，在具体的KVO中，如果alignment是vertical，则
        [_subheadingQuestion addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
        [_mainQuestion addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
        [_subQuestion addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
        [_subheadingAnswer addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
        [_mainAnswer addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
        [_subAnswer addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    }
    
    
    return self;
}


- (void) initDefaultValue {
    [iConsole info:@"%s",__FUNCTION__];
    _isUITextViewFocused = NO;
    
    _isAllCardsLogoNeedToBeUpdate = NO;
    _isTextFieldsChanged = NO;
    _saveButtonPressed = NO;
    _templateBackgroundImageName = @"card_background_blue.png";
    _logoLinkURL = @"http://www.";
    _logoImageFullPath = @"";
    
    _subheadingSizeQuestion = 40;
    _subheadingColorQuestion = @"Black";
    _subheadingAlignQuestion = @"Right";
    _subheadingAlignVerticalQuestion = @"";
    _mainSizeQuestion = 40;
    _mainColorQuestion = @"Black";
    _mainAlignQuestion = @"Center";
    _mainAlignVerticalQuestion = @"";
    _subSizeQuestion = 40;
    _subColorQuestion = @"Black";
    _subAlignQuestion = @"Center";
    _subAlignVerticalQuestion = @"";
    
    _subheadingSizeAnswer = 40;
    _subheadingColorAnswer = @"Black";
    _subheadingAlignAnswer = @"Right";
    _subheadingAlignVerticalAnswer = @"";
    _mainSizeAnswer = 40;
    _mainColorAnswer = @"Black";
    _mainAlignAnswer = @"Center";
    _mainAlignVerticalAnswer = @"";
    _subSizeAnswer = 40;
    _subColorAnswer = @"Black";
    _subAlignAnswer = @"Center";
    _subAlignVerticalAnswer = @"";
    
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
        _questionTitle.frame = CGRectMake(80, 60, 400, 52);
        _questionTitle.backgroundColor = [UIColor clearColor];
        _questionTitle.font =[UIFont systemFontOfSize:40];
        _questionTitle.textAlignment = NSTextAlignmentLeft;
        _questionTitle.text =NSLocalizedString(@"ToolbarItem_Question",nil);
        _questionTitle.userInteractionEnabled = FALSE;
        _questionTitle.layer.shadowColor = [[UIColor whiteColor] CGColor];
        _questionTitle.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _questionTitle.layer.shadowOpacity = 1.0f;
        _questionTitle.layer.shadowRadius = 3.5f;
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
        _answerTitle.frame = CGRectMake(80, 60, 400, 52);
        _answerTitle.backgroundColor = [UIColor clearColor];
        _answerTitle.font =[UIFont systemFontOfSize:40];
        _answerTitle.textAlignment = NSTextAlignmentLeft;
        _answerTitle.text =NSLocalizedString(@"ToolbarItem_Question",nil);
        _answerTitle.userInteractionEnabled = FALSE;
        _answerTitle.layer.shadowColor = [[UIColor whiteColor] CGColor];
        _answerTitle.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _answerTitle.layer.shadowOpacity = 1.0f;
        _answerTitle.layer.shadowRadius = 3.5f;
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
        _imageQuestion= [[UIImageView  alloc] init];
        _imageQuestion.userInteractionEnabled = FALSE;
        _imageQuestion.contentMode = UIViewContentModeScaleAspectFit;
        _imageQuestion.clipsToBounds = YES;
        _imageQuestion.backgroundColor = [UIColor clearColor];
        _imageQuestion.layer.cornerRadius = 15;
        _imageQuestion.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageQuestion];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
        [_imageQuestion addGestureRecognizer:imageSingeTap];
    }
    
    if (_imageQuestion2 == nil) {
        _imageQuestion2= [[UIImageView  alloc] init];
        _imageQuestion2.userInteractionEnabled = FALSE;
        _imageQuestion2.contentMode = UIViewContentModeScaleAspectFit;
        _imageQuestion2.clipsToBounds = YES;
        _imageQuestion2.backgroundColor = [UIColor clearColor];
        _imageQuestion2.layer.cornerRadius = 15;
        _imageQuestion2.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageQuestion2];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped2:)];
        [_imageQuestion2 addGestureRecognizer:imageSingeTap];
    }
    
    if (_subheadingQuestion == nil) {
        _subheadingQuestion = [[UITextView alloc]init];
        _subheadingQuestion.tag = kTagSubheadingQuestion;
        
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
        [_verticalScrollView addSubview:_subheadingQuestion];
    }
    
    if (_mainQuestion == nil) {
        _mainQuestion = [[UITextView alloc]init];
        _mainQuestion.tag = kTagMainQuestion;
        
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
        [_verticalScrollView addSubview:_mainQuestion];
    }
    
    
    if (_subQuestion == nil) {
        _subQuestion = [[UITextView alloc]init];
        _subQuestion.tag = kTagSubQuestion;
        
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
        [_verticalScrollView addSubview:_subQuestion];
    }
    
    if (_imageAnswer == nil) {
        _imageAnswer= [[UIImageView  alloc] init];
        _imageAnswer.userInteractionEnabled = FALSE;
        _imageAnswer.contentMode = UIViewContentModeScaleAspectFit;
        _imageAnswer.clipsToBounds = YES;
        _imageAnswer.backgroundColor = [UIColor clearColor];
        _imageAnswer.layer.cornerRadius = 15;
        _imageAnswer.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageAnswer];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
        [_imageAnswer addGestureRecognizer:imageSingeTap];
    }
    
    if (_imageAnswer2 == nil) {
        _imageAnswer2= [[UIImageView  alloc] init];
        _imageAnswer2.userInteractionEnabled = FALSE;
        _imageAnswer2.contentMode = UIViewContentModeScaleAspectFit;
        _imageAnswer2.clipsToBounds = YES;
        _imageAnswer2.backgroundColor = [UIColor clearColor];
        _imageAnswer2.layer.cornerRadius = 15;
        _imageAnswer2.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageAnswer2];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped2:)];
        [_imageAnswer2 addGestureRecognizer:imageSingeTap];
    }
    
    _imageAnswer.hidden = YES;
    _imageAnswer2.hidden = YES;
    
    if (_subheadingAnswer == nil) {
        _subheadingAnswer = [[UITextView alloc]init];
        _subheadingAnswer.tag = kTagSubheadingAnswer;
        
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
        [_verticalScrollView addSubview:_subheadingAnswer];
    }
    _subheadingAnswer.hidden = TRUE;
    
    if (_mainAnswer == nil) {
        _mainAnswer = [[UITextView alloc]init];
        _mainAnswer.tag = kTagMainAnswer;
        
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
        [_verticalScrollView addSubview:_mainAnswer];
    }
    _mainAnswer.hidden = TRUE;
    
    
    if (_subAnswer == nil) {
        _subAnswer = [[UITextView alloc]init];
        _subAnswer.tag = kTagSubAnswer;
        
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
        [_verticalScrollView addSubview:_subAnswer];
    }
    _subAnswer.hidden = TRUE;
    
    if (_sidebarTitle == nil) {
        _sidebarTitle = [[UITextField alloc] init];
        _sidebarTitle.frame = CGRectMake(0, 0, 400, 60);
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
        [self addSubview:_sidebarTitle];
    }
    
    
    if (_cardSNText == nil) {
        CGPoint point = CGPointMake(30, kQuestionViewTopMarginForiPad+25);
        if (self.isPlayingCard) {
            point.x = (point.x) * kFlashCardViewProporation_iPhone;
            point.y = (point.y) * kFlashCardViewProporation_iPhone;
        }
        _cardSNText = [[JSBadgeView alloc] initWithParentView:self offset:point];
        
    }
    
    if (_segmentedControl == nil) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                             @[NSLocalizedString(@"ToolbarItem_Question",nil),
                               NSLocalizedString(@"ToolbarItem_Answer",nil)]];
        
        
        CGRect frame = CGRectMake(kSegmentLeftMarginForiPad,
                                  self.bounds.size.height-kSegmentHeightForiPad-kSegmentButtomMarginForiPad,
                                  500,
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
        CAShapeLayer *styleLayer = [CAShapeLayer layer];
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:_logoImage.bounds byRoundingCorners:(UIRectCornerBottomRight|UIRectCornerBottomLeft|UIRectCornerTopRight|UIRectCornerTopLeft) cornerRadii:CGSizeMake(25, 25.0)];
        styleLayer.path = shadowPath.CGPath;
        _logoImage.layer.mask = styleLayer;
        
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
        
        UITextField *des = [[UITextField alloc] init];
        des.frame = CGRectMake(490, 25, 90, 20);
        des.textAlignment = NSTextAlignmentLeft;
        des.backgroundColor = [UIColor clearColor];
        des.font = [UIFont systemFontOfSize:12];
        des.textColor = [UIColor grayColor];
        des.text = @"Created by:";
        des.userInteractionEnabled = FALSE;
        [self addSubview:des];
        
        
        _creatorText = [[UITextField alloc] init];
        _creatorText.frame = CGRectMake(490, 50, 90, 20);
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
        _creatorText.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [self addSubview:_creatorText];
        
        _jobTitleText = [[UITextField alloc] init];
        _jobTitleText.frame = CGRectMake(490, 75, 90, 20);
        _jobTitleText.textAlignment = NSTextAlignmentLeft;
        _jobTitleText.backgroundColor = [UIColor clearColor];
        _jobTitleText.font = [UIFont systemFontOfSize:12];
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
        [self addSubview:_jobTitleText];
    }
    
    //------- begin _functionAreaView
    
    if (_isPlayingCard == NO) {
        if (_functionAreaView == nil) {
            _functionAreaView = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 150, CGRectGetMinY(_segmentedControl.frame), 150, CGRectGetHeight(_segmentedControl.frame))];
            _functionAreaView.backgroundColor = [UIColor colorWithRed:43.0/255 green:43.0/255 blue:43.0/255 alpha:1];
            _functionAreaView.layer.borderColor = [[UIColor grayColor]CGColor];
            _functionAreaView.layer.borderWidth = 0;
            _functionAreaView.layer.cornerRadius =3;
            _functionAreaView.layer.masksToBounds = YES;
            [self addSubview:_functionAreaView];
        }
        
        if (_soundButton == nil) {
            _soundButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _soundButton.frame = CGRectMake(114, 8, 24, 24);
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
            _backgroundImageSelectButton.frame = CGRectMake(68, 8, 24, 24);
            [_backgroundImageSelectButton setBackgroundImage:[UIImage imageNamed:@"change_card_background_image_button"] forState:UIControlStateNormal];
            [_functionAreaView addSubview:_backgroundImageSelectButton];
            UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundImageSelectButtonClicked:)];
            [_backgroundImageSelectButton addGestureRecognizer:logoSingeTap];
            _backgroundImageSelectButton.showsTouchWhenHighlighted = YES;
        }
        
        
        if (_changeTemplateButton == nil) {
            _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _changeTemplateButton.frame = CGRectMake(18, 8, 24, 24);
            [_changeTemplateButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
            _changeTemplateButton.showsTouchWhenHighlighted = YES;
            [_changeTemplateButton setImage:[UIImage imageNamed:@"change_card_layout_template"] forState:UIControlStateNormal];
            [_functionAreaView addSubview:_changeTemplateButton];
            [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
            _changeTemplateButton.showsTouchWhenHighlighted = YES;
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
        _questionBackgroundImageView.frame = CGRectMake(kFlashCardSidebarWidth_iPhone, kFlashCardHeaderHeight_iPhone, CGRectGetWidth(_templateBackgroundImageView.frame) - kFlashCardSidebarWidth_iPhone, CGRectGetHeight(_templateBackgroundImageView.frame) - kFlashCardHeaderHeight_iPhone);;
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
        _answerBackgroundImageView.frame = CGRectMake(kFlashCardSidebarWidth_iPhone, kFlashCardHeaderHeight_iPhone, CGRectGetWidth(_templateBackgroundImageView.frame) - kFlashCardSidebarWidth_iPhone, CGRectGetHeight(_templateBackgroundImageView.frame) - kFlashCardHeaderHeight_iPhone);
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
        _questionTitle.frame = CGRectMake(kFlashCardSidebarWidth_iPhone + 5, 15, 200, 23);
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
        _questionTitle.layer.shadowRadius = .5f;
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
        _answerTitle.frame = CGRectMake(kFlashCardSidebarWidth_iPhone + 5, 15, 200, 23);
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
        _answerTitle.layer.shadowRadius = .5f;
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
        _sidebarTitle.frame = CGRectMake(0, 0, 200, kFlashCardSidebarWidth_iPhone);
        [_sidebarTitle setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _sidebarTitle.center = CGPointMake(kFlashCardSidebarWidth_iPhone/2, 112);
        } else {
            _sidebarTitle.center = CGPointMake(kFlashCardSidebarWidth_iPhone/2, 112);
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
        
    }
    
    
    if (_imageQuestion ==  nil) {
        _imageQuestion= [[UIImageView  alloc] init];
        _imageQuestion.userInteractionEnabled = FALSE;
        _imageQuestion.contentMode = UIViewContentModeScaleAspectFit;
        _imageQuestion.clipsToBounds = YES;
        _imageQuestion.backgroundColor = [UIColor clearColor];
        _imageQuestion.tag = 1;
        _imageQuestion.layer.cornerRadius = 10;
        _imageQuestion.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageQuestion];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
        [_imageQuestion addGestureRecognizer:imageSingeTap];
    }
    
    if (_imageQuestion2 ==  nil) {
        _imageQuestion2= [[UIImageView  alloc] init];
        _imageQuestion2.userInteractionEnabled = FALSE;
        _imageQuestion2.contentMode = UIViewContentModeScaleAspectFit;
        _imageQuestion2.clipsToBounds = YES;
        _imageQuestion2.backgroundColor = [UIColor clearColor];
        _imageQuestion2.tag = 1;
        _imageQuestion2.layer.cornerRadius = 10;
        _imageQuestion2.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageQuestion2];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped2:)];
        [_imageQuestion2 addGestureRecognizer:imageSingeTap];
    }
    
    if (_subheadingQuestion ==  nil) {
        _subheadingQuestion = [[UITextView alloc]init];
        _subheadingQuestion.tag = kTagSubheadingQuestion;
        _subheadingQuestion.userInteractionEnabled = FALSE;
        _subheadingQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _subheadingQuestion.returnKeyType = UIReturnKeyDefault;
        _subheadingQuestion.delegate = self;
        _subheadingQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _subheadingQuestion.backgroundColor = [UIColor clearColor];
        _subheadingQuestion.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [_verticalScrollView addSubview:_subheadingQuestion];
    }
    
    if (_mainQuestion ==  nil) {
        _mainQuestion = [[UITextView alloc]init];
        _mainQuestion.tag = kTagMainQuestion;
        _mainQuestion.userInteractionEnabled = FALSE;
        _mainQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _mainQuestion.returnKeyType = UIReturnKeyDefault;
        _mainQuestion.delegate = self;
        _mainQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _mainQuestion.backgroundColor = [UIColor clearColor];
        _mainQuestion.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [_verticalScrollView addSubview:_mainQuestion];
    }
    
    
    if (_subQuestion ==  nil) {
        _subQuestion = [[UITextView alloc]init];
        _subQuestion.tag = kTagSubQuestion;
        _subQuestion.userInteractionEnabled = FALSE;
        _subQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _subQuestion.returnKeyType = UIReturnKeyDefault;
        _subQuestion.delegate = self;
        _subQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _subQuestion.backgroundColor = [UIColor clearColor];
        _subQuestion.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [_verticalScrollView addSubview:_subQuestion];
    }
    
    if (_imageAnswer ==  nil) {
        _imageAnswer= [[UIImageView  alloc] init];
        _imageAnswer.userInteractionEnabled = FALSE;
        _imageAnswer.contentMode = UIViewContentModeScaleAspectFit;
        _imageAnswer.clipsToBounds = YES;
        _imageAnswer.backgroundColor = [UIColor clearColor];
        _imageAnswer.tag = 1;
        _imageAnswer.layer.cornerRadius = 10;
        _imageAnswer.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageAnswer];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
        [_imageAnswer addGestureRecognizer:imageSingeTap];
    }
    _imageAnswer.hidden = YES;
    
    if (_imageAnswer2 ==  nil) {
        _imageAnswer2= [[UIImageView  alloc] init];
        _imageAnswer2.userInteractionEnabled = FALSE;
        _imageAnswer2.contentMode = UIViewContentModeScaleAspectFit;
        _imageAnswer2.clipsToBounds = YES;
        _imageAnswer2.backgroundColor = [UIColor clearColor];
        _imageAnswer2.tag = 1;
        _imageAnswer2.layer.cornerRadius = 10;
        _imageAnswer2.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_imageAnswer2];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped2:)];
        [_imageAnswer2 addGestureRecognizer:imageSingeTap];
    }
    _imageAnswer2.hidden = YES;
    
    
    if (_subheadingAnswer ==  nil) {
        _subheadingAnswer = [[UITextView alloc]init];
        _subheadingAnswer.tag = kTagSubheadingAnswer;
        _subheadingAnswer.userInteractionEnabled = FALSE;
        _subheadingAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _subheadingAnswer.returnKeyType = UIReturnKeyDefault;
        _subheadingAnswer.delegate = self;
        _subheadingAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _subheadingAnswer.backgroundColor = [UIColor clearColor];
        _subheadingAnswer.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [_verticalScrollView addSubview:_subheadingAnswer];
    }
    _subheadingAnswer.hidden = YES;
    
    if (_mainAnswer ==  nil) {
        _mainAnswer = [[UITextView alloc]init];
        _mainAnswer.tag = kTagMainAnswer;
        _mainAnswer.userInteractionEnabled = FALSE;
        _mainAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _mainAnswer.returnKeyType = UIReturnKeyDefault;
        _mainAnswer.delegate = self;
        _mainAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _mainAnswer.backgroundColor = [UIColor clearColor];
        _mainAnswer.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [_verticalScrollView addSubview:_mainAnswer];
    }
    _mainAnswer.hidden = YES;
    
    if (_subAnswer ==  nil) {
        _subAnswer = [[UITextView alloc]init];
        _subAnswer.tag = kTagSubAnswer;
        _subAnswer.userInteractionEnabled = FALSE;
        _subAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _subAnswer.returnKeyType = UIReturnKeyDefault;
        _subAnswer.delegate = self;
        _subAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _subAnswer.backgroundColor = [UIColor clearColor];
        _subAnswer.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [_verticalScrollView addSubview:_subAnswer];
    }
    _subAnswer.hidden = YES;
    
    if (_segmentedControl == nil) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                             @[NSLocalizedString(@"ToolbarItem_Question",nil),
                               NSLocalizedString(@"ToolbarItem_Answer",nil)]];
        
        CGRect frame = CGRectMake(kSegmentLeftMarginForiPhone,
                                  self.bounds.size.height-kSegmentHeightForiPhone-kSegmentButtomMarginForiPhone,
                                  180,
                                  kSegmentHeightForiPhone);
        _segmentedControl.frame = frame;
        [_segmentedControl addTarget:self action:@selector(segmentedControlQAClicked:) forControlEvents:UIControlEventValueChanged];
        _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        _segmentedControl.selectedSegmentIndex = 0;
        [self addSubview:_segmentedControl];
    }
    
    
    
    
    if (_logoImage == nil){
        _logoImage = [[UIImageView  alloc] init];
        _logoImage.contentMode = UIViewContentModeScaleAspectFit;
        _logoImage.frame = CGRectMake(kFlashCardViewWidth_Detail_iPhone - 54, 5, 54, 30);
        if (self.isPlayingCard) {
            _logoImage.frame = [Common getScaledViewRect:_logoImage withProportion:kFlashCardViewProporation_iPhone];
        }
        _logoImage.backgroundColor = [UIColor whiteColor];
        
        CAShapeLayer *styleLayer = [CAShapeLayer layer];
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:_logoImage.bounds byRoundingCorners:(UIRectCornerBottomRight|UIRectCornerBottomLeft|UIRectCornerTopRight|UIRectCornerTopLeft) cornerRadii:CGSizeMake(15, 15.0)];
        styleLayer.path = shadowPath.CGPath;
        _logoImage.layer.mask = styleLayer;
        
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
        UITextField *des = [[UITextField alloc] init];
        des.frame = CGRectMake(190, 5, 68, 10);
        if (self.isPlayingCard) {
            des.frame = [Common getScaledViewRect:des withProportion:kFlashCardViewProporation_iPhone];
        }
        des.textAlignment = NSTextAlignmentLeft;
        des.backgroundColor = [UIColor clearColor];
        des.font = [UIFont systemFontOfSize:8];
        if (self.isPlayingCard) {
            des.font =[UIFont systemFontOfSize:8*kFlashCardViewProporation_iPhone];
        }
        des.textColor = [UIColor grayColor];
        des.text = @"Created by:";
        des.userInteractionEnabled = FALSE;
        [self addSubview:des];
        
        
        _creatorText = [[UITextField alloc] init];
        _creatorText.frame = CGRectMake(190, 15, 68, 10);
        if (self.isPlayingCard) {
            _creatorText.frame = [Common getScaledViewRect:_creatorText withProportion:kFlashCardViewProporation_iPhone];
        }
        _creatorText.textAlignment = NSTextAlignmentLeft;
        _creatorText.backgroundColor = [UIColor clearColor];
        _creatorText.font = [UIFont systemFontOfSize:8];
        if (self.isPlayingCard) {
            _creatorText.font =[UIFont systemFontOfSize:8*kFlashCardViewProporation_iPhone];
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
        [self addSubview:_creatorText];
        
        _jobTitleText = [[UITextField alloc] init];
        _jobTitleText.frame = CGRectMake(190, 25, 68, 10);
        if (self.isPlayingCard) {
            _jobTitleText.frame = [Common getScaledViewRect:_jobTitleText withProportion:kFlashCardViewProporation_iPhone];
        }
        _jobTitleText.textAlignment = NSTextAlignmentLeft;
        _jobTitleText.backgroundColor = [UIColor clearColor];
        _jobTitleText.font = [UIFont systemFontOfSize:8];
        if (self.isPlayingCard) {
            _jobTitleText.font =[UIFont systemFontOfSize:8*kFlashCardViewProporation_iPhone];
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
        [self addSubview:_jobTitleText];
    }
    
    //------- begin _functionAreaView
    
    if (_isPlayingCard == NO) {
        if (_functionAreaView == nil) {
            _functionAreaView = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 150, CGRectGetMinY(_segmentedControl.frame), 150, CGRectGetHeight(_segmentedControl.frame))];
            _functionAreaView.backgroundColor = [UIColor darkGrayColor];
            _functionAreaView.layer.borderColor = [[UIColor grayColor]CGColor];
            _functionAreaView.layer.borderWidth = 0;
            _functionAreaView.layer.cornerRadius =3;
            _functionAreaView.layer.masksToBounds = YES;
            [self addSubview:_functionAreaView];
        }
        
        if (_soundButton == nil) {
            _soundButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _soundButton.frame = CGRectMake(117, 4, 20, 20);
            [_soundButton setImage:[UIImage imageNamed:@"record_button"] forState:UIControlStateNormal];
            [_soundButton addTarget:self action:@selector(soundRecordButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            _soundButton.backgroundColor = [UIColor clearColor];
            [_functionAreaView addSubview:_soundButton];
            _soundButton.showsTouchWhenHighlighted = YES;
        }
        
        if (_backgroundImageSelectButton == nil) {
            _backgroundImageSelectButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _backgroundImageSelectButton.showsTouchWhenHighlighted = YES;
            _backgroundImageSelectButton.frame = CGRectMake(67, 4, 20, 20);
            [_backgroundImageSelectButton setBackgroundImage:[UIImage imageNamed:@"change_card_background_image_button"] forState:UIControlStateNormal];
            [_functionAreaView addSubview:_backgroundImageSelectButton];
            UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundImageSelectButtonClicked:)];
            [_backgroundImageSelectButton addGestureRecognizer:logoSingeTap];
            _backgroundImageSelectButton.showsTouchWhenHighlighted = YES;
        }
        
        
        if (_changeTemplateButton == nil) {
            _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _changeTemplateButton.frame = CGRectMake(17, 4, 20, 20);
            _changeTemplateButton.showsTouchWhenHighlighted = YES;
            [_changeTemplateButton setImage:[UIImage imageNamed:@"change_card_layout_template"] forState:UIControlStateNormal];
            [_functionAreaView addSubview:_changeTemplateButton];
            [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
            _changeTemplateButton.showsTouchWhenHighlighted = YES;
        }
        
        if (_isPlayingCard) {
            _functionAreaView.hidden = YES;
        }
    }
    
    //------- end _functionAreaView
    
    
}

- (int) setTextViewTopPadding: (int) fontSize {
    
    int val = 0;
    
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
#ifdef CLIENT_DEBUG_MODE
    result = [[NSUserDefaults standardUserDefaults] boolForKey:@"isCardEditableForDebugMode"];
    BOOL flag = [_currentCard.creator isEqualToString:[OpenUDID value]];
    return (result || flag);
#else
    if ([_currentCard.creator isEqualToString:[OpenUDID value]]) {
        result = YES;
    } else {
        result = NO;
    }
#endif
    return result;
    
}

- (void) disableCardEdit{
    [iConsole info:@"%s",__FUNCTION__];
    _logoLinkageButton.hidden = TRUE;
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWebviewViaLogoURL:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    if (_currentCard.question.movieFullPath.length > 0) {
        //allow to play movie
        _imageQuestion.userInteractionEnabled        = YES;
    } else {
        _imageQuestion.userInteractionEnabled        = FALSE;
    }
    
    if (_currentCard.question.movieFullPath2.length > 0) {
        //allow to play movie
        _imageQuestion2.userInteractionEnabled        = YES;
    } else {
        _imageQuestion2.userInteractionEnabled        = FALSE;
    }
    
    _imageQuestion.layer.borderWidth = 0;
    _imageQuestion2.layer.borderWidth = 0;
    _mainQuestion.userInteractionEnabled         = FALSE;
    _mainQuestion.layer.borderWidth = 0;
    _subQuestion.userInteractionEnabled          = FALSE;
    _subQuestion.layer.borderWidth = 0;
    _subheadingQuestion.userInteractionEnabled   = FALSE;
    _subheadingQuestion.layer.borderWidth = 0;
    
    if (_currentCard.answer.movieFullPath.length > 0) {
        _imageAnswer.userInteractionEnabled        = YES;
    } else {
        _imageAnswer.userInteractionEnabled        = FALSE;
    }
    
    if (_currentCard.answer.movieFullPath2.length > 0) {
        _imageAnswer2.userInteractionEnabled        = YES;
    } else {
        _imageAnswer2.userInteractionEnabled        = FALSE;
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
}

- (void) enableCardEdit{
    [iConsole info:@"%s",__FUNCTION__];
    _logoLinkageButton.hidden = FALSE;
    
    int scale = [[UIScreen mainScreen] scale];
    
    
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    _imageQuestion.userInteractionEnabled        = TRUE;
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
}



#pragma mark -
#pragma mark - Refresh


- (void) refreshAll {
    [iConsole info:@"%s",__FUNCTION__];
    [self refreshAll:NO withIndexPlaying:-1];
    
}

/**
 *  刷新操作，考虑：
 *  1. play mode和 edit mode下的scroll view
 *  2. 卡片可编辑，或不可编辑
 *  @param isDisableAutoResize 如果为NO，满足下面的条件执行adjustAllTextViewsToFitIfNecessary
 *  @param indexPlaying        indexPlaying =0时，表明为第一个card，这时如果已经被缓存过（isDisableAutoResize = YES），则不会执行adjustAllTextViewsToFitIfNecessary
 */
- (void) refreshAll:(BOOL) isDisableAutoResize withIndexPlaying: (int) indexPlaying {
    [iConsole info:@"%s",__FUNCTION__];
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
    }
    
    
    if (_segmentedControl.selectedSegmentIndex == 1) {
        [self adjustAllTextViewsToFitIfNecessary];
    } else {
        if ([_currentPack.creator isEqualToString:[OpenUDID value]] == FALSE) {
            //当不可编辑时，我们将限制adjustAllTextViewsToFitIfNecessary执行。主要原因时这时我们将通过前后页来预加载，而非当前页执行adjustAllTextViewsToFitIfNecessary
            //几种情况
            //1. 如果是刚进入play mode，显示第一个card，这时indexPlaying = 0， isDisableAutoResize = NO；
            //2. 其它情况下，我们不直接渲染第一个card，而是通过previous/next card进行提前渲染
            if (((self.tag != CURRENT_FLASHCARDVIEW_TAG) && (isDisableAutoResize == NO))
                || ((indexPlaying == 0) && (isDisableAutoResize == NO))){
                
                BOOL isFontResized = [self adjustAllTextViewsToFitIfNecessary];
                
                if ((isFontResized)) {
                    
                    [iConsole warn:@"%s:card(sn=%d) is font resized",__FUNCTION__,_currentCard.cardSN];
                    
                }
            }
        } else {
            [self adjustAllTextViewsToFitIfNecessary];
        }
    }
    
    //当可编辑时，我们不进行自动autoresize的notification
    //当为CURRENT_FLASHCARDVIEW_TAG，我们也不作处理
    if (([_currentPack.creator isEqualToString:[OpenUDID value]] == FALSE)
        && (self.tag != CURRENT_FLASHCARDVIEW_TAG)){
        
        if (self.tag == PREVIOUS_FLASHCARDVIEW_TAG) {
            NSArray *myArray = [NSArray arrayWithObjects:
                                [NSNumber numberWithFloat:_subheadingQuestion.font.pointSize],
                                [NSNumber numberWithFloat:_mainQuestion.font.pointSize],
                                [NSNumber numberWithFloat:_subQuestion.font.pointSize], nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PREVIOUS_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION" object:myArray];
        }
        
        if (self.tag == NEXT_FLASHCARDVIEW_TAG) {
            NSArray *myArray = [NSArray arrayWithObjects:
                                [NSNumber numberWithFloat:_subheadingQuestion.font.pointSize],
                                [NSNumber numberWithFloat:_mainQuestion.font.pointSize],
                                [NSNumber numberWithFloat:_subQuestion.font.pointSize], nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NEXT_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION" object:myArray];
        }
    }
    
    
    [self updateQuestionAnswerAllTextViewVeriticalAlignment];//由于此方法的执行跟内容相关，一般放在最后
    
    if ([_synth isSpeaking]) {
        [_synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    
    
    if (APP_DELEGATE.isAllowToShowTooltip) {
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
    [self refreshQuestionContent];
    [self refreshAnswerContent];
    
    _cardSNText.badgeText= [NSString stringWithFormat:@"%d",_currentCard.cardSN];
    
    //it's quite strange logic below, but it indeed
    if ((_currentPack.sidebarTitle.length == 0) || ([_currentPack.sidebarTitle rangeOfString:@"null"].length != 0)) {
        _sidebarTitle.text = _currentPack.packName;
    } else {
        _sidebarTitle.text = _currentPack.sidebarTitle;
    }
    _templateBackgroundImageName = _currentCard.templateBackgroundName;
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
    
    if (checkNullOrEmptyOrNullStr(_currentPack.creatorNickName)) {
        _creatorText.text = @"";
    } else {
        _creatorText.text = [NSString stringWithFormat:@"%@",_currentPack.creatorNickName];
    }
    
    if (_isPlayingCard) {
        if ([_creatorText.text isEqualToString:NSLocalizedString(@"Label_Creator", nil)]) {
            _creatorText.text = @"";
        }
    }
    
    if (checkNullOrEmptyOrNullStr(_currentPack.jobTitle)) {
        _jobTitleText.text = @"";
    } else {
        _jobTitleText.text = [NSString stringWithFormat:@"%@",_currentPack.jobTitle];
    }
    
    if (_isPlayingCard) {
        if ([_jobTitleText.text isEqualToString:NSLocalizedString(@"Job_Title", nil)]) {
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
    NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.imageFullPath lastPathComponent]];
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:path];
    [iConsole info:@"%s,_answerImageFullPath = %@",__FUNCTION__,path];
    if (imageTemp) {
        _answerImageFullPath = path;
        _imageAnswer.image = imageTemp;
    } else {
        [iConsole info:@"%s,[UIImage imageWithContentsOfFile:path] return with nil, so use placehold image",__FUNCTION__];
        _answerImageFullPath = @"";
        _imageAnswer.image = [UIImage imageNamed:@"answer_placeholder_content"];
        
        if (_isPlayingCard) {
            _imageAnswer.hidden = YES;
        } else {
        }
    }
    
    path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.imageFullPath2 lastPathComponent]];
    imageTemp = [UIImage imageWithContentsOfFile:path];
    [iConsole info:@"%s,_answerImageFullPath2 = %@",__FUNCTION__,path];
    if (imageTemp) {
        _answerImageFullPath2 = path;
        _imageAnswer2.image = imageTemp;
    } else {
        [iConsole info:@"%s,[UIImage imageWithContentsOfFile:path] return with nil, so use placehold image",__FUNCTION__];
        _answerImageFullPath2 = @"";
        _imageAnswer2.image = [UIImage imageNamed:@"answer_placeholder_content"];
        
        if (_isPlayingCard) {
            _imageAnswer2.hidden = YES;
        } else {
        }
    }
    
    path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.backgroundImageFullPath lastPathComponent]];
    imageTemp = [UIImage imageWithContentsOfFile:path];
    if (imageTemp) {
        _answerBackgroundImageFullPath = path;
        _answerBackgroundImageView.image = imageTemp;
    } else {
        _answerBackgroundImageFullPath = @"";
        _answerBackgroundImageView.image = nil;
    }
    
    //两种情况，普通youtube，另外一种，本地创建
    if (_currentCard.answer.movieFullPath.length > 0) {
        if ([Common isValidYoutubeLinkage:_currentCard.answer.movieFullPath]) {
            _answerMovieFullPath = _currentCard.answer.movieFullPath;
        } else {
            path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.movieFullPath lastPathComponent]];
            _answerMovieFullPath = path;
        }
        
    } else {
        _answerMovieFullPath = @"";
    }
    
    if (_currentCard.answer.movieFullPath2.length > 0) {
        if ([Common isValidYoutubeLinkage:_currentCard.answer.movieFullPath2]) {
            _answerMovieFullPath2 = _currentCard.answer.movieFullPath2;
        } else {
            path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.movieFullPath2 lastPathComponent]];
            _answerMovieFullPath2 = path;
        }
        
    } else {
        _answerMovieFullPath2 = @"";
    }
    
    if (_currentCard.answer.recordedSoundFullPath.length > 0) {
        path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.recordedSoundFullPath lastPathComponent]];
        _answerRecordedSoundFullPath = path;
    } else {
        _answerRecordedSoundFullPath = @"";
    }
    
    
    
    _answerTitle.text = _currentCard.answer.title;
    
    _subheadingAnswer.text = _currentCard.answer.subheading;
    _mainAnswer.text =_currentCard.answer.main;
    _subAnswer.text =_currentCard.answer.sub;
    
}

- (void) refreshQuestionContent {
    NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.imageFullPath lastPathComponent]];
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:path];
    [iConsole info:@"%s,_questionImageFullPath = %@",__FUNCTION__,path];
    if (imageTemp) {
        _questionImageFullPath = path;
        _imageQuestion.image = imageTemp;
    } else {
        [iConsole info:@"%s,[UIImage imageWithContentsOfFile:path] return with nil, so use placehold image",__FUNCTION__];
        _questionImageFullPath = @"";
        _imageQuestion.image = [UIImage imageNamed:@"question_placeholder_content"];
        
        if (_isPlayingCard) {
            _imageQuestion.hidden = YES;
        } else {
        }
        
    }
    
    path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.imageFullPath2 lastPathComponent]];
    imageTemp = [UIImage imageWithContentsOfFile:path];
    [iConsole info:@"%s,_questionImageFullPath2 = %@",__FUNCTION__,path];
    if (imageTemp) {
        _questionImageFullPath2 = path;
        _imageQuestion2.image = imageTemp;
    } else {
        [iConsole info:@"%s,[UIImage imageWithContentsOfFile:path] return with nil, so use placehold image",__FUNCTION__];
        _questionImageFullPath2 = @"";
        _imageQuestion2.image = [UIImage imageNamed:@"question_placeholder_content"];
        
        if (_isPlayingCard) {
            _imageQuestion2.hidden = YES;
        } else {
        }
        
    }
    
    path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.logoFullPath lastPathComponent]];
    imageTemp = [UIImage imageWithContentsOfFile:path];
    if (imageTemp) {
        _logoImageFullPath = path;
        _logoImage.image = imageTemp;
    } else {
        _logoImageFullPath = @"";
        _logoImage.image = [UIImage imageNamed:@"question_placeholder_logo"];
        
        if (_isPlayingCard) {
            _logoImage.hidden = YES;
        } else {
        }
    }
    
    
    path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.backgroundImageFullPath lastPathComponent]];
    imageTemp = [UIImage imageWithContentsOfFile:path];
    if (imageTemp) {
        _questionBackgroundImageFullPath = path;
        _questionBackgroundImageView.image = imageTemp;
    } else {
        _questionBackgroundImageFullPath = @"";
        _questionBackgroundImageView.image = nil;
    }
    
    //两种情况，普通youtube，另外一种，本地创建
    if (_currentCard.question.movieFullPath.length > 0) {
        if ([Common isValidYoutubeLinkage:_currentCard.question.movieFullPath]) {
            _questionMovieFullPath = _currentCard.question.movieFullPath;
        } else {
            path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.movieFullPath lastPathComponent]];
            _questionMovieFullPath = path;
        }
        
    } else {
        _questionMovieFullPath = @"";
    }
    
    if (_currentCard.question.movieFullPath2.length > 0) {
        if ([Common isValidYoutubeLinkage:_currentCard.question.movieFullPath2]) {
            _questionMovieFullPath2 = _currentCard.question.movieFullPath2;
        } else {
            path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.movieFullPath2 lastPathComponent]];
            _questionMovieFullPath2 = path;
        }
        
    } else {
        _questionMovieFullPath2 = @"";
    }
    
    if (_currentCard.question.recordedSoundFullPath.length > 0) {
        path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.recordedSoundFullPath lastPathComponent]];
        _questionRecordedSoundFullPath = path;
    } else {
        _questionRecordedSoundFullPath = @"";
    }
    
    
    _questionTitle.text = _currentCard.question.title;
    
    _subheadingQuestion.text = _currentCard.question.subheading;
    _mainQuestion.text =_currentCard.question.main;
    _subQuestion.text =_currentCard.question.sub;
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
    [self refreshAll];
}

- (void) backgroundImageSelectButtonClicked:(UITapGestureRecognizer *)sender {
    
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
        [self selectFromImageLibraryByBackgroundSelectButton:sender];
    } else {
        
        CGPoint point = [_backgroundImageSelectButton convertPoint:CGPointMake(CGRectGetWidth(_backgroundImageSelectButton.frame)/2, 0) toView:self];
        
        PopoverView *backgroundImageSelectPopoverView;
        if (isAllowUndo) {
            backgroundImageSelectPopoverView = [PopoverView showPopoverAtPoint:point
                                                                        inView:self
                                                                     withTitle:@"Edit/Remove"
                                                               withStringArray:[NSArray arrayWithObjects:@"Remove background image", @"Change background image",@"Undo last operation", nil]
                                                                      delegate:self];
        } else {
            backgroundImageSelectPopoverView = [PopoverView showPopoverAtPoint:point
                                                                        inView:self
                                                                     withTitle:@"Edit/Remove"
                                                               withStringArray:[NSArray arrayWithObjects:@"Remove background image", @"Change background image", nil]
                                                                      delegate:self];
        }
        backgroundImageSelectPopoverView.tag = Type_PopoverView_SelectBackground;
    }
    
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
    _currentCard.answer.css.mainAlign = _mainAlignAnswer;
    _currentCard.answer.css.mainColor = _mainColorAnswer;
    _currentCard.answer.css.mainSize = _mainSizeAnswer;
    _currentCard.answer.css.subAlign = _subAlignAnswer;
    _currentCard.answer.css.subColor = _subColorAnswer;
    _currentCard.answer.css.subSize = _subSizeAnswer;
    
    _currentCard.answer.css.subheadingAlignVertical = _subheadingAlignVerticalAnswer;
    _currentCard.answer.css.mainAlignVertical = _mainAlignVerticalAnswer;
    _currentCard.answer.css.subAlignVertical = _subAlignVerticalAnswer;
    
    _currentCard.answer.css.subheadingFont = _subheadingFontAnswer;
    _currentCard.answer.css.mainFont = _mainFontAnswer;
    _currentCard.answer.css.subFont = _subFontAnswer;
    
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
    _currentCard.question.css.mainAlign = _mainAlignQuestion;
    _currentCard.question.css.mainColor = _mainColorQuestion;
    _currentCard.question.css.mainSize = _mainSizeQuestion;
    _currentCard.question.css.subAlign = _subAlignQuestion;
    _currentCard.question.css.subColor = _subColorQuestion;
    _currentCard.question.css.subSize = _subSizeQuestion;
    
    _currentCard.question.css.subheadingAlignVertical = _subheadingAlignVerticalQuestion;
    _currentCard.question.css.mainAlignVertical = _mainAlignVerticalQuestion;
    _currentCard.question.css.subAlignVertical = _subAlignVerticalQuestion;
    
    _currentCard.question.css.subheadingFont = _subheadingFontQuestion;
    _currentCard.question.css.mainFont = _mainFontQuestion;
    _currentCard.question.css.subFont = _subFontQuestion;
    
    _currentCard.question.lineNoSubheading = [self lineNumberWithUITextView:_subheadingQuestion];
    _currentCard.question.lineNoMain = [self lineNumberWithUITextView:_mainQuestion];
    _currentCard.question.lineNoSub = [self lineNumberWithUITextView:_subQuestion];
    
    _currentCard.answer.lineNoSubheading = [self lineNumberWithUITextView:_subheadingAnswer];
    _currentCard.answer.lineNoMain = [self lineNumberWithUITextView:_mainAnswer];
    _currentCard.answer.lineNoSub = [self lineNumberWithUITextView:_subAnswer];
    
    _currentPack.creatorNickName = _creatorText.text;
    _currentPack.jobTitle = _jobTitleText.text;
    _currentPack.sidebarTitle = _sidebarTitle.text;
}

- (int) lineNumberWithUITextView:(UITextView *) textView
{
    float textHeight = [self getTextSizeHeight:textView];
    float lineHeight = textView.font.lineHeight;
    
    float numLines = textHeight / lineHeight;
    
    int returnVal = ceilf(numLines);
    
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
            _subheadingAnswer.frame = CGRectMake(3, 5, 304, 26);
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
            _mainAnswer.frame = CGRectMake(3, 33, 304.5, 147);
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
            _subheadingAnswer.frame = CGRectMake(3, 4, 218.75, 21);
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
            _mainAnswer.frame = CGRectMake(3, 29, 304.5, 77);
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
            _subAnswer.frame = CGRectMake(3, 109, 304.5, 68.5);
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
            _mainAnswer.frame = CGRectMake(3, 5, 304.5, 120);
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
            _subAnswer.frame = CGRectMake(3, 130, 304.5, 41.56);
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
            _mainAnswer.frame = CGRectMake(3, 5, 304.5, 86.5);
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
            _subAnswer.frame = CGRectMake(3, 95, 304.5, 82);
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
            _mainAnswer.frame = CGRectMake(3, 15, 304.5, 165.5);
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
            _imageAnswer.frame = CGRectMake(3, 5, 304.5, 180.0);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 0:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 154, 26);
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
            _mainAnswer.frame = CGRectMake(3, 28, 154, 156);
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
            _imageAnswer.frame = CGRectMake(162, 15, 152, 152);
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
            _mainAnswer.frame = CGRectMake(3, 3, 155.5, 182);
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
            _imageAnswer.frame = CGRectMake(160, 10, 153, 153);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
        case 1:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 304.5, 24.5);
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
            _mainAnswer.frame = CGRectMake(3, 30, 156, 127);
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
            _subAnswer.frame = CGRectMake(3, 160, 156, 21);
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
            _imageAnswer.frame = CGRectMake(164, 33, 143, 143);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 11:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 156, 24.5);
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
            _imageAnswer2.frame = CGRectMake(10, 30, 134, 134);
            if (self.isPlayingCard) {
                _imageAnswer2.frame = [Common getScaledViewRect:_imageAnswer2 withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(160, 15, 152, 152);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            break;
        }
            
        case 2:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(3, 3, 156, 90);
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
            _mainAnswer.frame = CGRectMake(3, 94.5, 156, 90);
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
            _mainAnswer.frame = CGRectMake(3, 10, 150, 164.5);
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
            _subAnswer.frame = CGRectMake(158, 10, 150, 164.5);
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
    int index = _currentCard.answer.templateID;
    
    switch (index) {
        case 10: //Template 0
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 20, 700, 50);
            
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
            _mainAnswer.frame = CGRectMake(10, 75, 700, 350);
            
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
            _subheadingAnswer.frame = CGRectMake(10, 20, 500, 50);
            
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
            _mainAnswer.frame = CGRectMake(10, 75, 700, 180);
            
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
            _subAnswer.frame = CGRectMake(10, 260, 700, 160);
            
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
            _mainAnswer.frame = CGRectMake(10, 30, 700, 280);
            
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
            _subAnswer.frame = CGRectMake(10, 320, 700, 100);
            
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
            _mainAnswer.frame = CGRectMake(10, 20, 700, 200);
            
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
            _subAnswer.frame = CGRectMake(10, 230, 700, 190);
            
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
            _mainAnswer.frame = CGRectMake(10, 40, 700, 380);
            
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
            _imageAnswer.frame = CGRectMake(10, 20, 700, 410);
            
            _imageAnswer2.hidden = TRUE;
            
            break;
        }
            
        case 0:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 360, 60);
            
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
            _mainAnswer.frame = CGRectMake(10, 75, 360, 355);
            
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
            _mainAnswer.frame = CGRectMake(10, 10, 360, 420);
            
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
            _subheadingAnswer.frame = CGRectMake(10, 10, 700, 60);
            
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
            _mainAnswer.frame = CGRectMake(10, 75, 360, 295);
            
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
            _subAnswer.frame = CGRectMake(10, 380, 360, 50);
            
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
            _subheadingAnswer.frame = CGRectMake(10, 10, 360, 60);
            
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
            _imageAnswer2.frame = CGRectMake(30, 80, 310, 310);
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 40, 350, 350);
            
            
            break;
        }
        case 2:
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 360, 210);
            
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
            _mainAnswer.frame = CGRectMake(10, 225, 360, 210);
            
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
            _mainAnswer.frame = CGRectMake(10, 40, 345, 380);
            
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
            _subAnswer.frame = CGRectMake(365, 40, 345, 380);
            
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
    int index = _currentCard.question.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 20, 700, 50);
            
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
            _mainQuestion.frame = CGRectMake(10, 75, 700, 350);
            
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
            _subheadingQuestion.frame = CGRectMake(10, 20, 500, 50);
            
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
            _mainQuestion.frame = CGRectMake(10, 75, 700, 180);
            
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
            _subQuestion.frame = CGRectMake(10, 260, 700, 160);
            
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
            _mainQuestion.frame = CGRectMake(10, 30, 700, 280);
            
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
            _subQuestion.frame = CGRectMake(10, 320, 700, 100);
            
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
            _mainQuestion.frame = CGRectMake(10, 20, 700, 200);
            
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
            _subQuestion.frame = CGRectMake(10, 230, 700, 190);
            
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
            _mainQuestion.frame = CGRectMake(10, 40, 700, 380);
            
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
            _imageQuestion.frame = CGRectMake(10, 20, 700, 410);
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 6:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 10, 360, 60);
            
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
            _mainQuestion.frame = CGRectMake(10, 75, 360, 355);
            
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
            _mainQuestion.frame = CGRectMake(10, 10, 360, 420);
            
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
            _subheadingQuestion.frame = CGRectMake(10, 10, 700, 60);
            
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
            _mainQuestion.frame = CGRectMake(10, 75, 360, 295);
            
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
            _subQuestion.frame = CGRectMake(10, 380, 360, 50);
            
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
            _subheadingQuestion.frame = CGRectMake(10, 10, 360, 60);
            
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
            _imageQuestion2.frame = CGRectMake(30, 80, 310, 310);
            
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(380, 40, 350, 350);
            
            
            break;
        }
        case 10:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 10, 360, 210);
            
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
            _mainQuestion.frame = CGRectMake(10, 225, 360, 210);
            
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
            _mainQuestion.frame = CGRectMake(10, 40, 345, 380);
            
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
            _subQuestion.frame = CGRectMake(365, 40, 345, 380);
            
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
    int index = _currentCard.question.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 5, 304, 25.375);
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
            _mainQuestion.frame = CGRectMake(3, 33, 304.5, 147);
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
            _subheadingQuestion.frame = CGRectMake(3, 4, 218.75, 21);
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
            _mainQuestion.frame = CGRectMake(3, 29, 304.5, 77);
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
            _subQuestion.frame = CGRectMake(3, 109, 304.5, 68.5);
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
            _mainQuestion.frame = CGRectMake(3, 5, 304.5, 120);
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
            _subQuestion.frame = CGRectMake(3, 130, 304.5, 41.56);
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
            _mainQuestion.frame = CGRectMake(3, 5, 304.5, 86.5);
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
            _subQuestion.frame = CGRectMake(3, 95, 304.5, 82);
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
            _mainQuestion.frame = CGRectMake(3, 15, 304.5, 165.5);
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
            _subheadingQuestion.frame = CGRectMake(3, 3, 154, 26);
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
            _mainQuestion.frame = CGRectMake(3, 28, 154, 156);
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
            _imageQuestion.frame = CGRectMake(162, 15, 152, 152);
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
            _mainQuestion.frame = CGRectMake(3, 3, 155.5, 182);
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
            _imageQuestion.frame = CGRectMake(160, 10, 153, 153);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            
            break;
        }
        case 8:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 3, 304.5, 24.5);
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
            _mainQuestion.frame = CGRectMake(3, 30, 156, 127);
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
            _subQuestion.frame = CGRectMake(3, 160, 156, 21);
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
            _imageQuestion.frame = CGRectMake(164, 33, 143, 143);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion2.hidden = TRUE;
            
            break;
        }
            
        case 9:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 3, 156, 24.5);
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
            _imageQuestion2.frame = CGRectMake(10, 30, 134, 134);
            if (self.isPlayingCard) {
                _imageQuestion2.frame = [Common getScaledViewRect:_imageQuestion2 withProportion:kFlashCardViewProporation_iPhone];
            }
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(160, 15, 152, 152);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            break;
        }
            
        case 10:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(3, 3, 156, 90);
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
            _mainQuestion.frame = CGRectMake(3, 94.5, 156, 90);
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
            _mainQuestion.frame = CGRectMake(3, 10, 150, 164.5);
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
            _subQuestion.frame = CGRectMake(158, 10, 150, 164.5);
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
            size.height =size.height + fabsf(scrollableOffset) + gap;
        } else {
            size.height =size.height + fabsf(scrollableOffset) + gap;
        }
        
    } else {
        size.height =size.height + fabsf(scrollableOffset) - fabsf(gap);
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
            [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_NEW_CREATED_CARD_NOTIFICATION object:nil];
        } else {
            [self saveEdittedCard];
        }
    } else {
        //只是关闭键盘
        //每当只是关闭键盘时，这时如果是NEW_FLASHCARDVIEW_TAG，我们需要把数据暂存一下，以免segement QA切换会引起数据丢失
        if (self.tag == NEW_FLASHCARDVIEW_TAG) {
            [self commitQuestionAndAnswerData];
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


-(void)dismissKeyBoard:(id) sender
{
    [iConsole info:@"%s",__FUNCTION__];
    if (isUserInterfaceIdiomPhone) {
        //we don't need to hide navigation bar on iPad
        [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NAVIGATION_BAR_NOTIFICATION object:nil];
    }
    
    //reset contentSize which is used by user for manually scroll up/down
    CGSize size = _verticalScrollView.contentSize;
    size.height = _verticalScrollView.frame.size.height;
    _verticalScrollView.contentSize = size;
    
    //reset offset
    [self resetVerticalScrollViewOffset];
    
    
    //step1:close keyboard and related view
    _keyboardSwitchButtonType = KeyboardSwitchButtonTypeSystem;
    [_lastBecomeFirstRespondTextView setInputAccessoryView:_keyboardTopViewV2];
    [_lastBecomeFirstRespondTextView setInputView:nil];
    
    //step2:
    _isUITextViewFocused = NO;
    [_lastBecomeFirstRespondTextView resignFirstResponder];
    
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
    
    //Step3: save data in keyboardWasHidden
    _saveButtonPressed = YES;
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
    if ([_currentCard.creator isEqualToString:[OpenUDID value]] == FALSE) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"You can only edit card that you have created it." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
        
    }
    
    _imageSourceType = Type_Image_Source_Background;
    [self selectFromImageLibrary:[sender view] withPopoverArrowUp:NO  supportMov:NO];
}



- (void)selectFromImageLibraryByLogo:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    _imageSourceType = Type_Image_Source_Logo;
    
    [self selectFromImageLibrary:[sender view] withPopoverArrowUp:YES  supportMov:NO];
    
    
}

- (void)imageViewTapped:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    //1. play mode
    if (_isPlayingCard) {
        
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if (_currentCard.question.movieFullPath.length > 0) {
                
                [self playVideo:_currentCard.question.movieFullPath];
                
            }
            
        } else {
            if (_currentCard.answer.movieFullPath.length > 0) {
                [self playVideo:_currentCard.answer.movieFullPath];
            }
        }
        
        return;
        
    }
    
    //2. edit mode, and have video, but not own the pack
    NSString *targetStr;
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        targetStr = _currentCard.question.movieFullPath;
    } else {
        targetStr = _currentCard.answer.movieFullPath;
    }
    if (([self checkCardEditable] == FALSE) && (targetStr.length >0)) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Video play is only available in play mode" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    UIImageView *pickerImageView;
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        pickerImageView = _imageQuestion;
    } else {
        pickerImageView = _imageAnswer;
    }
    
    PopoverView *imageSelectPopoverView = [PopoverView showPopoverAtPoint:pickerImageView.center
                                                                   inView:self
                                                                withTitle:@"Image/video selection"
                                                          withStringArray:[NSArray arrayWithObjects:@"Insert YouTube url", @"Select from library",@"Remove video/image", nil]
                                                                 delegate:self];
    
    imageSelectPopoverView.tag = Type_PopoverView_SelectImage;
    
}

- (void)imageViewTapped2:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    //1. play mode
    if (_isPlayingCard) {
        
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if (_currentCard.question.movieFullPath2.length > 0) {
                
                [self playVideo:_currentCard.question.movieFullPath2];
                
            }
            
        } else {
            if (_currentCard.answer.movieFullPath2.length > 0) {
                [self playVideo:_currentCard.answer.movieFullPath2];
            }
        }
        
        return;
        
    }
    
    //2. edit mode, and have video, but not own the pack
    NSString *targetStr;
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        targetStr = _currentCard.question.movieFullPath2;
    } else {
        targetStr = _currentCard.answer.movieFullPath2;
    }
    if (([self checkCardEditable] == FALSE) && (targetStr.length >0)) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Video play is only available in play mode" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    UIImageView *pickerImageView;
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        pickerImageView = _imageQuestion2;
    } else {
        pickerImageView = _imageAnswer2;
    }
    
    PopoverView *imageSelectPopoverView = [PopoverView showPopoverAtPoint:pickerImageView.center
                                                                   inView:self
                                                                withTitle:@"Image/video selection"
                                                          withStringArray:[NSArray arrayWithObjects:@"Insert YouTube url", @"Select from library",@"Remove video/image", nil]
                                                                 delegate:self];
    
    imageSelectPopoverView.tag = Type_PopoverView_SelectImage2;
    
}

- (void)selectImageOrVideoFromLibraryWithImageType:(Type_PopoverView) sourceType{
    [iConsole info:@"%s",__FUNCTION__];
    
    if (sourceType == Type_PopoverView_SelectImage) {
        _imageSourceType = Type_Image_Source_Image;
    } else {
        _imageSourceType = Type_Image_Source_Image2;
    }
    
    
    if ([_currentCard.creator isEqualToString:[OpenUDID value]]) {
        [self selectFromImageLibrary:nil withPopoverArrowUp:YES supportMov:YES];
    } else {
        if (sourceType == Type_PopoverView_SelectImage) {
            if (_segmentedControl.selectedSegmentIndex == 0) {
                if ([_currentCard.question.movieFullPath hasSuffix:@".3gp"]) {
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Video play is only supported in play mode." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                    
                }
                
            } else {
                if ([_currentCard.answer.movieFullPath hasSuffix:@".3gp"]) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Video play is only supported in play mode." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                }
            }
        } else {
            if (_segmentedControl.selectedSegmentIndex == 0) {
                if ([_currentCard.question.movieFullPath2 hasSuffix:@".3gp"]) {
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Video play is only supported in play mode." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                    
                }
                
            } else {
                if ([_currentCard.answer.movieFullPath2 hasSuffix:@".3gp"]) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Video play is only supported in play mode." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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

- (void) playAudio:(BOOL) isManualClicked {
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
        
        _audioPlayer.numberOfLoops = 0;
        _audioPlayer.delegate = self;
        [_audioPlayer prepareToPlay];
        
        if (_audioPlayer == nil)
            [iConsole error:@"%s:%@,audio file:%@",__FUNCTION__,[error description],audioURL];
        else
            [_audioPlayer play];
        
    } else {
        [iConsole info:@"%s:no audio file:%@",__FUNCTION__,audioURL];
        
        if (isManualClicked) {
            NSString *msg;
            if (_segmentedControl.selectedSegmentIndex == 0) {
                msg = @"There is no audio on the question card";
            } else {
                msg = @"There is no audio on the answer card";
            }
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

/**
 *  Play movie/video
 */
- (void) playVideo:(NSString *) urlStr {
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
        
    } else {
        
        MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:urlStr]];
        [[playerViewController moviePlayer] play];
        
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
        CGPoint point;
        if (sender == nil) {
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                point = _imageQuestion.center;
            } else {
                point = _imageAnswer.center;
            }
        }else {
            point = CGPointMake(CGRectGetWidth(sender.frame)/2, 2);
            point = [sender convertPoint:point toView:self];
        }
        
        
        
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        
        if (_imagePickerPopover != nil) {
            [_imagePickerPopover dismissPopoverAnimated:YES];
            _imagePickerPopover=nil;
        }
        
        _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_imagePickerController];
        _imagePickerPopover.delegate = self;
        if (isArrowUp) {
            [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        } else {
            [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        }
        
    }
    
}



- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [iConsole info:@"%s",__FUNCTION__];
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.movie"]){
        
        
        
        NSURL *movieURL = [info objectForKey:UIImagePickerControllerMediaURL];
        [iConsole info:@"found a movie %@", movieURL];
        
        //check video lenght
        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
        CMTime duration = sourceAsset.duration;
        float seconds = CMTimeGetSeconds(duration);
        if (seconds > 30) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Max 30 seconds of video duration is support" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
        
        
        //save movie info
        NSString *destPath;
        if (_imageSourceType == Type_Image_Source_Image) {
            
            if (_segmentedControl.selectedSegmentIndex == 0) {
                if ([_questionMovieFullPath rangeOfString:@".3gp"].location != NSNotFound) {
                    NSError *error = nil;
                    if (![[NSFileManager defaultManager] removeItemAtPath:_questionMovieFullPath
                                                                    error:&error])
                    {
                        [iConsole info:@"[Error] %@ (%@)", error, _questionMovieFullPath];
                    }
                    destPath = _questionMovieFullPath;
                } else {
                    _questionMovieFullPath = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                    destPath = _questionMovieFullPath;
                }
                
            } else {
                
                if ([_answerMovieFullPath rangeOfString:@".3gp"].location != NSNotFound) {
                    NSError *error = nil;
                    if (![[NSFileManager defaultManager] removeItemAtPath:_answerMovieFullPath
                                                                    error:&error])
                    {
                        [iConsole info:@"[Error] %@ (%@)", error, _answerMovieFullPath];
                    }
                    destPath = _answerMovieFullPath;
                } else {
                    _answerMovieFullPath = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                    destPath = _answerMovieFullPath;
                }
            }
        } else {
            if (_segmentedControl.selectedSegmentIndex == 0) {
                if ([_questionMovieFullPath2 rangeOfString:@".3gp"].location != NSNotFound) {
                    NSError *error = nil;
                    if (![[NSFileManager defaultManager] removeItemAtPath:_questionMovieFullPath2
                                                                    error:&error])
                    {
                        [iConsole info:@"[Error] %@ (%@)", error, _questionMovieFullPath2];
                    }
                    destPath = _questionMovieFullPath2;
                } else {
                    _questionMovieFullPath2 = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                    destPath = _questionMovieFullPath2;
                }
                
                
            } else {
                if ([_answerMovieFullPath2 rangeOfString:@".3gp"].location != NSNotFound) {
                    NSError *error = nil;
                    if (![[NSFileManager defaultManager] removeItemAtPath:_answerMovieFullPath2
                                                                    error:&error])
                    {
                        [iConsole info:@"[Error] %@ (%@)", error, _answerMovieFullPath2];
                    }
                    destPath = _answerMovieFullPath2;
                } else {
                    _answerMovieFullPath2 = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                    destPath = _answerMovieFullPath2;
                }
            }
        }
        
        if (destPath) {
            AVAsset *video = [AVAsset assetWithURL:movieURL];
            AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:video presetName:AVAssetExportPresetPassthrough];
            exportSession.shouldOptimizeForNetworkUse = YES;
            exportSession.outputFileType = AVFileType3GPP;
            exportSession.outputURL = [NSURL fileURLWithPath:destPath];
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                
                //check file size for test purpose
                NSDictionary *fileDictionary = [[NSFileManager defaultManager] fileAttributesAtPath:destPath traverseLink:YES];
                long fileSize = [fileDictionary fileSize];
                [iConsole info:@"%s:Done and converted 3gp size is:%ld",__FUNCTION__,fileSize];
                
            }];
        }
        
        
        //save thumbnail info
        [self thumbnailImageFromURL:[info objectForKey:@"UIImagePickerControllerMediaURL"] withImageSource:_imageSourceType];
        
        
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
            if ([Common isDefaultPath:_logoImageFullPath]) {
                _logoImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            }
            
            [imageData writeToFile:_logoImageFullPath atomically:YES];
            _logoImage.image = [UIImage imageWithData:imageData];
            
            _currentCard.question.logoFullPath = _logoImageFullPath;
            if (isFromNewCreatedCard) {
                //we don't do save operation now but need to tell to save all cards' logo when we click "save button"
                _isAllCardsLogoNeedToBeUpdate = YES;
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
                if ([Common isDefaultPath:_questionImageFullPath]) {
                    _questionImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
                }
                [imageData writeToFile:_questionImageFullPath atomically:YES];
                _imageQuestion.image = [UIImage imageWithData:imageData];
            } else {
                if ([Common isDefaultPath:_answerImageFullPath]) {
                    _answerImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
                }
                [imageData writeToFile:_answerImageFullPath atomically:YES];
                _imageAnswer.image = [UIImage imageWithData:imageData];
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
                if ([Common isDefaultPath:_questionImageFullPath2]) {
                    _questionImageFullPath2 = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
                }
                [imageData writeToFile:_questionImageFullPath2 atomically:YES];
                _imageQuestion2.image = [UIImage imageWithData:imageData];
            } else {
                if ([Common isDefaultPath:_answerImageFullPath2]) {
                    _answerImageFullPath2 = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
                }
                [imageData writeToFile:_answerImageFullPath2 atomically:YES];
                _imageAnswer2.image = [UIImage imageWithData:imageData];
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
    
    
    BOOL isEditable = [self checkCardEditable];
    if (isEditable == YES) {
        [self disableCardEdit];
        _segmentedControl.hidden = YES;
        
        if ((_currentCard.question.logoFullPath.length == 0) || ([_currentCard.question.logoFullPath rangeOfString:@"placeholder"].location != NSNotFound)) {
            _logoImage.hidden = true;
        } else {
            _logoImage.hidden = false;
        }
        
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
    }
    
    if (switchSegment == YES) {
        _segmentedControl.selectedSegmentIndex = 1;
        [self refreshAll];
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
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Symbol could possibly not be supported by selected font,when considering to be used on Android platform" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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
    
    int index = ((UIButton *) sender).tag;
    
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
    static int tag = -1;
    
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
    CGFloat gap;  //
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
    
    [self adjustFontToFit:textView];
    
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
            [Common alertViewCommon:@"Please set your mail address!"];
        }
        
        
    } else {
        [Common alertViewCommon:@"Incorrect URL or Email format"];
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
 *  用于根据textview的frame，进行自动调节:
 *  结果不写入数据库，也就是说切换一个pack，就需要重新执行。这主要是考虑到写入数据库的严重性。
 *  1. 如果字体太小导致行数不一致，则进行字体增加措施，是的行数一致
 *  2. 如果字体太大，导致无法显示，则缩小字体
 *  返回true,表示执行了；false，表示没有任何调节
 */
- (BOOL) adjustAllTextViewsToFitIfNecessary {
    [iConsole info:@"%s",__FUNCTION__];
    BOOL result = NO;
    
    int i = 0;
    int kMax = 40;
    int lineNumber;
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        
        if (_currentCard.question.autoresizeFlag == 1) { //1表示允许
            i = 0;
            
            //行数不一致时，增大字体
            lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
            while ((_currentCard.question.lineNoSubheading > lineNumber) && (_currentCard.question.lineNoSubheading != 0) && (i<kMax) && (lineNumber > 0)) {
                [_subheadingQuestion setFont:[_subheadingQuestion.font fontWithSize:(_subheadingQuestion.font.pointSize *1.1)]];
                lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
                //[iConsole info:@"%s:_currentCard.question.lineNoSubheading= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSubheading,lineNumber];
                i++;
                usleep(5000);
            }
            
            i = 0;
            
            //行数不一致时，增大字体
            lineNumber = [self lineNumberWithUITextView:_mainQuestion];
            while ((_currentCard.question.lineNoMain > lineNumber) && (_currentCard.question.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_mainQuestion setFont:[_mainQuestion.font fontWithSize:(_mainQuestion.font.pointSize *1.1)]];
                lineNumber = [self lineNumberWithUITextView:_mainQuestion];
                //[iConsole info:@"%s:_currentCard.question.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoMain,lineNumber];
                i++;
                usleep(5000);
            }
            
            //行数不一致时，增大字体
            i = 0;
            lineNumber = [self lineNumberWithUITextView:_subQuestion];
            while ((_currentCard.question.lineNoSub > lineNumber)&& (_currentCard.question.lineNoSub >= 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_subQuestion setFont:[_subQuestion.font fontWithSize:(_subQuestion.font.pointSize *1.1)]];
                lineNumber = [self lineNumberWithUITextView:_subQuestion];
                //[iConsole info:@"%s:_currentCard.question.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSub,lineNumber];
                i++;
                usleep(5000);
            }
        }
        
        if ([self adjustFontToFit:_subheadingQuestion]){
            result= YES;
        }
        if ([self adjustFontToFit:_mainQuestion]){
            
            result= YES;
        }
        if ([self adjustFontToFit:_subQuestion]){
            result= YES;
        }
        
        
        //这时，有有可能导致行数变小，这时需要重新微调
        if (true) {
            i = 0;
            
            //减少字体大小
            lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
            while ((_currentCard.question.lineNoSubheading < lineNumber) && (_currentCard.question.lineNoSubheading != 0) && (i<kMax) && (lineNumber > 0)) {
                [_subheadingQuestion setFont:[_subheadingQuestion.font fontWithSize:(_subheadingQuestion.font.pointSize -0.3)]];
                lineNumber = [self lineNumberWithUITextView:_subheadingQuestion];
                //[iConsole info:@"%s:_currentCard.question.lineNoSubheading= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSubheading,lineNumber];
                i++;
                usleep(5000);
            }
            
            i = 0;
            
            //减少字体大小
            lineNumber = [self lineNumberWithUITextView:_mainQuestion];
            while ((_currentCard.question.lineNoMain < lineNumber) && (_currentCard.question.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_mainQuestion setFont:[_mainQuestion.font fontWithSize:(_mainQuestion.font.pointSize -0.3)]];
                lineNumber = [self lineNumberWithUITextView:_mainQuestion];
                //[iConsole info:@"%s:_currentCard.question.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoMain,lineNumber];
                i++;
                usleep(5000);
            }
            
            
            i = 0;
            
            //减少字体大小
            lineNumber = [self lineNumberWithUITextView:_subQuestion];
            while ((_currentCard.question.lineNoSub < lineNumber)&& (_currentCard.question.lineNoSub >= 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_subQuestion setFont:[_subQuestion.font fontWithSize:(_subQuestion.font.pointSize -0.3)]];
                lineNumber = [self lineNumberWithUITextView:_subQuestion];
                //[iConsole info:@"%s:_currentCard.question.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSub,lineNumber];
                i++;
                usleep(5000);
            }
        }
        
        
        //这样下次就不会进行autoresize操作了 （除非切换到另外一个pack或fore to restart。此autoresizeFlag字段不会写入数据库）
        if (result == YES) {
            _currentCard.question.autoresizeFlag = 0;
        }
        
        
        
        
    } else {
        
        if (_currentCard.answer.autoresizeFlag == 1) { //1表示允许
            
            i = 0;
            //行数不一致时，增大字体
            lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
            while ((_currentCard.answer.lineNoSubheading > lineNumber)&& (_currentCard.answer.lineNoSubheading != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_subheadingAnswer setFont:[_subheadingAnswer.font fontWithSize:(_subheadingAnswer.font.pointSize*1.1)]];
                lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
                //[iConsole info:@"%s:_currentCard.answer.lineNoSubheading = %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSubheading ,lineNumber];
                i++;
                usleep(5000);
            }
            
            i = 0;
            //行数不一致时，增大字体
            lineNumber = [self lineNumberWithUITextView:_mainAnswer];
            while ((_currentCard.answer.lineNoMain > lineNumber)&& (_currentCard.answer.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_mainAnswer setFont:[_mainAnswer.font fontWithSize:(_mainAnswer.font.pointSize*1.1)]];
                lineNumber = [self lineNumberWithUITextView:_mainAnswer];
                //[iConsole info:@"%s:_currentCard.answer.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoMain,lineNumber];
                i++;
                usleep(5000);
            }
            
            i = 0;
            //行数不一致时，增大字体
            lineNumber = [self lineNumberWithUITextView:_subAnswer];
            while ((_currentCard.answer.lineNoSub > lineNumber)&& (_currentCard.answer.lineNoSub != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_subAnswer setFont:[_subAnswer.font fontWithSize:(_subAnswer.font.pointSize*1.1)]];
                lineNumber = [self lineNumberWithUITextView:_subAnswer];
                //[iConsole info:@"%s:_currentCard.answer.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSub,lineNumber];
                i++;
                usleep(5000);
            }
        }
        
        if ([self adjustFontToFit:_subheadingAnswer]){
            result= YES;
        }
        if ([self adjustFontToFit:_mainAnswer]){
            result= YES;
        }
        if ([self adjustFontToFit:_subAnswer]){
            result= YES;
        }
        
        if (true) { //adjustFontToFit会有可能导致行数变小，这时需要微调
            
            i = 0;
            //减少字体大小
            lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
            while ((_currentCard.answer.lineNoSubheading < lineNumber)&& (_currentCard.answer.lineNoSubheading != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_subheadingAnswer setFont:[_subheadingAnswer.font fontWithSize:(_subheadingAnswer.font.pointSize - 0.3)]];
                lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
                //[iConsole info:@"%s:_currentCard.answer.lineNoSubheading = %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSubheading ,lineNumber];
                i++;
                usleep(5000);
            }
            
            i = 0;
            //减少字体大小
            lineNumber = [self lineNumberWithUITextView:_mainAnswer];
            while ((_currentCard.answer.lineNoMain < lineNumber)&& (_currentCard.answer.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_mainAnswer setFont:[_mainAnswer.font fontWithSize:(_mainAnswer.font.pointSize - 0.3)]];
                lineNumber = [self lineNumberWithUITextView:_mainAnswer];
                //[iConsole info:@"%s:_currentCard.answer.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoMain,lineNumber];
                i++;
                usleep(5000);
            }
            
            i = 0;
            //减少字体大小
            lineNumber = [self lineNumberWithUITextView:_subAnswer];
            while ((_currentCard.answer.lineNoSub < lineNumber)&& (_currentCard.answer.lineNoSub != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_subAnswer setFont:[_subAnswer.font fontWithSize:(_subAnswer.font.pointSize - 0.3)]];
                lineNumber = [self lineNumberWithUITextView:_subAnswer];
                //[iConsole info:@"%s:_currentCard.answer.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSub,lineNumber];
                i++;
                usleep(5000);
            }
        }
        
        
        //这样下次就不会进行autoresize操作了。除非切换到另外一个pack或fore to restart。此autoresizeFlag字段不会写入数据库）
        if (result == YES) {
            _currentCard.answer.autoresizeFlag = 0;
        }
    }
    
    
    return result;
}

/**
 *  获取textview中文字高度，而不是frame的高度，这是迄今位置，最靠谱的做法
 */
- (float) getTextSizeHeight:(UITextView *) textView{
    [iConsole info:@"%s",__FUNCTION__];
    CGSize tallerSize = CGSizeMake(textView.frame.size.width-16,999); //左右边间距为8,还要注意，高度要足够，否则会错误
    CGSize stringSize;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        stringSize = [textView.text sizeWithFont:textView.font constrainedToSize:tallerSize lineBreakMode:NSLineBreakByWordWrapping];
    } else {
        stringSize = [textView.text sizeWithFont:textView.font constrainedToSize:tallerSize lineBreakMode:UILineBreakModeWordWrap];
    }
    
    
    CGFloat textHeight = stringSize.height; //textView.contentSize.height不准确
    return textHeight;
}


/**
 *  当字体太大时，自动调整font size以适合textView frame]。同时为了不让字体过小，也设置了下限
 *  有几个前提条件（同时满足下）触发这个方法
 *  1. 必须是不可编辑的卡片
 *  2. textview必须有内容
 *  3. 文字高度超出了[textView frame]。当文字很小，导致高度很小时，我们不作调整，而是默认为10号字体
 */
- (BOOL) adjustFontToFit:(UITextView *) textView {
    [iConsole info:@"%s",__FUNCTION__];
    BOOL result = NO;
    
    //we don't do this in edit mode
    if ([_currentPack.creator isEqualToString:[OpenUDID value]]) {
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
    
    //确保top margin和bottom margin足够，所以用一个经验值代替frameHeight/5
    while ((textHeight > frameHeight - frameHeight/5)&&(textHeight >0)&&(textView.font.pointSize >0)) {
        outputFlag = TRUE;
        result = YES;
        
        if (textView.font.pointSize <=gate) {
            //字体越小，size变化越明显
            [iConsole warn:@"%s:......textView.font.pointSize <gate:%@",__FUNCTION__,textView.text];
            break;
        }
        float factor = 1.0;
        if (textView.font.pointSize < 10.0) {
            factor = 0.25;
        }
        if (textView.font.pointSize < 12.0) {
            factor = 0.5;
        }
        
        [textView setFont:[textView.font fontWithSize:(textView.font.pointSize -factor)]];
        [textView layoutSubviews];
        usleep(5000);
        textHeight = [self getTextSizeHeight:textView];
        
    }
    
    
    //必须把auto resize的最终字体大小限制在离散值内
    //_keyboardTopViewV2和_keyboardTopViewForInputViewV2返回一样的sizeArray，任取一都可以
    int index = [Common nearestIndexForStringArray:_keyboardTopViewV2.realSizeArray withElement:textView.font.pointSize];
    if (index == - 1) {
        [iConsole error:@"%s:return - 1 when execut [Common nearestIndexForStringArray:_keyboardTopViewV2.realSizeArray withElement:textView.font.pointSize]",__FUNCTION__];
    } else {
        [textView.font fontWithSize:[[_keyboardTopViewV2.realSizeArray objectAtIndex:index] integerValue]];
    }
    
    
    if (outputFlag) {
        [iConsole info:@"CardSN %d:text(%@).\n---Original value: height(%f), font size(%f);\n---Final value:height(%f), font size(%f)",_currentCard.cardSN,textView.text,originalTextHeight, orginalFontSize,textView.contentSize.height, textView.font.pointSize];
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
        if ([Common isDefaultPath:_currentCard.coverImageURL]) {
            NSString *savedFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
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
    
    //Update all cards logo image if possible (only applicable when creating new card)
    if (_isAllCardsLogoNeedToBeUpdate == YES) {
        [self updatelogoImageForAllCards:_logoImageFullPath];
        _isAllCardsLogoNeedToBeUpdate = NO;
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


/**
 *  Record or play
 *
 *  @param sender <#sender description#>
 */
- (void) soundRecordButtonClicked:(id)sender {
    [iConsole info:@"%s",__FUNCTION__];
    
    if ([_currentCard.creator isEqualToString:[OpenUDID value]]) {
        
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
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Audio play is only supported in play mode." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
}


- (void) changeTemplateButtonClick:(id)sender {
    [iConsole info:@"%s",__FUNCTION__];
    
    if ([_currentCard.creator isEqualToString:[OpenUDID value]] == FALSE) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"You can only edit card that you have created it." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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
    
    [iConsole info:@"%s,tag = %d,selected templateID = %@",__FUNCTION__,self.tag, templateIDString];
    
    [self updateQuestionOrAnswerTemplate];//we will do other side's update when clicking segment
    
    // we put all the save operations only when click the "save button"
    if (!isFromNewCreatedCard) {
        [self saveEdittedCard];
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    } else {
        [self commitQuestionAndAnswerData];
    }
    
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
            pickerImageView = _imageQuestion;
        } else {
            pickerImageView = _imageAnswer;
        }
    } else if (imageSoucrType == Type_Image_Source_Image2) {
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            pickerImageView = _imageQuestion2;
        } else {
            pickerImageView = _imageAnswer2;
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error on thumbnailImageFromURL" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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
    
    UIImage *playImage = [UIImage imageNamed:@"play"];
    
    UIGraphicsBeginImageContext(thumbnail.size);
    [thumbnail drawInRect:CGRectMake(0, 0, thumbnail.size.width, thumbnail.size.height)];
    
    [playImage drawInRect:CGRectMake(thumbnail.size.width *0.4, thumbnail.size.height *0.4, thumbnail.size.width *0.2, thumbnail.size.width *0.2)];
    UIImage *compositeThumbNail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (imageSoucrType == Type_Image_Source_Image) {
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if ([Common isDefaultPath:_questionImageFullPath]) {
                _questionImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            }
            [UIImagePNGRepresentation(compositeThumbNail) writeToFile:_questionImageFullPath atomically:YES];
            _imageQuestion.image = compositeThumbNail;
        } else {
            if ([Common isDefaultPath:_answerImageFullPath]) {
                _answerImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            }
            [UIImagePNGRepresentation(compositeThumbNail) writeToFile:_answerImageFullPath atomically:YES];
            _imageAnswer.image = compositeThumbNail;
        }
    } else if (imageSoucrType == Type_Image_Source_Image2) {
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if ([Common isDefaultPath:_questionImageFullPath2]) {
                _questionImageFullPath2 = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            }
            [UIImagePNGRepresentation(compositeThumbNail) writeToFile:_questionImageFullPath2 atomically:YES];
            _imageQuestion2.image = compositeThumbNail;
        } else {
            if ([Common isDefaultPath:_answerImageFullPath2]) {
                _answerImageFullPath2 = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            }
            [UIImagePNGRepresentation(compositeThumbNail) writeToFile:_answerImageFullPath2 atomically:YES];
            _imageAnswer2.image = compositeThumbNail;
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error on thumbnailImageFromURL2" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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
            if ([Common isDefaultPath:card.coverImageURL]) {
                NSString *savedFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
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
    
    int  location =_lastBecomeFirstRespondTextView.selectedRange.location;
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
        
        int symbolLength = insertVal.length;
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
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Invalid YouTube url, it must be a full url - for example: http://www.youtube.com/watch?v=3-EaGGPGiJY" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Invalid YouTube url, it must be a full url - for example: http://www.youtube.com/watch?v=3-EaGGPGiJY" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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

#pragma mark – PopoverviewDelegate

/**
 *  两种情况：
 *  1. 点击image
 *  2. 点击_backgroundImageSelectButton
 */
- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
    [iConsole info:@"%s",__FUNCTION__];
    
    Type_PopoverView sourceType = popoverView.tag;
    
    if (sourceType == Type_PopoverView_SelectImage) {
        [popoverView dismiss];
        
        if (index == 1) {
            [self selectImageOrVideoFromLibraryWithImageType:sourceType];
        } else if (index == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your YouTube url"
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
            
        } else if (index == 2) {
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                
                BOOL isToSetImageViewEmpty = false;
                
                if (([_questionImageFullPath rangeOfString:@"placeholder"].location == NSNotFound) &&
                    (_questionImageFullPath.length > 0)) {
                    NSError *error = nil;
                    if (![[NSFileManager defaultManager] removeItemAtPath:_questionImageFullPath
                                                                    error:&error])
                    {
                        NSLog(@"[Error] %@ (%@)", error, _questionImageFullPath);
                    } else {
                        isToSetImageViewEmpty = YES;
                    }
                    
                    
                }
                
                if (([_questionMovieFullPath rangeOfString:@"placeholder"].location == NSNotFound) &&
                    (_questionMovieFullPath.length > 0)) {
                    NSError *error = nil;
                    if (![[NSFileManager defaultManager] removeItemAtPath:_questionMovieFullPath
                                                                    error:&error])
                    {
                        NSLog(@"[Error] %@ (%@)", error, _questionMovieFullPath);
                    } else {
                        isToSetImageViewEmpty = YES;
                    }
                }
                
                if (isToSetImageViewEmpty) {
                    _questionImageFullPath = @"";
                    _questionMovieFullPath = @"";
                    
                    _currentCard.question.movieFullPath = @"";
                    _currentCard.question.imageFullPath = @"";
                    [_imageQuestion setImage:[UIImage imageNamed:@"question_placeholder_content"]];
                } else {
                    [iConsole info:@"%s: delete is ignored since empty or default image",__FUNCTION__];
                }
                
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
                [_imageAnswer setImage:[UIImage imageNamed:@"answer_placeholder_content"]];
            }
            if (isFromNewCreatedCard == FALSE) {
                [self saveEdittedCard];
            }
        }
    }  else if (sourceType == Type_PopoverView_SelectImage2) {
        [popoverView dismiss];
        
        if (index == 1) {
            [self selectImageOrVideoFromLibraryWithImageType:sourceType];
        } else if (index == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your YouTube url"
                                                            message:nil
                                                           delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                                  otherButtonTitles:NSLocalizedString(@"Keyboard_Cancel",@""), nil];
            alert.tag = Type_AlertView_VideoURL2;
            [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
            [alert textFieldAtIndex:0].text = @"";
            [alert textFieldAtIndex:0].placeholder = @"http://www.youtube.com/";
            alert.delegate = self;
            [alert show];
        } else if (index == 2) {
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
                
                [_imageQuestion2 setImage:[UIImage imageNamed:@"question_placeholder_content"]];
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
                [_imageAnswer2 setImage:[UIImage imageNamed:@"answer_placeholder_content"]];
            }
            if (isFromNewCreatedCard == FALSE) {
                [self saveEdittedCard];
            }
        }
    }else {
        //change card background
        [popoverView dismiss];
        if (index == 0) {
            
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
            
            
            
        } else if (index == 1) {
            _imageSourceType = Type_Image_Source_Background;
            [self selectFromImageLibrary:_backgroundImageSelectButton withPopoverArrowUp:NO  supportMov:NO];
        } else if (index == 2) {
            
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
        AVSpeechUtterance *utterance = [AVSpeechUtterance
                                        speechUtteranceWithString:_textToSpeechArray[0]];
        utterance.rate = 0.02;
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
        AVSpeechUtterance *utterance = [AVSpeechUtterance
                                        speechUtteranceWithString:_textToSpeechArray[self.textToSpeechContentArrayIndex]];
        utterance.rate = 0.02;
        
        //utterance.postUtteranceDelay = 0.3;
        
        if ([_textToSpeechArray count] > 0) {
            [self.synth speakUtterance:utterance];
        } else {
            [self.synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        }
        
    } else {
        //[self playAudio];
    }
    
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    [iConsole info:@"%s",__FUNCTION__];
}


- (NSMutableArray *) textToSpeechContentArray  {
    NSMutableArray *myArray = [NSMutableArray array];
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        if ((_subheadingQuestion.text.length >0) && (_subheadingQuestion.hidden == NO)) {
            
            [myArray addObjectsFromArray:[self replaceBasicSymbol:_subheadingQuestion.text]];
        }
        
        if ((_mainQuestion.text.length >0)&& (_mainQuestion.hidden == NO)) {
            [myArray addObjectsFromArray:[self replaceBasicSymbol:_mainQuestion.text]];
        }
        
        if ((_subQuestion.text.length >0)&& (_subQuestion.hidden == NO)) {
            [myArray addObjectsFromArray:[self replaceBasicSymbol:_subQuestion.text]];
        }
    } else {
        if ((_subheadingAnswer.text.length >0)&& (_subheadingAnswer.hidden == NO)) {
            [myArray addObjectsFromArray:[self replaceBasicSymbol:_subheadingAnswer.text]];
        }
        
        if ((_mainAnswer.text.length >0)&& (_mainAnswer.hidden == NO)) {
            [myArray addObjectsFromArray:[self replaceBasicSymbol:_mainAnswer.text]];
        }
        
        if ((_subAnswer.text.length >0)&& (_subAnswer.hidden == NO)) {
            [myArray addObjectsFromArray:[self replaceBasicSymbol:_subAnswer.text]];
        }
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

/**
 *  当选择了“vertical alignment”会执行这个
 */
- (void) setVerticalAlignment:(UITextView *) textView {
    
    if (textView == nil) {
        return;
    }
    
    CGFloat topCorrect = ([textView bounds].size.height - [textView contentSize].height * [textView zoomScale])/2.0;
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
    
    UITextView *tv = object;
    
    if ([self isVerticalAlignment:tv]) {
        CGFloat topCorrect = ([tv bounds].size.height - [tv contentSize].height * [tv zoomScale])  / 2.0;
        topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
        tv.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
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

- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedSaveButton:(id)sender {
    [self dismissKeyBoard:sender];
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
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Symbol",@"")] || [title isEqualToString:NSLocalizedString(@"ToolbarItem_Keyboard",@"")]){
        [self symbolAndKeyboardSwitch:sender];
    } else {
        //do nothing
    }
    
}

#pragma mark - PECropViewControllerDelegate methods

- (void)cropViewController:(PECropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage
{
    float downScaleWidth = CGRectGetWidth(_questionBackgroundImageView.frame);
    float downScaleHeight = CGRectGetHeight(_questionBackgroundImageView.frame);
    
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    
    NSData *imageData = UIImageJPEGRepresentation([croppedImage scaleToSize:CGSizeMake(downScaleWidth *screenScale, downScaleHeight * screenScale)], kJPEGQualityFactor);
    
    [controller dismissViewControllerAnimated:YES completion:NULL];
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        if ([Common isDefaultPath:_questionBackgroundImageFullPath]) {
            _questionBackgroundImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
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
        if ([Common isDefaultPath:_answerBackgroundImageFullPath]) {
            _answerBackgroundImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
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


#pragma mark -
#pragma mark - Memory management

- (void)dealloc {
    [iConsole info:@"%s,tag = %d,question main = %@",__FUNCTION__,self.tag,_mainQuestion.text];
    
    _synth = nil;
    
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
    CGRect recLinkButton = [_logoLinkageButton  convertRect:CGRectMake(CGRectGetWidth(_logoLinkageButton.frame)/3, CGRectGetHeight(_logoLinkageButton.frame)/4, 0, 0) toView:self];
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



@end
