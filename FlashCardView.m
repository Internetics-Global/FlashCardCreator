//
//  FlashCardView.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 8/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "FlashCardView.h"
#import "QuestionView.h"
#import "AnswerView.h"
#import "Card.h"

#define kSegmentLeftMargin 30.0
#define kSegmentHeight 44.0
#define kSegmentButtomMargin 20.0

#define kQuestionViewLeftMargin 0.0
#define kQuestionViewTopMargin 10.0
#define kQuestionViewButtomMargin 80.0
#define kQuestionViewCornerRadius 30.0


@implementation FlashCardView

@synthesize currentCard = _currentCard;
@synthesize questionView = _questionView;
@synthesize answerView = _answerView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
        
        _isQuestionShowing = YES; //default to show question
        [self loadView];
    }
    return self;
}

- (void) loadView {
    
    if (_questionView == nil) {
        _questionView = [[QuestionView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMargin, kQuestionViewTopMargin, self.frame.size.width-2*kQuestionViewLeftMargin, self.frame.size.height-kQuestionViewButtomMargin-kQuestionViewTopMargin)];
        _questionView.layer.cornerRadius = kQuestionViewCornerRadius;
        _questionView.currentCard = _currentCard;
        [self addSubview:_questionView];
    }
    
    if (_answerView == nil) {
        _answerView = [[AnswerView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMargin, kQuestionViewTopMargin, self.frame.size.width-2*kQuestionViewLeftMargin, self.frame.size.height-kQuestionViewButtomMargin-kQuestionViewTopMargin)];
        _answerView.layer.cornerRadius = kQuestionViewCornerRadius;
        _answerView.currentCard = _currentCard;
    }
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                         @[@"Question",
                         @"Answer"]];
    
    CGRect frame = CGRectMake(kSegmentLeftMargin,
                              self.bounds.size.height-kSegmentHeight-kSegmentButtomMargin,
                              self.bounds.size.width-2*kSegmentLeftMargin,
                              kSegmentHeight);
    _segmentedControl.frame = frame;
    [_segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmentedControl.selectedSegmentIndex = 0;
    [self addSubview:_segmentedControl];
}

- (void) refreshQuestionAnserView {
    _questionView.currentCard = _currentCard;
    [_questionView refreshDisplay];
    _answerView.currentCard = _currentCard;
    [_answerView refreshDisplay];
}

#pragma mark -
#pragma mark Segment callback

- (void)segmentAction:(id)sender
{
	UISegmentedControl *segControl = sender;
    
    switch (segControl.selectedSegmentIndex)
	{
		case 0:	//show question
		{
            if (_isQuestionShowing == NO) {
                [_answerView removeFromSuperview];
                [self addSubview:_questionView];
                _isQuestionShowing = YES;
                _segmentedControl.selectedSegmentIndex = 0;
            }
			break;
		}
		case 1: //show answer
		{
            if (_isQuestionShowing == YES) {
                [_questionView removeFromSuperview];
                [self addSubview:_answerView];
                _isQuestionShowing = NO;
                _segmentedControl.selectedSegmentIndex = 1;
            }
			break;
		}
	}
}

@end
