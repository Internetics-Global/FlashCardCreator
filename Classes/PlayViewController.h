//
//  PlayViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 2/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Pack;
@class Card;
@class FlashCard;
@class CMMotionManager;

@interface PlayViewController : UIViewController <UIScrollViewDelegate>{
    UIScrollView *_scrollView;
    UIButton *_closeButton;
    Pack *_currentPack;
    NSMutableArray *_flashCardViewArray;
    CMMotionManager *_motionManager;
    
    FlashCard *_previousFlashCardView;
    FlashCard *_currentFlashCardView;
    FlashCard *_nextFlashCardView;
    
    int _indexCard;
    
    NSArray *_shuffledCardArray;
    NSMutableArray *_isResizedArray; //用于判断是否已经被autoresize
    
    NSDate *_startDate;
}

@property (strong, nonatomic) Pack *currentPack;

@end
