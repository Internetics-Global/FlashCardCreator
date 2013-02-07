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
#import "Pack.h"
#import "Question.h"
#import "Answer.h"
#import "UIImage+Scale.h"
#import "FileOperationHelper.h"
#import "SelectTemplateTableViewController.h"

#define kSegmentLeftMarginForiPad 30.0
#define kSegmentHeightForiPad 44.0
#define kSegmentButtomMarginForiPad 20.0
#define kQuestionViewLeftMarginForiPad 0.0
#define kQuestionViewTopMarginForiPad 10.0
#define kQuestionViewButtomMarginForiPad 80.0
#define kQuestionViewCornerRadiusForiPad 30.0

#define kSegmentLeftMarginForiPhone 15.0
#define kSegmentHeightForiPhone 22.0
#define kSegmentButtomMarginForiPhone 10.0
#define kQuestionViewLeftMarginForiPhone 0.0
#define kQuestionViewTopMarginForiPhone 5.0
#define kQuestionViewButtomMarginForiPhone 40.0
#define kQuestionViewCornerRadiusForiPhone 15.0


@implementation FlashCardView

@synthesize currentCard = _currentCard;
@synthesize currentPack = _currentPack;
@synthesize questionView = _questionView;
@synthesize answerView = _answerView;
@synthesize segmentedControl = _segmentedControl;
@synthesize cardSNText = _cardSNText;
@synthesize maxAllowedCardIndex = _maxAllowedCardIndex;
@synthesize templateID = _templateID;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
        
        _isQuestionShowing = YES; //default to show question
        
        _currentCard = [[Card alloc] init];
        _currentPack = [[Pack alloc] init];
        
        _maxAllowedCardIndex = -1;
        
        if (isUserInterfaceIdiomPhone) {
            [self loadViewForiPhone];
        } else {
            [self loadViewForiPad];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(templateSelectedNotification:) name:TEMPLATE_SELECTED_NOTIFICATION object:nil];
    }
    return self;
}


- (void) loadViewForiPad {
    
    if (_questionView == nil) {
        _questionView = [[QuestionView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPad, kQuestionViewTopMarginForiPad, self.frame.size.width-2*kQuestionViewLeftMarginForiPad, self.frame.size.height-kQuestionViewButtomMarginForiPad-kQuestionViewTopMarginForiPad)];
        _questionView.layer.cornerRadius = kQuestionViewCornerRadiusForiPad;
        _questionView.currentCard = _currentCard;
        _questionView.delegate = self;
        [self addSubview:_questionView];
    }
    
    if (_answerView == nil) {
        _answerView = [[AnswerView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPad, kQuestionViewTopMarginForiPad, self.frame.size.width-2*kQuestionViewLeftMarginForiPad, self.frame.size.height-kQuestionViewButtomMarginForiPad-kQuestionViewTopMarginForiPad)];
        _answerView.layer.cornerRadius = kQuestionViewCornerRadiusForiPad;
        _answerView.currentCard = _currentCard;
        _questionView.delegate = self;
    }
    
    if (_cardSNText == nil) {
        _cardSNText = [[UITextField alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPad, kQuestionViewTopMarginForiPad, 60, 30)];
        _cardSNText.text = @"";
        _cardSNText.layer.cornerRadius =10;
        _cardSNText.layer.masksToBounds = YES;
        _cardSNText.backgroundColor = [UIColor yellowColor];
        _cardSNText.textAlignment = UITextAlignmentCenter;
        _cardSNText.userInteractionEnabled = TRUE;
        _cardSNText.delegate = self;
        _cardSNText.keyboardType = UIKeyboardTypeNumberPad;
        [self addSubview:_cardSNText];
        
    }
    
    //Template button
    if (_changeTemplateButton == nil) {
        _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeTemplateButton.frame = CGRectMake(kQuestionViewLeftMarginForiPad+80, kQuestionViewTopMarginForiPad, 150, 40);
        [_changeTemplateButton setTitle:@"Change template" forState:UIControlStateNormal];
        _changeTemplateButton.backgroundColor = [UIColor redColor];
        [self addSubview:_changeTemplateButton];
        [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
    }
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                         @[@"Question",
                         @"Answer"]];
    
    CGRect frame = CGRectMake(kSegmentLeftMarginForiPad,
                              self.bounds.size.height-kSegmentHeightForiPad-kSegmentButtomMarginForiPad,
                              self.bounds.size.width-2*kSegmentLeftMarginForiPad,
                              kSegmentHeightForiPad);
    _segmentedControl.frame = frame;
    [_segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmentedControl.selectedSegmentIndex = 0;
    [self addSubview:_segmentedControl];
}

- (void) loadViewForiPhone {
    
    if (_questionView == nil) {
        _questionView = [[QuestionView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPhone, kQuestionViewTopMarginForiPhone, self.frame.size.width-2*kQuestionViewLeftMarginForiPhone, self.frame.size.height-kQuestionViewButtomMarginForiPhone-kQuestionViewTopMarginForiPhone)];
        _questionView.layer.cornerRadius = kQuestionViewCornerRadiusForiPhone;
        _questionView.currentCard = _currentCard;
        _questionView.delegate = self;
        [self addSubview:_questionView];
    }
    
    if (_answerView == nil) {
        _answerView = [[AnswerView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPhone, kQuestionViewTopMarginForiPhone, self.frame.size.width-2*kQuestionViewLeftMarginForiPhone, self.frame.size.height-kQuestionViewButtomMarginForiPhone-kQuestionViewTopMarginForiPhone)];
        _answerView.layer.cornerRadius = kQuestionViewCornerRadiusForiPhone;
        _answerView.currentCard = _currentCard;
        _answerView.delegate = self;
    }
    
    if (_cardSNText == nil) {
        _cardSNText = [[UITextField alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPhone, kQuestionViewTopMarginForiPhone, 50, 30)];
        _cardSNText.text = @"";
        _cardSNText.layer.cornerRadius =5;
        _cardSNText.layer.masksToBounds = YES;
        _cardSNText.backgroundColor = [UIColor yellowColor];
        _cardSNText.textAlignment = UITextAlignmentCenter;
        _cardSNText.userInteractionEnabled = TRUE;
        _cardSNText.delegate = self;
        _cardSNText.keyboardType = UIKeyboardTypeNumberPad;
        [self addSubview:_cardSNText];
    }
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                         @[@"Question",
                         @"Answer"]];
    
    CGRect frame = CGRectMake(kSegmentLeftMarginForiPhone,
                              self.bounds.size.height-kSegmentHeightForiPhone-kSegmentButtomMarginForiPhone,
                              self.bounds.size.width-2*kSegmentLeftMarginForiPhone,
                              kSegmentHeightForiPhone);
    _segmentedControl.frame = frame;
    [_segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmentedControl.selectedSegmentIndex = 0;
    [self addSubview:_segmentedControl];
}


- (void)checkCardEditable {
    if ([_currentCard.creator isEqualToString:[OpenUDID value]]) {
        _questionView.logoImage.userInteractionEnabled  = TRUE;
        _questionView.type.userInteractionEnabled       = TRUE;
        _questionView.title.userInteractionEnabled      = TRUE;
        _questionView.image.userInteractionEnabled      = TRUE;
        _questionView.summary.userInteractionEnabled    = TRUE;
        _questionView.detail.userInteractionEnabled     = TRUE;
        _questionView.type.userInteractionEnabled       = TRUE;
        _answerView.logoImage.userInteractionEnabled    = TRUE;
        _answerView.title.userInteractionEnabled        = TRUE;
        _answerView.image.userInteractionEnabled        = TRUE;
        _answerView.summary.userInteractionEnabled      = TRUE;
        _answerView.detail.userInteractionEnabled       = TRUE;
        
    } else {
        _questionView.logoImage.userInteractionEnabled = FALSE;
        _questionView.type.userInteractionEnabled      = FALSE;
        _questionView.title.userInteractionEnabled     = FALSE;
        _questionView.image.userInteractionEnabled     = FALSE;
        _questionView.summary.userInteractionEnabled   = FALSE;
        _questionView.detail.userInteractionEnabled    = FALSE;
        _questionView.type.userInteractionEnabled      = FALSE;
        _answerView.logoImage.userInteractionEnabled   = FALSE;
        _answerView.title.userInteractionEnabled       = FALSE;
        _answerView.image.userInteractionEnabled       = FALSE;
        _answerView.summary.userInteractionEnabled     = FALSE;
        _answerView.detail.userInteractionEnabled      = FALSE;
        
    }
}

- (void) disableCardEdit {
    _questionView.logoImage.userInteractionEnabled = FALSE;
    _questionView.type.userInteractionEnabled      = FALSE;
    _questionView.title.userInteractionEnabled     = FALSE;
    _questionView.image.userInteractionEnabled     = FALSE;
    _questionView.summary.userInteractionEnabled   = FALSE;
    _questionView.detail.userInteractionEnabled    = FALSE;
    _questionView.type.userInteractionEnabled      = FALSE;
    _answerView.logoImage.userInteractionEnabled   = FALSE;
    _answerView.title.userInteractionEnabled       = FALSE;
    _answerView.image.userInteractionEnabled       = FALSE;
    _answerView.summary.userInteractionEnabled     = FALSE;
    _answerView.detail.userInteractionEnabled      = FALSE;
}

- (void) refreshQuestionAnserView {
    _cardSNText.text = [NSString stringWithFormat:@"%d",_currentCard.cardSN];
    
    _questionView.currentCard = _currentCard;
    [_questionView refreshDisplay];
    [_questionView updateQuestionViewTemplate:_currentCard.templateID];
    
    _answerView.currentCard = _currentCard;
    [_answerView refreshDisplay];
    [_answerView updateAnswerViewTemplate:_currentCard.templateID];
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
    
    [self bringSubviewToFront:_cardSNText];
    [self bringSubviewToFront:_changeTemplateButton];

}

#pragma mark -
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    for (Card *card in [_currentPack cards]) {
        if ([textField.text intValue] == card.cardSN) {
            [Common alertViewCommon:@"Existing number, Please rename it"];
            return;
        }
            
    }
            
    _currentCard.cardSN = [_cardSNText.text intValue];
    _currentCard.packID = _currentPack.packID;
    [_currentCard save];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:_currentCard];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (!string.length) // allow backspace
    {
        return YES;
    }
    
    if ([string rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location != NSNotFound)
    {
        return NO;
    }
    
    if (_maxAllowedCardIndex == -1) {
        NSLog(@"%s:Need to set maxAllowedCardIndex beforehand",__FUNCTION__);
    }
    
    return YES;
    
}

#pragma mark -
#pragma mark - BaseViewDelegate

- (void)save {
    if (_currentPack == nil) {
        NSLog(@"Error to create new card, since _currentPack is nil");
        return;
    }
    
    UIImage *origialmage = [self.questionView captureWholeViewAsImage];
    NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
    NSString *savedFullPath = [FileOperationHelper generateUniquePNGImageFilePath];
    [imageData writeToFile:savedFullPath atomically:YES];
    
    _currentCard.coverImageURL = savedFullPath;
    _currentCard.cardSN = _cardSNText.text;
    _currentCard.templateID = _templateID;
    _currentCard.question.title = self.questionView.title.text;
    _currentCard.question.type = self.questionView.type.text;
    _currentCard.question.summary = self.questionView.summary.text;
    _currentCard.question.detail = self.questionView.detail.text;
    _currentCard.question.imageFullPath = self.questionView.imageFullPath;
    _currentCard.question.logoFullPath = self.questionView.logoImageFullPath;
    
    _currentCard.answer.title = self.answerView.title.text;
    _currentCard.answer.summary = self.answerView.summary.text;
    _currentCard.answer.detail = self.answerView.detail.text;
    _currentCard.answer.imageFullPath = self.answerView.imageFullPath;
    _currentCard.answer.logoFullPath = self.answerView.logoImageFullPath;
    
    _currentCard.packID = _currentPack.packID;
    [_currentCard save];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:_currentCard];

}


- (void) changeTemplateButtonClick:(id)sender {
    
    SelectTemplateTableViewController *selectTemplateTableViewController = [[SelectTemplateTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    if (isUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:selectTemplateTableViewController animated:YES];
    } else {
        if (_popoverController == nil)
            _popoverController = [[UIPopoverController alloc] initWithContentViewController:selectTemplateTableViewController];
        _popoverController.popoverContentSize = CGSizeMake(480, 163*5);
        [_popoverController presentPopoverFromRect:((UIButton *) sender).frame inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}

- (void) templateSelectedNotification: (NSNotification *) notification {
    [_popoverController dismissPopoverAnimated:YES];
    NSString *templateIDString = (NSString *)[notification object];
    if ([templateIDString integerValue] == _templateID) {
        //do nothing
    } else {
        _templateID = [templateIDString integerValue];
        
        [_questionView updateQuestionViewTemplate:_templateID];
        [_answerView updateAnswerViewTemplate:_templateID];
        
        _currentCard.templateID = _templateID;
        
        UIImage *origialmage = [self.questionView captureWholeViewAsImage];
        NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
        NSString *savedFullPath = [FileOperationHelper generateUniquePNGImageFilePath];
        [imageData writeToFile:savedFullPath atomically:YES];
        _currentCard.coverImageURL = savedFullPath;
        
        _currentCard.packID = _currentPack.packID;
        [_currentCard save];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:_currentCard];
    }
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
