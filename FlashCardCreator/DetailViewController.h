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

#import "PopoverView.h"

@class FlashCardView;
@class QuestionView;
@class AnswerView;
@class Card;
@class Pack;
@class FlashCard;
@class DropboxSharekitHelper;


@interface DetailViewController : UIViewController <MGSplitViewControllerDelegate, UIScrollViewDelegate, PopoverViewDelegate, UIAlertViewDelegate, UIPopoverControllerDelegate> {
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
    
    FlashCard *_previousCardView;
    FlashCard *_currentCardView;
    FlashCard *_nextCardView;
    
    UIBarButtonItem *_templateBackgroundSelectButton;
    UIBarButtonItem *_settingButton;
    UIBarButtonItem *_helpButton;
    
    MBProgressHUD *_HUD;
    
    DropboxSharekitHelper *_shareHelper;
    
    /**
     *  General pack info (like pack image and no of cards) on the right.
     *  Only applicable for iPad (on iPad, we have the similar logic on the master view)
     */
    UIView        *_rightPackView;
    
}

@property (strong, nonatomic) id detailItem;

@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, assign) int indexCard;

@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) UIPopoverController *settingPopoverController;
@property (nonatomic, strong) UIPopoverController *helpPopoverController;

@property (strong, nonatomic) NSMutableArray *isResizedArray; //用于判断是否已经被autoresize

- (void) showCurrentCardInScrollView:(BOOL) shouldResetSegment;

- (void)shareButtonClicked:(id) sender;

- (void) showPackInfoView;
- (void) hidePackInfoView;

@end
