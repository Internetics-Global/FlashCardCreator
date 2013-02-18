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
        
        //setup default value;
        _main.text = @"main";
        _sub.text = @"sub";
        _title.text = NSLocalizedString(@"ToolbarItem_Answer",nil);
        _image.image = [UIImage imageNamed:@"answer_placeholder_content.png"];
        _logoImage.image = [UIImage imageNamed:@"answer_placeholder_logo.png"];
        _imageFullPath = [NSString stringWithFormat:@"%@/answer_placeholder_content.png", [[NSBundle mainBundle] resourcePath]];
        _logoImageFullPath = [NSString stringWithFormat:@"%@/answer_placeholder_logo.png", [[NSBundle mainBundle] resourcePath]];
        
        _logoLinkageButton.hidden = YES;
        
    }
    return self;
}


#pragma mark -
#pragma mark - Refresh content (only content)

//content part which is included in three main parts: CSS, template(position) and content
- (void) refreshDisplay {
    UIImage *imageTemp = [UIImage imageWithContentsOfFile:_currentCard.answer.imageFullPath];
    if (imageTemp) {
        _image.image = imageTemp;
    } else {
        _image.image = [UIImage imageNamed:@"answer_placeholder_content.png"];
    }
    
    imageTemp = [UIImage imageWithContentsOfFile:_currentCard.answer.logoFullPath];
    if (imageTemp) {
        _logoImage.image = imageTemp;
    } else {
        _logoImage.image = [UIImage imageNamed:@"answer_placeholder_logo.png"];
    }
    
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
            _subheading.frame = CGRectMake(30, 40, 140, 30);
            _subheading.font = [UIFont systemFontOfSize:15];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentCenter;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(30, 80, 360, 100);
            _main.font = [UIFont systemFontOfSize:16];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = TRUE;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(30, 1900, 360, 100);
            
            _logoImage.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(30, 40, 140, 30);
            _main.font = [UIFont systemFontOfSize:16 ];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(30, 80, 360, 100);
            _sub.font = [UIFont systemFontOfSize:16];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(30, 1900, 360, 100);
            
            _logoImage.hidden = TRUE;
            
            break;
        }
        case 2: //Template 2
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(30, 40, 140, 30);
            _main.font = [UIFont systemFontOfSize:16 ];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(30, 80, 360, 100);
            _sub.font = [UIFont systemFontOfSize:16];
            _sub.textColor = [UIColor redColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(30, 1900, 360, 100);
            
            _logoImage.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(30, 40, 140, 30);
            _main.font = [UIFont systemFontOfSize:22 ];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(30, 80, 360, 100);
            _sub.font = [UIFont systemFontOfSize:14];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            
            _image.hidden = TRUE;
            
            _logoImage.hidden = TRUE;
            
            break;
        }
        case 4: //Template4
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(30, 40, 140, 30);
            _main.font = [UIFont systemFontOfSize:14 ];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(30, 80, 360, 100);
            _sub.font = [UIFont systemFontOfSize:14];
            _sub.textColor = [UIColor redColor];
            _sub.textAlignment = NSTextAlignmentLeft;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(30, 1900, 360, 100);
            
            _logoImage.hidden = TRUE;
            
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
            _subheading.frame = CGRectMake(80, 120, 360, 30);
            _subheading.font = [UIFont systemFontOfSize:20];
            _subheading.textColor = [UIColor blackColor];
            _subheading.textAlignment = NSTextAlignmentCenter;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(80, 160, 360, 300);
            _main.font = [UIFont systemFontOfSize:16];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = TRUE;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(440, 120, 350, 350);
            
            _logoImage.hidden = TRUE;
            
            break;
        }
        case 1: //Template 1
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(80, 120, 700, 40);
            _main.font = [UIFont systemFontOfSize:16 ];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(80, 170, 360, 360);
            _sub.font = [UIFont systemFontOfSize:16];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(440, 170, 350, 350);
            
            _logoImage.hidden = TRUE;
            
            break;
        }
        case 2: //Template 2
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(80, 120, 360, 360);
            _main.font = [UIFont systemFontOfSize:16 ];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentLeft;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(600, 400, 100, 50);
            _sub.font = [UIFont systemFontOfSize:16];
            _sub.textColor = [UIColor redColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(440, 120, 350, 350);
            
            _logoImage.hidden = TRUE;
            
            break;
        }
        case 3: //Template 3
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(600, 30, 180, 50);
            _main.font = [UIFont systemFontOfSize:22 ];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(80, 120, 700, 400);
            _sub.font = [UIFont systemFontOfSize:14];
            _sub.textColor = [UIColor blackColor];
            _sub.textAlignment = NSTextAlignmentCenter;
            
            _image.hidden = TRUE;
            
            _logoImage.hidden = TRUE;
            
            break;
        }
        case 4: //Template4
        {
            _subheading.hidden = TRUE;
            
            _main.hidden = FALSE;
            _main.frame = CGRectMake(80, 120, 360, 360);
            _main.font = [UIFont systemFontOfSize:14 ];
            _main.textColor = [UIColor blackColor];
            _main.textAlignment = NSTextAlignmentCenter;
            
            _sub.hidden = FALSE;
            _sub.frame = CGRectMake(80, 400, 360, 40);
            _sub.font = [UIFont systemFontOfSize:14];
            _sub.textColor = [UIColor redColor];
            _sub.textAlignment = NSTextAlignmentLeft;
            
            _image.hidden = FALSE;
            _image.frame = CGRectMake(440, 120, 350, 350);
            
            _logoImage.hidden = TRUE;
            
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

@end
