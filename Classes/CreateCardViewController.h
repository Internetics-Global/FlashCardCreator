//
//  CreateCardViewController.h
//  FFC
//
//  Created by Wang Bourne on 15/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Pack;
@class FlashCardView;
@class FlashCard;
@class Card;

@interface CreateCardViewController : UIViewController {
    FlashCard *_newCardView;
    Card *_newCard;
    Pack *_currentPack;
}

@property (strong, nonatomic) Pack *currentPack;


- (void) saveAndCloseCreateCardView;

@end
