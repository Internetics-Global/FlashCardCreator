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
#import <QuartzCore/QuartzCore.h>
#import "Card.h"

#define kSegmentLeftMargin 20.0
#define kSegmentHeight 30.0

#define kQuestionViewLeftMargin 30.0
#define kQuestionViewTopMargin 30.0
#define kQuestionViewButtomMargin 60.0
#define kQuestionViewCornerRadius 30.0


@implementation FlashCardView

@synthesize currentCard = _currentCard;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blueColor];
        
        _isQuestionShowing = YES; //default to show question
        [self loadView];
    }
    return self;
}

- (void) loadView {
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                         @[@"Question",
                         @"Answer"]];
    
    CGRect frame = CGRectMake(kSegmentLeftMargin,
                              self.frame.size.height-kSegmentHeight-kSegmentLeftMargin,
                              self.frame.size.width-2*kSegmentLeftMargin,
                              kSegmentHeight);
    _segmentedControl.frame = frame;
    [_segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    _segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    _segmentedControl.selectedSegmentIndex = 0;
    [self addSubview:_segmentedControl];
    
    if (_questionView == nil) {
        _questionView = [[QuestionView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMargin, kQuestionViewLeftMargin, self.frame.size.width-2*kQuestionViewLeftMargin, self.frame.size.height-kQuestionViewButtomMargin-kQuestionViewTopMargin)];
        _questionView.layer.cornerRadius = kQuestionViewCornerRadius;
        _questionView.currentCard = _currentCard;
        [self addSubview:_questionView];
    }
    
    if (_answerView == nil) {
        _answerView = [[AnswerView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMargin, kQuestionViewLeftMargin, self.frame.size.width-2*kQuestionViewLeftMargin, self.frame.size.height-kQuestionViewButtomMargin-kQuestionViewTopMargin)];
        _answerView.layer.cornerRadius = kQuestionViewCornerRadius;
        _answerView.currentCard = _currentCard;
    }
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
