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
#import "PopupListComponent.h"

@class FlashCardView;
@class QuestionView;
@class AnswerView;
@class Card;
@class Pack;
@class FlashCard;
@class DropboxSharekitHelper;

@interface DetailViewController : UIViewController <MGSplitViewControllerDelegate, UIScrollViewDelegate, PopupListComponentDelegate, UIAlertViewDelegate, UIPopoverControllerDelegate> {
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
    
    PopupListComponent *_templateBackgroundSelectPopup;
    PopupListComponent *_shareSelectPopup;
    
    MBProgressHUD *_HUD;
    
    DropboxSharekitHelper *_shareHelper;
    
}

@property (strong, nonatomic) id detailItem;

@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, assign) int indexCard;

@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) UIPopoverController *settingPopoverController;
@property (nonatomic, strong) UIPopoverController *helpPopoverController;

@property (nonatomic, strong) PopupListComponent *templateBackgroundSelectPopup;
@property (nonatomic, strong) PopupListComponent *shareSelectPopup;

- (void) showCurrentCardInScrollView:(BOOL) shouldResetSegment;

- (void)shareButtonClicked:(id) sender;

@end
