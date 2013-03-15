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
    Card *_currentCard;
    FlashCard *_currentFlashCardView;
    NSMutableArray *_flashCardViewArray;
    CMMotionManager *_motionManager;
}

@property (strong, nonatomic) Pack *currentPack;
@property (strong, nonatomic) Card *currentCard;

@end
