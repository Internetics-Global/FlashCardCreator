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
        self.backgroundColor = [UIColor yellowColor];
    }
    return self;
}

- (void) refreshDisplay {
    _content.text =_currentCard.answer.content;
    _image.image = [UIImage imageNamed:_currentCard.answer.imageName];
}

@end
