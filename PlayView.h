//
//  PlayView.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 25/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Pack;
@class Card;
@class FlashCardView;

@interface PlayView : UIView <UIScrollViewDelegate> {
    UIScrollView *_scrollView;
    UIButton *_closeButton;
    Pack *_currentPack;
    Card *_currentCard;
    FlashCardView *_currentFlashCardView;
    NSMutableArray *_cardArray;
}

@property (strong, nonatomic) Pack *currentPack;
@property (strong, nonatomic) Card *currentCard;

@end
