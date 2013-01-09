//
//  BaseView.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 10/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;

@interface BaseView : UIView {
    UIImageView *_logoImage;
    UITextView *_content;
    UITextView *_title;
    UIImageView *_image;
    Card *_currentCard;
    
    BOOL _keyboardShown;
}

@property (nonatomic, strong) Card *currentCard;

@end
