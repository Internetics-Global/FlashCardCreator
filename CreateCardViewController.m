//
//  CreateCardViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 15/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "CreateCardViewController.h"
#import "FlashCardView.h"
#import "Card.h"
#import "User.h"
#import "Pack.h"
#import "QuestionView.h"
#import "AnswerView.h"
#import "SQLiteHelper.h"
#import "Question.h"
#import "Answer.h"
#import "FileOperationHelper.h"
#import "AppDelegate.h"
#import "MasterViewController.h"
#import "UIImage+Scale.h"

@interface CreateCardViewController ()

@end

@implementation CreateCardViewController

@synthesize currentPack = _currentPack;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveAndCloseCreateCardView)];
        self.navigationItem.rightBarButtonItem = saveButton;
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(backAndPopCreateCardView)];
        self.navigationItem.leftBarButtonItem = backButton;
        self.title = @"Create a new card";
        _newCard = [[Card alloc] init];
    }
    return self;
}

- (void)loadView {
    [super loadView];

    if (_cardView == nil) {
        
        if (isUserInterfaceIdiomPhone) {
            _cardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,(IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPhone)/2,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone)];
        } else {
            _cardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,(IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPad)/2,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad)];
        }
        
        
        _cardView.cardSNText.text = [NSString stringWithFormat:@"%d",[[_currentPack cards] count]+1];
        _cardView.questionView.logoImage.userInteractionEnabled    = TRUE;
        _cardView.questionView.title.userInteractionEnabled        = FALSE;
        _cardView.questionView.image.userInteractionEnabled        = TRUE;
        _cardView.questionView.subheading.userInteractionEnabled   = TRUE;
        _cardView.questionView.main.userInteractionEnabled         = TRUE;
        _cardView.questionView.sub.userInteractionEnabled          = TRUE;
        _cardView.answerView.logoImage.userInteractionEnabled      = TRUE;
        _cardView.answerView.title.userInteractionEnabled          = FALSE;
        _cardView.answerView.image.userInteractionEnabled          = TRUE;
        _cardView.answerView.subheading.userInteractionEnabled     = TRUE;
        _cardView.answerView.main.userInteractionEnabled           = TRUE;
        _cardView.answerView.sub.userInteractionEnabled            = TRUE;
        
        //User template 0
        [_cardView.questionView updateQuestionViewTemplate:0];
        [_cardView.answerView updateAnswerViewTemplate:0];
        
        [self.view addSubview:_cardView];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void) saveAndCloseCreateCardView {
    [self.navigationController popViewControllerAnimated:YES];
    
    if (_currentPack == nil) {
        NSLog(@"Error to create new card, since _currentPack is nil");
        return;
    }
    
    UIImage *origialmage = [_cardView.questionView captureWholeViewAsImage];
    NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
    NSString *savedFullPath = [FileOperationHelper generateUniquePNGImageFilePath];
    [imageData writeToFile:savedFullPath atomically:YES];
    _newCard.coverImageURL = savedFullPath;
    
    //card.cardName = _cardView.questionView.title.text;   //warning, need to be confirmed
    _newCard.packID = _currentPack.packID;
    _newCard.cardID = [SQLiteHelper getMaxValueForColumn:@"card_id" inTable:@"Cards_Tables"] + 1;
    _newCard.creator = [OpenUDID value];
    
    _newCard.cardSN = [[_currentPack cards] count]+1;
    _newCard.templateID = _cardView.templateID;
    _newCard.question.title = _cardView.questionView.title.text;
    _newCard.question.cardID = _newCard.cardID;
    _newCard.question.subheading = _cardView.questionView.subheading.text;
    _newCard.question.main = _cardView.questionView.main.text;
    _newCard.question.sub = _cardView.questionView.sub.text;
    _newCard.question.imageFullPath = _cardView.questionView.imageFullPath;
    _newCard.question.logoFullPath = _cardView.questionView.logoImageFullPath;
    
    _newCard.answer.title = _cardView.answerView.title.text;
    _newCard.answer.cardID = _newCard.cardID;
    _newCard.answer.subheading = _cardView.answerView.subheading.text;
    _newCard.answer.main = _cardView.answerView.main.text;
    _newCard.answer.sub = _cardView.answerView.sub.text;
    _newCard.answer.imageFullPath = _cardView.answerView.imageFullPath;
    _newCard.answer.logoFullPath = _cardView.answerView.logoImageFullPath;
    
    [_currentPack addCard:_newCard];
    
    [[NSUserDefaults standardUserDefaults] setInteger:_currentPack.packID forKey:@"lastCreatedPackID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NEW_CARD_ADDED_NOTIFICATION object:nil];
}

- (void) backAndPopCreateCardView {
    [self.navigationController popViewControllerAnimated:YES];
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.masterViewController.backgroundOfCreateCardView removeFromSuperview];
}


#pragma mark -
#pragma mark - Memory Management

// will not be called in iOS 6
// will not be called when it's current view
- (void)viewDidUnload
{
    [super viewDidUnload];
    [self my_viewDidUnload];
}

// in iOS 6, view is no longer unloaded so do it manually
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && [self.view window] == nil) {
        self.view = nil;
        [self my_viewDidUnload];
    }
}

- (void)my_viewDidUnload
{
    
}

@end
