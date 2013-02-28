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
@class BadgeLabel;

@interface FlashCardView : UIView <UITextFieldDelegate, BaseViewDelegate> {
    UISegmentedControl *_segmentedControl;
    BadgeLabel *_cardSNText;
    UIButton *_changeTemplateButton;
    QuestionView *_questionView;
    AnswerView *_answerView;
    Card *_currentCard;
    Pack *_currentPack;
    BOOL _isQuestionShowing;
    
    UIPopoverController *_popoverController;
    NSUInteger _maxAllowedCardIndex;
    NSUInteger _templateID;
}

@property (nonatomic, strong) QuestionView *questionView;
@property (nonatomic, strong) AnswerView *answerView;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) BadgeLabel *cardSNText;
@property (assign, nonatomic) NSUInteger maxAllowedCardIndex;
@property (assign, nonatomic) NSUInteger templateID;

- (void) refreshQuestionAnserView;
- (void) checkCardEditable;
- (void) disableCardEdit;
- (void) reset:(Card *) card curPack: (Pack *) pack;
- (void) segmentAction:(id)sender;
- (void) setQuestionAnswerViewDelegate;
- (void) removeQuestionAnswerViewDelegate;

@end
