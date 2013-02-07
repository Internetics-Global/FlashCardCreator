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

@implementation AnswerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        //setup default value;
        _summary.text = @"summary";
        _detail.text = @"detail";
        _title.text = @"Answer";
        _image.image = [UIImage imageNamed:@"answer_placeholder_content.png"];
        _logoImage.image = [UIImage imageNamed:@"answer_placeholder_logo.png"];
        _imageFullPath = [NSString stringWithFormat:@"%@/answer_placeholder_content.png", [[NSBundle mainBundle] resourcePath]];
        _logoImageFullPath = [NSString stringWithFormat:@"%@/answer_placeholder_logo.png", [[NSBundle mainBundle] resourcePath]];
        
        _type.hidden = TRUE; //we don't use _type in answer view;
    }
    return self;
}

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
    
    _summary.text =_currentCard.answer.summary;
    _detail.text =_currentCard.answer.detail;
    _title.text = _currentCard.answer.title;
}

//Only to change the positioning
- (void) updateAnswerViewTemplate:(int) index {
    
    switch (index) {
        case 0: //Template 0
        {
            _summary.frame = CGRectMake(0, 70, 470, 50);
            _summary.hidden = FALSE;
            
            _detail.frame = CGRectMake(0, 120, 470, 400);
            _detail.hidden = FALSE;
            
            _image.frame = CGRectMake(480, 150, 300, 300);
            _image.hidden = FALSE;
            break;
        }
        case 1: //Template 1
        {
            _summary.frame = CGRectMake(0, 70, 770, 50);
            _summary.hidden = FALSE;
            
            _detail.frame = CGRectMake(0, 120, 470, 400);
            _detail.hidden = FALSE;
            
            _image.frame = CGRectMake(480, 150, 300, 300);
            _image.hidden = FALSE;
            break;
        }
        case 2: //Template 2
        {
            _summary.hidden = TRUE;
            
            _detail.frame = CGRectMake(0, 100, 470, 400);
            _detail.hidden = FALSE;
            
            _image.frame = CGRectMake(480, 150, 300, 300);
            _image.hidden = FALSE;
            break;
        }
        case 3: //Template 3
        {
            _summary.hidden = YES;
            
            _detail.frame = CGRectMake(0, 100, 770, 400);
            _detail.hidden = FALSE;
            
            _image.hidden = TRUE;
            break;
        }
        case 4: //Template4
        {
            _summary.hidden = TRUE;
            
            _detail.frame = CGRectMake(0, 100, 470, 400);
            _detail.hidden = FALSE;
            
            _image.frame = CGRectMake(480, 150, 300, 300);
            _image.hidden = FALSE;
            break;
        }
        default:
        {
            NSLog(@"%s:No template is selected",__FUNCTION__);
            break;
        }
            
    }
}


@end
