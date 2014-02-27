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

extern BOOL isFromNewCreatedCard;

#define kSegmentLeftMarginForiPad 150.0
#define kSegmentHeightForiPad 44.0
#define kSegmentButtomMarginForiPad 10.0
#define kQuestionViewTopMarginForiPad 10.0
#define kQuestionViewButtomMarginForiPad 80.0
#define kQuestionViewCornerRadiusForiPad 20.0

#define kSegmentLeftMarginForiPhone 60.0
#define kSegmentHeightForiPhone 22.0
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

#define KEYBOARD_ANIMATION_DURATION 0.25

@interface FlashCard ()


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
            NSLog(@"%s:Check your code, it could be possiblly an issue",__FUNCTION__);
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
    
    _isUITextViewFocused = NO;
    
    _isAllCardsLogoNeedToBeUpdate = NO;
    _isTextFieldsChanged = NO;
    _doneButtonPressed = NO;
    _backgroundImageName = @"card_background_blue.png";
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
    
    [self setUpInputView];
    [self setUpInputAccessoryView];
    
    _keyboardSwitchButtonType = KeyboardSwitchButtonTypeSystem;
    
    self.backgroundColor = [UIColor clearColor];

}



#pragma mark -
#pragma mark - Layout view

- (void) loadQuestionAnswerViewForiPad {
    
    if (_backgroundImageView == nil) {
        _backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:_backgroundImageName]];
        _backgroundImageView.contentMode = UIViewContentModeScaleToFill;
        _backgroundImageView.frame = CGRectMake(0, 0, 800, 550);
        _backgroundImageView.backgroundColor = [UIColor whiteColor];
        _backgroundImageView.userInteractionEnabled = NO;
        _backgroundImageView.layer.masksToBounds = YES;
        _backgroundImageView.layer.cornerRadius = 35;
        [self addSubview:_backgroundImageView];
    }
    

    if (_questionTitle == nil) {
        _questionTitle = [[UITextField alloc]init];
        _questionTitle.frame = CGRectMake(80, 30, 400, 110);
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
        _questionTitle.keyboardType = UIKeyboardAppearanceDefault;
        _questionTitle.returnKeyType = UIReturnKeyDone;
        _questionTitle.tag = kTagTitleQuestion;
        [self addSubview:_questionTitle];
    }
    
    if (_answerTitle == nil) {
        _answerTitle = [[UITextField alloc]init];
        _answerTitle.frame = CGRectMake(80, 30, 400, 110);
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
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
        [_imageQuestion addGestureRecognizer:imageSingeTap];
    }
    
    if (_subheadingQuestion == nil) {
        _subheadingQuestion = [[UITextView alloc]init];
        _subheadingQuestion.tag = kTagSubheadingQuestion;
        _subheadingQuestion.font =[UIFont boldSystemFontOfSize:28];
        _subheadingQuestion.userInteractionEnabled = FALSE;
        _subheadingQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _subheadingQuestion.returnKeyType = UIReturnKeyDefault;
        _subheadingQuestion.delegate = self;
        _subheadingQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _subheadingQuestion.backgroundColor = [UIColor clearColor];
        [_verticalScrollView addSubview:_subheadingQuestion];
    }
    
    if (_mainQuestion == nil) {
        _mainQuestion = [[UITextView alloc]init];
        _mainQuestion.tag = kTagMainQuestion;
        _mainQuestion.font =[UIFont boldSystemFontOfSize:28];
        _mainQuestion.userInteractionEnabled = FALSE;
        _mainQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _mainQuestion.returnKeyType = UIReturnKeyDefault;
        _mainQuestion.delegate = self;
        _mainQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _mainQuestion.backgroundColor = [UIColor clearColor];
        [_verticalScrollView addSubview:_mainQuestion];
    }
    
    
    if (_subQuestion == nil) {
        _subQuestion = [[UITextView alloc]init];
        _subQuestion.tag = kTagSubQuestion;
        _subQuestion.font =[UIFont boldSystemFontOfSize:28];
        _subQuestion.userInteractionEnabled = FALSE;
        _subQuestion.keyboardType = UIKeyboardAppearanceDefault;
        _subQuestion.returnKeyType = UIReturnKeyDefault;
        _subQuestion.delegate = self;
        _subQuestion.autocorrectionType = UITextAutocorrectionTypeYes;
        _subQuestion.backgroundColor = [UIColor clearColor];
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
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
        [_imageAnswer addGestureRecognizer:imageSingeTap];
    }
    
    _imageAnswer.hidden = YES;
    
    if (_subheadingAnswer == nil) {
        _subheadingAnswer = [[UITextView alloc]init];
        _subheadingAnswer.tag = kTagSubheadingAnswer;
        _subheadingAnswer.font =[UIFont boldSystemFontOfSize:28];
        _subheadingAnswer.userInteractionEnabled = FALSE;
        _subheadingAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _subheadingAnswer.returnKeyType = UIReturnKeyDefault;
        _subheadingAnswer.delegate = self;
        _subheadingAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _subheadingAnswer.backgroundColor = [UIColor clearColor];
        [_verticalScrollView addSubview:_subheadingAnswer];
    }
    _subheadingAnswer.hidden = TRUE;
    
    if (_mainAnswer == nil) {
        _mainAnswer = [[UITextView alloc]init];
        _mainAnswer.tag = kTagMainAnswer;
        _mainAnswer.font =[UIFont boldSystemFontOfSize:28];
        _mainAnswer.userInteractionEnabled = FALSE;
        _mainAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _mainAnswer.returnKeyType = UIReturnKeyDefault;
        _mainAnswer.delegate = self;
        _mainAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _mainAnswer.backgroundColor = [UIColor clearColor];
        [_verticalScrollView addSubview:_mainAnswer];
    }
    _mainAnswer.hidden = TRUE;
    
    
    if (_subAnswer == nil) {
        _subAnswer = [[UITextView alloc]init];
        _subAnswer.tag = kTagSubAnswer;
        _subAnswer.font =[UIFont boldSystemFontOfSize:28];
        _subAnswer.userInteractionEnabled = FALSE;
        _subAnswer.keyboardType = UIKeyboardAppearanceDefault;
        _subAnswer.returnKeyType = UIReturnKeyDefault;
        _subAnswer.delegate = self;
        _subAnswer.autocorrectionType = UITextAutocorrectionTypeYes;
        _subAnswer.backgroundColor = [UIColor clearColor];
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
    
    if (_changeTemplateButton == nil) {
        _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeTemplateButton.frame = CGRectMake(kFlashCardViewWidth_Detail_iPad-45-5, kFlashCardViewHeight_Detail_iPad-kQuestionViewButtomMarginForiPad-60, 40, 40);
        [_changeTemplateButton setBackgroundImage:[UIImage imageNamed:@"change_template_button.png"] forState:UIControlStateNormal];
        [self addSubview:_changeTemplateButton];
        [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
    }
    
    if (_segmentedControl == nil) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                             @[NSLocalizedString(@"ToolbarItem_Question",nil),
                             NSLocalizedString(@"ToolbarItem_Answer",nil)]];

        
        CGRect frame = CGRectMake(kSegmentLeftMarginForiPad,
                                  self.bounds.size.height-kSegmentHeightForiPad-kSegmentButtomMarginForiPad,
                                  self.bounds.size.width-2*kSegmentLeftMarginForiPad,
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
        _logoImage.frame = CGRectMake(660, 10, 120, 120);
        _logoImage.clipsToBounds = YES;
        _logoImage.backgroundColor = [UIColor clearColor];
        _logoImage.userInteractionEnabled = TRUE; //alway true
        _logoImage.layer.cornerRadius = 8;
        _logoImage.layer.masksToBounds = YES;
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
        des.frame = CGRectMake(540, 45, 90, 50);
        des.textAlignment = NSTextAlignmentLeft;
        des.backgroundColor = [UIColor clearColor];
        des.font = [UIFont systemFontOfSize:12];
        des.textColor = [UIColor grayColor];
        des.text = @"Created by:";
        des.userInteractionEnabled = FALSE;
        [self addSubview:des];
        
        
        _creatorText = [[UITextField alloc] init];
        _creatorText.frame = CGRectMake(540, 70, 90, 50);
        _creatorText.textAlignment = NSTextAlignmentLeft;
        _creatorText.backgroundColor = [UIColor clearColor];
        _creatorText.font = [UIFont systemFontOfSize:12];
        _creatorText.textColor = [UIColor grayColor];
        _creatorText.userInteractionEnabled = FALSE;
        _creatorText.delegate = self;
        _creatorText.keyboardType = UIKeyboardAppearanceDefault;
        _creatorText.returnKeyType = UIReturnKeyDone;
        _creatorText.tag = kTagCreator;
        [self addSubview:_creatorText];
    }

}


- (void) loadQuestionAnswerViewForiPhone {
    
    if (_backgroundImageView == nil) {
        _backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:_backgroundImageName]];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.backgroundColor = [UIColor whiteColor];
        _backgroundImageView.frame = CGRectMake(0, 0, kFlashCardViewWidth_Detail_iPhone, kFlashCardViewHeight_Detail_iPhone);
        if (self.isPlayingCard) {
            _backgroundImageView.frame = [Common getScaledViewRect:_backgroundImageView withProportion:kFlashCardViewProporation_iPhone];
        }
        _backgroundImageView.userInteractionEnabled = NO;
        _backgroundImageView.layer.masksToBounds = YES;
        _backgroundImageView.layer.cornerRadius = 15;
        [self addSubview:_backgroundImageView];
    }
    
    
    if (_questionTitle == nil) {
        _questionTitle = [[UITextField alloc]init];
        _questionTitle.frame = CGRectMake(40, 10, 200, 40);
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
        [self addSubview:_questionTitle];
    }
    
    if (_answerTitle == nil) {
        _answerTitle = [[UITextField alloc]init];
        _answerTitle.frame = CGRectMake(40, 10, 200, 40);
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
        _sidebarTitle.backgroundColor = [UIColor clearColor];
        _sidebarTitle.font = [UIFont systemFontOfSize:12];
        if (self.isPlayingCard) {
            _sidebarTitle.font =[UIFont systemFontOfSize:12*kFlashCardViewProporation_iPhone];
        }
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
        _cardSNText = [[JSBadgeView alloc] initWithParentView:self offset:point];
        if (self.isPlayingCard) {
            _cardSNText.frame = [Common getScaledViewRect:_cardSNText withProportion:kFlashCardViewProporation_iPhone];
        }
        
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
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
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
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
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
        [_verticalScrollView addSubview:_subAnswer];
    }
    _subAnswer.hidden = YES;
    
    if (_segmentedControl == nil) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                             @[NSLocalizedString(@"ToolbarItem_Question",nil),
                             NSLocalizedString(@"ToolbarItem_Answer",nil)]];
        
        CGRect frame = CGRectMake(kSegmentLeftMarginForiPhone,
                                  self.bounds.size.height-kSegmentHeightForiPhone-kSegmentButtomMarginForiPhone,
                                  self.bounds.size.width-2*kSegmentLeftMarginForiPhone,
                                  kSegmentHeightForiPhone);
        _segmentedControl.frame = frame;
        [_segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
        _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        _segmentedControl.selectedSegmentIndex = 0;
        [self addSubview:_segmentedControl];
    }
    
    if (_changeTemplateButton == nil) {
        _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeTemplateButton.frame = CGRectMake(kFlashCardViewWidth_Detail_iPhone-25-2, kFlashCardViewHeight_Detail_iPhone-22-5, 22, 20);
        if (self.isPlayingCard) {
            _changeTemplateButton.frame = [Common getScaledViewRect:_changeTemplateButton withProportion:kFlashCardViewProporation_iPhone];
        }
        [_changeTemplateButton setBackgroundImage:[UIImage imageNamed:@"change_template_button.png"] forState:UIControlStateNormal];
        [self addSubview:_changeTemplateButton];
        [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
    }
    
    if (_logoImage == nil){
        _logoImage = [[UIImageView  alloc] init];
        _logoImage.contentMode = UIViewContentModeScaleAspectFit;
        _logoImage.frame = CGRectMake(330, 5, 64, 40);
        if (self.isPlayingCard) {
            _logoImage.frame = [Common getScaledViewRect:_logoImage withProportion:kFlashCardViewProporation_iPhone];
        }
        _logoImage.clipsToBounds = YES;
        _logoImage.backgroundColor = [UIColor clearColor];
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
        des.frame = CGRectMake(250, 15, 68, 15);
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
        _creatorText.frame = CGRectMake(250, 25, 68, 15);
        if (self.isPlayingCard) {
            _creatorText.frame = [Common getScaledViewRect:_creatorText withProportion:kFlashCardViewProporation_iPhone];
        }
        _creatorText.textAlignment = NSTextAlignmentLeft;
        _creatorText.backgroundColor = [UIColor clearColor];
        _creatorText.font = [UIFont systemFontOfSize:8];
        if (self.isPlayingCard) {
            _creatorText.font =[UIFont systemFontOfSize:8*kFlashCardViewProporation_iPhone];
        }
        _creatorText.textColor = [UIColor grayColor];
        _creatorText.userInteractionEnabled = FALSE;
        _creatorText.delegate = self;
        _creatorText.keyboardType = UIKeyboardAppearanceDefault;
        _creatorText.returnKeyType = UIReturnKeyDone;
        _creatorText.tag = kTagCreator;
        [self addSubview:_creatorText];
    }
    
    
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
    
    _logoLinkageButton.hidden = TRUE;
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWebviewViaLogoURL:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    _imageQuestion.userInteractionEnabled        = FALSE;
    _imageQuestion.layer.borderWidth = 0;
    _mainQuestion.userInteractionEnabled         = FALSE;
    _mainQuestion.layer.borderWidth = 0;
    _subQuestion.userInteractionEnabled          = FALSE;
    _subQuestion.layer.borderWidth = 0;
    _subheadingQuestion.userInteractionEnabled   = FALSE;
    _subheadingQuestion.layer.borderWidth = 0;
    
    _imageAnswer.userInteractionEnabled        = FALSE;
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
    
    _changeTemplateButton.hidden = TRUE;
    
    if (_isPlayingCard) {
        _creatorText.userInteractionEnabled = TRUE;
        UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWebviewViaLogoURL:)];
        [_creatorText addGestureRecognizer:logoSingeTap];
    } else {
        _creatorText.userInteractionEnabled = FALSE;
    }
}

- (void) enableCardEdit{
    
    _logoLinkageButton.hidden = FALSE;
    
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    _imageQuestion.userInteractionEnabled        = TRUE;
    _imageQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _imageQuestion.layer.borderWidth = 2;
    } else {
        _imageQuestion.layer.borderWidth = 3;
    }
    
    _mainQuestion.userInteractionEnabled         = TRUE;
    _mainQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _mainQuestion.layer.borderWidth = 2;
    } else {
        _mainQuestion.layer.borderWidth = 3;
    }
    _subQuestion.userInteractionEnabled          = TRUE;
    _subQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subQuestion.layer.borderWidth = 2;
    } else {
        _subQuestion.layer.borderWidth = 3;
    }
    _subheadingQuestion.userInteractionEnabled   = TRUE;
    _subheadingQuestion.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subheadingQuestion.layer.borderWidth = 2;
    } else {
        _subheadingQuestion.layer.borderWidth = 3;
    }
    
    _imageAnswer.userInteractionEnabled        = TRUE;
    _imageAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _imageAnswer.layer.borderWidth = 2;
    } else {
        _imageAnswer.layer.borderWidth = 3;
    }
    
    _mainAnswer.userInteractionEnabled         = TRUE;
    _mainAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _mainAnswer.layer.borderWidth = 2;
    } else {
        _mainAnswer.layer.borderWidth = 3;
    }
    _subAnswer.userInteractionEnabled          = TRUE;
    _subAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subAnswer.layer.borderWidth = 2;
    } else {
        _subAnswer.layer.borderWidth = 3;
    }
    _subheadingAnswer.userInteractionEnabled   = TRUE;
    _subheadingAnswer.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subheadingAnswer.layer.borderWidth = 2;
    } else {
        _subheadingAnswer.layer.borderWidth = 3;
    }
    
    _changeTemplateButton.hidden = FALSE;
    _changeTemplateButton.userInteractionEnabled = YES;
    
    _questionTitle.userInteractionEnabled = YES;
    _answerTitle.userInteractionEnabled = YES;
    
    _sidebarTitle.userInteractionEnabled = YES;
    _creatorText.userInteractionEnabled = YES;
}



#pragma mark -
#pragma mark - Refresh

- (void) refreshAll {
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
    }
    
    [self updateUITextViewPaddingTop];
    
    [self adjustAllTextViewsToFitIfNecessary];
    

}


- (void) resetVerticalScrollViewOffset {
    //reset offset
    CGPoint offset = _verticalScrollView.contentOffset;
    offset.y = 0;
    [_verticalScrollView setContentOffset:offset animated:YES];
}


- (void) updateUITextViewPaddingTop {
    _subheadingQuestion.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subheadingSizeQuestion], 0, 0, 0.0);
    _subheadingAnswer.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subheadingSizeAnswer], 0, 0, 0.0);
    _mainQuestion.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_mainSizeQuestion], 0, 0, 0.0);
    _mainAnswer.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_mainSizeAnswer], 0, 0, 0.0);
    _subQuestion.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subSizeQuestion], 0, 0, 0.0);
    _subAnswer.contentInset = UIEdgeInsetsMake([self setTextViewTopPadding:_subSizeAnswer], 0, 0, 0.0);
}


- (void) refreshQuestionAndAnswerContent {
    [self refreshQuestionContent];
    [self refreshAnswerContent];
    
    _cardSNText.badgeText= [NSString stringWithFormat:@"%d",_currentCard.cardSN];
    
    //it's quite strange logic below, but it indeed
    if ((_currentPack.sidebarTitle.length == 0) || ([_currentPack.sidebarTitle rangeOfString:@"null"].length != 0)) {
        _sidebarTitle.text = _currentPack.packName;
    } else {
        _sidebarTitle.text = _currentPack.sidebarTitle;
    }
    _backgroundImageName = _currentCard.templateBackgroundName;
    _backgroundImageView.image = [UIImage imageNamed:_backgroundImageName];
    
    _creatorText.text = [NSString stringWithFormat:@"%@",_currentPack.creatorNickName];
    
    NSString *logoFullPath = _currentCard.question.logoFullPath;
    if (((logoFullPath.length == 0) || ([logoFullPath rangeOfString:@"placeholder"].location != NSNotFound)) && (_isPlayingCard == true)) {
        _logoImage.hidden = true;
    } else {
        _logoImage.hidden = false;
    }
    
    
    
}

- (void) refreshAnswerContent {
    
    NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.answer.imageFullPath lastPathComponent]];
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:path];
    _answerImageFullPath = path;
    if (imageTemp) {
        _imageAnswer.image = imageTemp;
    } else {
        NSLog(@"%s:Use answer_placeholder_content.jpg as self.imageAnswer",__FUNCTION__);
        _imageAnswer.image = [UIImage imageNamed:@"answer_placeholder_content.jpg"];
    }
    
    _answerTitle.text = _currentCard.answer.title;

    _subheadingAnswer.text = _currentCard.answer.subheading;
    _mainAnswer.text =_currentCard.answer.main;
    _subAnswer.text =_currentCard.answer.sub;
    
}

- (void) refreshQuestionContent {
    
    NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.imageFullPath lastPathComponent]];
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:path];
    _questionImageFullPath = path;
    if (imageTemp) {
        _imageQuestion.image = imageTemp;
    } else {
        NSLog(@"%s:Set question_placeholder_content.jpg as self.imageQuestion",__FUNCTION__);
        _imageQuestion.image = [UIImage imageNamed:@"question_placeholder_content.jpg"];
    }
    
    path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.logoFullPath lastPathComponent]];
    imageTemp = [UIImage imageWithContentsOfFile:path];
    if (imageTemp) {
        _logoImage.image = imageTemp;
    } else {
        NSLog(@"%s:Use placeholder logo image for self.logoImage",__FUNCTION__);
        _logoImage.image = [UIImage imageNamed:@"question_placeholder_logo.jpg"];
    }
    
    _questionTitle.text = _currentCard.question.title;
    
    _subheadingQuestion.text = _currentCard.question.subheading;
    _mainQuestion.text =_currentCard.question.main;
    _subQuestion.text =_currentCard.question.sub;
}


#pragma mark -
#pragma mark Segment callback

- (void) showQuestionOrAnswer {
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
    }
}


- (void)segmentAction:(id)sender
{
	[self refreshAll];
}

- (void) doQuestionAndAnswerData {
    _currentCard.answer.title = _answerTitle.text;
    _currentCard.answer.subheading = _subheadingAnswer.text;
    _currentCard.answer.main = _mainAnswer.text;
    _currentCard.answer.sub = _subAnswer.text;
    _currentCard.answer.imageFullPath = _answerImageFullPath;
    
    _currentCard.answer.css.subheadingAlign = _subheadingAlignAnswer;
    _currentCard.answer.css.subheadingColor = _subheadingColorAnswer;
    _currentCard.answer.css.subheadingSize = _subheadingSizeAnswer;
    _currentCard.answer.css.mainAlign = _mainAlignAnswer;
    _currentCard.answer.css.mainColor = _mainColorAnswer;
    _currentCard.answer.css.mainSize = _mainSizeAnswer;
    _currentCard.answer.css.subAlign = _subAlignAnswer;
    _currentCard.answer.css.subColor = _subColorAnswer;
    _currentCard.answer.css.subSize = _subSizeAnswer;
    
    _currentCard.question.title = _questionTitle.text;
    _currentCard.question.subheading = _subheadingQuestion.text;
    _currentCard.question.main = _mainQuestion.text;
    _currentCard.question.sub = _subQuestion.text;
    _currentCard.question.imageFullPath = _questionImageFullPath;
    
    _currentCard.question.css.subheadingAlign = _subheadingAlignQuestion;
    _currentCard.question.css.subheadingColor = _subheadingColorQuestion;
    _currentCard.question.css.subheadingSize = _subheadingSizeQuestion;
    _currentCard.question.css.mainAlign = _mainAlignQuestion;
    _currentCard.question.css.mainColor = _mainColorQuestion;
    _currentCard.question.css.mainSize = _mainSizeQuestion;
    _currentCard.question.css.subAlign = _subAlignQuestion;
    _currentCard.question.css.subColor = _subColorQuestion;
    _currentCard.question.css.subSize = _subSizeQuestion;
    
    _currentPack.creatorNickName = _creatorText.text;
    _currentPack.sidebarTitle = _sidebarTitle.text;
}


#pragma mark -
#pragma mark - Update CSS (only CSS)

//CSS part which is included in three main parts: CSS, template(position) and content
- (void) updateQuestionAndAnswerCSS {
    
    if (_currentCard == nil) {
        [Common alertViewCommon:@"Need to set currentCard beforehand"];
    }
    
    //PartA: Question
    CSS *css = _currentCard.question.css;
    //1. subheading
    //during creating a new card, we used default value
    _subheadingQuestion.font = [UIFont boldSystemFontOfSize:css.subheadingSize];
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        _subheadingQuestion.font =[UIFont boldSystemFontOfSize:css.subheadingSize*kFlashCardViewProporation_iPhone];
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
    }
    
    //2. main
    //during creating a new card, we used default value
    _mainQuestion.font = [UIFont boldSystemFontOfSize:css.mainSize];
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        _mainQuestion.font =[UIFont systemFontOfSize:css.mainSize*kFlashCardViewProporation_iPhone];
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
    }
    
    //3. sub
    //during creating a new card, we used default value
    _subQuestion.font = [UIFont boldSystemFontOfSize:css.subSize];
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        _subQuestion.font =[UIFont systemFontOfSize:css.subSize*kFlashCardViewProporation_iPhone];
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
    }
    
    
    //PartB: Answer
    css= _currentCard.answer.css;
    //1. subheading
    //during creating a new card, we used default value
    _subheadingAnswer.font = [UIFont boldSystemFontOfSize:css.subheadingSize];
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        _subheadingAnswer.font =[UIFont boldSystemFontOfSize:css.subheadingSize*kFlashCardViewProporation_iPhone];
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
    }
    
    //2. main
    //during creating a new card, we used default value
    _mainAnswer.font = [UIFont boldSystemFontOfSize:css.mainSize];
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        _mainAnswer.font =[UIFont systemFontOfSize:css.mainSize*kFlashCardViewProporation_iPhone];
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
    }
    
    //3. sub
    //during creating a new card, we used default value
    _subAnswer.font = [UIFont boldSystemFontOfSize:css.subSize];
    if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
        _subAnswer.font =[UIFont systemFontOfSize:css.subSize*kFlashCardViewProporation_iPhone];
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
    }
}


#pragma mark -
#pragma mark - Update template (postion and css, but css will be rewrited by updateCSS)

- (void) updateQuestionOrAnswerTemplate {
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
}

- (void) updateQuestionAndAnswerTemplate {
    if (isUserInterfaceIdiomPhone) {
        [self updateQuestionViewTemplateForiPhone];
        [self updateAnswerViewTemplateForiPhone];
    }
    else {
        [self updateQuestionViewTemplateForiPad];
        [self updateAnswerViewTemplateForiPad];
    }
}

//postion part which is included in three main parts: CSS, template(position) and content
- (void) updateAnswerViewTemplateForiPhone {
    
    int index = _currentCard.answer.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(1, 0, 210, 30);
            if (self.isPlayingCard) {
                _subheadingAnswer.frame = [Common getScaledViewRect:_subheadingAnswer withProportion:kFlashCardViewProporation_iPhone];
            }
            _subheadingAnswer.font = [UIFont boldSystemFontOfSize:20];
            if (self.isPlayingCard) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
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
            _mainAnswer.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _mainAnswer.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _subheadingAnswer.font = [UIFont boldSystemFontOfSize:20];
            if (self.isPlayingCard) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
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
            _mainAnswer.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _mainAnswer.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _subAnswer.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _subAnswer.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _subheadingAnswer.font = [UIFont boldSystemFontOfSize:20];
            if (self.isPlayingCard) {
                _subheadingAnswer.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
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
            _mainAnswer.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _mainAnswer.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _mainAnswer.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _mainAnswer.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _mainAnswer.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _mainAnswer.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            
        default:
        {
            NSLog(@"%s:No template is selected",__FUNCTION__);
            break;
        }
            
    }
}

- (void) updateAnswerViewTemplateForiPad{
    
    int index = _currentCard.answer.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingAnswer.hidden = FALSE;
            _subheadingAnswer.frame = CGRectMake(10, 10, 360, 80);
            _subheadingAnswer.font = [UIFont boldSystemFontOfSize:34];
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentCenter;
            _subheadingAlignAnswer = @"Center";
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 34;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 100, 360, 320);
            _mainAnswer.font = [UIFont boldSystemFontOfSize:30];
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
            _subheadingAnswer.font = [UIFont boldSystemFontOfSize:42];
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 75, 360, 295);
            _mainAnswer.font = [UIFont boldSystemFontOfSize:38];
            _mainAnswer.textColor = [UIColor blackColor];
            _mainAnswer.textAlignment = NSTextAlignmentLeft;
            _mainAlignAnswer = @"Left";
            _mainColorAnswer = @"Black";
            _mainSizeAnswer = 38;
            
            _subAnswer.hidden = FALSE;
            _subAnswer.frame = CGRectMake(10, 380, 360, 50);
            _subAnswer.font = [UIFont boldSystemFontOfSize:38];
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
            _subheadingAnswer.font = [UIFont boldSystemFontOfSize:42];
            _subheadingAnswer.textColor = [UIColor blackColor];
            _subheadingAnswer.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignAnswer = @"Left";
            _subheadingColorAnswer = @"Black";
            _subheadingSizeAnswer = 42;
            
            _mainAnswer.hidden = FALSE;
            _mainAnswer.frame = CGRectMake(10, 75, 360, 355);
            _mainAnswer.font = [UIFont boldSystemFontOfSize:34];
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
            _mainAnswer.font = [UIFont boldSystemFontOfSize:34];
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
            _mainAnswer.font = [UIFont boldSystemFontOfSize:34];
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
            
        default:
        {
            NSLog(@"%s:No template is selected",__FUNCTION__);
            break;
        }
            
    }
}


//postion part which is included in three main parts: CSS, template(position) and content
- (void) updateQuestionViewTemplateForiPad {
    
    int index = _currentCard.question.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(10, 20, 700, 50);
            _subheadingQuestion.font = [UIFont boldSystemFontOfSize:30];
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 30;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 75, 700, 350);
            _mainQuestion.font = [UIFont boldSystemFontOfSize:38];
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
            _subheadingQuestion.font = [UIFont boldSystemFontOfSize:34];
            _subheadingQuestion.textColor = [UIColor blackColor];
            _subheadingQuestion.textAlignment = NSTextAlignmentLeft;
            _subheadingAlignQuestion = @"Left";
            _subheadingColorQuestion = @"Black";
            _subheadingSizeQuestion = 34;
            
            _mainQuestion.hidden = FALSE;
            _mainQuestion.frame = CGRectMake(10, 75, 700, 180);
            _mainQuestion.font = [UIFont boldSystemFontOfSize:38];
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 38;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(10, 260, 700, 160);
            _subQuestion.font = [UIFont boldSystemFontOfSize:30];
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
            _mainQuestion.font = [UIFont boldSystemFontOfSize:42];
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 42;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(10, 320, 700, 100);
            _subQuestion.font = [UIFont boldSystemFontOfSize:34];
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
            _mainQuestion.font = [UIFont boldSystemFontOfSize:42];
            _mainQuestion.textColor = [UIColor blackColor];
            _mainQuestion.textAlignment = NSTextAlignmentCenter;
            _mainAlignQuestion = @"Center";
            _mainColorQuestion = @"Black";
            _mainSizeQuestion = 42;
            
            _subQuestion.hidden = FALSE;
            _subQuestion.frame = CGRectMake(10, 230, 700, 190);
            _subQuestion.font = [UIFont boldSystemFontOfSize:34];
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
            _mainQuestion.font = [UIFont boldSystemFontOfSize:42];
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
            
        default:
        {
            NSLog(@"%s:No template is selected",__FUNCTION__);
            break;
        }
            
    }
}

- (void) updateQuestionViewTemplateForiPhone {
    
    int index = _currentCard.question.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheadingQuestion.hidden = FALSE;
            _subheadingQuestion.frame = CGRectMake(1, 5, 350, 39);
            if (self.isPlayingCard) {
                _subheadingQuestion.frame = [Common getScaledViewRect:_subheadingQuestion withProportion:kFlashCardViewProporation_iPhone];
            }
            _subheadingQuestion.font = [UIFont boldSystemFontOfSize:20];
            if (self.isPlayingCard) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
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
            _mainQuestion.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _mainQuestion.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _subheadingQuestion.font = [UIFont boldSystemFontOfSize:20];
            if (self.isPlayingCard) {
                _subheadingQuestion.font =[UIFont boldSystemFontOfSize:20*kFlashCardViewProporation_iPhone];
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
            _mainQuestion.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _mainQuestion.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _subQuestion.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _subQuestion.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _mainQuestion.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _mainQuestion.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _subQuestion.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _subQuestion.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _mainQuestion.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _mainQuestion.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _subQuestion.font = [UIFont boldSystemFontOfSize:16];
            if (self.isPlayingCard) {
                _subQuestion.font =[UIFont systemFontOfSize:16*kFlashCardViewProporation_iPhone];
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
            _mainQuestion.font = [UIFont boldSystemFontOfSize:14];
            if (self.isPlayingCard) {
                _mainQuestion.font =[UIFont systemFontOfSize:14*kFlashCardViewProporation_iPhone];
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
    
        default:
        {
            NSLog(@"%s:No template is selected",__FUNCTION__);
            break;
        }
            
    }
}

#pragma mark -
#pragma mark - Keyboard Notification and related

- (void)keyboardWillHide:(NSNotification*)aNotification {
    
    //we only deal with current card and new created card
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        return;
    }
    
}


- (void)keyboardWillShow:(NSNotification*)aNotification {
    
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
    //NSLog(@"Y position for current cursorY is %f",cursorY);
    
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
            [self doQuestionAndAnswerData];
            [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_NEW_CREATED_CARD_NOTIFICATION object:nil];
        } else {
            [self saveEdittedCard];
        }
    }
    
    
    
}

// For keyboard input view (top parts)
- (void) setInputViewTopViewItems  {
    
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
        
        _buttonArrayForInputView = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,_emotionButtonForInputView,btnSpace,btnSpace,closeButtonItem,doneButtonItem,nil];
        
    } else {
        _buttonArrayForInputView = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,_emotionButtonForInputView,btnSpace,btnSpace,btnSpace,doneButtonItem,nil];
    }
    
    
    

    
}


// For keyboard input accessary view
- (void) setInputAccessoryViewItems  {
    
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
        _buttonArray = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,_emotionButton,btnSpace,btnSpace,closeButtonItem,doneButtonItem,nil];
        
    } else {
        _buttonArray = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,_emotionButton,btnSpace,btnSpace,btnSpace,doneButtonItem,nil];
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
    
    //Color Array
    UIBarButtonItem *redButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Red",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *blueButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Blue",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *blackButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Black",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *yelloButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Yellow",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *greenButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Green",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    if (_colorArray == nil) {
        _colorArray = [NSArray arrayWithObjects:backButton,redButton,blueButton,blackButton,yelloButton,greenButton,nil];
    }
    
    //Align Array
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Left",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    UIBarButtonItem *centerButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Center",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Right",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    if (_alignArray == nil) {
        _alignArray = [NSArray arrayWithObjects:backButton,leftButton,centerButton,rightButton,nil];
    }
    
}


- (void) setUpInputView {
    
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

- (void)selectFromImageLibraryByLogo:(UITapGestureRecognizer *)sender {
    
    _isLogoImageViewClicked = YES;
    
    if (_imagePickerController != nil) {
        _imagePickerPopover = nil;
    }
    
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _imagePickerController.navigationBar.barStyle = UIBarStyleBlack;
    _imagePickerController.contentSizeForViewInPopover = CGSizeMake(320, 400);
    _imagePickerController.delegate = self;
    
    if (isUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:_imagePickerController animated:YES];
    } else {
        CGPoint point = [sender locationInView:self];
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        
        if (_imagePickerPopover != nil) {
            [_imagePickerPopover dismissPopoverAnimated:YES];
            _imagePickerPopover=nil;
        }
        
        _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_imagePickerController];
        _imagePickerPopover.delegate = self;
        [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    
    
    
}

- (void)selectFromImageLibraryByImage:(UITapGestureRecognizer *)sender {
    
    _isLogoImageViewClicked = NO;
    
    if (_imagePickerController != nil) {
        _imagePickerPopover = nil;
    }
    
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _imagePickerController.navigationBar.barStyle = UIBarStyleBlack;
    _imagePickerController.contentSizeForViewInPopover = CGSizeMake(320, 400);
    _imagePickerController.delegate = self;
    
    if (isUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:_imagePickerController animated:YES];
    } else {
        CGPoint point = [sender locationInView:self];
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        
        if (_imagePickerPopover != nil) {
            [_imagePickerPopover dismissPopoverAnimated:YES];
            _imagePickerPopover=nil;
        }
        
        _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_imagePickerController];
        _imagePickerPopover.delegate = self;
        [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
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
    
    _logoImageFullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentCard.question.logoFullPath lastPathComponent]];
    
    if (_isLogoImageViewClicked) {
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
        
    } else {
        
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
    }
}

- (void) execUpdatelogoImageForAllCards:(NSString *)logoImageFullPath {
    [self updatelogoImageForAllCards:logoImageFullPath];
    [_HUD removeFromSuperview];
    _HUD = nil;
}

- (UIImage *)captureWholeViewAsImage {
    
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
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}


#pragma mark -
#pragma mark - Text edit function

- (void) sizeUpDownAction {
    [_keyboardTopView setItems:_fontSizeArray animated:TRUE];
}

- (void) selectColorAction {
    [_keyboardTopView setItems:_colorArray animated:TRUE];
}

- (void) alignAction {
    [_keyboardTopView setItems:_alignArray animated:TRUE];
}

- (void) sizeUpDownActionForInputView {
    [_keyboardTopViewForInputView setItems:_fontSizeArray animated:TRUE];
}

- (void) selectColorActionForInputView {
    [_keyboardTopViewForInputView setItems:_colorArray animated:TRUE];
}

- (void) alignActionForInputView {
    [_keyboardTopViewForInputView setItems:_alignArray animated:TRUE];
}

- (void) emotionAndKeyboardSwitch:(id) sender {
    
    [_lastBecomeFirstRespondTextView resignFirstResponder];
    
    if (_lastBecomeFirstRespondTextView.inputView == nil) {
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

- (void) changeFontSize:(id) sender{
    
    NSUInteger selectFontSize;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    
    UITextView *responderTextView = _lastBecomeFirstRespondTextView;
    
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size12",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:12];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:12*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 12;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size18",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:18];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:18*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 18;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size24",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:24];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:24*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 24;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size28",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:28];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:28*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 28;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size32",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:32];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:32*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 32;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size36",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:36];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:36*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 36;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size40",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:40];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:40*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 40;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size45",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:45];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:45*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 45;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size50",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:50];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:50*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 50;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size55",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:55];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:55*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 55;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size60",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:60];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:60*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 60;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size80",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:80];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:80*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 80;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size100",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:100];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:100*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 100;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size160",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:160];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:160*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 160;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Size260",nil)]) {
        responderTextView.font = [UIFont boldSystemFontOfSize:260];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:260*kFlashCardViewProporation_iPhone];
        }
        selectFontSize = 260;
    } else {
        responderTextView.font = [UIFont boldSystemFontOfSize:32];
        if ((self.isPlayingCard) && (isUserInterfaceIdiomPhone)) {
            responderTextView.font =[UIFont boldSystemFontOfSize:32*kFlashCardViewProporation_iPhone];
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
    [_keyboardTopView setItems:_buttonArray animated:TRUE];
    [_keyboardTopViewForInputView setItems:_buttonArrayForInputView animated:TRUE];
}

#pragma mark -
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {    
    _isUITextViewFocused = FALSE;
    _keyboardInputBaseView.hidden = TRUE;
    [_emotionButton setTitle:NSLocalizedString(@"ToolbarItem_Emotion",@"")];
    
    [_lastBecomeFirstRespondTextView setInputAccessoryView:_keyboardTopView];
    [_lastBecomeFirstRespondTextView setInputView:nil];
    _keyboardSwitchButtonType = KeyboardSwitchButtonTypeSystem;
    
    return TRUE;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    _isTextFieldsChanged = YES;
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (_isTextFieldsChanged == NO) {
        return;
    }
    
    if (self.tag == NEW_FLASHCARDVIEW_TAG) {
        //we will save until after we press the save button
        [self doQuestionAndAnswerData];
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
    } else {
        NSLog(@"%s:Error",__FUNCTION__);
    }
    
    [_HUD removeFromSuperview];
    _HUD = nil;
}




#pragma mark -
#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    //    CGRect frame = textView.frame;
    //    frame.size.height = textView.contentSize.height;
    //    textView.frame = frame;
    
}


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    _lastBecomeFirstRespondTextView = textView;
    _isUITextViewFocused = TRUE;
    _keyboardInputBaseView.hidden = FALSE;
    [_emotionButton setTitle:NSLocalizedString(@"ToolbarItem_Emotion",@"")];
    
    return TRUE;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
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
    
    NSLog(@"lineHeight = %f, height = %f, cursorY = %f",responderTextView.font.lineHeight,height,cursorY);
    
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
    alert.delegate = self;
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex ==1) {
        NSString *temp = [alertView textFieldAtIndex:0].text;
        
        if (![temp isEqualToString:_logoLinkURL]) {
            _logoLinkURL = temp;
            _currentCard.question.logoURLLinkage = temp;
            
            [self updatelogoURLForAllCards:temp];
            
        }
    }
}

- (void)openWebviewViaLogoURL:(UITapGestureRecognizer *)sender {
    
    NSString *str = _currentCard.question.logoURLLinkage;
    if ([str hasPrefix:@"http://"]) {
        
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
	[controller dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark - BaseViewDelegate

- (void) updatelogoURLForAllCards:(NSString *)urlString {
    for (Card *card in [_currentPack cards]) {
        card.question.logoURLLinkage =urlString;
        [card save];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
}

- (void) updatelogoImageForAllCards:(NSString *) imagePath {
    
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

// only adjust font size if text height > frame's height
- (void) adjustAllTextViewsToFitIfNecessary {
    if (_segmentedControl.selectedSegmentIndex == 0) {
        [self adjustFontToFit:_subheadingQuestion];
        [self adjustFontToFit:_mainQuestion];
        [self adjustFontToFit:_subQuestion];
    } else {
        [self adjustFontToFit:_subheadingAnswer];
        [self adjustFontToFit:_mainAnswer];
        [self adjustFontToFit:_subAnswer];
    }
}


- (void) adjustFontToFit:(UITextView *) textView {
    
    if ([_currentPack.creator isEqualToString:[OpenUDID value]]) {
        return;
    }
    
    if ((textView == NULL) || (textView.text.length ==0) || (textView.hidden == TRUE)) {
        return;
    }
    
    CGFloat frameHeight = textView.frame.size.height;
    CGFloat textHeight = textView.contentSize.height;
    CGFloat originalTextHeight = textHeight;
    UIFont  *font = textView.font;
    BOOL outputFlag = FALSE;
    
    
    int delta = 0;
    if (font.pointSize < 13) {
        delta = 10;
    } else {
        delta = fabsf([self setTextViewTopPadding:font.pointSize]);
    }
    
    while ((textHeight > frameHeight + delta)&&(textHeight >0)&&(font.pointSize >0)) {
//        textView.backgroundColor = [UIColor blueColor];
        font = textView.font;
        [textView setFont:[UIFont boldSystemFontOfSize:(font.pointSize -1)]];
        [textView layoutSubviews];
        textHeight = textView.contentSize.height;
        outputFlag = TRUE;
    }
    
    if (outputFlag == TRUE)
        NSLog(@"CardSN %d:Original text(%@) height:%f, final text height:%f, final font size is :%f",_currentCard.cardSN,textView.text,originalTextHeight, textView.contentSize.height, font.pointSize);
    
    textView.contentOffset = CGPointMake(0, 0);
    
    
}



- (void) saveEdittedCard {
    
    //we only deal with current card and new created card
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        return;
    }
    
    if (_currentPack == nil) {
        [Common alertViewCommon:@"Error to create new card, since _currentPack is nil"];
        return;
    }
    
    _currentCard.templateBackgroundName = _backgroundImageName;
    
    _currentCard.packID = _currentPack.packID;
    
    [self doQuestionAndAnswerData];
    
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


- (void) changeTemplateButtonClick:(id)sender {
    
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
            [_selectTemplatePopoverController presentPopoverFromRect:((UIButton *) sender).frame inView:self permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        } else {
            [_selectTemplatePopoverController dismissPopoverAnimated:YES];
            _selectTemplatePopoverController = nil;
        }
        
    }
}

- (void) dismissSelectTemplatePopoverController {
    [_selectTemplatePopoverController dismissPopoverAnimated:YES];
    _selectTemplatePopoverController = nil;
    
}

- (void) templateSelectedNotification: (NSNotification *) notification {
    
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
    
    [self updateQuestionOrAnswerTemplate];//we will do other side's update when clicking segment
    
    // we put all the save operations only when click the "save button"
    if (!isFromNewCreatedCard) {
        [self saveEdittedCard];
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
    } else {
        [self doQuestionAndAnswerData];
    }
    
}

#pragma mark – UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [popoverController dismissPopoverAnimated:YES];
    popoverController = nil;
    
}


#pragma mark -
#pragma mark - Re-screenshot all cards under current pack
- (void) reSceenshotAll: (RescreenshotReason) why withStringVal: (NSString *) val{
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



#pragma mark -
#pragma mark - Memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _imagePickerController = nil;
    _imagePickerPopover = nil;
    _selectTemplatePopoverController = nil;
}


@end
