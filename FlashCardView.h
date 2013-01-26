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
    Card *_currentCard;
    BOOL _isQuestionShowing;
}

@property (strong, nonatomic) QuestionView *questionView;
@property (strong, nonatomic) AnswerView *answerView;
@property (nonatomic, strong) Card *currentCard;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;

- (void) refreshQuestionAnserView;
- (void)checkCardEditable;
- (void) disableCardEdit;

- (void)segmentAction:(id)sender;

@end
