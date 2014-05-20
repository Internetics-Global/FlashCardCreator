//
//  CreateCardViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 15/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

/* 一些重要的说明 （区别于已存在card的情况）
 * 1. 我们只有在用户点击了"save" button后，才进行保存操作，所以要避免所有的其它的save操作
 * 2. 由于我们的question和answer字段共享，而在切换segment后会丢失数据，所以需要在切换时，进行数据的暂存（保存到_currentCard中，由FlashView对象负责）
*/

#import "CreateCardViewController.h"
#import "FlashCard.h"
#import "Card.h"
#import "User.h"
#import "Pack.h"
#import "SQLiteHelper.h"
#import "Question.h"
#import "Answer.h"
#import "FileOperationHelper.h"
#import "AppDelegate.h"
#import "MasterViewController.h"
#import "UIImage+Scale.h"
#import "OpenUDID.h"
#import "Common.h"
#import "FCCBarButton.h"

BOOL isFromNewCreatedCard = NO;

@interface CreateCardViewController ()

@end

@implementation CreateCardViewController

@synthesize currentPack = _currentPack;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"save_button"] target:self action:@selector(saveAndCloseCreateCardView)]];
        

        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"close2_button"] target:self action:@selector(backAndPopCreateCardView)]];
        
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        if (isUserInterfaceIdiomPhone) {
            label.font = [UIFont boldSystemFontOfSize:16.0];
        }else {
            label.font = [UIFont boldSystemFontOfSize:20.0];
        }
        label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor]; // change this color
        label.text =NSLocalizedString(@"Title_Create_A_New_Card", nil);
        [label sizeToFit];
        [self.navigationItem setTitleView:label];

    }
    return self;
}

- (void)loadView {
    [super loadView];

    if (_newCardView == nil) {
        
        //Step1: Apply default value from first card
        _newCard = [[Card alloc] init];
        if ([[_currentPack cards] count] >0) {
            Card *firstCard = ((Card *)[_currentPack cards][0]); //inherit first card
            _newCard.question.logoFullPath = firstCard.question.logoFullPath;
            _newCard.question.logoURLLinkage = firstCard.question.logoURLLinkage;
            _newCard.templateBackgroundName = firstCard.templateBackgroundName;
        } else {
            // we take default value
        }
        _newCard.cardSN = [[_currentPack cards] count] + 1;
        _newCard.question.templateID = 0;
        _newCard.answer.templateID = 0;
        _newCard.packID = _currentPack.packID;
        _newCard.cardID = [SQLiteHelper getMaxValueForColumn:@"card_id" inTable:@"Cards_Tables"] + 1;
        _newCard.creator = [OpenUDID value];
        _newCard.question.title = NSLocalizedString(@"ToolbarItem_Question",nil);
        _newCard.answer.title = NSLocalizedString(@"ToolbarItem_Answer",nil);
                
        //Step2: Init card
        float flashCardYPositionInScrollView;
        if (isUserInterfaceIdiomPhone) {
            flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPhone - kFalshCardViewHeight_QASegment_iPhone)/2;
            _newCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPhone,kFlashCardViewHeight_Detail_iPhone + kFalshCardViewHeight_QASegment_iPhone) defaultPack:_currentPack defaultCard:_newCard];
            
        } else {
            flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_Detail_iPad)/2;
            _newCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_DETAIL_WIDTH-kFlashCardViewWidth_Detail_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_Detail_iPad,kFlashCardViewHeight_Detail_iPad) defaultPack:_currentPack defaultCard:_newCard];
        }
        
        //Step3: Response (这个非常重要)
        _newCardView.tag = NEW_FLASHCARDVIEW_TAG;  
        
        //Step4: Show
        [self.view addSubview:_newCardView];
        [_newCardView refreshAll];
        [_newCardView enableCardEdit];
        
        //Step5: Some special assignment
        if ([_currentPack cards].count >0) {
            Card *firstCard = (Card *) [[_currentPack cards] objectAtIndex:0];
            _newCardView.questionTitle.text = firstCard.question.title;
            _newCardView.answerTitle.text = firstCard.answer.title;
            
            _newCard.question.title = firstCard.question.title;
            _newCard.answer.title = firstCard.answer.title;
        }
        
        _newCardView.questionTitle.userInteractionEnabled = NO;
        _newCardView.answerTitle.userInteractionEnabled = NO;
        
        //Step6: set flag
        isFromNewCreatedCard = YES;
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if isUserInterfaceIdiomPhone {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"w1136"]];
    } else {
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0)) {
            // Retina display
            self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"w1648"]];
        } else {
            // non-Retina display
            self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"w824"]];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveNewCreatedCardNotification:) name:SAVE_NEW_CREATED_CARD_NOTIFICATION object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //iOS7 special, since UIImagePickerController will display status bar forcely.
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void) saveAndCloseCreateCardView {
    
    //Step1: dismiss window
    [self.navigationController popViewControllerAnimated:YES];
    
    //Step2: exception dealing
    if (_currentPack.packID == -1) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_NEED_TO_CREATE_PACK_FIRST",@"")];
        return;
    }
    
    //Step3: Save.
    [_newCardView saveEdittedCard];
    
    //Step4: Send notification to remove the background in master view
    [[NSNotificationCenter defaultCenter] postNotificationName:REMOVE_BACKGROUND_AFTER_CARD_CREATED_NOTIFICATION object:nil];
    
    //Step5: set flag
    isFromNewCreatedCard = NO;
    _newCardView.tag = OTHER_FLASHCARDVIEW_TAG;
    _newCardView = nil;
}

- (void) backAndPopCreateCardView {
    [self.navigationController popViewControllerAnimated:YES];
    if (!isUserInterfaceIdiomPhone) {
        AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.masterViewController.backgroundOfCreateCardView removeFromSuperview];
    }
    
    //Set flag
    isFromNewCreatedCard = NO;
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

- (void)dealloc {
    _currentPack = nil;
    _newCard = nil;
    _newCardView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark – notification
- (void) saveNewCreatedCardNotification: (NSNotification *) notification {
    [self saveAndCloseCreateCardView];
}

@end
