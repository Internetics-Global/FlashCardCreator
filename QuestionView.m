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
        self.backgroundColor = [UIColor cyanColor];
    }
    return self;
}

- (void) refreshDisplay {
    _image.image = [UIImage imageNamed:_currentCard.question.imageName];
    _content.text =_currentCard.question.content;
}


@end
