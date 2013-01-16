//
//  CreateCardViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 15/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Pack;
@class FlashCardView;
@class Card;

@interface CreateCardViewController : UIViewController {
    Pack *_currentPack;
    FlashCardView *_cardView;
    Card *_newCard;
}

@property (strong, nonatomic) Pack *currentPack;

@end
