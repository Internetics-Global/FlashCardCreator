//
//  PlayViewControllerV2.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 23/03/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pack.h"

typedef NS_ENUM(NSInteger, Play_Type) {
    Play_Type_Unkown      = -1,
    Play_Type_Manually      = 0,
    Play_Type_Auto_Play       = 1,
    Play_Type_Auto_Play_Loop   = 2,
};

@interface PlayViewControllerV2 : UIViewController

@property (strong, nonatomic) Pack *currentPack;

@property (assign, nonatomic) Play_Type playType;

- (void) text2SpeechFinished:(NSNumber*)isQuestionShowing;

@end
