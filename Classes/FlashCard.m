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
#import "Common.h"
#import <AVFoundation/AVFoundation.h>

#import "CreateSoundViewController.h"

#import "OpenUDID.h"
#import "Common.h"

extern BOOL isFromNewCreatedCard;

#define kSegmentLeftMarginForiPad 0.0
#define kSegmentHeightForiPad 44.0
#define kSegmentButtomMarginForiPad 10.0
#define kQuestionViewTopMarginForiPad 10.0
#define kQuestionViewButtomMarginForiPad 80.0
#define kQuestionViewCornerRadiusForiPad 20.0

#define kSegmentLeftMarginForiPhone 0.0
#define kSegmentHeightForiPhone 28.0
#define kSegmentButtomMarginForiPhone 10.0
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
#define kTagJobTitle               305

#define KEYBOARD_ANIMATION_DURATION 0.25

typedef NS_ENUM(NSInteger, Type_Image_Selector) {
    Type_Image_Selector_Logo       = 0,//when clicking the logo
    Type_Image_Selector_Image      = 1,//when clicking the image from card
    Type_Image_Selector_Background = 2,//when trying to change card's background image (not template)
    Type_Image_Selector_Unkown     = -1,
};

typedef NS_ENUM(NSInteger, Type_AlertView) {
    Type_AlertView_Unkown   = -1,
    Type_AlertView_LogoURL  = 0,
    Type_AlertView_VideoURL = 1,
};

typedef NS_ENUM(NSInteger, Type_PopoverView) {
    Type_PopoverView_Unkown           = -1,
    Type_PopoverView_SelectImage      = 1,
    Type_PopoverView_SelectBackground = 2,
};

@interface FlashCard () {
    Type_Image_Selector    _typeImageSelector;
    AVAudioPlayer          *_audioPlayer;
}

@property (strong, nonatomic) UIButton *soundButton;


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
        
        if ((card == nil) || (pack == nil)) {
            //DDLogInfo(@"%s:Check your code, it could be possiblly an issue",__FUNCTION__);
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
        
    }

    
    return self;
}


- (void) initDefaultValue {
    DDLogInfo(@"%s",__FUNCTION__);
    _isUITextViewFocused = NO;
    
    _isAllCardsLogoNeedToBeUpdate = NO;
    _isTextFieldsChanged = NO;
    _doneButtonPressed = NO;
    _templateBackgroundImageName = @"card_background_blue.png";
    _logoLinkURL = @"http://www.";
    _logoImageFullPath = @"";
    
    _subheadingSizeQuestion = 40;
    _subheadingColorQuestion = @"Black";
    _subheadingAlignQuestion = @"Right";
    _mainSizeQuestion = 40;
    _mainColorQuestion = @"Black";
    _mainAlignQuestion = @"Center";
    _subSizeQuestion = 40;
    _subColorQuestion = @"Black";
    _subAlignQuestion = @"Center";
    
    _subheadingSizeAnswer = 40;
    _subheadingColorAnswer = @"Black";
    _subheadingAlignAnswer = @"Right";
    _mainSizeAnswer = 40;
    _mainColorAnswer = @"Black";
    _mainAlignAnswer = @"Center";
    _subSizeAnswer = 40;
    _subColorAnswer = @"Black";
    _subAlignAnswer = @"Center";
    
    _keyboardShown = FALSE;
    
    //background image
    _questionBackgroundImageFullPath = @"";
    _answerBackgroundImageFullPath = @"";
    
    //movie or video
    _answerMovieFullPath = @"";
    _questionMovieFullPath = @"";
    
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
    DDLogInfo(@"%s",__FUNCTION__);
    if (_templateBackgroundImageView == nil) {
        _templateBackgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:_templateBackgroundImageName]];
        _templateBackgroundImageView.contentMode = UIViewContentModeScaleToFill;
        _templateBackgroundImageView.frame = CGRectMake(0, 0, 800, 550);
        _templateBackgroundImageView.backgroundColor = [UIColor clearColor];
        _templateBackgroundImageView.userInteractionEnabled = NO;
        _templateBackgroundImageView.layer.masksToBounds = YES;
        _templateBackgroundImageView.layer.cornerRadius = 35;
        [self addSubview:_templateBackgroundImageView];
    }
    
    
    if (_questionBackgroundImageView == nil) {
        _questionBackgroundImageView = [[UIImageView alloc] init];
        _questionBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _questionBackgroundImageView.frame = CGRectMake(41, 112, CGRectGetWidth(_templateBackgroundImageView.frame) - 41, CGRectGetHeight(_templateBackgroundImageView.frame) - 112);
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
        _answerBackgroundImageView.frame = CGRectMake(41, 112, CGRectGetWidth(_templateBackgroundImageView.frame) - 41, CGRectGetHeight(_templateBackgroundImageView.frame) - 112);;
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
    
    _imageAnswer.hidden = YES;
    
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
        [_segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
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
        
        UIImageView *upImageView = [[UIImageView  alloc] init];
        [upImageView setImage:[UIImage imageNamed:@"upButton"]];
        upImageView.contentMode = UIViewContentModeScaleAspectFit;
        upImageView.frame = CGRectMake(720-7, 110-18.75-5, 15, 18.75);
        upImageView.clipsToBounds = YES;
        upImageView.backgroundColor = [UIColor clearColor];
        upImageView.userInteractionEnabled = NO;
        [self addSubview:upImageView];

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
        des.frame = CGRectMake(510, 35, 90, 20);
        des.textAlignment = NSTextAlignmentLeft;
        des.backgroundColor = [UIColor clearColor];
        des.font = [UIFont systemFontOfSize:12];
        des.textColor = [UIColor grayColor];
        des.text = @"Created by:";
        des.userInteractionEnabled = FALSE;
        [self addSubview:des];
        
        
        _creatorText = [[UITextField alloc] init];
        _creatorText.frame = CGRectMake(510, 60, 90, 20);
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
        _jobTitleText.frame = CGRectMake(510, 85, 90, 20);
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
        [_soundButton setImage:[UIImage imageNamed:@"record_button"] forState:UIControlStateNormal];
        [_soundButton addTarget:self action:@selector(soundRecordButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _soundButton.backgroundColor = [UIColor clearColor];
        _soundButton.showsTouchWhenHighlighted = YES;
        [_functionAreaView addSubview:_soundButton];
    }
    
    if (_backgroundImageSelectButton == nil) {
        _backgroundImageSelectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backgroundImageSelectButton.showsTouchWhenHighlighted = YES;
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
        _changeTemplateButton.showsTouchWhenHighlighted = YES;
        [_changeTemplateButton setImage:[UIImage imageNamed:@"change_card_layout_template"] forState:UIControlStateNormal];
        [_functionAreaView addSubview:_changeTemplateButton];
        [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
        _changeTemplateButton.showsTouchWhenHighlighted = YES;
    }
    
    if (_isPlayingCard) {
        
        _functionAreaView.backgroundColor = [UIColor clearColor];
        _functionAreaView.layer.borderWidth = 0;
        
        _changeTemplateButton.hidden = YES;
        _backgroundImageSelectButton.hidden = YES;
        [_soundButton setImage:[UIImage imageNamed:@"play_recorded_sound_button_bigger"] forState:UIControlStateNormal];
        _functionAreaView.frame = CGRectMake(self.bounds.size.width - 50, CGRectGetMinY(_segmentedControl.frame), 50, 50);
        _soundButton.frame = CGRectMake(5, 5, 40, 40);
        
    }
    
    //------- end _functionAreaView

}


- (void) loadQuestionAnswerViewForiPhone {
    DDLogInfo(@"%s",__FUNCTION__);
    if (_templateBackgroundImageView == nil) {
        _templateBackgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:_templateBackgroundImageName]];
        _templateBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _templateBackgroundImageView.backgroundColor = [UIColor clearColor];
        _templateBackgroundImageView.frame = CGRectMake(0, 0, kFlashCardViewWidth_Detail_iPhone, kFlashCardViewHeight_Detail_iPhone);
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
        _questionBackgroundImageView.frame = CGRectMake(31, 38, CGRectGetWidth(_templateBackgroundImageView.frame) - 31, CGRectGetHeight(_templateBackgroundImageView.frame) - 38);;
        _questionBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _questionBackgroundImageView.backgroundColor = [UIColor whiteColor];
        _questionBackgroundImageView.userInteractionEnabled = NO;
        _questionBackgroundImageView.layer.masksToBounds = YES;
        CAShapeLayer * maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: _questionBackgroundImageView.bounds byRoundingCorners: UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: (CGSize){15, 15.}].CGPath;
        _questionBackgroundImageView.layer.mask = maskLayer;
        [self addSubview:_questionBackgroundImageView];
        [self bringSubviewToFront:_templateBackgroundImageView];
    }
    
    if (_answerBackgroundImageView == nil) {
        _answerBackgroundImageView = [[UIImageView alloc] init];
        _answerBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _answerBackgroundImageView.frame = CGRectMake(31, 38, CGRectGetWidth(_templateBackgroundImageView.frame) - 31, CGRectGetHeight(_templateBackgroundImageView.frame) - 38);
        _answerBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _answerBackgroundImageView.backgroundColor = [UIColor whiteColor];
        _answerBackgroundImageView.userInteractionEnabled = NO;
        _answerBackgroundImageView.layer.masksToBounds = YES;
        CAShapeLayer * maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: _answerBackgroundImageView.bounds byRoundingCorners: UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: (CGSize){15, 15.}].CGPath;
        _answerBackgroundImageView.layer.mask = maskLayer;
        [self addSubview:_answerBackgroundImageView];
        [self bringSubviewToFront:_templateBackgroundImageView];
    }
    
    
    if (_questionTitle == nil) {
        _questionTitle = [[UITextField alloc]init];
        _questionTitle.frame = CGRectMake(40, 15, 200, 23);
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
        _answerTitle.frame = CGRectMake(40, 15, 200, 23);
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
        _verticalScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(30, 40, 370, 195)];
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
        _sidebarTitle.frame = CGRectMake(0, 0, 200, 30);
        [_sidebarTitle setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _sidebarTitle.center = CGPointMake(15, 112);
        } else {
            _sidebarTitle.center = CGPointMake(25, 112);
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
        CGPoint point = CGPointMake(15, kQuestionViewTopMarginForiPhone+15);
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
                                  200,
                                  kSegmentHeightForiPhone);
        _segmentedControl.frame = frame;
        [_segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
        _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        _segmentedControl.selectedSegmentIndex = 0;
        [self addSubview:_segmentedControl];
    }
    

    
    
    if (_logoImage == nil){
        _logoImage = [[UIImageView  alloc] init];
        _logoImage.contentMode = UIViewContentModeScaleAspectFit;
        _logoImage.frame = CGRectMake(340, 5, 54, 30);
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
        
        UIImageView *upImageView = [[UIImageView  alloc] init];
        [upImageView setImage:[UIImage imageNamed:@"upButton"]];
        upImageView.contentMode = UIViewContentModeScaleAspectFit;
        upImageView.frame = CGRectMake(394-5, 45-13.75-5, 10, 13.75);
        if (self.isPlayingCard) {
            upImageView.frame = [Common getScaledViewRect:upImageView withProportion:kFlashCardViewProporation_iPhone];
        }
        upImageView.clipsToBounds = YES;
        upImageView.backgroundColor = [UIColor clearColor];
        upImageView.userInteractionEnabled = NO;
        [self addSubview:upImageView];
    }
    
    if (_logoLinkageButton == nil) {
        _logoLinkageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _logoLinkageButton.frame = CGRectMake(318, 24, 12, 12);
        if (self.isPlayingCard) {
            _logoLinkageButton.frame = [Common getScaledViewRect:_logoLinkageButton withProportion:kFlashCardViewProporation_iPhone];
        }
        [_logoLinkageButton setBackgroundImage:[UIImage imageNamed:@"edit_link_button.png"] forState:UIControlStateNormal];
        [_logoLinkageButton addTarget:self action:@selector(editLogoLinkageURL:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:_logoLinkageButton];
    }
    
    if (_creatorText == nil) {
        UITextField *des = [[UITextField alloc] init];
        des.frame = CGRectMake(220, 5, 68, 10);
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
        _creatorText.frame = CGRectMake(220, 15, 68, 10);
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
        _jobTitleText.frame = CGRectMake(220, 25, 68, 10);
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
        
        _functionAreaView.backgroundColor = [UIColor clearColor];
        _functionAreaView.layer.borderWidth = 0;
        
        [_soundButton setImage:[UIImage imageNamed:@"play_recorded_sound_button"] forState:UIControlStateNormal];
        _changeTemplateButton.hidden = YES;
        _backgroundImageSelectButton.hidden = YES;
        _functionAreaView.frame = CGRectMake(self.bounds.size.width - 50, CGRectGetMinY(_segmentedControl.frame), 50, CGRectGetHeight(_segmentedControl.frame));
        _soundButton.frame = CGRectMake(13, 8, 24, 24);
        
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
    DDLogInfo(@"%s",__FUNCTION__);
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
    DDLogInfo(@"%s",__FUNCTION__);
    _logoLinkageButton.hidden = TRUE;
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWebviewViaLogoURL:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    if (_currentCard.question.movieFullPath.length > 0) {
        //allow to play movie
      _imageQuestion.userInteractionEnabled        = YES;
    } else {
        _imageQuestion.userInteractionEnabled        = FALSE;
    }
    
    _imageQuestion.layer.borderWidth = 0;
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
    
    _imageAnswer.layer.borderWidth = 0;
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
    DDLogInfo(@"%s",__FUNCTION__);
    _logoLinkageButton.hidden = FALSE;
    
    int scale = [[UIScreen mainScreen] scale];
    
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    _imageQuestion.userInteractionEnabled        = TRUE;
    _imageQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _imageQuestion.layer.borderWidth = 2/scale;
    } else {
        _imageQuestion.layer.borderWidth = 3/scale;
    }
    
    _mainQuestion.userInteractionEnabled         = TRUE;
    _mainQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _mainQuestion.layer.borderWidth = 2/scale;
    } else {
        _mainQuestion.layer.borderWidth = 3/scale;
    }
    _subQuestion.userInteractionEnabled          = TRUE;
    _subQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subQuestion.layer.borderWidth = 2/scale;
    } else {
        _subQuestion.layer.borderWidth = 3/scale;
    }
    _subheadingQuestion.userInteractionEnabled   = TRUE;
    _subheadingQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subheadingQuestion.layer.borderWidth = 2/scale;
    } else {
        _subheadingQuestion.layer.borderWidth = 3/scale;
    }
    
    _imageAnswer.userInteractionEnabled        = TRUE;
    _imageAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _imageAnswer.layer.borderWidth = 2/scale;
    } else {
        _imageAnswer.layer.borderWidth = 3/scale;
    }
    
    _mainAnswer.userInteractionEnabled         = TRUE;
    _mainAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _mainAnswer.layer.borderWidth = 2/scale;
    } else {
        _mainAnswer.layer.borderWidth = 3/scale;
    }
    _subAnswer.userInteractionEnabled          = TRUE;
    _subAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subAnswer.layer.borderWidth = 2/scale;
    } else {
        _subAnswer.layer.borderWidth = 3/scale;
    }
    _subheadingAnswer.userInteractionEnabled   = TRUE;
    _subheadingAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subheadingAnswer.layer.borderWidth = 2/scale;
    } else {
        _subheadingAnswer.layer.borderWidth = 3/scale;
    }
    
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
    DDLogInfo(@"%s",__FUNCTION__);
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
    DDLogInfo(@"%s",__FUNCTION__);
    [self resetVerticalScrollViewOffset];
    [self showQuestionOrAnswer];
    [self updateQuestionOrAnswerTemplate];
    
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
        _functionAreaView.hidden = YES;
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
                    
                    DDLogWarn(@"%s:card(sn=%d) is font resized",__FUNCTION__,_currentCard.cardSN);

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
    

    
    
    

}


- (void) resetVerticalScrollViewOffset {
    DDLogInfo(@"%s",__FUNCTION__);
    //reset offset
    CGPoint offset = _verticalScrollView.contentOffset;
    offset.y = 0;
    [_verticalScrollView setContentOffset:offset animated:YES];
}


- (void) updateUITextViewPaddingTop {
    DDLogInfo(@"%s",__FUNCTION__);
    _subheadingQuestion.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subheadingSizeQuestion], 0, 0, 0.0);
    _subheadingAnswer.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subheadingSizeAnswer], 0, 0, 0.0);
    _mainQuestion.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_mainSizeQuestion], 0, 0, 0.0);
    _mainAnswer.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_mainSizeAnswer], 0, 0, 0.0);
    _subQuestion.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subSizeQuestion], 0, 0, 0.0);
    _subAnswer.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subSizeAnswer], 0, 0, 0.0);
}


- (void) refreshQuestionAndAnswerContent {
    DDLogInfo(@"%s",__FUNCTION__);
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
    
    
    _creatorText.text = [NSString stringWithFormat:@"%@",_currentPack.creatorNickName];
    _jobTitleText.text = [NSString stringWithFormat:@"%@",_currentPack.jobTitle];
    
    NSString *logoFullPath = _currentCard.question.logoFullPath;
    if (((logoFullPath.length == 0) || ([logoFullPath rangeOfString:@"placeholder"].location != NSNotFound)) && (_isPlayingCard == true)) {
        _logoImage.hidden = true;
    } else {
        _logoImage.hidden = false;
    }
    
    
    
}

- (void) refreshAnswerContent {
    DDLogInfo(@"%s",__FUNCTION__);
    NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.imageFullPath lastPathComponent]];
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:path];
    if (imageTemp) {
        _answerImageFullPath = path;
        _imageAnswer.image = imageTemp;
    } else {
        _answerImageFullPath = @"";
        DDLogInfo(@"%s:Use answer_placeholder_content.jpg as self.imageAnswer",__FUNCTION__);
        _imageAnswer.image = [UIImage imageNamed:@"answer_placeholder_content.jpg"];
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
    
    _subheadingFontAnswer = _currentCard.answer.css.subheadingFont;
    _mainFontAnswer = _currentCard.answer.css.mainFont;
    _subFontAnswer = _currentCard.answer.css.subFont;
    
}

- (void) refreshQuestionContent {
    DDLogInfo(@"%s",__FUNCTION__);
    NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.imageFullPath lastPathComponent]];
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:path];
    if (imageTemp) {
        _questionImageFullPath = path;
        _imageQuestion.image = imageTemp;
    } else {
        _questionImageFullPath = @"";
        DDLogInfo(@"%s:Set question_placeholder_content.jpg as self.imageQuestion",__FUNCTION__);
        _imageQuestion.image = [UIImage imageNamed:@"question_placeholder_content.jpg"];
    }
    
    path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.logoFullPath lastPathComponent]];
    imageTemp = [UIImage imageWithContentsOfFile:path];
    if (imageTemp) {
        _logoImageFullPath = path;
        _logoImage.image = imageTemp;
    } else {
        _logoImageFullPath = @"";
        DDLogInfo(@"%s:Use placeholder logo image for self.logoImage",__FUNCTION__);
        _logoImage.image = [UIImage imageNamed:@"question_placeholder_logo.jpg"];
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
    
    _subheadingFontQuestion = _currentCard.question.css.subheadingFont;
    _mainFontQuestion = _currentCard.question.css.mainFont;
    _subFontQuestion = _currentCard.question.css.subFont;
}


#pragma mark -
#pragma mark Segment callback

- (void) showQuestionOrAnswer {
    DDLogInfo(@"%s",__FUNCTION__);
    if (_segmentedControl.selectedSegmentIndex == 0) {
        _imageQuestion.hidden = NO;
        _subheadingQuestion.hidden = NO;
        _mainQuestion.hidden = NO;
        _subQuestion.hidden = NO;
        
        _imageAnswer.hidden = YES;
        _subheadingAnswer.hidden = YES;
        _mainAnswer.hidden = YES;
        _subAnswer.hidden = YES;
        
        _questionTitle.hidden = NO;
        _answerTitle.hidden = YES;
        
        _questionBackgroundImageView.hidden = NO;
        _answerBackgroundImageView.hidden = YES;
        
        
    } else {
        _imageQuestion.hidden = YES;
        _subheadingQuestion.hidden = YES;
        _mainQuestion.hidden = YES;
        _subQuestion.hidden = YES;
        
        _imageAnswer.hidden = NO;
        _subheadingAnswer.hidden = NO;
        _mainAnswer.hidden = NO;
        _subAnswer.hidden = NO;
        
        _questionTitle.hidden = YES;
        _answerTitle.hidden = NO;
        
        _questionBackgroundImageView.hidden = YES;
        _answerBackgroundImageView.hidden = NO;
    }
}


- (void)segmentAction:(id)sender
{
	[self refreshAll];
}

- (void) backgroundImageSelectButtonClicked:(UITapGestureRecognizer *)sender {
    
    NSString *backgroundImagePath;
    if (_segmentedControl.selectedSegmentIndex == 0) {
        backgroundImagePath =  _currentCard.question.backgroundImageFullPath;
    } else {
        backgroundImagePath =  _currentCard.answer.backgroundImageFullPath;
    }
    
    if (backgroundImagePath.length == 0) {
        [self selectFromImageLibraryByBackgroundSelectButton:sender];
    } else {
        
        CGPoint point = [_backgroundImageSelectButton convertPoint:CGPointMake(CGRectGetWidth(_backgroundImageSelectButton.frame)/2, 0) toView:self];
        
        PopoverView *backgroundImageSelectPopoverView = [PopoverView showPopoverAtPoint:point
                                                                                 inView:self
                                                                              withTitle:@"Edit/Remove"
                                                                        withStringArray:[NSArray arrayWithObjects:@"Remove background image", @"Change background image", nil]
                                                                               delegate:self];
        backgroundImageSelectPopoverView.tag = Type_PopoverView_SelectBackground;
    }
    
}


/**
 *  不是保存到数据库中，而是保存到_currentCard中。主要场景用在create new card
 */
- (void) commitQuestionAndAnswerData {
    DDLogInfo(@"%s",__FUNCTION__);
    _currentCard.answer.title = _answerTitle.text;
    _currentCard.answer.subheading = _subheadingAnswer.text;
    _currentCard.answer.main = _mainAnswer.text;
    _currentCard.answer.sub = _subAnswer.text;
    _currentCard.answer.imageFullPath = _answerImageFullPath;
    
    _currentCard.answer.backgroundImageFullPath = _answerBackgroundImageFullPath;
    
    _currentCard.answer.movieFullPath = _answerMovieFullPath;
    
    _currentCard.answer.recordedSoundFullPath = _answerRecordedSoundFullPath;
    _currentCard.question.recordedSoundFullPath = _questionRecordedSoundFullPath;
    
    _currentCard.answer.css.subheadingAlign = _subheadingAlignAnswer;
    _currentCard.answer.css.subheadingColor = _subheadingColorAnswer;
    _currentCard.answer.css.subheadingSize = _subheadingSizeAnswer;
    _currentCard.answer.css.mainAlign = _mainAlignAnswer;
    _currentCard.answer.css.mainColor = _mainColorAnswer;
    _currentCard.answer.css.mainSize = _mainSizeAnswer;
    _currentCard.answer.css.subAlign = _subAlignAnswer;
    _currentCard.answer.css.subColor = _subColorAnswer;
    _currentCard.answer.css.subSize = _subSizeAnswer;
    
    _currentCard.answer.css.subheadingFont = _subheadingFontAnswer;
    _currentCard.answer.css.mainFont = _mainFontAnswer;
    _currentCard.answer.css.subFont = _subFontAnswer;
    
    _currentCard.question.title = _questionTitle.text;
    _currentCard.question.subheading = _subheadingQuestion.text;
    _currentCard.question.main = _mainQuestion.text;
    _currentCard.question.sub = _subQuestion.text;
    _currentCard.question.imageFullPath = _questionImageFullPath;
    
    _currentCard.question.backgroundImageFullPath = _questionBackgroundImageFullPath;
    
    _currentCard.question.movieFullPath = _questionMovieFullPath;
    
    _currentCard.question.css.subheadingAlign = _subheadingAlignQuestion;
    _currentCard.question.css.subheadingColor = _subheadingColorQuestion;
    _currentCard.question.css.subheadingSize = _subheadingSizeQuestion;
    _currentCard.question.css.mainAlign = _mainAlignQuestion;
    _currentCard.question.css.mainColor = _mainColorQuestion;
    _currentCard.question.css.mainSize = _mainSizeQuestion;
    _currentCard.question.css.subAlign = _subAlignQuestion;
    _currentCard.question.css.subColor = _subColorQuestion;
    _currentCard.question.css.subSize = _subSizeQuestion;
    
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
    int numLines = [self getTextSizeHeight:textView] / textView.font.lineHeight;
    
    return numLines;
}


#pragma mark -
#pragma mark - Update CSS (only CSS)

//CSS part which is included in three main parts: CSS, template(position) and content
- (void) updateQuestionAndAnswerCSS {
    DDLogInfo(@"%s",__FUNCTION__);
    if (_currentCard == nil) {
        [Common alertViewCommon:@"Need to set currentCard beforehand"];
    }
    
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
    DDLogInfo(@"%s",__FUNCTION__);
    _mainQuestion.contentOffset = CGPointZero;
    _subheadingQuestion.contentOffset = CGPointZero;
    _subQuestion.contentOffset = CGPointZero;
    
    _mainAnswer.contentOffset = CGPointZero;
    _subheadingAnswer.contentOffset = CGPointZero;
    _subAnswer.contentOffset = CGPointZero;
}

- (void) updateQuestionOrAnswerTemplate {
    DDLogInfo(@"%s",__FUNCTION__);
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
    DDLogInfo(@"%s",__FUNCTION__);
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
    DDLogInfo(@"%s",__FUNCTION__);
    int index = _currentCard.answer.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(1, 0, 210, 30);
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
            _subheadingAnswer.textAlignment = NSTextAlignmentCenter;
            _subheadingAlignAnswer = @"Center";
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(1, 35, 210, 150);
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(210, 10, 155, 155);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            break;
        }
        case 1: //Template 1
        {
            
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(1, 0, 210, 30);
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
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(1, 33, 210, 126);
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(1, 160, 210, 30);
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
            _subAnswer.textColor = [UIColor redColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            _subColorAnswer = @"Red";
            _subSizeAnswer = 16;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(210, 10, 155, 155);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            break;
        }
        case 2: //Template 2
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(1, 0, 210, 30);
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
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 20;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(1, 35, 210, 155);
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(210, 30, 155, 155);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            
            break;
        }
        case 3: //Template 3
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(1, 5, 360, 185);
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = YES;
            
            _imageAnswer.hidden = TRUE;
            
            break;
        }
        case 4: //Template4
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(1, 0, 210, 190);
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(210, 10, 155, 155);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }

            
            break;
        }
        case 5: //Template 5
        {
            _subheadingAnswer.hidden = TRUE;
            _mainAnswer.hidden = TRUE;
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.frame = CGRectMake(1, 5, 360, 185);
            if (self.isPlayingCard) {
                _imageAnswer.frame = [Common getScaledViewRect:_imageAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            _imageAnswer.hidden = FALSE;
            
            break;
        }
            
        case 6:
        {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(1, 15, 350, 85);
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(1, 103, 349, 85);
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
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            
            _imageAnswer.hidden = TRUE;
            break;
        }
            
        case 7:
        {
            _subheadingAnswer.hidden = YES;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(1, 15, 350, 85);
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 16;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(1, 103, 349, 85);
            if (self.isPlayingCard) {
                _subAnswer.frame = [Common getScaledViewRect:_subAnswer withProportion:kFlashCardViewProporation_iPhone];
            }

            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16];
            }
            if (self.isPlayingCard) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                if (_subFontAnswer.length == 0) {
                    _subAnswer.font =[UIFont boldSystemFontOfSize:16*kFlashCardViewProporation_iPhone];
                } else {
                    _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:16*kFlashCardViewProporation_iPhone];
                }
            }
            _subAnswer.textColor = [UIColor blackColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            _subColorAnswer = @"Black";
            _subSizeAnswer = 16;
            
            
            _imageAnswer.hidden = TRUE;
            break;
        }
            
        default:
        {
            DDLogInfo(@"%s:No template is selected",__FUNCTION__);
            break;
        }
            
    }
}

- (void) updateAnswerViewTemplateForiPad{
    DDLogInfo(@"%s",__FUNCTION__);
    int index = _currentCard.answer.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 360, 80);
            
            if (_subheadingFontAnswer.length == 0) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _subheadingAnswer.font =[UIFont fontWithName:_subheadingFontAnswer size:34];
            }
            
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentCenter;
            _subheadingAlignAnswer = @"Center";
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 34;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 100, 360, 320);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:30];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:30];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentCenter;
            _mainAlignAnswer = @"Center";
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 30;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 40, 350, 350);

            
            break;
        }
        case 1: //Template 1
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 38;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(10, 380, 360, 50);
            
            if (_subFontAnswer.length == 0) {
                _subAnswer.font =[UIFont boldSystemFontOfSize:38];
            } else {
                _subAnswer.font =[UIFont fontWithName:_subFontAnswer size:38];
            }
            
            _subAnswer.textColor = [UIColor redColor];
            _subAnswer.textAlignment = NSTextAlignmentLeft;
            _subAlignAnswer = @"Left";
            _subColorAnswer = @"Red";
            _subSizeAnswer = 38;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 80, 330, 330);
            
            break;
        }
        case 2: //Template 2
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 34;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 40, 350, 350);
            
            break;
        }
        case 3: //Template 3
        {
            _subheadingAnswer.hidden = TRUE;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 10, 700, 420);
            
            if (_mainFontAnswer.length == 0) {
                _mainAnswer.font =[UIFont boldSystemFontOfSize:34];
            } else {
                _mainAnswer.font =[UIFont fontWithName:_mainFontAnswer size:34];
            }
            
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 34;
            
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = TRUE;
            
            break;
        }
        case 4: //Template4
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
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 34;
            
            _subAnswer.hidden = YES;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(380, 40, 350, 350);
            
            
            break;
        }
        
        case 5: //Template 5
        {
            _subheadingAnswer.hidden = TRUE;
            _mainAnswer.hidden = TRUE;
            _subAnswer.hidden = TRUE;
            
            _imageAnswer.hidden = FALSE;
            _imageAnswer.frame = CGRectMake(10, 20, 700, 410);
            
            break;
        }
        
        case 6:
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
            _subColorAnswer = @"Black";
            _subSizeAnswer = 34;
            
            
            _imageAnswer.hidden = TRUE;
            break;
        }
            
        case 7:
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
            _subColorAnswer = @"Black";
            _subSizeAnswer = 34;
            
            
            _imageAnswer.hidden = TRUE;
            break;
        }
            
        default:
        {
            DDLogInfo(@"%s:No template is selected",__FUNCTION__);
            break;
        }
            
    }
}


//postion part which is included in three main parts: CSS, template(position) and content
- (void) updateQuestionViewTemplateForiPad {
    DDLogInfo(@"%s",__FUNCTION__);
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 38;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = TRUE;
            
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
            _subColorQuestion = @"Black";
            _subSizeQuestion = 30;
            
            _imageQuestion.hidden = TRUE;
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
            _subColorQuestion = @"Black";
            _subSizeQuestion = 34;
            
            _imageQuestion.hidden = TRUE;
            
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
            _subColorQuestion = @"Black";
            _subSizeQuestion = 34;
            
            
            _imageQuestion.hidden = TRUE;
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 42;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = TRUE;
            break;
        }
        
        case 5: //Template 5
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = TRUE;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(10, 20, 700, 410);
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 34;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(380, 40, 350, 350);
            
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 34;
            
            _subQuestion.hidden = YES;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(380, 40, 350, 350);
            
            
            break;
        }
            
        default:
        {
            DDLogInfo(@"%s:No template is selected",__FUNCTION__);
            break;
        }
            
    }
}

- (void) updateQuestionViewTemplateForiPhone {
    DDLogInfo(@"%s",__FUNCTION__);
    int index = _currentCard.question.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(1, 5, 350, 39);
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
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(1, 43, 350, 150);
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(1, 5, 300, 33);
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
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(1, 39, 350, 81);
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(1, 120, 350, 80);
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
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            _imageQuestion.hidden = TRUE;
            break;
        }
        case 2: //Template 2
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(1, 25, 350, 100);
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(1, 140, 350, 52);
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
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            _imageQuestion.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(1, 15, 350, 85);
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(1, 103, 349, 85);
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
            _subColorQuestion = @"Black";
            _subSizeQuestion = 16;
            
            
            _imageQuestion.hidden = TRUE;
            break;
        }
        case 4: //Template 4
        {
            _subheadingQuestion.hidden = YES;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(1, 5, 350, 190);
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 14;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = TRUE;
            break;
        }
        
        case 5: //Template 5
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = TRUE;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(1, 5, 360, 185);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            break;
        }
            
        case 6:
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(1, 0, 210, 30);
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
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 20;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(1, 35, 210, 155);
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(210, 30, 155, 155);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            break;
        }
            
        case 7:
        {
            _subheadingQuestion.hidden = TRUE;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(1, 0, 210, 190);
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
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 16;
            
            _subQuestion.hidden = TRUE;
            
            _imageQuestion.hidden = FALSE;
            _imageQuestion.frame = CGRectMake(210, 10, 155, 155);
            if (self.isPlayingCard) {
                _imageQuestion.frame = [Common getScaledViewRect:_imageQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            
            
            break;
        }
    
        default:
        {
            DDLogInfo(@"%s:No template is selected",__FUNCTION__);
            break;
        }
            
    }
}

#pragma mark -
#pragma mark - Keyboard Notification and related

- (void)keyboardWillHide:(NSNotification*)aNotification {
    DDLogInfo(@"%s",__FUNCTION__);
    //we only deal with current card and new created card
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        return;
    }
    
}


- (void)keyboardWillShow:(NSNotification*)aNotification {
    DDLogInfo(@"%s",__FUNCTION__);
    //step1: we only deal with current card and new created card
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        return;
    }
    
    //only repsonde to UITextView
    if (_isUITextViewFocused) {
        
        //step1: bring out the _keyboardTopView
        CGRect keyboardBounds;
        [[aNotification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
        _keyboardHeight = keyboardBounds.size.width;
        
    }

    
    if (isUserInterfaceIdiomPhone) {
        //we don't need to hide navigation bar on ipAD
        [[NSNotificationCenter defaultCenter] postNotificationName:HIDE_NAVIGATION_BAR_NOTIFICATION object:nil];
    }
    
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    DDLogInfo(@"%s",__FUNCTION__);
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
    CGFloat cursorY = [responderTextView caretRectForPosition:responderTextView.selectedTextRange.start].origin.y;
    //DDLogInfo(@"Y position for current cursorY is %f",cursorY);
    
    //Step2: Get view's Y value relative to screen
    CGFloat yInScrren;
    if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight) {
        yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].x;
    } else {
        //Since we convert to point based on UIWindow
        if (isUserInterfaceIdiomPhone) {
            yInScrren = IPHONE_UI_HEIGHT - [responderTextView convertPoint:CGPointZero toView:nil].x;
        } else {
            yInScrren = IPAD_UI_HEIGHT -[responderTextView convertPoint:CGPointZero toView:nil].x;
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
        offset.y = gap+responderTextView.font.lineHeight;
    
    
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
    DDLogInfo(@"%s",__FUNCTION__);
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
    
    if (_doneButtonPressed == YES) {
        _doneButtonPressed = NO;
        
        if (self.tag == NEW_FLASHCARDVIEW_TAG) {
            //we will save until after we press the save button
            [self commitQuestionAndAnswerData];
            [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_NEW_CREATED_CARD_NOTIFICATION object:nil];
        } else {
            [self saveEdittedCard];
        }
    }
    
    
    
}

// For keyboard input view (top parts)
- (void) setInputViewTopViewItems  {
    DDLogInfo(@"%s",__FUNCTION__);
    UIBarButtonItem *fontType = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Font",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(fontTypeActionForInputView)];
    
    UIBarButtonItem *sizeSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Size",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(sizeUpDownActionForInputView)];
    
    
    UIBarButtonItem *colorSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectColorActionForInputView)];
    
    UIBarButtonItem *alignSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignActionForInputView)];
    
    _emotionButtonForInputView = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Emotion",nil) style:UIBarButtonItemStyleDone target:self action:@selector(emotionAndKeyboardSwitch:)];
    
    UIBarButtonItem * btnSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    //UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Keyboard_Done",nil) style:UIBarStyleDefault target:self action:@selector(dismissKeyBoard)];
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (isUserInterfaceIdiomPhone) {
        saveButton.bounds = CGRectMake(0, 0, 48, 40);
    } else {
        saveButton.bounds = CGRectMake(0, 0, 60, 50);
    }
    [saveButton setTitle:NSLocalizedString(@"Keyboard_Save",nil) forState:UIControlStateNormal];
    if (isUserInterfaceIdiomPhone) {
        [saveButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
    }   else {
        [saveButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        
    } else {
        [saveButton setBackgroundImage:[UIImage imageNamed:@"uibarbuttonitem_normal.png"] forState:UIControlStateNormal];
        [saveButton setBackgroundImage:[UIImage imageNamed:@"uibarbuttonitem_highlight.png"] forState:UIControlStateHighlighted];
    }
    [saveButton addTarget:self action:@selector(dismissKeyBoard:) forControlEvents:UIControlEventTouchDown];
    
    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    
    if (isUserInterfaceIdiomPhone) {
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        closeButton.bounds = CGRectMake(0, 0, 48, 40);
        [closeButton setTitle:NSLocalizedString(@"Keyboard_Cancel",nil) forState:UIControlStateNormal];
        [closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            
        } else {
            [closeButton setBackgroundImage:[UIImage imageNamed:@"uibarbuttonitem_normal.png"] forState:UIControlStateNormal];
            [closeButton setBackgroundImage:[UIImage imageNamed:@"uibarbuttonitem_highlight.png"] forState:UIControlStateHighlighted];
        }
        [closeButton addTarget:self action:@selector(dismissKeyBoard:) forControlEvents:UIControlEventTouchDown];
        
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        
        _buttonArrayForInputView = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,fontType,_emotionButtonForInputView,btnSpace,btnSpace,closeButtonItem,doneButtonItem,nil];
        
    } else {
        _buttonArrayForInputView = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,fontType,_emotionButtonForInputView,btnSpace,btnSpace,btnSpace,doneButtonItem,nil];
    }
    
    
    

    
}


// For keyboard input accessary view
- (void) setInputAccessoryViewItems  {
    DDLogInfo(@"%s",__FUNCTION__);
    UIBarButtonItem *fontType = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Font",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(fontTypeAction)];
    
    UIBarButtonItem *sizeSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Size",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(sizeUpDownAction)];
    
    UIBarButtonItem *colorSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectColorAction)];
    
    UIBarButtonItem *alignSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignAction)];
    
    _emotionButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Emotion",nil) style:UIBarButtonItemStyleDone target:self action:@selector(emotionAndKeyboardSwitch:)];
    
    UIBarButtonItem * btnSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    //UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Keyboard_Done",nil) style:UIBarStyleDefault target:self action:@selector(dismissKeyBoard)];
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (isUserInterfaceIdiomPhone) {
        saveButton.bounds = CGRectMake(0, 0, 48, 40);
    } else {
        saveButton.bounds = CGRectMake(0, 0, 60, 50);
    }
    [saveButton setTitle:NSLocalizedString(@"Keyboard_Save",nil) forState:UIControlStateNormal];
    if (isUserInterfaceIdiomPhone) {
        [saveButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
    }   else {
        [saveButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        
    } else {
        [saveButton setBackgroundImage:[UIImage imageNamed:@"uibarbuttonitem_normal.png"] forState:UIControlStateNormal];
        [saveButton setBackgroundImage:[UIImage imageNamed:@"uibarbuttonitem_highlight.png"] forState:UIControlStateHighlighted];
    }
    [saveButton addTarget:self action:@selector(dismissKeyBoard:) forControlEvents:UIControlEventTouchDown];
    
    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    
    
    if (isUserInterfaceIdiomPhone) {
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        closeButton.bounds = CGRectMake(0, 0, 48, 40);
        [closeButton setTitle:NSLocalizedString(@"Keyboard_Cancel",nil) forState:UIControlStateNormal];
        [closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            
        } else {
            [closeButton setBackgroundImage:[UIImage imageNamed:@"uibarbuttonitem_normal.png"] forState:UIControlStateNormal];
            [closeButton setBackgroundImage:[UIImage imageNamed:@"uibarbuttonitem_highlight.png"] forState:UIControlStateHighlighted];
        }
        [closeButton addTarget:self action:@selector(dismissKeyBoard:) forControlEvents:UIControlEventTouchDown];
        
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        _buttonArray = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,fontType,_emotionButton,btnSpace,btnSpace,closeButtonItem,doneButtonItem,nil];
        
    } else {
        _buttonArray = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,fontType,_emotionButton,btnSpace,btnSpace,btnSpace,doneButtonItem,nil];
    }
    
    
    //Back Button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Back",nil) style:UIBarButtonItemStyleDone target:self action:@selector(backAction:)];
    NSDictionary *textAttributes;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [NSDictionary dictionaryWithObjectsAndKeys:[UIFont boldSystemFontOfSize:16], UITextAttributeFont,nil];
    } else {
        [NSDictionary dictionaryWithObjectsAndKeys:[UIFont boldSystemFontOfSize:14], UITextAttributeFont,nil];
    }
    [backButton setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    
    //Font Array
    UIBarButtonItem *fontSizeAlert = [[UIBarButtonItem alloc] initWithTitle:@"Size" style:UIBarButtonItemStyleBordered target:self action:nil];
    [fontSizeAlert setEnabled:FALSE];
    
    UIBarButtonItem *fontSize12 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Size12",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize18 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Size18",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize24 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size24",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize28 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size28",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize32 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size32",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize36 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size36",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize40 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size40",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize45 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size45",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize50 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size50",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize55 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size55",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize60 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size60",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize80 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size80",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize100 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size100",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize160 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size160",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize260 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Size260",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    if (_fontSizeArray == nil) {
        if (isUserInterfaceIdiomPhone) {
            _fontSizeArray = [NSArray arrayWithObjects:backButton,fontSizeAlert,fontSize12,fontSize18,fontSize24,fontSize28,fontSize32,fontSize36, fontSize40, fontSize45,fontSize50, fontSize55, fontSize80,nil];
        } else {
            _fontSizeArray = [NSArray arrayWithObjects:backButton,fontSizeAlert,fontSize12,fontSize18,fontSize24,fontSize28,fontSize32,fontSize36, fontSize40, fontSize45,fontSize50, fontSize55, fontSize60, fontSize80, fontSize100, fontSize160,fontSize260,nil];
        }
        
    }
    
    if (_fontTypeArray == nil) {
        _fontTypeArray = [NSMutableArray arrayWithObject:backButton];
        
        NSArray *fontArray = [Common recommendedFonts];
        for (NSString *fontName in fontArray) {
            UIBarButtonItem *fontBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:fontName style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontType:)];
            [_fontTypeArray addObject:fontBarButtonItem];
        }
        
    }
    
    //Color Array
    UIBarButtonItem *redButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Red",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *blueButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Blue",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *blackButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Black",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *yelloButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Yellow",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *greenButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Green",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *whiteButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_White",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    if (_colorArray == nil) {
        _colorArray = [NSArray arrayWithObjects:backButton,redButton,blueButton,blackButton,yelloButton,greenButton,whiteButton,nil];
    }
    
    //Align Array
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Left",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    UIBarButtonItem *centerButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Center",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Right",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    UIBarButtonItem *justifyButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Justify",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    if (_alignArray == nil) {
        _alignArray = [NSArray arrayWithObjects:backButton,leftButton,centerButton,rightButton,justifyButton,nil];
    }
    
}


- (void) setUpInputView {
    DDLogInfo(@"%s",__FUNCTION__);
    [self setInputViewTopViewItems];
    
    int columnCount;
    int rowCount;
    int emotionViewHeight;
    int cssToolbarHeight; 
    if (isUserInterfaceIdiomPhone) {
        columnCount = CSS_EMOTION_COLUMN_COUNT_IPHONE;
        rowCount = CSS_EMOTION_ROW_COUNT_IPHONE;
        cssToolbarHeight = IPHONE_UI_TOOL_BAR_HEIGHT;
        emotionViewHeight = CSS_EMOTION_VIEW_HEIGHT_IPHONE;
    } else {
        columnCount = CSS_EMOTION_COLUMN_COUNT_IPAD;
        rowCount = CSS_EMOTION_ROW_COUNT_IPAD;
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
    
    
    //Keyboard top view for keyboard input view
    if (_keyboardTopViewForInputView == nil) {
        _keyboardTopViewForInputView = [[UIToolbar alloc]init];
    }
    
    [_keyboardTopViewForInputView setBarStyle:UIBarStyleBlackTranslucent];
    
    _keyboardTopViewForInputView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    _keyboardTopViewForInputView.frame = CGRectMake(0, 0, [Common getScreenWidthInLandscape], cssToolbarHeight);
    [_keyboardTopViewForInputView setItems:_buttonArrayForInputView];
    [_keyboardInputBaseView addSubview:_keyboardTopViewForInputView];
    [_keyboardInputBaseView bringSubviewToFront:_keyboardTopViewForInputView];

    
}

- (void) setUpInputAccessoryView {
    DDLogInfo(@"%s",__FUNCTION__);
    [self setInputAccessoryViewItems];
    
    int columnCount;
    int rowCount;
    int emotionViewHeight;
    int cssToolbarHeight;
    if (isUserInterfaceIdiomPhone) {
        columnCount = CSS_EMOTION_COLUMN_COUNT_IPHONE;
        rowCount = CSS_EMOTION_ROW_COUNT_IPHONE;
        cssToolbarHeight = IPHONE_UI_TOOL_BAR_HEIGHT;
        emotionViewHeight = CSS_EMOTION_VIEW_HEIGHT_IPHONE;
    } else {
        columnCount = CSS_EMOTION_COLUMN_COUNT_IPAD;
        rowCount = CSS_EMOTION_ROW_COUNT_IPAD;
        emotionViewHeight = CSS_EMOTION_VIEW_HEIGHT_IPAD;
        cssToolbarHeight = IPAD_UI_TOOL_BAR_HEIGHT;
    }
    
    //Keyboard top view for accessary view
    if (_keyboardTopView == nil) {
        _keyboardTopView = [[UIToolbar alloc]init];
    }
    
    [_keyboardTopView setBarStyle:UIBarStyleBlackTranslucent];
    
    _keyboardTopView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    _keyboardTopView.frame = CGRectMake(0, 0, [Common getScreenWidthInLandscape], cssToolbarHeight);
    [_keyboardTopView setItems:_buttonArray];
    
    //default input method
    [_subheadingQuestion setInputAccessoryView:_keyboardTopView];
    [_mainQuestion setInputAccessoryView:_keyboardTopView];
    [_subQuestion setInputAccessoryView:_keyboardTopView];
    [_subheadingAnswer setInputAccessoryView:_keyboardTopView];
    [_mainAnswer setInputAccessoryView:_keyboardTopView];
    [_subAnswer setInputAccessoryView:_keyboardTopView];
    
}


-(void)dismissKeyBoard:(id) sender
{
    DDLogInfo(@"%s",__FUNCTION__);
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
    [_lastBecomeFirstRespondTextView setInputAccessoryView:_keyboardTopView];
    [_lastBecomeFirstRespondTextView setInputView:nil];
    
    //step2:
    _isUITextViewFocused = NO;
    [_lastBecomeFirstRespondTextView resignFirstResponder];
    [_lastBecomeFirstRespondTextView setContentOffset:CGPointMake(0, 0) animated:YES];
    
    //Step3: save data in keyboardWasHidden
    if ([[(UIButton *)sender titleLabel].text isEqualToString:NSLocalizedString(@"Keyboard_Save",@"")]) {
        _doneButtonPressed = YES;
    } else {
        _doneButtonPressed = NO;
    }
    
    
}

#pragma mark -
#pragma mark - UIImagePickerController related

- (void) selectFromImageLibraryByBackgroundSelectButton:(UITapGestureRecognizer *)sender {
    DDLogInfo(@"%s",__FUNCTION__);
    if ([_currentCard.creator isEqualToString:[OpenUDID value]] == FALSE) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"You can only edit card that you have created it." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
        
    }
    
    _typeImageSelector = Type_Image_Selector_Background;
    [self selectFromImageLibrary:[sender view] withPopoverArrowUp:NO  supportMov:NO];
}



- (void)selectFromImageLibraryByLogo:(UITapGestureRecognizer *)sender {
    DDLogInfo(@"%s",__FUNCTION__);
    _typeImageSelector = Type_Image_Selector_Logo;
    
    [self selectFromImageLibrary:[sender view] withPopoverArrowUp:YES  supportMov:NO];
    
    
}

- (void)imageViewTapped:(UITapGestureRecognizer *)sender {
    DDLogInfo(@"%s",__FUNCTION__);
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
                                                               withStringArray:[NSArray arrayWithObjects:@"Insert YouTube url", @"Select from library", nil]
                                                                      delegate:self];
    imageSelectPopoverView.tag = Type_PopoverView_SelectImage;

}

- (void)selectImageOrVideoFromLibrary{
    DDLogInfo(@"%s",__FUNCTION__);
    if ([_currentCard.creator isEqualToString:[OpenUDID value]]) {
        _typeImageSelector = Type_Image_Selector_Image;
        [self selectFromImageLibrary:nil withPopoverArrowUp:YES supportMov:YES];
    } else {
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
    }
    
}

- (void) playAudio {
    DDLogInfo(@"%s",__FUNCTION__);
    NSError *error;
    //不能声明为局部变量，否则无法播放
    NSURL *audioURL;
    if (_segmentedControl.selectedSegmentIndex == 0) {
        audioURL = [NSURL fileURLWithPath:_currentCard.question.recordedSoundFullPath];
    } else {
        audioURL = [NSURL fileURLWithPath:_currentCard.answer.recordedSoundFullPath];
    }
    
    [_audioPlayer stop];
    
    if (audioURL) {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&error];
        
        _audioPlayer.numberOfLoops = 0;
        _audioPlayer.delegate = self;
        [_audioPlayer prepareToPlay];
        
        if (_audioPlayer == nil)
            DDLogError(@"%s:%@,audio file:%@",__FUNCTION__,[error description],audioURL);
        else
            [_audioPlayer play];
    } else {
        DDLogInfo(@"%s:no audio file:%@",__FUNCTION__,audioURL);
    }
}

/**
 *  Play movie/video
 */
- (void) playVideo:(NSString *) urlStr {
    DDLogInfo(@"%s",__FUNCTION__);
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
    DDLogInfo(@"%s",__FUNCTION__);
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
   DDLogInfo(@"%s",__FUNCTION__);
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.movie"]){
        
        
        
        NSURL *movieURL = [info objectForKey:UIImagePickerControllerMediaURL];
        DDLogInfo(@"found a movie %@", movieURL);
        
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
        if (_segmentedControl.selectedSegmentIndex == 0) {
            if (([_questionMovieFullPath rangeOfString:@".3gp"].location == NSNotFound)
                  || (_questionMovieFullPath.length == 0)){
                _questionMovieFullPath = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                destPath = _questionMovieFullPath;
            }
            

        } else {
            if (([_answerMovieFullPath rangeOfString:@".3gp"].location == NSNotFound)
                   || (_answerMovieFullPath.length == 0)){
                _answerMovieFullPath = [FileOperationHelper generateUniqueMovFilePathUnderImagesFolder];
                destPath = _answerMovieFullPath;
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
                DDLogInfo(@"%s:Done and converted 3gp size is:%ld",__FUNCTION__,fileSize);
                
            }];
        }
        
        
        //save thumbnail info
        [self thumbnailImageFromURL:[info objectForKey:@"UIImagePickerControllerMediaURL"]];
        
        
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
        
    
    
    } else if ([mediaType isEqualToString:@"public.image"]) {
        UIImage *origialmage = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSData *imageData = UIImageJPEGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)], kJPEGQualityFactor);
        
        if (isUserInterfaceIdiomPhone) {
            [picker dismissModalViewControllerAnimated:YES];
            picker = nil;
        } else {
            //        picker = nil;
            [_imagePickerPopover dismissPopoverAnimated:YES];
            _imagePickerPopover = nil;
        }
        
        if (_typeImageSelector == Type_Image_Selector_Logo) {
            
            _logoImageFullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.logoFullPath lastPathComponent]];
            if (([_logoImageFullPath rangeOfString:@".jpg"].location == NSNotFound) || ([_logoImageFullPath hasSuffix:@"question_placeholder_logo.jpg"])||((_logoImageFullPath.length == 0))) {
                _logoImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            }
            
            [imageData writeToFile:_logoImageFullPath atomically:YES];
            _logoImage.image = [UIImage imageWithData:imageData];
            
            if (isFromNewCreatedCard) {
                //we don't do save operation now but need to tell to save all cards' logo when we click "save button"
                _isAllCardsLogoNeedToBeUpdate = YES;
                _currentCard.question.logoFullPath = _logoImageFullPath;
            } else {
                //do save operation and update all others
                
                if (!_HUD) {
                    _HUD = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
                }
                [[[UIApplication sharedApplication] keyWindow] insertSubview:_HUD atIndex:0];
                [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:_HUD];
                
                _HUD.mode = MBProgressHUDModeIndeterminate;
                [_HUD show:YES];
                _HUD.labelText = NSLocalizedString(@"DIALOG_APPLY_TO_ALL_CARD",@"");
                [self performSelector:@selector(execUpdatelogoImageForAllCards:) withObject:_logoImageFullPath afterDelay:0.01];
            }
            
        } else if (_typeImageSelector == Type_Image_Selector_Image) {
            
            if (_segmentedControl.selectedSegmentIndex == 0) {
                if (([_questionImageFullPath rangeOfString:@".jpg"].location == NSNotFound)
                    || ([_questionImageFullPath hasSuffix:@"question_placeholder_content.jpg"])
                    || ((_questionImageFullPath.length == 0))) {
                    _questionImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
                }
                [imageData writeToFile:_questionImageFullPath atomically:YES];
                _imageQuestion.image = [UIImage imageWithData:imageData];
            } else {
                if (([_answerImageFullPath rangeOfString:@".jpg"].location == NSNotFound)
                    || ([_answerImageFullPath hasSuffix:@"answer_placeholder_content.jpg"])
                    || ((_answerImageFullPath.length == 0))) {
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
        } else if (_typeImageSelector == Type_Image_Selector_Background) {
            
            if (_segmentedControl.selectedSegmentIndex == 0) {
                if (([_questionBackgroundImageFullPath rangeOfString:@".jpg"].location == NSNotFound)
                    || ([_questionBackgroundImageFullPath hasSuffix:@"question_placeholder_content.jpg"])
                    || ((_questionBackgroundImageFullPath.length == 0))) {
                    _questionBackgroundImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
                }
                [imageData writeToFile:_questionBackgroundImageFullPath atomically:YES];
                _questionBackgroundImageView.image = [UIImage imageWithData:imageData];
            } else {
                if (([_answerBackgroundImageFullPath rangeOfString:@".jpg"].location == NSNotFound)
                    || ([_answerBackgroundImageFullPath hasSuffix:@"answer_placeholder_content.jpg"])
                    || ((_answerBackgroundImageFullPath.length == 0))) {
                    _answerBackgroundImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
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
    }
    
    if (isUserInterfaceIdiomPhone) {
        [picker dismissModalViewControllerAnimated:YES];
    } else {
      [_imagePickerPopover dismissPopoverAnimated:YES];
    }
    
    
    
}

- (void) execUpdatelogoImageForAllCards:(NSString *)logoImageFullPath {
    DDLogInfo(@"%s",__FUNCTION__);
    [self updatelogoImageForAllCards:logoImageFullPath];
    [_HUD removeFromSuperview];
    _HUD = nil;
}

- (UIImage *)captureWholeViewAsImage {
    DDLogInfo(@"%s",__FUNCTION__);
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
        screenRect.size.height = kFlashCardViewHeight_Detail_iPhone;
    } else {
        screenRect.size.height = 550;    
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
    DDLogInfo(@"%s",__FUNCTION__);
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}


#pragma mark -
#pragma mark - Text edit function


- (void) fontTypeAction {
    DDLogInfo(@"%s",__FUNCTION__);
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    if ([Common isSymbolIncluded:responderTextView.text]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"You can not change font once text includes symbol" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    
    [_keyboardTopView setItems:_fontTypeArray animated:TRUE];
}

- (void) sizeUpDownAction {
    DDLogInfo(@"%s",__FUNCTION__);
    [_keyboardTopView setItems:_fontSizeArray animated:TRUE];
}

- (void) selectColorAction {
    DDLogInfo(@"%s",__FUNCTION__);
    [_keyboardTopView setItems:_colorArray animated:TRUE];
}

- (void) alignAction {
    DDLogInfo(@"%s",__FUNCTION__);
    [_keyboardTopView setItems:_alignArray animated:TRUE];
}

- (void) fontTypeActionForInputView {
    DDLogInfo(@"%s",__FUNCTION__);
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    if ([Common isSymbolIncluded:responderTextView.text]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"You can not change font once text includes symbol" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    [_keyboardTopViewForInputView setItems:_fontTypeArray animated:TRUE];
}

- (void) sizeUpDownActionForInputView {
    DDLogInfo(@"%s",__FUNCTION__);
    [_keyboardTopViewForInputView setItems:_fontSizeArray animated:TRUE];
}

- (void) selectColorActionForInputView {
    DDLogInfo(@"%s",__FUNCTION__);
    [_keyboardTopViewForInputView setItems:_colorArray animated:TRUE];
}

- (void) alignActionForInputView {
    DDLogInfo(@"%s",__FUNCTION__);
    [_keyboardTopViewForInputView setItems:_alignArray animated:TRUE];
}

- (void) emotionAndKeyboardSwitch:(id) sender {
    DDLogInfo(@"%s",__FUNCTION__);
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
        [_emotionButton setTitle:NSLocalizedString(@"ToolbarItem_Emotion",nil)];
        _keyboardSwitchButtonType = KeyboardSwitchButtonTypeSystem;
        _lastBecomeFirstRespondTextView.inputAccessoryView = _keyboardTopView;
        _lastBecomeFirstRespondTextView.inputView = nil;
        
    }
    
    [_lastBecomeFirstRespondTextView becomeFirstResponder];
    
    
}


- (void) changeFontType:(id) sender{
    DDLogInfo(@"%s",__FUNCTION__);
    NSString *title = ((UIBarButtonItem *) sender).title;
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


- (void) changeFontSize:(id) sender{
    DDLogInfo(@"%s",__FUNCTION__);
    NSUInteger selectFontSize;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size12",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:12]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:12*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 12;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size18",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:18]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:18*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 18;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size24",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:24]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:24*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 24;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size28",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:28]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:28*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 28;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size32",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:32]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:32*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 32;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size36",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:36]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:36*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 36;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size40",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:40]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:40*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 40;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size45",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:45]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:45*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 45;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size50",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:50]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:50*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 50;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size55",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:55]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:55*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 55;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size60",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:60]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:60*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 60;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size80",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:80]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:80*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 80;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size100",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:100]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:100*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 100;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size160",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:160]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:160*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 160;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size260",nil)]) {
        [responderTextView setFont:[responderTextView.font fontWithSize:260]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:260*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 260;
    } else {
        [responderTextView setFont:[responderTextView.font fontWithSize:32]];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            [responderTextView setFont:[responderTextView.font fontWithSize:32*kFlashCardViewProporation_iPhone]];
        }
        selectFontSize = 32;
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
    
    [_keyboardTopView setItems:_buttonArray animated:TRUE];
}

- (void) alignPosition:(id) sender{
    DDLogInfo(@"%s",__FUNCTION__);
    NSString *selectAlignStr = nil;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
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
    responderTextView.selectedRange = range;  // to restore cursor position
    
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
    
    
    [_keyboardTopView setItems:_buttonArray animated:TRUE];
}

- (void) changeColor:(id) sender{
    DDLogInfo(@"%s",__FUNCTION__);
    NSString *selectColorStr = nil;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
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
    
    [_keyboardTopView setItems:_buttonArray animated:TRUE];
}


- (void) backAction:(id) sender{
    DDLogInfo(@"%s",__FUNCTION__);
    [_keyboardTopView setItems:_buttonArray animated:TRUE];
    [_keyboardTopViewForInputView setItems:_buttonArrayForInputView animated:TRUE];
}

#pragma mark -
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    DDLogInfo(@"%s",__FUNCTION__);
    [textField resignFirstResponder];
    
    return YES;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    DDLogInfo(@"%s",__FUNCTION__);
    _isUITextViewFocused = FALSE;
    _keyboardInputBaseView.hidden = TRUE;
    [_emotionButton setTitle:NSLocalizedString(@"ToolbarItem_Emotion",@"")];
    
    [_lastBecomeFirstRespondTextView setInputAccessoryView:_keyboardTopView];
    [_lastBecomeFirstRespondTextView setInputView:nil];
    _keyboardSwitchButtonType = KeyboardSwitchButtonTypeSystem;
    
    return TRUE;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    DDLogInfo(@"%s",__FUNCTION__);
    _isTextFieldsChanged = YES;
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    DDLogInfo(@"%s",__FUNCTION__);
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
            _HUD = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
        }
        [[[UIApplication sharedApplication] keyWindow] insertSubview:_HUD atIndex:0];
        [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:_HUD];
        
        _HUD.mode = MBProgressHUDModeIndeterminate;
        [_HUD show:YES];
        _HUD.labelText = NSLocalizedString(@"DIALOG_APPLY_TO_ALL_CARD",@"");
        [self performSelector:@selector(execTextFieldDidEndEditingTask:) withObject:textField afterDelay:0.01];
    
    }
    
    _isTextFieldsChanged = NO;
    
}

- (void) execTextFieldDidEndEditingTask:(UITextField *)textField  {
    DDLogInfo(@"%s",__FUNCTION__);
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
        DDLogInfo(@"%s:Error",__FUNCTION__);
    }
    
    [_HUD removeFromSuperview];
    _HUD = nil;
}




#pragma mark -
#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    DDLogInfo(@"%s",__FUNCTION__);
    //    CGRect frame = textView.frame;
    //    frame.size.height = textView.contentSize.height;
    //    textView.frame = frame;
    
}


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    DDLogInfo(@"%s",__FUNCTION__);
    _lastBecomeFirstRespondTextView = textView;
    _isUITextViewFocused = TRUE;
    _keyboardInputBaseView.hidden = FALSE;
    [_emotionButton setTitle:NSLocalizedString(@"ToolbarItem_Emotion",@"")];
    
    return TRUE;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    DDLogInfo(@"%s",__FUNCTION__);
    static CGFloat height = 0;
    static int tag = -1;
    
    if (tag != textView.tag) {
        height = 0; 
    }

    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    CGFloat cursorY = [responderTextView caretRectForPosition:responderTextView.selectedTextRange.start].origin.y;
    
    CGFloat yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].x;
    
    CGPoint offset = _verticalScrollView.contentOffset;
    CGFloat gap;
    if (isUserInterfaceIdiomPhone) {
        gap = _keyboardHeight -(IPHONE_UI_HEIGHT - yInScrren - cursorY);
    } else {
        gap = _keyboardHeight -(IPAD_UI_HEIGHT - yInScrren - cursorY);
    }
    
    if ((textView.contentSize.height > height) && (height != 0)) {
        if (gap > -responderTextView.font.lineHeight) {
            offset.y = offset.y + responderTextView.font.lineHeight;
        }
        [_verticalScrollView setContentOffset:offset animated:YES];
    } else if ((textView.contentSize.height < height)&& (height != 0)) {
        if (gap < -responderTextView.font.lineHeight) {
            //offset.y = offset.y - responderTextView.font.lineHeight;
        }
        //[_verticalScrollView setContentOffset:offset animated:YES];
    }
    
    DDLogInfo(@"lineHeight = %f, height = %f, cursorY = %f",responderTextView.font.lineHeight,height,cursorY);
    
    height= textView.contentSize.height;
    tag = textView.tag;
    
    [self adjustFontToFit:textView];
    
    //limit text within text box
    NSString *originalStr = textView.text;
    textView.text = [textView.text stringByAppendingString:text];
    CGFloat lineHeight = textView.font.lineHeight;
    int currentLines = textView.contentSize.height / lineHeight;
    int maxLines = textView.frame.size.height/lineHeight;
    if ((currentLines > maxLines)&&(maxLines > 0)&&(originalStr.length >0)) {
        NSString * firstHalfString = [originalStr substringToIndex:range.location];
        NSString * secondHalfString = [originalStr substringFromIndex: range.location];
        textView.text = [NSString stringWithFormat: @"%@%@%@",
                         firstHalfString,
                         text,
                         secondHalfString];
        
        textView.text = [textView.text substringToIndex:(textView.text.length -1)];
        [textView layoutIfNeeded];
        
        range.location++;
        textView.selectedRange = range;
        return false;
    } else {
        textView.text = originalStr;
        textView.selectedRange = range;
        return true;
    }
    
}

#pragma mark -
#pragma mark - Add logo linkage relate

- (void) editLogoLinkageURL:(id) sender {
    DDLogInfo(@"%s",__FUNCTION__);
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
}



- (void)openWebviewViaLogoURL:(UITapGestureRecognizer *)sender {
    DDLogInfo(@"%s",__FUNCTION__);
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
    DDLogInfo(@"%s",__FUNCTION__);
	[controller dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark - BaseViewDelegate

- (void) updatelogoURLForAllCards:(NSString *)urlString {
    DDLogInfo(@"%s",__FUNCTION__);
    for (Card *card in [_currentPack cards]) {
        card.question.logoURLLinkage =urlString;
        [card save];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
}

- (void) updatelogoImageForAllCards:(NSString *) imagePath {
    DDLogInfo(@"%s",__FUNCTION__);
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
    DDLogInfo(@"%s",__FUNCTION__);
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
                DDLogInfo(@"%s:_currentCard.question.lineNoSubheading= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSubheading,lineNumber);
                i++;
                usleep(5000);
            }
            
            i = 0;
            
            //行数不一致时，增大字体
            lineNumber = [self lineNumberWithUITextView:_mainQuestion];
            while ((_currentCard.question.lineNoMain > lineNumber) && (_currentCard.question.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_mainQuestion setFont:[_mainQuestion.font fontWithSize:(_mainQuestion.font.pointSize *1.1)]];
                lineNumber = [self lineNumberWithUITextView:_mainQuestion];
                DDLogInfo(@"%s:_currentCard.question.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoMain,lineNumber);
                i++;
                usleep(5000);
            }
            
            //行数不一致时，增大字体
            i = 0;
            lineNumber = [self lineNumberWithUITextView:_subQuestion];
            while ((_currentCard.question.lineNoSub > lineNumber)&& (_currentCard.question.lineNoSub >= 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_subQuestion setFont:[_subQuestion.font fontWithSize:(_subQuestion.font.pointSize *1.1)]];
                lineNumber = [self lineNumberWithUITextView:_subQuestion];
                DDLogInfo(@"%s:_currentCard.question.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.question.lineNoSub,lineNumber);
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
                [_subheadingAnswer setFont:[_subheadingAnswer.font fontWithSize:(_subheadingAnswer.font.pointSize *1.1)]];
                lineNumber = [self lineNumberWithUITextView:_subheadingAnswer];
                DDLogInfo(@"%s:_currentCard.answer.lineNoSubheading = %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSubheading ,lineNumber);
                i++;
                usleep(5000);
            }
            
            i = 0;
            //行数不一致时，增大字体
            lineNumber = [self lineNumberWithUITextView:_mainAnswer];
            while ((_currentCard.answer.lineNoMain > lineNumber)&& (_currentCard.answer.lineNoMain != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_mainAnswer setFont:[_mainAnswer.font fontWithSize:(_mainAnswer.font.pointSize *1.1)]];
                lineNumber = [self lineNumberWithUITextView:_mainAnswer];
                DDLogInfo(@"%s:_currentCard.answer.lineNoMain= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoMain,lineNumber);
                i++;
                usleep(5000);
            }
            
            i = 0;
            //行数不一致时，增大字体
            lineNumber = [self lineNumberWithUITextView:_subAnswer];
            while ((_currentCard.answer.lineNoSub > lineNumber)&& (_currentCard.answer.lineNoSub != 0)&& (i<kMax)&& (lineNumber > 0)) {
                [_subAnswer setFont:[_subAnswer.font fontWithSize:(_subAnswer.font.pointSize *1.1)]];
                lineNumber = [self lineNumberWithUITextView:_subAnswer];
                DDLogInfo(@"%s:_currentCard.answer.lineNoSub= %d,lineNumber=%d",__FUNCTION__,_currentCard.answer.lineNoSub,lineNumber);
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
    DDLogInfo(@"%s",__FUNCTION__);
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
    DDLogInfo(@"%s",__FUNCTION__);
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
        
        DDLogError(@"%s:......Fuck textHeight <0",__FUNCTION__);
        
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
        DDLogError(@"%s:......textView.font.pointSize < 10:%@",__FUNCTION__,textView.text);
    }
    
    float orginalFontSize = textView.font.pointSize;
    
    //为了防止字体太小而设立
    int gate;
    if (_isPlayingCard) {
        gate = 12;
    } else {
        gate = 10;
    }
    
    //确保top margin和bottom margin足够，所以用一个经验值代替frameHeight/5
    while ((textHeight > frameHeight - frameHeight/5)&&(textHeight >0)&&(textView.font.pointSize >0)) {
        outputFlag = TRUE;
        result = YES;
        
        if (textView.font.pointSize <=gate) {
            //字体越小，size变化越明显
            DDLogWarn(@"%s:......textView.font.pointSize <gate:%@",__FUNCTION__,textView.text);
            break;
        }
        [textView setFont:[textView.font fontWithSize:(textView.font.pointSize -1)]];
        [textView layoutSubviews];
        usleep(5000);
        textHeight = [self getTextSizeHeight:textView];
        
    }
    
    if (outputFlag) {
        DDLogInfo(@"CardSN %d:text(%@).\n---Original value: height(%f), font size(%f);\n---Final value:height(%f), font size(%f)",_currentCard.cardSN,textView.text,originalTextHeight, orginalFontSize,textView.contentSize.height, textView.font.pointSize);
    }
    
    
    
    return result;
}



- (void) saveEdittedCard {
    DDLogInfo(@"%s",__FUNCTION__);
    //we only deal with current card and new created card
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
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
        NSData *imageData = UIImageJPEGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)], kJPEGQualityFactor);
        if (([_currentCard.coverImageURL rangeOfString:@".jpg"].location == NSNotFound) || ((_currentCard.coverImageURL == nil))) {
            NSString *savedFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
            [imageData writeToFile:savedFullPath atomically:YES];
            _currentCard.coverImageURL = savedFullPath;
        } else {
            [imageData writeToFile:_currentCard.coverImageURL atomically:YES];
        }
    }
    
    if (self.tag == NEW_FLASHCARDVIEW_TAG) {
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
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    }
    
    
    
}


/**
 *  Record or play
 *
 *  @param sender <#sender description#>
 */
- (void) soundRecordButtonClicked:(id)sender {
    DDLogInfo(@"%s",__FUNCTION__);
    if (_isPlayingCard) {
        //play sound
        [self playAudio];
        
    } else {
        
        if ([_currentCard.creator isEqualToString:[OpenUDID value]]) {
            
            CreateSoundViewController *createSoundViewController = [[CreateSoundViewController alloc] initWithNibName:nil bundle:nil];
            createSoundViewController.isOnQuestion = (_segmentedControl.selectedSegmentIndex == 0);
            createSoundViewController.card = _currentCard;
            createSoundViewController.pack = _currentPack;
            UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:createSoundViewController];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navController animated:YES];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Audio play is only supported in play mode." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
    
}


- (void) changeTemplateButtonClick:(id)sender {
    DDLogInfo(@"%s",__FUNCTION__);
    
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
        if (_selectTemplatePopoverController == nil) {
            _selectTemplatePopoverController = [[UIPopoverController alloc] initWithContentViewController:selectTemplateTableViewController];
            _selectTemplatePopoverController.delegate = self;
            _selectTemplatePopoverController.popoverContentSize = CGSizeMake(250, 95*5);
            if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
                _selectTemplatePopoverController.backgroundColor = [UIColor colorWithRed:63.0/255 green:63.0/255 blue:63.0/255 alpha:0.3];
            }
            
        } else {
            [_selectTemplatePopoverController setContentViewController:selectTemplateTableViewController];
        }
        
        
        
        CGPoint point = [sender convertPoint:CGPointMake(0, 0) toView:nil];
        CGRect rect = CGRectMake(point.x, point.y, 24, 24);
        
        [_selectTemplatePopoverController presentPopoverFromRect:rect inView:[UIApplication sharedApplication].keyWindow permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        
    }
}

- (void) dismissSelectTemplatePopoverController {
    DDLogInfo(@"%s",__FUNCTION__);
    [_selectTemplatePopoverController dismissPopoverAnimated:YES];
    
}

- (void) templateSelectedNotification: (NSNotification *) notification {
    DDLogInfo(@"%s",__FUNCTION__);
    [self performSelector:@selector(dismissSelectTemplatePopoverController) withObject:nil];
    
    //  We don't want to accept when there's create card action now
    if (((isFromNewCreatedCard == YES) && (self.tag == CURRENT_FLASHCARDVIEW_TAG))
        ||
        ((self.tag != CURRENT_FLASHCARDVIEW_TAG) && (self.tag != NEW_FLASHCARDVIEW_TAG))){
        return;
    }
    
    NSString *templateIDString = (NSString *)[notification object];
    if (_segmentedControl.selectedSegmentIndex == 0) {
        _currentCard.question.templateID = [templateIDString integerValue];
    } else {
        _currentCard.answer.templateID = [templateIDString integerValue];
    }
    
    DDLogInfo(@"%s,selected templateID = %@",__FUNCTION__,templateIDString);
    
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
- (void) thumbnailImageFromURL:(NSURL *) url {
    DDLogInfo(@"%s",__FUNCTION__);
    UIImageView *pickerImageView;
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        pickerImageView = _imageQuestion;
    } else {
        pickerImageView = _imageAnswer;
    }
    
    MPMoviePlayerController *theMovie = [[MPMoviePlayerController alloc] initWithContentURL:url];
    theMovie.view.frame = CGRectMake(0, 0, CGRectGetWidth(pickerImageView.frame) * 2, CGRectGetHeight(pickerImageView.frame) * 2);
    theMovie.controlStyle = MPMovieControlStyleNone;
    theMovie.shouldAutoplay=NO;
    UIImage *thumbnail = [theMovie thumbnailImageAtTime:0 timeOption:MPMovieTimeOptionExact];
    if (thumbnail == nil) {
        thumbnail = [UIImage imageNamed:@"video_default"];
    }
    
    UIImage *playImage = [UIImage imageNamed:@"play"];
    
    UIGraphicsBeginImageContext(thumbnail.size);
    [thumbnail drawInRect:CGRectMake(0, 0, thumbnail.size.width, thumbnail.size.height)];
    
    [playImage drawInRect:CGRectMake(thumbnail.size.width *0.4, thumbnail.size.height *0.4, thumbnail.size.width *0.2, thumbnail.size.width *0.2)];
    UIImage *compositeThumbNail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        if (([_questionImageFullPath rangeOfString:@".jpg"].location == NSNotFound)
            || ([_questionImageFullPath hasSuffix:@"question_placeholder_content.jpg"])
            || ((_questionImageFullPath.length == 0))) {
            _questionImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
        }
        [UIImageJPEGRepresentation(compositeThumbNail, 0.6) writeToFile:_questionImageFullPath atomically:YES];
        _imageQuestion.image = compositeThumbNail;
    } else {
        if (([_answerImageFullPath rangeOfString:@".jpg"].location == NSNotFound)
            || ([_answerImageFullPath hasSuffix:@"answer_placeholder_content.jpg"])
            || ((_answerImageFullPath.length == 0))) {
            _answerImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
        }
        [UIImageJPEGRepresentation(compositeThumbNail, 0.6) writeToFile:_answerImageFullPath atomically:YES];
        _imageAnswer.image = compositeThumbNail;
    }
}

#pragma mark – UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    DDLogInfo(@"%s",__FUNCTION__);
    [popoverController dismissPopoverAnimated:YES];
    popoverController = nil;
    
}


#pragma mark -
#pragma mark - Re-screenshot all cards under current pack
- (void) reSceenshotAll: (RescreenshotReason) why withStringVal: (NSString *) val{
    DDLogInfo(@"%s",__FUNCTION__);
    float flashCardYPositionInScrollView;
    FlashCard *tempCardView;
    if (isUserInterfaceIdiomPhone) {
        flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPhone + kFalshCardViewHeight_QASegment_iPhone)/2; //Since it's horizontal movement, so this is a constant value
        tempCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone + kFalshCardViewHeight_QASegment_iPhone) defaultPack:_currentPack defaultCard:_currentCard];
        
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
            NSData *imageData = UIImageJPEGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)], kJPEGQualityFactor);
            if (([card.coverImageURL rangeOfString:@".jpg"].location == NSNotFound) || ((card.coverImageURL == nil))) {
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
    DDLogInfo(@"%s",__FUNCTION__);
    
    int  location =_lastBecomeFirstRespondTextView.selectedRange.location;
    NSString *beforeStr = @"";
    NSString *afterStr = @"";
    
    beforeStr = [_lastBecomeFirstRespondTextView.text substringToIndex:location];
    afterStr = [_lastBecomeFirstRespondTextView.text substringFromIndex:location];

    NSString *newValue;
    if (_lastBecomeFirstRespondTextView.text == NULL) {
        _lastBecomeFirstRespondTextView.text = @"";
    }
    
    newValue = [NSString stringWithFormat:@"%@%@%@",beforeStr,emoticon.code,afterStr];
    
    _lastBecomeFirstRespondTextView.text = newValue;
    
    NSRange range = _lastBecomeFirstRespondTextView.selectedRange;
    range.location = location + 1;
    [_lastBecomeFirstRespondTextView setSelectedRange:range];
}

#pragma mark – AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    DDLogInfo(@"%s",__FUNCTION__);
    player = nil;
}

#pragma mark – UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    DDLogInfo(@"%s",__FUNCTION__);
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
                   DDLogInfo(@"%s:unvalid url adress",__FUNCTION__);
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Invalid YouTube url, it must be a full url - for example: http://www.youtube.com/watch?v=3-EaGGPGiJY" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                } else {
                    
                    [self thumbnailImageFromURL:[NSURL URLWithString:[Common embeddedYoutubeURL:youtbueLinkage]]];
                    
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
        default:
            break;
    }
}

#pragma mark – PopoverviewDelegate

/**
 *  两种情况：
 *  1. 点击image
 *  2. 点击_backgroundImageSelectButton
 */
- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
    DDLogInfo(@"%s",__FUNCTION__);
    
    if (popoverView.tag == Type_PopoverView_SelectImage) {
      [popoverView dismiss];
        
        if (index == 1) {
            [self selectImageOrVideoFromLibrary];
        } else {
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
        }
    } else {
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
            _typeImageSelector = Type_Image_Selector_Background;
            [self selectFromImageLibrary:_backgroundImageSelectButton withPopoverArrowUp:NO  supportMov:NO];
        }
    }
    
    
    
    
    
}




#pragma mark -
#pragma mark - Memory management

- (void)dealloc {
    DDLogInfo(@"%s",__FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _imagePickerController = nil;
    _imagePickerPopover = nil;
    _selectTemplatePopoverController = nil;
    
    _audioPlayer = nil;
    
    DDLogInfo(@"%s",__FUNCTION__);
}


@end
