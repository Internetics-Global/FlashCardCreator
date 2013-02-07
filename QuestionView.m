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

@implementation QuestionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        //setup default value;
        _summary.text = @"summary";
        _detail.text = @"detail";
        _title.text = @"Question";
        _image.image = [UIImage imageNamed:@"question_placeholder_content.png"];
        _logoImage.image = [UIImage imageNamed:@"question_placeholder_logo.png"];
        _imageFullPath = [NSString stringWithFormat:@"%@/question_placeholder_content.png", [[NSBundle mainBundle] resourcePath]];
        _logoImageFullPath = [NSString stringWithFormat:@"%@/question_placeholder_logo.png", [[NSBundle mainBundle] resourcePath]];

    }
    return self;
}

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

    _type.text = _currentCard.question.type;
    _summary.text =_currentCard.question.summary;
    _detail.text =_currentCard.question.detail;
    _title.text = _currentCard.question.title;
    
    
}

//Only to change the positioning
- (void) updateQuestionViewTemplate:(int) index {
    switch (index) {
        case 0: //Template 0
        {
            _type.frame = CGRectMake(0, 60, 570, 50);
            _type.hidden = FALSE;
            
            _summary.frame = CGRectMake(0, 120, 700, 300);
            _summary.hidden = FALSE;
            
            _detail.hidden = TRUE;
            
            _image.hidden = TRUE;
            break;
        }
        case 1: //Template 1
        {
            _type.frame = CGRectMake(0, 60, 570, 50);
            _type.hidden = FALSE;
            
            _summary.frame = CGRectMake(0, 120, 700, 200);
            _summary.hidden = FALSE;
            
            _detail.frame = CGRectMake(0, 330, 700, 200);
            _detail.hidden = FALSE;
            
            _image.hidden = TRUE;
            break;
        }
        case 2: //Template 2
        {
            _type.hidden = YES;
            
            _summary.frame = CGRectMake(30, 120, 700, 300);
            _summary.hidden = FALSE;
            
            _detail.frame = CGRectMake(30, 430, 700, 100);
            _detail.hidden = FALSE;
            
            _image.hidden = TRUE;
            break;
        }
        case 3: //Template 3
        {
            _type.hidden = YES;
            
            _summary.frame = CGRectMake(30, 120, 700, 200);
            _summary.hidden = FALSE;
            
            _detail.frame = CGRectMake(30, 340, 700, 200);
            _detail.hidden = FALSE;
            
            _image.hidden = TRUE;
            break;
        }
        case 4: //Template 4
        {
            _type.hidden = YES;
            
            _summary.frame = CGRectMake(30, 200, 700, 200);
            _summary.hidden = FALSE;
            
            _detail.hidden = YES;
            
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




@end
