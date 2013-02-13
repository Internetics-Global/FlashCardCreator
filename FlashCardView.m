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
#import "CSS.h"
#import "UINavigationController+DismissKeyboard.h"

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


#pragma mark -
#pragma mark - Life Cycle
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
        
        _isQuestionShowing = YES; //default to show question
        
        _currentCard = [[Card alloc] init];
        _currentPack = [[Pack alloc] init];
        
        _maxAllowedCardIndex = -1;
        _templateID = 0;
        
        if (isUserInterfaceIdiomPhone) {
            [self loadViewForiPhone];
        } else {
            [self loadViewForiPad];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(templateSelectedNotification:) name:TEMPLATE_SELECTED_NOTIFICATION object:nil];
    }
    return self;
}

#pragma mark -
#pragma mark - Layout view

- (void) loadViewForiPad {
    
    if (_questionView == nil) {
        _questionView = [[QuestionView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPad, kQuestionViewTopMarginForiPad, self.frame.size.width-2*kQuestionViewLeftMarginForiPad, self.frame.size.height-kQuestionViewButtomMarginForiPad-kQuestionViewTopMarginForiPad)];
        _questionView.layer.cornerRadius = kQuestionViewCornerRadiusForiPad;
        _questionView.currentCard = _currentCard;
        _questionView.currentPack = _currentPack;
        _questionView.delegate = self;
        [self addSubview:_questionView];
    }
    
    if (_answerView == nil) {
        _answerView = [[AnswerView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPad, kQuestionViewTopMarginForiPad, self.frame.size.width-2*kQuestionViewLeftMarginForiPad, self.frame.size.height-kQuestionViewButtomMarginForiPad-kQuestionViewTopMarginForiPad)];
        _answerView.layer.cornerRadius = kQuestionViewCornerRadiusForiPad;
        _answerView.currentCard = _currentCard;
        _answerView.currentPack = _currentPack;
        _questionView.delegate = self;
    }
    
    
    if (_cardSNText == nil) {
        
        UIImageView *numberingBackroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"numbering_background.png"]];
        numberingBackroundImageView.frame = CGRectMake(10, 20, 40, 40);
        [self addSubview:numberingBackroundImageView];
        
        _cardSNText = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 40, 40)];
        _cardSNText.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _cardSNText.backgroundColor = [UIColor clearColor];
        _cardSNText.textAlignment = UITextAlignmentCenter;
        _cardSNText.userInteractionEnabled = FALSE;
        [self addSubview:_cardSNText];
        
    }
    
    //Template button
    if (_changeTemplateButton == nil) {
        _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeTemplateButton.frame = CGRectMake(kFlashCardViewWidth_Detail_iPad-60, kFlashCardViewHeight_Detail_iPad-kQuestionViewButtomMarginForiPad-60, 60, 60);
        [_changeTemplateButton setImage:[UIImage imageNamed:@"change_template_button.png"] forState:UIControlStateNormal];
        [self addSubview:_changeTemplateButton];
        [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
    }
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                         @[NSLocalizedString(@"ToolbarItem_Question",nil),
                         NSLocalizedString(@"ToolbarItem_Answer",nil)]];
    
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
        _questionView.currentPack = _currentPack;
        _questionView.delegate = self;
        [self addSubview:_questionView];
    }
    
    if (_answerView == nil) {
        _answerView = [[AnswerView alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPhone, kQuestionViewTopMarginForiPhone, self.frame.size.width-2*kQuestionViewLeftMarginForiPhone, self.frame.size.height-kQuestionViewButtomMarginForiPhone-kQuestionViewTopMarginForiPhone)];
        _answerView.layer.cornerRadius = kQuestionViewCornerRadiusForiPhone;
        _answerView.currentCard = _currentCard;
        _answerView.currentPack = _currentPack;
        _answerView.delegate = self;
    }
    
    if (_cardSNText == nil) {
        
        UIImageView *numberingBackroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"numbering_background.png"]];
        numberingBackroundImageView.frame = CGRectMake(kQuestionViewLeftMarginForiPhone+3, kQuestionViewTopMarginForiPhone+5, 25, 25);
        [self addSubview:numberingBackroundImageView];
        
        _cardSNText = [[UITextField alloc] initWithFrame:CGRectMake(kQuestionViewLeftMarginForiPhone+3, kQuestionViewTopMarginForiPhone+5, 25, 20)];
        _cardSNText.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _cardSNText.backgroundColor = [UIColor clearColor];
        _cardSNText.font = [UIFont systemFontOfSize:12];
        _cardSNText.textAlignment = UITextAlignmentCenter;
        _cardSNText.userInteractionEnabled = FALSE;
        [self addSubview:_cardSNText];
        
    }
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                         @[NSLocalizedString(@"ToolbarItem_Question",nil),
                         NSLocalizedString(@"ToolbarItem_Answer",nil)]];
    
    CGRect frame = CGRectMake(kSegmentLeftMarginForiPhone,
                              self.bounds.size.height-kSegmentHeightForiPhone-kSegmentButtomMarginForiPhone,
                              self.bounds.size.width-2*kSegmentLeftMarginForiPhone,
                              kSegmentHeightForiPhone);
    _segmentedControl.frame = frame;
    [_segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmentedControl.selectedSegmentIndex = 0;
    [self addSubview:_segmentedControl];
    
    //Template button
    if (_changeTemplateButton == nil) {
        _changeTemplateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeTemplateButton.frame = CGRectMake(kFlashCardViewWidth_Detail_iPhone-20, kFlashCardViewHeight_Detail_iPhone-kQuestionViewButtomMarginForiPhone-20, 20, 20);
        [_changeTemplateButton setImage:[UIImage imageNamed:@"change_template_button.png"] forState:UIControlStateNormal];
        [self addSubview:_changeTemplateButton];
        [_changeTemplateButton addTarget:self action:@selector(changeTemplateButtonClick:) forControlEvents:UIControlEventTouchDown];
    }
}

#pragma mark -
#pragma mark - Editable related

- (void)checkCardEditable {
    if ([_currentCard.creator isEqualToString:[OpenUDID value]]) {
        _questionView.subheading.userInteractionEnabled = TRUE;
        _questionView.image.userInteractionEnabled      = TRUE;
        _questionView.main.userInteractionEnabled       = TRUE;
        _questionView.sub.userInteractionEnabled        = TRUE;
        _questionView.subheading.userInteractionEnabled = TRUE;
        _answerView.image.userInteractionEnabled        = TRUE;
        _answerView.subheading.userInteractionEnabled   = TRUE;
        _answerView.main.userInteractionEnabled         = TRUE;
        _answerView.sub.userInteractionEnabled          = TRUE;
        
    } else {
        _questionView.subheading.userInteractionEnabled      = FALSE;
        _questionView.image.userInteractionEnabled     = FALSE;
        _questionView.main.userInteractionEnabled   = FALSE;
        _questionView.sub.userInteractionEnabled    = FALSE;
        _questionView.subheading.userInteractionEnabled      = FALSE;
        _answerView.image.userInteractionEnabled       = FALSE;
        _answerView.subheading.userInteractionEnabled  = FALSE;
        _answerView.main.userInteractionEnabled     = FALSE;
        _answerView.sub.userInteractionEnabled      = FALSE;
        
    }
}

- (void) disableCardEdit {
    _questionView.subheading.userInteractionEnabled      = FALSE;
    _questionView.image.userInteractionEnabled     = FALSE;
    _questionView.main.userInteractionEnabled   = FALSE;
    _questionView.sub.userInteractionEnabled    = FALSE;
    _questionView.subheading.userInteractionEnabled      = FALSE;
    _answerView.image.userInteractionEnabled       = FALSE;
    _answerView.subheading.userInteractionEnabled      = FALSE;
    _answerView.main.userInteractionEnabled     = FALSE;
    _answerView.sub.userInteractionEnabled      = FALSE;
}


#pragma mark -
#pragma mark - Refresh
- (void) refreshQuestionAnserView {
    _cardSNText.text = [NSString stringWithFormat:@"%d",_currentCard.cardSN];
    
    _questionView.currentCard = _currentCard;
    _questionView.packName.text = _currentPack.packName;
    [_questionView refreshDisplay]; //content
    if (isUserInterfaceIdiomPhone) {
        [_questionView updateQuestionViewTemplateForiPhone:_currentCard.templateID]; //template
    } else {
        [_questionView updateQuestionViewTemplateForiPad:_currentCard.templateID]; //template
    }
    [_questionView switchLogoStatus]; //logo
    [_questionView updateCSS]; //css
    
    _answerView.currentCard = _currentCard;
    _answerView.packName.text = _currentPack.packName;
    [_answerView refreshDisplay];
    if (isUserInterfaceIdiomPhone) {
        [_answerView updateAnswerViewTemplateForiPhone:_currentCard.templateID];
    } else {
        [_answerView updateAnswerViewTemplateForiPad:_currentCard.templateID];
    }
    [_answerView switchLogoStatus];
    [_answerView updateCSS];
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
                _questionView.delegate = self;
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
                _answerView.delegate = self;
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

- (void) updatelogoURLForAllCards:(NSString *)urlString {
    for (Card *card in [_currentPack cards]) {
        card.question.logoURLLinkage =urlString;
        [card save];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
}

- (void) updatelogoImageForAllCards:(NSString *) imagePath {
    for (Card *card in [_currentPack cards]) {
        card.question.logoFullPath =imagePath;
        [card save];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:nil];
}

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
    _currentCard.templateID = _templateID;
    
    _currentCard.question.title = self.questionView.title.text;
    _currentCard.question.subheading = self.questionView.subheading.text;
    _currentCard.question.main = self.questionView.main.text;
    _currentCard.question.sub = self.questionView.sub.text;
    _currentCard.question.imageFullPath = self.questionView.imageFullPath;

    _currentCard.question.css.subheadingAlign = self.questionView.subheadingAlign;
    _currentCard.question.css.subheadingColor = self.questionView.subheadingColor;
    _currentCard.question.css.subheadingSize = self.questionView.subheadingSize;
    _currentCard.question.css.mainAlign = self.questionView.mainAlign;
    _currentCard.question.css.mainColor = self.questionView.mainColor;
    _currentCard.question.css.mainSize = self.questionView.mainSize;
    _currentCard.question.css.subAlign = self.questionView.subAlign;
    _currentCard.question.css.subColor = self.questionView.subColor;
    _currentCard.question.css.subSize = self.questionView.subSize;
    
    _currentCard.answer.title = self.answerView.title.text;
    _currentCard.answer.subheading = self.answerView.subheading.text;
    _currentCard.answer.main = self.answerView.main.text;
    _currentCard.answer.sub = self.answerView.sub.text;
    _currentCard.answer.imageFullPath = self.answerView.imageFullPath;
    
    _currentCard.answer.css.subheadingAlign = self.answerView.subheadingAlign;
    _currentCard.answer.css.subheadingColor = self.answerView.subheadingColor;
    _currentCard.answer.css.subheadingSize = self.answerView.subheadingSize;
    _currentCard.answer.css.mainAlign = self.answerView.mainAlign;
    _currentCard.answer.css.mainColor = self.answerView.mainColor;
    _currentCard.answer.css.mainSize = self.answerView.mainSize;
    _currentCard.answer.css.subAlign = self.answerView.subAlign;
    _currentCard.answer.css.subColor = self.answerView.subColor;
    _currentCard.answer.css.subSize = self.answerView.subSize;
    
    _currentCard.packID = _currentPack.packID;
    [_currentCard save];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_MASTER_AFTER_SAVE_CARD_NOTFICATION object:_currentCard];

}


- (void) changeTemplateButtonClick:(id)sender {
    
    SelectTemplateTableViewController *selectTemplateTableViewController = [[SelectTemplateTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    if (isUserInterfaceIdiomPhone) {
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:selectTemplateTableViewController];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navController animated:YES];
    } else {
        if (_popoverController == nil)
            _popoverController = [[UIPopoverController alloc] initWithContentViewController:selectTemplateTableViewController];
        _popoverController.popoverContentSize = CGSizeMake(250, 95*5);
        [_popoverController presentPopoverFromRect:((UIButton *) sender).frame inView:self permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
}

- (void) templateSelectedNotification: (NSNotification *) notification {
    [_popoverController dismissPopoverAnimated:YES];
    NSString *templateIDString = (NSString *)[notification object];
    if ([templateIDString integerValue] == _templateID) {
        //do nothing
    } else {
        _templateID = [templateIDString integerValue];
        
        if (isUserInterfaceIdiomPhone ) {
            [_questionView updateQuestionViewTemplateForiPhone:_templateID];
            [_answerView updateAnswerViewTemplateForiPhone:_templateID];
        } else {
            [_questionView updateQuestionViewTemplateForiPad:_templateID];
            [_answerView updateAnswerViewTemplateForiPad:_templateID];
        }
        
        
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


#pragma mark -
#pragma mark - Memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
