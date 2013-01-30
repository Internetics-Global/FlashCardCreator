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
        _content.text = @"Click and Edit";
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

    _content.text =_currentCard.question.content;
    _title.text = _currentCard.question.title;
    
}






@end
