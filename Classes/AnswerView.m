//
//  AnswerView.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 8/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "AnswerView.h"
#import "Card.h"
#import "Answer.h"
#import "Pack.h"
#import "CSS.h"

@implementation AnswerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];

        _title.text = NSLocalizedString(@"ToolbarItem_Answer",nil);
        _title.textColor = [UIColor redColor];
        _backgroundImageName = @"card_background_blue.png";
        _backgroundImageView.image = [UIImage imageNamed:_backgroundImageName];
        _image.image = [UIImage imageNamed:@"answer_placeholder_content.jpg"];
        _imageFullPath = [NSString stringWithFormat:@"%@/answer_placeholder_content.jpg", [[NSBundle mainBundle] resourcePath]];
        _logoImage.image = [UIImage imageNamed:@"answer_placeholder_logo.jpg"];
        _logoImageFullPath = [NSString stringWithFormat:@"%@/answer_placeholder_logo.jpg", [[NSBundle mainBundle] resourcePath]];
        
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
        
    }
    return self;
}


#pragma mark -
#pragma mark - Refresh content (only content)

//content part which is included in three main parts: CSS, template(position) and content
- (void) refreshDisplay {
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:_currentCard.answer.imageFullPath];
    _imageFullPath = _currentCard.answer.imageFullPath;
    if (imageTemp) {
        _image.image = imageTemp;
    } else {
        _image.image = [UIImage imageNamed:@"answer_placeholder_content.jpg"];
    }
    
    _backgroundImageName = _currentCard.templateBackgroundName; 
    _backgroundImageView.image = [UIImage imageNamed:_backgroundImageName];

    _subheading.text = _currentCard.answer.subheading;
    _main.text =_currentCard.answer.main;
    _sub.text =_currentCard.answer.sub;
    
}

#pragma mark -
#pragma mark - Update template (postion and css, but css will be rewrited by updateCSS)

//postion part which is included in three main parts: CSS, template(position) and content
- (void) updateAnswerViewTemplateForiPhone:(int) index {
    
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

- (void) updateAnswerViewTemplateForiPad:(int) index {
    
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

#pragma mark -
#pragma mark - Get/set currentCard
- (void) setCurrentCard:(Card *)card {
    _currentCard = card;
    _subheadingColor = card.answer.css.subheadingColor;
    _subheadingAlign = card.answer.css.subheadingAlign;
    _subheadingSize = card.answer.css.subheadingSize;
    
    _mainColor = card.answer.css.mainColor;
    _mainAlign = card.answer.css.mainAlign;
    _mainSize = card.answer.css.mainSize;
    
    _subColor = card.answer.css.subColor;
    _subAlign = card.answer.css.subAlign;
    _subSize = card.answer.css.subSize;
}

#pragma mark -
#pragma mark - Memory Management

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
