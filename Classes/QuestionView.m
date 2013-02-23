//
//  QuestionView.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 8/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "QuestionView.h"
#import "Card.h"
#import "Question.h"
#import "CSS.h"
#import "Pack.h"

@implementation QuestionView

#pragma mark -
#pragma mark - Life Cycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        //setup default value;
        _main.text = @"main";
        _sub.text = @"sub";
        _title.text = _title.text = NSLocalizedString(@"ToolbarItem_Question",nil);;
        _image.image = [UIImage imageNamed:@"question_placeholder_content.png"];
        _logoImage.image = [UIImage imageNamed:@"question_placeholder_logo.png"];
        _imageFullPath = [NSString stringWithFormat:@"%@/question_placeholder_content.png", [[NSBundle mainBundle] resourcePath]];
        _logoImageFullPath = [NSString stringWithFormat:@"%@/question_placeholder_logo.png", [[NSBundle mainBundle] resourcePath]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasHidden:)
                                                     name:UIKeyboardDidHideNotification object:nil];

    }
    return self;
}

#pragma mark -
#pragma mark - Refresh content (only content)

//content part which is included in three main parts: CSS, template(position) and content
- (void) refreshDisplay {
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:_currentCard.question.imageFullPath];
    if (imageTemp) {
        _image.image = imageTemp;
    } else {
        _image.image = [UIImage imageNamed:@"question_placeholder_content.png"];
    }
    
    imageTemp = [UIImage imageWithContentsOfFile:_currentCard.question.logoFullPath];
    if (imageTemp) {
        _logoImage.image = imageTemp;
    } else {
        _logoImage.image = [UIImage imageNamed:@"question_placeholder_logo.png"];    
    }

    _logoLinkURL = _currentCard.question.logoURLLinkage;
    _subheading.text = _currentCard.question.subheading;
    _main.text =_currentCard.question.main;
    _sub.text =_currentCard.question.sub;
}

#pragma mark -
#pragma mark - Update template (postion and css, but css will be rewrited by updateCSS)

//postion part which is included in three main parts: CSS, template(position) and content
- (void) updateQuestionViewTemplateForiPad:(int) index {
    switch (index) {
        case 0: //Template 0
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(20, 10, 700, 50);
            _subheading.font = [UIFont systemFontOfSize:20];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 70, 700, 300);
            _main.font = [UIFont systemFontOfSize:22];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = TRUE;
        
            _image.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(20, 10, 700, 50);
            _subheading.font = [UIFont systemFontOfSize:20];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 70, 700, 70);
            _main.font = [UIFont systemFontOfSize:22];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(20, 150, 700, 200);
            _sub.font = [UIFont systemFontOfSize:16];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentLeft;
            
            _image.hidden = TRUE;
            break;
        }
        case 2: //Template 2
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 70, 700, 200);
            _main.font = [UIFont systemFontOfSize:22];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(20, 290, 700, 100);
            _sub.font = [UIFont systemFontOfSize:22];
            _sub.textColor = [UIColor redColor];
             _sub.textAlignment = NSTextAlignmentCenter;
            
            _image.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 10, 700, 200);
            _main.font = [UIFont systemFontOfSize:24];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(20, 220, 700, 200);
            _sub.font = [UIFont systemFontOfSize:18];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            
            
            _image.hidden = TRUE;
            break;
        }
        case 4: //Template 4
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(20, 40, 700, 350);
            _main.font = [UIFont systemFontOfSize:22];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
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

- (void) updateQuestionViewTemplateForiPhone:(int) index {
    switch (index) {
        case 0: //Template 0
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(0, 0, 350, 40);
            _subheading.font = [UIFont systemFontOfSize:14];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 40, 350, 120);
            _main.font = [UIFont systemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = TRUE;
            
            _image.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheading.hidden = FALSE;
            _subheading.frame = CGRectMake(0, 80, 350, 80);
            _subheading.font = [UIFont systemFontOfSize:14];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentLeft;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 350, 40);
            _main.font = [UIFont systemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(0, 40, 350, 30);
            _sub.font = [UIFont systemFontOfSize:12];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentLeft;
            
            _image.hidden = TRUE;
            break;
        }
        case 2: //Template 2
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 350, 30);
            _main.font = [UIFont systemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(0, 40, 350, 130);
            _sub.font = [UIFont systemFontOfSize:12];
            _sub.textColor = [UIColor redColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            
            _image.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 350, 30);
            _main.font = [UIFont systemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(0, 40, 350, 30);
            _sub.font = [UIFont systemFontOfSize:12];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            
            
            _image.hidden = TRUE;
            break;
        }
        case 4: //Template 4
        {
            _subheading.hidden = YES;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(0, 0, 350, 40);
            _main.font = [UIFont systemFontOfSize:12];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
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
#pragma mark - Get/set currentCard

- (void) setCurrentCard:(Card *)card {
    _currentCard = card;
    _subheadingColor = card.question.css.subheadingColor;
    _subheadingAlign = card.question.css.subheadingAlign;
    _subheadingSize = card.question.css.subheadingSize;
    
    _mainColor = card.question.css.mainColor;
    _mainAlign = card.question.css.mainAlign;
    _mainSize = card.question.css.mainSize;
    
    _subColor = card.question.css.subColor;
    _subAlign = card.question.css.subAlign;
    _subSize = card.question.css.subSize;
}


#pragma mark -
#pragma mark - Memory Management

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
