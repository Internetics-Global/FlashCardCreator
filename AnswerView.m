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
        _content.text = @"Click and Edit";
        _image.image = [UIImage imageNamed:@"answer_placeholder_content.png"];
        _logoImage.image = [UIImage imageNamed:@"answer_placeholder_logo.png"];
        _content.text = @"Click and Edit";
        _imageFullPath = [NSString stringWithFormat:@"%@/answer_placeholder_content.png", [[NSBundle mainBundle] resourcePath]];
        _logoImageFullPath = [NSString stringWithFormat:@"%@/answer_placeholder_logo.png", [[NSBundle mainBundle] resourcePath]];
    }
    return self;
}

- (void) refreshDisplay {
    _image.image = [UIImage imageWithContentsOfFile:_currentCard.answer.imageFullPath];
    _logoImage.image = [UIImage imageWithContentsOfFile:_currentCard.answer.logoFullPath];
    _content.text =_currentCard.answer.content;
    _title.text = _currentCard.answer.title;
}


@end
