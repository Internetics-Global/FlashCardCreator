//
//  QuestionView.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 8/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseView.h"

@class Card;

@interface QuestionView : BaseView

- (void) refreshDisplay;
- (void) updateQuestionViewTemplateForiPhone:(int) index;
- (void) updateQuestionViewTemplateForiPad:(int) index;

- (void) setCurrentCard:(Card *)currentCard;

@end
