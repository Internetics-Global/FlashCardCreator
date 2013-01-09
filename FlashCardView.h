//
//  FlashCardView.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 8/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QuestionView;
@class AnswerView;
@class Pack;
@class Card;

@interface FlashCardView : UIView {
    UISegmentedControl *_segmentedControl;
    QuestionView *_questionView;
    AnswerView *_answerView;
    BOOL _isQuestionShowing;
    Card *_currentCard;
}

@property (nonatomic, strong) Card *currentCard;

- (void) refreshQuestionAnserView;

@end
