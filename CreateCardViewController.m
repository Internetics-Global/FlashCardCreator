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
        self.view.backgroundColor = [UIColor greenColor];
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
        
        _cardView = [[FlashCardView alloc] initWithFrame:CGRectMake(0,0,IPAD_UI_DETAIL_WIDTH,IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT)];
        _cardView.questionView.logoImage.userInteractionEnabled = TRUE;
        _cardView.questionView.title.userInteractionEnabled = TRUE;
        _cardView.questionView.image.userInteractionEnabled = TRUE;
        _cardView.questionView.content.userInteractionEnabled = TRUE;
        _cardView.answerView.logoImage.userInteractionEnabled = TRUE;
        _cardView.answerView.title.userInteractionEnabled = TRUE;
        _cardView.answerView.image.userInteractionEnabled = TRUE;
        _cardView.answerView.content.userInteractionEnabled = TRUE;
        
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
    
    if ([_currentPack.packName isEqualToString:PUBLIC_PACK_NAME]) {
        NSLog(@"Can not create card under public online pack");
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
    _newCard.isOnline = FALSE;
    
    _newCard.question.title = _cardView.questionView.title.text;
    _newCard.question.cardID = _newCard.cardID;
    _newCard.question.content = _cardView.questionView.content.text;
    _newCard.question.imageFullPath = _cardView.questionView.imageFullPath;
    _newCard.question.logoFullPath = _cardView.questionView.logoImageFullPath;
    
    _newCard.answer.title = _cardView.answerView.title.text;
    _newCard.answer.cardID = _newCard.cardID;
    _newCard.answer.content = _cardView.answerView.content.text;
    _newCard.answer.imageFullPath = _cardView.answerView.imageFullPath;
    _newCard.answer.logoFullPath = _cardView.answerView.logoImageFullPath;
    
    [_currentPack addCard:_newCard];
    
    [[NSUserDefaults standardUserDefaults] setInteger:([[_currentPack cards] count]-1) forKey:@"indexCard"];
    [[NSUserDefaults standardUserDefaults] setInteger:_currentPack.packID forKey:@"lastCreatedPackID"];
    [[NSUserDefaults standardUserDefaults] setInteger:_newCard.cardID forKey:@"lastCreatedCardID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NEW_CARD_ADDED_NOTIFICATION object:nil];
}

- (void) backAndPopCreateCardView {
    [self.navigationController popViewControllerAnimated:YES];
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.masterViewController.backgroundOfCreateCardView removeFromSuperview];
}


@end
