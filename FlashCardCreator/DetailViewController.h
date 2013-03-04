//
//  DetailViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "MBProgressHUD.h"

@class FlashCardView;
@class QuestionView;
@class AnswerView;
@class Card;
@class Pack;

@interface DetailViewController : UIViewController <MGSplitViewControllerDelegate, UIScrollViewDelegate> {
    UISegmentedControl *_segmentedControl;
    QuestionView *_questionView;
    AnswerView *_answerView;
    UIScrollView    *_scrollView;
    
    Pack *_currentPack;
    Card *_currentCard;
    int _indexCard;  //selected card index in master view
    
    UIPopoverController *_settingPopoverController;
    UIPopoverController *_helpPopoverController;
    UIPopoverController *_masterPopoverController;
    
    FlashCardView *_previousCardView;
    FlashCardView *_currentCardView;
    FlashCardView *_nextCardView;
    
    UIBarButtonItem *_settingButton;
    UIBarButtonItem *_helpButton;
    
}

@property (strong, nonatomic) id detailItem;

@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, assign) int indexCard;

@property (nonatomic, strong) UIPopoverController *masterPopoverController;

- (void) showCurrentCardInScrollView;

@end
