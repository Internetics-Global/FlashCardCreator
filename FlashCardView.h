//
//  FlashCardView.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 8/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseView.h"

@class QuestionView;
@class AnswerView;
@class Pack;
@class Card;

@interface FlashCardView : UIView <UITextFieldDelegate, BaseViewDelegate> {
    UISegmentedControl *_segmentedControl;
    UITextField *_cardSNText;
    QuestionView *_questionView;
    AnswerView *_answerView;
    Card *_currentCard;
    Pack *_currentPack;
    BOOL _isQuestionShowing;
    
    NSUInteger _maxAllowedCardIndex;
}

@property (nonatomic, strong) QuestionView *questionView;
@property (nonatomic, strong) AnswerView *answerView;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UITextField *cardSNText;

@property (assign, nonatomic) NSUInteger maxAllowedCardIndex;

- (void) refreshQuestionAnserView;
- (void)checkCardEditable;
- (void) disableCardEdit;

- (void)segmentAction:(id)sender;

@end
