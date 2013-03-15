//
//  FlashCard.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

/* 一些重要的说明 （区别于已存在card的情况）
 * 1. 我们的question和answer字段共享，而在切换segment后会丢失数据，所以需要在切换时，进行数据的暂存（保存到_currentCard中，由FlashView对象负责）
 * 2. 保存操作是写入到数据库，即[_currentCard save]
 * 3. 我们数据的参考对象是_currentCard，而不是界面上的view，所有要确保他们之间一致（a, 初始化时保持一致;b,view内容变化时，要及时更新_currentCard）
 */


#import "FlashCard.h"
#import "BadgeLabel.h"
#import "Pack.h"
#import "Question.h"
#import "Answer.h"
#import "Card.h"
#import "CSS.h"
#import "SimpleWebBrowserController.h"
#import "FileOperationHelper.h"
#import "UIImage+Scale.h"
#import "SelectTemplateTableViewController.h"

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


#define kTagSubheading    100
#define kTagMain          101
#define kTagSub           102

@interface FlashCard ()


@end

@implementation FlashCard

- (id)initWithFrame:(CGRect)frame defaultPack:(Pack *)pack defaultCard:(Card *) card
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
    _isQuestionShowing = YES;
    _isAllCardsLogoNeedToBeUpdate = NO;
    
    _backgroundImageName = @"card_background_blue.png";
    _logoLinkURL = @"http://www.";
    _subheadingSize = 40;
    _subheadingColor = @"Black";
    _subheadingAlign = @"Right";
    _mainSize = 40;
    _mainColor = @"Black";;
    _mainAlign = @"Center";;
    _subSize = 40;
    _subColor = @"Black";;
    _subAlign = @"Center";;
    
    _keyboardShown = FALSE;
    [self setInputAccessoryViewDone];
    
    //We can not make UIImagePickerController in landscape since it's illegal
    _picker = [[UIImagePickerController alloc] init];
    _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _picker.contentSizeForViewInPopover = CGSizeMake(320, 400);
    _picker.delegate = self;
    
    if (isUserInterfaceIdiomPhone) {
        
    } else {
        if (_imagePickerPopover == nil) {
            _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
        }
    }

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
        _backgroundImageView.layer.cornerRadius = 15;
        [self addSubview:_backgroundImageView];
    }
    
    if (_logoImage == nil) {
        _logoImage = [[UIImageView  alloc] init];
        _logoImage.contentMode = UIViewContentModeScaleAspectFit;
        _logoImage.frame = CGRectMake(645, 10, 150, 100);
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
        _logoLinkageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _logoLinkageButton.frame = CGRectMake(700, 90, 50, 20);
        [_logoLinkageButton setBackgroundImage:[UIImage imageNamed:@"edit_link_button.png"] forState:UIControlStateNormal];
        [_logoLinkageButton addTarget:self action:@selector(editLogoLinkageURL:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:_logoLinkageButton];
    }
    
    
    if (_title == nil) {
        _title = [[UITextView alloc]init];
        _title.frame = CGRectMake(60, 30, 200, 110);
        _title.backgroundColor = [UIColor clearColor];
        _title.font =[UIFont systemFontOfSize:40];
        _title.textAlignment = NSTextAlignmentCenter;
        _title.text =NSLocalizedString(@"ToolbarItem_Question",nil);
        _title.userInteractionEnabled = FALSE;
        [self addSubview:_title];
    }
    
    if (_verticalScrollView == nil) {
        _verticalScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(60, 110, 740, 440)];
        _verticalScrollView.backgroundColor = [UIColor clearColor];
        [self addSubview:_verticalScrollView];
    }
    
    
    if (_image == nil) {
        _image= [[UIImageView  alloc] init];
        _image.userInteractionEnabled = FALSE;
        _image.contentMode = UIViewContentModeScaleAspectFit;
        _image.clipsToBounds = YES;
        _image.backgroundColor = [UIColor clearColor];
        _image.layer.cornerRadius = 15;
        _image.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_image];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
        [_image addGestureRecognizer:imageSingeTap];
    }
    
    if (_subheading == nil) {
        _subheading = [[UITextView alloc]init];
        _subheading.tag = kTagSubheading;
        _subheading.font =[UIFont boldSystemFontOfSize:28];
        _subheading.userInteractionEnabled = FALSE;
        _subheading.keyboardType = UIKeyboardAppearanceDefault;
        _subheading.returnKeyType = UIReturnKeyDefault;
        _subheading.delegate = self;
        [_verticalScrollView addSubview:_subheading];
    }
    
    if (_main == nil) {
        _main = [[UITextView alloc]init];
        _main.tag = kTagMain;
        _main.font =[UIFont boldSystemFontOfSize:28];
        _main.userInteractionEnabled = FALSE;
        _main.keyboardType = UIKeyboardAppearanceDefault;
        _main.returnKeyType = UIReturnKeyDefault;
        _main.delegate = self;
        [_verticalScrollView addSubview:_main];
    }
    
    
    if (_sub == nil) {
        _sub = [[UITextView alloc]init];
        _sub.tag = kTagSub;
        _sub.font =[UIFont boldSystemFontOfSize:28];
        _sub.userInteractionEnabled = FALSE;
        _sub.keyboardType = UIKeyboardAppearanceDefault;
        _sub.returnKeyType = UIReturnKeyDefault;
        _sub.delegate = self;
        [_verticalScrollView addSubview:_sub];
    }
    
    if (_packName == nil) {
        _packName = [[UILabel alloc] init];
        _packName.frame = CGRectMake(0, 0, 400, 60);
        [_packName setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
        _packName.center = CGPointMake(30, 275);
        //_packName.text = @"This is the pack name";
        _packName.textAlignment = NSTextAlignmentCenter;
        _packName.backgroundColor = [UIColor clearColor];
        _packName.font = [UIFont systemFontOfSize:20];
        _packName.textColor = [UIColor whiteColor];
        [self addSubview:_packName];
    }
    
    
    if (_cardSNText == nil) {
        
        _cardSNText = [[BadgeLabel alloc] init];
        _cardSNText.frame = CGRectMake(0, kQuestionViewTopMarginForiPad+15, 27, 27);
        [_cardSNText setStyle:BadgeLabelStyleAppIcon];
        _cardSNText.backgroundColor = [UIColor colorWithRed:143.0/255 green:204.0/255 blue:1 alpha:1];
        _cardSNText.textColor = [UIColor blackColor];
        CGPoint point = _cardSNText.center;
        point.x = 30;
        _cardSNText.center = point;
        [self addSubview:_cardSNText];
        
    }
    
    if (_changeTemplateButton == nil) {
        _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeTemplateButton.frame = CGRectMake(kFlashCardViewWidth_Detail_iPad-90-10, kFlashCardViewHeight_Detail_iPad-kQuestionViewButtomMarginForiPad-45, 90, 25);
        [_changeTemplateButton setTitle:@"   Select Template" forState:UIControlStateNormal];
        _changeTemplateButton.titleLabel.font = [UIFont systemFontOfSize:9];
        [_changeTemplateButton setBackgroundImage:[UIImage imageNamed:@"select_template_button.png"] forState:UIControlStateNormal];
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

}


- (void) loadQuestionAnswerViewForiPhone {
    
    if (_backgroundImageView == nil) {
        _backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:_backgroundImageName]];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.backgroundColor = [UIColor whiteColor];
        _backgroundImageView.frame = CGRectMake(0, 0, kFlashCardViewWidth_Detail_iPhone, kFlashCardViewHeight_Detail_iPhone-45);
        _backgroundImageView.userInteractionEnabled = NO;
        _backgroundImageView.layer.masksToBounds = YES;
        _backgroundImageView.layer.cornerRadius = 6;
        [self addSubview:_backgroundImageView];
    }
    
    
    if (_title == nil) {
        _title = [[UITextView alloc]init];
        _title.frame = CGRectMake(30, 0, 100, 40);
        _title.text =NSLocalizedString(@"ToolbarItem_Question",nil);
        _title.font =[UIFont systemFontOfSize:18];
        _title.textAlignment = NSTextAlignmentCenter;
        _title.backgroundColor = [UIColor clearColor];
        _title.userInteractionEnabled = FALSE;
        [self addSubview:_title];
    }
    
    
    if (_logoImage == nil){
        _logoImage = [[UIImageView  alloc] init];
        _logoImage.contentMode = UIViewContentModeScaleAspectFit;
        _logoImage.frame = CGRectMake(340, 5, 50, 30);
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
        _logoLinkageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _logoLinkageButton.frame = CGRectMake(357, 32, 20, 8);
        [_logoLinkageButton setBackgroundImage:[UIImage imageNamed:@"edit_link_button.png"] forState:UIControlStateNormal];
        [_logoLinkageButton addTarget:self action:@selector(editLogoLinkageURL:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:_logoLinkageButton];
    }
    
    
    if (_verticalScrollView == nil) {
        _verticalScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(30, 40, 370, 175)];
        //_verticalScrollView.backgroundColor = [UIColor blueColor];
        [self addSubview:_verticalScrollView];
    }
    
    
    if (_packName ==  nil) {
        _packName = [[UILabel alloc] init];
        _packName.frame = CGRectMake(0, 0, 200, 30);
        [_packName setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
        _packName.center = CGPointMake(15, 112);
        //_packName.text = @"This is the pack name";
        _packName.textAlignment = NSTextAlignmentCenter;
        _packName.backgroundColor = [UIColor clearColor];
        _packName.font = [UIFont systemFontOfSize:12];
        _packName.textColor = [UIColor whiteColor];
        [self addSubview:_packName];
    }
    
    //Step3: Common
    if (_cardSNText == nil) {
        
        _cardSNText = [[BadgeLabel alloc] init];
        _cardSNText.frame = CGRectMake(5, kQuestionViewTopMarginForiPhone+5, 20, 20);
        [_cardSNText setStyle:BadgeLabelStyleAppIcon];
        _cardSNText.backgroundColor = [UIColor colorWithRed:143.0/255 green:204.0/255 blue:1 alpha:1];
        _cardSNText.textColor = [UIColor blackColor];
        _cardSNText.font = [UIFont systemFontOfSize:12];
        CGPoint point = _cardSNText.center;
        point.x = 15;
        _cardSNText.center = point;
        [self addSubview:_cardSNText];
        
    }
    
    
    if (_image ==  nil) {
        _image= [[UIImageView  alloc] init];
        _image.userInteractionEnabled = FALSE;
        _image.contentMode = UIViewContentModeScaleAspectFit;
        _image.clipsToBounds = YES;
        _image.backgroundColor = [UIColor clearColor];
        _image.tag = 1;
        _image.layer.cornerRadius = 10;
        _image.layer.masksToBounds = YES;
        [_verticalScrollView addSubview:_image];
        
        UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
        [_image addGestureRecognizer:imageSingeTap];
    }
    
    if (_subheading ==  nil) {
        _subheading = [[UITextView alloc]init];
        _subheading.tag = kTagSubheading;
        _subheading.userInteractionEnabled = FALSE;
        _subheading.keyboardType = UIKeyboardAppearanceDefault;
        _subheading.returnKeyType = UIReturnKeyDefault;
        _subheading.delegate = self;
        [_verticalScrollView addSubview:_subheading];
    }
    
    if (_main ==  nil) {
        _main = [[UITextView alloc]init];
        _main.tag = kTagMain;
        _main.userInteractionEnabled = FALSE;
        _main.keyboardType = UIKeyboardAppearanceDefault;
        _main.returnKeyType = UIReturnKeyDefault;
        //_main.backgroundColor = [UIColor greenColor];
        _main.delegate = self;
        [_verticalScrollView addSubview:_main];
    }
    
    
    if (_sub ==  nil) {
        _sub = [[UITextView alloc]init];
        _sub.tag = kTagSub;
        _sub.userInteractionEnabled = FALSE;
        _sub.keyboardType = UIKeyboardAppearanceDefault;
        _sub.returnKeyType = UIReturnKeyDefault;
        _sub.delegate = self;
        [_verticalScrollView addSubview:_sub];
    }
    
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
        _changeTemplateButton.frame = CGRectMake(kFlashCardViewWidth_Detail_iPhone-72-10, kFlashCardViewHeight_Detail_iPhone-kQuestionViewButtomMarginForiPhone-30, 72, 20);
        [_changeTemplateButton setTitle:@"   Select Template" forState:UIControlStateNormal];
        _changeTemplateButton.titleLabel.font = [UIFont systemFontOfSize:7];
        [_changeTemplateButton setBackgroundImage:[UIImage imageNamed:@"select_template_button.png"] forState:UIControlStateNormal];
        [self addSubview:_changeTemplateButton];
        [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
    }
}





#pragma mark -
#pragma mark - Editable related
- (void)checkCardEditable {
    if ([_currentCard.creator isEqualToString:[OpenUDID value]]) {
        [self enableCardEdit];
        
    } else {
        [self disableCardEdit];
    }
}

- (void) disableCardEdit {
    _logoImage.userInteractionEnabled  = TRUE;  //we always enable it.
    _logoLinkageButton.userInteractionEnabled  = FALSE;
    [_logoLinkageButton setHidden:YES];
    _subheading.userInteractionEnabled = FALSE;
    _image.userInteractionEnabled      = FALSE;
    _main.userInteractionEnabled       = FALSE;
    _main.layer.borderWidth = 0;
    _sub.userInteractionEnabled        = FALSE;
    _sub.layer.borderWidth = 0;
    _subheading.userInteractionEnabled = FALSE;
    _subheading.layer.borderWidth = 0;
    
    _logoImage.userInteractionEnabled    = FALSE;
    _image.userInteractionEnabled        = FALSE;
    _main.userInteractionEnabled         = FALSE;
    _main.layer.borderWidth = 0;
    _sub.userInteractionEnabled          = FALSE;
    _sub.layer.borderWidth = 0;
    _subheading.userInteractionEnabled   = FALSE;
    _subheading.layer.borderWidth = 0;
    
    _changeTemplateButton.hidden = TRUE;
}

- (void) enableCardEdit {
    _logoImage.userInteractionEnabled  = TRUE;
    _logoLinkageButton.userInteractionEnabled  = FALSE;
    [_logoLinkageButton setHidden:NO];
    _logoLinkageButton.userInteractionEnabled = YES;
    _image.userInteractionEnabled      = TRUE;
    _main.userInteractionEnabled       = TRUE;
    _main.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _main.layer.borderWidth = 2;
    } else {
        _main.layer.borderWidth = 3;
    }
    
    _sub.userInteractionEnabled        = TRUE;
    _sub.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _sub.layer.borderWidth = 2;
    } else {
        _sub.layer.borderWidth = 3;
    }
    _subheading.userInteractionEnabled = TRUE;
    _subheading.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subheading.layer.borderWidth = 2;
    } else {
        _subheading.layer.borderWidth = 3;
    }
    _logoImage.userInteractionEnabled    = TRUE;
    _logoImage.hidden = FALSE;
    _image.userInteractionEnabled        = TRUE;
    _main.userInteractionEnabled         = TRUE;
    _main.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _main.layer.borderWidth = 2;
    } else {
        _main.layer.borderWidth = 3;
    }
    _sub.userInteractionEnabled          = TRUE;
    _sub.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _sub.layer.borderWidth = 2;
    } else {
        _sub.layer.borderWidth = 3;
    }
    _subheading.userInteractionEnabled   = TRUE;
    _subheading.layer.borderColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted_line.png"]] CGColor];
    if (isUserInterfaceIdiomPhone) {
        _subheading.layer.borderWidth = 2;
    } else {
        _subheading.layer.borderWidth = 3;
    }
    
    _changeTemplateButton.hidden = FALSE;
    _changeTemplateButton.userInteractionEnabled = YES;
}



#pragma mark -
#pragma mark - Refresh
- (void) refreshAll {
//    if (((isFromNewCreatedCard == YES) && (self.tag == CURRENT_FLASHCARDVIEW_TAG))
//        ||
//        ((self.tag != CURRENT_FLASHCARDVIEW_TAG) && (self.tag != NEW_FLASHCARDVIEW_TAG))){
//        return;
//    }
    
    [self switchLogoStatus];
    [self checkCardEditable];
    [self updateQuestionOrAnswerTemplate];
    [self updateQuestionOrAnswerCSS]; // need to be careful, since two properties (color/size) will replace with those in updateQuestionOrAnswerTemplate
    [self refreshQuestionOrAnswerContent];
}

- (void) refreshQuestionOrAnswerContent {
    if (_isQuestionShowing) {
        [self refreshQuestionContent];
    } else {
        [self refreshAnswerContent];
    }
    
    _cardSNText.text = [NSString stringWithFormat:@"%d",_currentCard.cardSN];
}

- (void) refreshAnswerContent {
    
    _title.text = _title.text = NSLocalizedString(@"ToolbarItem_Answer",nil);
    _title.textColor = [UIColor redColor];
    
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:_currentCard.answer.imageFullPath];
    _imageFullPath = _currentCard.answer.imageFullPath;
    if (imageTemp) {
        _image.image = imageTemp;
    } else {
        _image.image = [UIImage imageNamed:@"answer_placeholder_content.jpg"];
    }
    
    _backgroundImageName = _currentCard.templateBackgroundName;
    _backgroundImageView.image = [UIImage imageNamed:_backgroundImageName];
    
    _title.text = @"Answer";
    _title.textColor = [UIColor redColor];
    _subheading.text = _currentCard.answer.subheading;
    _main.text =_currentCard.answer.main;
    _sub.text =_currentCard.answer.sub;
    
}

- (void) refreshQuestionContent {
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:_currentCard.question.imageFullPath];
    _imageFullPath = _currentCard.question.imageFullPath;
    if (imageTemp) {
        _image.image = imageTemp;
    } else {
        _image.image = [UIImage imageNamed:@"question_placeholder_content.png"];
    }
    
    imageTemp = [UIImage imageWithContentsOfFile:_currentCard.question.logoFullPath];
    if (imageTemp) {
        _logoImage.image = imageTemp;
    } else {
        _logoImage.image = [UIImage imageNamed:@"question_placeholder_logo.jpg"];
    }
    
    _backgroundImageName = _currentCard.templateBackgroundName;
    _backgroundImageView.image = [UIImage imageNamed:_backgroundImageName];
    
    _title.text = @"Question";
    _title.textColor = [UIColor blueColor];
    _logoLinkURL = _currentCard.question.logoURLLinkage;
    _subheading.text = _currentCard.question.subheading;
    _main.text =_currentCard.question.main;
    _sub.text =_currentCard.question.sub;
}


#pragma mark -
#pragma mark Segment callback

- (void)segmentAction:(id)sender
{
	UISegmentedControl *segControl = sender;
    
    switch (segControl.selectedSegmentIndex)
	{
		case 0:	//show question
		{
            if (_isQuestionShowing == NO) {
                
                //keep the answer part data
                if (isFromNewCreatedCard) {
                    [self doAnswerData];
                }
                
                _isQuestionShowing = YES;
                [self refreshAll];
            }
			break;
		}
		case 1: //show answer
		{
            if (_isQuestionShowing == YES) {
                
                //keep the question part data
                if (isFromNewCreatedCard) {
                    [self doQuestionData];
                }
                
                _isQuestionShowing = NO;
                [self refreshAll];
            }
			break;
		}
	}

}

- (void) doAnswerData {
    _currentCard.answer.title = _title.text;
    _currentCard.answer.subheading = _subheading.text;
    _currentCard.answer.main = _main.text;
    _currentCard.answer.sub = _sub.text;
    _currentCard.answer.imageFullPath = _imageFullPath;
    
    _currentCard.answer.css.subheadingAlign = _subheadingAlign;
    _currentCard.answer.css.subheadingColor = _subheadingColor;
    _currentCard.answer.css.subheadingSize = _subheadingSize;
    _currentCard.answer.css.mainAlign = _mainAlign;
    _currentCard.answer.css.mainColor = _mainColor;
    _currentCard.answer.css.mainSize = _mainSize;
    _currentCard.answer.css.subAlign = _subAlign;
    _currentCard.answer.css.subColor = _subColor;
    _currentCard.answer.css.subSize = _subSize;
}

- (void) doQuestionData {
    _currentCard.question.title = _title.text;
    _currentCard.question.subheading = _subheading.text;
    _currentCard.question.main = _main.text;
    _currentCard.question.sub = _sub.text;
    _currentCard.question.imageFullPath = _imageFullPath;
    
    _currentCard.question.css.subheadingAlign = _subheadingAlign;
    _currentCard.question.css.subheadingColor = _subheadingColor;
    _currentCard.question.css.subheadingSize = _subheadingSize;
    _currentCard.question.css.mainAlign = _mainAlign;
    _currentCard.question.css.mainColor = _mainColor;
    _currentCard.question.css.mainSize = _mainSize;
    _currentCard.question.css.subAlign = _subAlign;
    _currentCard.question.css.subColor = _subColor;
    _currentCard.question.css.subSize = _subSize;
}


#pragma mark -
#pragma mark - Update CSS (only CSS) and Logo

- (void) switchLogoStatus {
    
    if (([_currentCard.creator isEqualToString:[OpenUDID value]]) && (_isQuestionShowing)) {
        //We don't need to show logoLinkageButton in AnswerView
        _logoLinkageButton.hidden = FALSE;
        UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
        [_logoImage addGestureRecognizer:logoSingeTap];
    } else {
        _logoLinkageButton.hidden = TRUE;
        UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWebviewViaLogoURL:)];
        [_logoImage addGestureRecognizer:logoSingeTap];
    }
}

//CSS part which is included in three main parts: CSS, template(position) and content
- (void) updateQuestionOrAnswerCSS {
    
    if (_currentCard == nil) {
        [Common alertViewCommon:@"Need to set currentCard beforehand"];
    }
    
    CSS *css;
    if (_isQuestionShowing) {
        css = _currentCard.question.css;
    } else {
        css = _currentCard.answer.css;
    }
    
    //1. subheading
    //during creating a new card, we used default value
    _subheading.font = [UIFont boldSystemFontOfSize:css.subheadingSize];
    _subheadingSize = css.subheadingSize;
    
    if ([css.subheadingColor isEqualToString:@"Blue"]) {
        _subheading.textColor = [UIColor blueColor];
        _subheadingColor = @"Blue";
    } else if ([css.subheadingColor isEqualToString:@"Red"]) {
        _subheading.textColor = [UIColor redColor];
        _subheadingColor = @"Red";
    } else if ([css.subheadingColor isEqualToString:@"Yellow"]) {
        _subheading.textColor = [UIColor yellowColor];
        _subheadingColor = @"Yellow";
    } else if ([css.subheadingColor isEqualToString:@"Black"]) {
        _subheading.textColor = [UIColor blackColor];
        _subheadingColor = @"Black";
    } else if ([css.subheadingColor isEqualToString:@"Green"]) {
        _subheading.textColor = [UIColor greenColor];
        _subheadingColor = @"Green";
    }
    
    if ([css.subheadingAlign isEqualToString:@"Left"]) {
        _subheading.textAlignment = NSTextAlignmentLeft;
        _subheadingAlign = @"Left";
    } else if ([css.subheadingAlign isEqualToString:@"Center"]) {
        _subheading.textAlignment = NSTextAlignmentCenter;
        _subheadingAlign = @"Center";
    }else if ([css.subheadingAlign isEqualToString:@"Right"]) {
        _subheading.textAlignment = NSTextAlignmentRight;
        _subheadingAlign = @"Right";
    }
    
    //2. main
    //during creating a new card, we used default value
    _main.font = [UIFont boldSystemFontOfSize:css.mainSize];
    _mainSize = css.mainSize;
    
    if ([css.mainColor isEqualToString:@"Blue"]) {
        _main.textColor = [UIColor blueColor];
        _mainColor = @"Blue";
    } else if ([css.mainColor isEqualToString:@"Red"]) {
        _main.textColor = [UIColor redColor];
        _mainColor = @"Red";
    } else if ([css.mainColor isEqualToString:@"Yellow"]) {
        _main.textColor = [UIColor yellowColor];
        _mainColor = @"Yellow";
    } else if ([css.mainColor isEqualToString:@"Black"]) {
        _main.textColor = [UIColor blackColor];
        _mainColor = @"Black";
    } else if ([css.mainColor isEqualToString:@"Green"]) {
        _main.textColor = [UIColor greenColor];
        _mainColor = @"Green";
    }
    
    if ([css.mainAlign isEqualToString:@"Left"]) {
        _main.textAlignment = NSTextAlignmentLeft;
        _mainAlign = @"Left";
    } else if ([css.mainAlign isEqualToString:@"Center"]) {
        _main.textAlignment = NSTextAlignmentCenter;
        _mainAlign = @"Center";
    }else if ([css.mainAlign isEqualToString:@"Right"]) {
        _main.textAlignment = NSTextAlignmentRight;
        _mainAlign = @"Right";
    }
    
    //3. sub
    //during creating a new card, we used default value
    _sub.font = [UIFont boldSystemFontOfSize:css.subSize];
    _subSize = css.subSize;
    
    if ([css.subColor isEqualToString:@"Blue"]) {
        _sub.textColor = [UIColor blueColor];
        _subColor = @"Blue";
    } else if ([css.subColor isEqualToString:@"Red"]) {
        _sub.textColor = [UIColor redColor];
        _subColor = @"Red";
    } else if ([css.subColor isEqualToString:@"Yellow"]) {
        _sub.textColor = [UIColor yellowColor];
        _subColor = @"Yellow";
    } else if ([css.subColor isEqualToString:@"Black"]) {
        _sub.textColor = [UIColor blackColor];
        _subColor = @"Black";
    } else if ([css.subColor isEqualToString:@"Green"]) {
        _sub.textColor = [UIColor greenColor];
        _subColor = @"Green";
    }
    
    if ([css.subAlign isEqualToString:@"Left"]) {
        _sub.textAlignment = NSTextAlignmentLeft;
        _subAlign = @"Left";
    } else if ([css.subAlign isEqualToString:@"Center"]) {
        _sub.textAlignment = NSTextAlignmentCenter;
        _subAlign = @"Center";
    }else if ([css.subAlign isEqualToString:@"Right"]) {
        _sub.textAlignment = NSTextAlignmentRight;
        _subAlign = @"Right";
    }
}



#pragma mark -
#pragma mark - Update template (postion and css, but css will be rewrited by updateCSS)

- (void) updateQuestionOrAnswerTemplate {
    if (isUserInterfaceIdiomPhone) {
        if (_isQuestionShowing) {
            [self updateQuestionViewTemplateForiPhone];
        } else {
            [self updateAnswerViewTemplateForiPhone];
        }
    } else {
        if (_isQuestionShowing) {
            [self updateQuestionViewTemplateForiPad];    
        } else {
            [self updateAnswerViewTemplateForiPad];
        }
        
    }
    
}

//postion part which is included in three main parts: CSS, template(position) and content
- (void) updateAnswerViewTemplateForiPhone {
    
    int index = _currentCard.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(0, 0, 210, 30);
            _subheading.font = [UIFont boldSystemFontOfSize:14];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentCenter;
            _subheadingAlign = @"Center";
            _subheadingColor = @"Black";
            _subheadingSize = 14;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 40, 210, 150);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = TRUE;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(210, 0, 140, 140);
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(0, 0, 210, 30);
            _subheading.font = [UIFont boldSystemFontOfSize:12];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            _subheadingAlign = @"Left";
            _subheadingColor = @"Black";
            _subheadingSize = 12;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 30, 210, 190);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            _mainAlign = @"Left";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = TRUE;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(210, 0, 140, 140);
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
            break;
        }
        case 2: //Template 2
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 210, 190);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            _mainAlign = @"Left";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = TRUE;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(210, 0, 140, 140);
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 360, 190);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = YES;
            
            _image.hidden = TRUE;
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
            break;
        }
        case 4: //Template4
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 210, 190);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = TRUE;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(210, 0, 140, 140);
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
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
    
    int index = _currentCard.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(20, 10, 360, 80);
            _subheading.font = [UIFont boldSystemFontOfSize:34];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentCenter;
            _subheadingAlign = @"Center";
            _subheadingColor = @"Black";
            _subheadingSize = 34;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 100, 360, 320);
            _main.font = [UIFont boldSystemFontOfSize:30];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 30;
            
            _sub.hidden = TRUE;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(380, 10, 350, 350);
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(20, 10, 700, 60);
            _subheading.font = [UIFont boldSystemFontOfSize:42];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            _subheadingAlign = @"Left";
            _subheadingColor = @"Black";
            _subheadingSize = 42;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 80, 360, 300);
            _main.font = [UIFont boldSystemFontOfSize:38];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            _mainAlign = @"Left";
            _mainColor = @"Black";
            _mainSize = 38;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(20, 380, 500, 50);
            _sub.font = [UIFont boldSystemFontOfSize:38];
            _sub.textColor = [UIColor redColor];
            _sub.textAlignment = NSTextAlignmentLeft;
            _subAlign = @"Left";
            _subColor = @"Black";
            _subSize = 38;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(380, 80, 330, 330);
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
            break;
        }
        case 2: //Template 2
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 10, 360, 360);
            _main.font = [UIFont boldSystemFontOfSize:34];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            _mainAlign = @"Left";
            _mainColor = @"Black";
            _mainSize = 34;
            
            _sub.hidden = TRUE;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(380, 10, 350, 350);
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 10, 700, 400);
            _main.font = [UIFont boldSystemFontOfSize:34];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            _mainAlign = @"Left";
            _mainColor = @"Black";
            _mainSize = 34;
            
            _sub.hidden = TRUE;
            
            _image.hidden = TRUE;
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
            break;
        }
        case 4: //Template4
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 10, 360, 360);
            _main.font = [UIFont boldSystemFontOfSize:34];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            _mainAlign = @"Left";
            _mainColor = @"Black";
            _mainSize = 34;
            
            _sub.hidden = YES;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(380, 10, 350, 350);
            
            _logoImage.hidden = TRUE;
            _logoLinkageButton.hidden = TRUE;
            
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
    
    int index = _currentCard.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(20, 10, 700, 50);
            _subheading.font = [UIFont boldSystemFontOfSize:30];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            _subheadingAlign = @"Left";
            _subheadingColor = @"Black";
            _subheadingSize = 30;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 70, 700, 350);
            _main.font = [UIFont boldSystemFontOfSize:38];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 38;
            
            _sub.hidden = TRUE;
            
            _image.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(20, 10, 700, 50);
            _subheading.font = [UIFont boldSystemFontOfSize:34];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            _subheadingAlign = @"Left";
            _subheadingColor = @"Black";
            _subheadingSize = 34;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 70, 700, 140);
            _main.font = [UIFont boldSystemFontOfSize:38];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 38;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(20, 220, 700, 180);
            _sub.font = [UIFont boldSystemFontOfSize:30];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            _subAlign = @"Center";
            _subColor = @"Black";
            _subSize = 30;
            
            _image.hidden = TRUE;
            break;
        }
        case 2: //Template 2
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 70, 700, 200);
            _main.font = [UIFont boldSystemFontOfSize:42];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 42;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(20, 290, 700, 100);
            _sub.font = [UIFont boldSystemFontOfSize:34];
            _sub.textColor = [UIColor redColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            _subAlign = @"Center";
            _subColor = @"Red";
            _subSize = 34;
            
            _image.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 10, 700, 200);
            _main.font = [UIFont boldSystemFontOfSize:42];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 42;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(20, 220, 700, 200);
            _sub.font = [UIFont boldSystemFontOfSize:34];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentLeft;
            _subAlign = @"Center";
            _subColor = @"Black";
            _subSize = 34;
            
            
            _image.hidden = TRUE;
            break;
        }
        case 4: //Template 4
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 40, 700, 350);
            _main.font = [UIFont boldSystemFontOfSize:42];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 42;
            
            _sub.hidden = TRUE;
            
            _image.hidden = TRUE;
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
    
    int index = _currentCard.templateID;
    
    switch (index) {
        case 0: //Template 0
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(0, 0, 350, 40);
            _subheading.font = [UIFont boldSystemFontOfSize:14];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            _subheadingAlign = @"Left";
            _subheadingColor = @"Black";
            _subheadingSize = 14;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 40, 350, 150);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = TRUE;
            
            _image.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(0, 0, 350, 25);
            _subheading.font = [UIFont boldSystemFontOfSize:14];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            _subheadingAlign = @"Left";
            _subheadingColor = @"Black";
            _subheadingSize = 14;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 25, 350, 90);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(0, 90, 350, 95);
            _sub.font = [UIFont boldSystemFontOfSize:12];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentLeft;
            _subAlign = @"Center";
            _subColor = @"Black";
            _subSize = 12;
            
            _image.hidden = TRUE;
            break;
        }
        case 2: //Template 2
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 350, 130);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(0, 130, 350, 60);
            _sub.font = [UIFont boldSystemFontOfSize:12];
            _sub.textColor = [UIColor redColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            _subAlign = @"Center";
            _subColor = @"Red";
            _subSize = 12;
            
            _image.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 350, 90);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(0, 90, 350, 100);
            _sub.font = [UIFont boldSystemFontOfSize:12];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            _subAlign = @"Center";
            _subColor = @"Black";
            _subSize = 12;
            
            
            _image.hidden = TRUE;
            break;
        }
        case 4: //Template 4
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 350, 190);
            _main.font = [UIFont boldSystemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            _mainAlign = @"Center";
            _mainColor = @"Black";
            _mainSize = 12;
            
            _sub.hidden = TRUE;
            
            _image.hidden = TRUE;
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
    if (isUserInterfaceIdiomPhone) {
        //we don't need to hide navigation bar on ipAD
        [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NAVIGATION_BAR_NOTIFICATION object:nil];
    }
}

- (void)keyboardWillShow:(NSNotification*)aNotification {
    if (isUserInterfaceIdiomPhone) {
        //we don't need to hide navigation bar on ipAD
        [[NSNotificationCenter defaultCenter] postNotificationName:HIDE_NAVIGATION_BAR_NOTIFICATION object:nil];
    }
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    //Step1: Get keyboard height
    NSDictionary* info = [aNotification userInfo];
    NSValue *aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    _keyboardHeight = [aValue CGRectValue].size.height;
    //NSLog(@"Keyboard height is %f",_keyboardHeight);
    
    //Step2: Get cursor Y value relative to view
    UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
    CGFloat cursorY = [responderTextView caretRectForPosition:responderTextView.selectedTextRange.start].origin.y;
    //NSLog(@"Y position for current cursorY is %f",cursorY);
    
    //Step3: Get view's Y value relative to screen
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
    
    //Step4: calculate the offset and gap value
    CGPoint offset = _verticalScrollView.contentOffset;
    CGFloat gap;
    if (isUserInterfaceIdiomPhone) {
        gap = _keyboardHeight -(IPHONE_UI_HEIGHT - yInScrren - cursorY);
    } else {
        gap = _keyboardHeight -(IPAD_UI_HEIGHT - yInScrren - cursorY);
    }
    
    if (gap >5) {
        offset.y = gap+20;
    }
    
    //Step5: move scrollview
    [_verticalScrollView setContentOffset:offset animated:YES];
    
    if (_keyboardShown)
        return;
    
    _keyboardShown = YES;
}


- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    _keyboardShown = NO;
    
    CGPoint offset = _verticalScrollView.contentOffset;
    offset.y = 0;
    [_verticalScrollView setContentOffset:offset animated:YES];
    
}

- (void) setInputAccessoryViewDone  {
    
    UIBarButtonItem *sizeSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Size",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(sizeUpDownAction)];
    
    UIBarButtonItem *colorSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectColorAction)];
    
    UIBarButtonItem *alignSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignAction)];
    
    UIBarButtonItem * btnSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Keyboard_Done",nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyBoard)];
    
    
    _buttonArray = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,btnSpace,btnSpace,btnSpace,doneButton,nil];
    
    //Back Button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Back",nil) style:UIBarButtonItemStyleDone target:self action:@selector(backAction:)];
    
    //Font Array
    UIBarButtonItem *fontSize12 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size12",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize16 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size16",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize20 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size20",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize24 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size24",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize28 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size28",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize32 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size32",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize36 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size36",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize40 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size40",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    if (_fontSizeArray == nil) {
        if (isUserInterfaceIdiomPhone) {
            _fontSizeArray = [NSArray arrayWithObjects:backButton,fontSize12,fontSize16,fontSize20,fontSize24,fontSize28,nil];
        } else {
            _fontSizeArray = [NSArray arrayWithObjects:backButton,fontSize24,fontSize28,fontSize32,fontSize36,fontSize40,nil];
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
    
    //Keyboard top view
    if (_keyboardTopView == nil) {
        _keyboardTopView = [[UIToolbar alloc]init];
    }
    
    if (isUserInterfaceIdiomPhone) {
        _keyboardTopView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_TOOL_BAR_HEIGHT);
    } else {
        _keyboardTopView.frame = CGRectMake(0, 0, IPAD_UI_WIDTH, IPAD_UI_TOOL_BAR_HEIGHT);
    }
    [_keyboardTopView setBarStyle:UIBarStyleBlackTranslucent];
    
    [_keyboardTopView setItems:_buttonArray];
    [_subheading setInputAccessoryView:_keyboardTopView];
    [_main setInputAccessoryView:_keyboardTopView];
    [_sub setInputAccessoryView:_keyboardTopView];
}

-(IBAction)dismissKeyBoard
{
    [_subheading resignFirstResponder];
    [_subheading setContentOffset:CGPointMake(0, 0) animated:YES];
    [_main resignFirstResponder];
    [_main setContentOffset:CGPointMake(0, 0) animated:YES];
    [_sub resignFirstResponder];
    [_subheading setContentOffset:CGPointMake(0, 0) animated:YES];
    
    if (self.tag == NEW_FLASHCARDVIEW_TAG) {
        //we will save until after we press the save button
    } else {
        [self saveEdittedCard];
    }
    
}

#pragma mark -
#pragma mark - UIImagePickerController related

- (void)selectFromImageLibraryByLogo:(UITapGestureRecognizer *)sender {
    
    _isLogoImageViewClicked = YES;
    
    if (isUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:_picker animated:YES];
    } else {
        CGPoint point = [sender locationInView:self];
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    
}

- (void)selectFromImageLibraryByImage:(UITapGestureRecognizer *)sender {
    
    _isLogoImageViewClicked = NO;
    
    if (isUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:_picker animated:YES];
    } else {
        CGPoint point = [sender locationInView:self];
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        
        [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (isUserInterfaceIdiomPhone) {
        [_picker dismissModalViewControllerAnimated:YES];
    } else {
        [_imagePickerPopover dismissPopoverAnimated:YES];
    }
    
    UIImage *origialmage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)], kJPEGQualityFactor);
    
    if (_isLogoImageViewClicked) {
        if (([_logoImageFullPath rangeOfString:@".jpg"].location == NSNotFound) || ([_logoImageFullPath hasSuffix:@"question_placeholder_logo.jpg"])||((_logoImageFullPath.length == 0))) {
            _logoImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePath];
        }
        
        [imageData writeToFile:_logoImageFullPath atomically:YES];
        _logoImage.image = [UIImage imageWithData:imageData];
        
        if (isFromNewCreatedCard) {
            //we don't do save operation now but need to tell to save all cards' logo when we click "save button"
            _isAllCardsLogoNeedToBeUpdate = YES;
            _currentCard.question.logoFullPath = _logoImageFullPath;
        } else {
            //do save operation and update all others
            [self updatelogoImageForAllCards:_logoImageFullPath];    
        }
        
    } else {
        if (([_imageFullPath rangeOfString:@".jpg"].location == NSNotFound) || ([_imageFullPath hasSuffix:@"answer_placeholder_content.jpg"]) || ((_imageFullPath.length == 0))) {
            _imageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePath];
        }
        [imageData writeToFile:_imageFullPath atomically:YES];
        _image.image = [UIImage imageWithData:imageData];
        
        if (self.tag == NEW_FLASHCARDVIEW_TAG) {
            //we will save until after we press the save button
        } else {
            [self saveEdittedCard];
        }
    }
}

- (UIImage *)captureWholeViewAsImage {
    CGRect screenRect = self.bounds;
    UIGraphicsBeginImageContext(screenRect.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self.backgroundColor set];
    CGContextFillRect(ctx, screenRect);
    [self.layer renderInContext:ctx];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


#pragma mark -
#pragma mark - Text edit function

- (UITextView *) getFirstResponderUITextViewUnderVerticalScrollView {
    //we put all the editable UITextView as subview of verticalScrollView
    for(UIView *view in [_verticalScrollView subviews])
    {
        if([view isKindOfClass:[UITextView class]])
        {
            if (view.isFirstResponder)
                return (UITextView *)view;
        }
    }
    return nil;
}

- (void) sizeUpDownAction {
    [_keyboardTopView setItems:_fontSizeArray];
}

- (void) selectColorAction {
    [_keyboardTopView setItems:_colorArray];
}

- (void) alignAction {
    [_keyboardTopView setItems:_alignArray];
}

- (void) changeFontSize:(id) sender{
    
    NSUInteger selectFontSize;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    
    UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
    
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size12",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:12];
        selectFontSize = 12;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size16",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:16];
        selectFontSize = 16;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size20",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:20];
        selectFontSize = 20;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size24",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:24];
        selectFontSize = 24;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size28",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:28];
        selectFontSize = 28;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size32",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:32];
        selectFontSize = 32;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size36",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:36];
        selectFontSize = 36;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size40",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:40];
        selectFontSize = 40;
    }
    
    if (responderTextView.tag == 100){
        _subheadingSize = selectFontSize;
    } else if (responderTextView.tag == 101) {
        _mainSize = selectFontSize;
    } else if (responderTextView.tag == 102) {
        _subSize = selectFontSize;
    }
    
    [_keyboardTopView setItems:_buttonArray];
}

- (void) alignPosition:(id) sender{
    
    NSString *selectAlignStr = nil;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
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
    
    if (responderTextView.tag == 100){
        _subheadingAlign = selectAlignStr;
    } else if (responderTextView.tag == 101) {
        _mainAlign = selectAlignStr;
    } else if (responderTextView.tag == 102) {
        _subAlign = selectAlignStr;
    }
    
    [_keyboardTopView setItems:_buttonArray];
}

- (void) changeColor:(id) sender{
    
    NSString *selectColorStr = nil;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
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
    
    if (responderTextView.tag == 100){
        _subheadingColor = selectColorStr;
    } else if (responderTextView.tag == 101) {
        _mainColor = selectColorStr;
    } else if (responderTextView.tag == 102) {
        _subColor = selectColorStr;
    }
    
    [_keyboardTopView setItems:_buttonArray];
}


- (void) backAction:(id) sender{
    [_keyboardTopView setItems:_buttonArray];
}


#pragma mark -
#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    //    CGRect frame = textView.frame;
    //    frame.size.height = textView.contentSize.height;
    //    textView.frame = frame;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    static CGFloat height = 0;
    
    if (([text isEqualToString:@"\n"]) || (textView.contentSize.height > height)) {
        UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
        CGFloat cursorY = [responderTextView caretRectForPosition:responderTextView.selectedTextRange.start].origin.y;
        NSLog(@"Y position for current cursorY is %f",cursorY);
        
        CGFloat yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].x;
        
        CGPoint offset = _verticalScrollView.contentOffset;
        CGFloat gap;
        if (isUserInterfaceIdiomPhone) {
            gap = _keyboardHeight -(IPHONE_UI_HEIGHT - yInScrren - cursorY);
        } else {
            gap = _keyboardHeight -(IPAD_UI_HEIGHT - yInScrren - cursorY);
        }
        
        if (gap >0) {
            offset.y = offset.y + responderTextView.font.lineHeight;
        }
        [_verticalScrollView setContentOffset:offset animated:YES];
        
    }
    
    height= textView.contentSize.height;
    
    return YES;
}

#pragma mark -
#pragma mark - Add logo linkage relate

- (void) editLogoLinkageURL:(id) sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Set URL"
                                                    message:[NSString stringWithFormat:@"Enter a valid URL"]
                                                   delegate:self cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Ok", nil];
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
    
    NSURL *url = [NSURL URLWithString:_logoLinkURL];
    
    if (url) {
        SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
        controller.hidesToolbar = NO;
        
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navController animated:YES];
        
    } else {
        [Common alertViewCommon:@"Incorrect URL format or empty "];
    }
}

#pragma mark -
#pragma mark - BaseViewDelegate

- (void) updatelogoURLForAllCards:(NSString *)urlString {
    for (Card *card in [_currentPack cards]) {
        card.question.logoURLLinkage =urlString;
        [card save];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:_currentCard];
}

- (void) updatelogoImageForAllCards:(NSString *) imagePath {
    
    if ((self.tag != CURRENT_FLASHCARDVIEW_TAG) && (self.tag != NEW_FLASHCARDVIEW_TAG)) {
        return;
    }
    
    for (Card *card in [_currentPack cards]) {
        card.question.logoFullPath =imagePath;
        [card save];
    }
    
    //we have to disable it, since it could affect performance
    //[self reSceenshotAll:kReasonLogoImageChangeEnum stringVal:imagePath];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:_currentCard];
}

- (void) saveEdittedCard {
    
    if (_currentPack == nil) {
        [Common alertViewCommon:@"Error to create new card, since _currentPack is nil"];
        return;
    }
    
    //we only deal with current card and new created card
    if ((self.tag == PREVIOUS_FLASHCARDVIEW_TAG) || (self.tag == NEXT_FLASHCARDVIEW_TAG)) {
        return;
    }
    
    UIImage *origialmage = [self captureWholeViewAsImage];
    NSData *imageData = UIImageJPEGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)], kJPEGQualityFactor);
    
    if (([_currentCard.coverImageURL rangeOfString:@".jpg"].location == NSNotFound) || ((_currentCard.coverImageURL == nil))) {
        NSString *savedFullPath = [FileOperationHelper generateUniqueJPEGImageFilePath];
        [imageData writeToFile:savedFullPath atomically:YES];
        _currentCard.coverImageURL = savedFullPath;
    } else {
        [imageData writeToFile:_currentCard.coverImageURL atomically:YES];
    }
    _currentCard.templateBackgroundName = _backgroundImageName; //to be noticed, currently, templateBackground means backgroundImageName;
    
    _currentCard.packID = _currentPack.packID;
    
    if (isFromNewCreatedCard == FALSE)  //we don't need to do this when it's in Create Card operation
    {
        if (_isQuestionShowing) {
            [self doQuestionData];
        } else {
            [self doAnswerData];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:_currentCard];
    
    
}


- (void) changeTemplateButtonClick:(id)sender {
    
    SelectTemplateTableViewController *selectTemplateTableViewController = [[SelectTemplateTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    if (isUserInterfaceIdiomPhone) {
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:selectTemplateTableViewController];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navController animated:YES];
    } else {
        if (_popoverController == nil)
            _popoverController = [[UIPopoverController alloc] initWithContentViewController:selectTemplateTableViewController];
        _popoverController.popoverContentSize = CGSizeMake(250, 95*5);
        [_popoverController presentPopoverFromRect:((UIButton *) sender).frame inView:self permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
}

- (void) templateSelectedNotification: (NSNotification *) notification {
    
    
    [_popoverController dismissPopoverAnimated:YES];
    
    //  We don't want to accept when there's create card action now
    if (((isFromNewCreatedCard == YES) && (self.tag == CURRENT_FLASHCARDVIEW_TAG))
        ||
        ((self.tag != CURRENT_FLASHCARDVIEW_TAG) && (self.tag != NEW_FLASHCARDVIEW_TAG))){
        return;
    }
    
    NSString *templateIDString = (NSString *)[notification object];
    _currentCard.templateID = [templateIDString integerValue];
    
    [self updateQuestionOrAnswerTemplate];
    
    
    // we put all the save operations only when click the "save button"
    if (!isFromNewCreatedCard) {
        [self saveEdittedCard];    
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:_currentCard];
}


#pragma mark -
#pragma mark - Re-screenshot all cards under current pack
- (void) reSceenshotAll: (RescreenshotReason) why stringVal: (NSString *) val{
    float flashCardYPositionInScrollView;
    FlashCard *tempCardView;
    if (isUserInterfaceIdiomPhone) {
        flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPhone)/2; //Since it's horizontal movement, so this is a constant value
        tempCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone) defaultPack:_currentPack defaultCard:_currentCard];
        
    } else {
        flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPad)/2; //Since it's horizontal movement, so this is a constant value
        tempCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad) defaultPack:_currentPack defaultCard:_currentCard];
        
    }
    
    for (Card *card in [_currentPack cards]) {
        
        if (why == kReasonTemplateBackgroundChangeEnum) {
            card.templateBackgroundName = val;
        } else if (why == kReasonLogoImageChangeEnum) {
            card.question.logoFullPath = val;
        }
        
        tempCardView.currentCard = card;
        tempCardView.segmentedControl.selectedSegmentIndex = 0;
        [tempCardView refreshAll];
        
        UIImage *origialmage = [tempCardView captureWholeViewAsImage];
        NSData *imageData = UIImageJPEGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)], kJPEGQualityFactor);
        if (([card.coverImageURL rangeOfString:@".jpg"].location == NSNotFound) || ((card.coverImageURL == nil))) {
            NSString *savedFullPath = [FileOperationHelper generateUniqueJPEGImageFilePath];
            [imageData writeToFile:savedFullPath atomically:YES];
            card.coverImageURL = savedFullPath;
        } else {
            [imageData writeToFile:card.coverImageURL atomically:YES];
        }
        
        [card save];
    }
}



#pragma mark -
#pragma mark - Memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




@end
