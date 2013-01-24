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

@class QuestionView;
@class AnswerView;
@class Card;
@class Pack;

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, UIScrollViewDelegate,DBRestClientDelegate> {
    UISegmentedControl *_segmentedControl;
    QuestionView *_questionView;
    AnswerView *_answerView;
    UIScrollView    *_scrollView;
    
    Pack *_currentPack;
    Card *_currentCard;
    int _indexCard;  //selected card index in master view
    
    NSMutableArray *_cardArray;
    
    MBProgressHUD *_HUD;
    
    DBRestClient *_restClient;
    
    UIPopoverController *_settingPopoverController;
    
    UIPopoverController *_masterPopoverController;
    
    BOOL _isShare;
}

@property (strong, nonatomic) id detailItem;

@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, assign) int indexCard;

@property (nonatomic, strong) UIPopoverController *masterPopoverController;

- (void) showCurrentCardInScrollView;

@end
