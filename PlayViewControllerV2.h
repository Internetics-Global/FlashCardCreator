//
//  PlayViewControllerV2.h
//  FFC
//
//  Created by Bourne Wang on 23/03/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pack.h"

typedef NS_ENUM(NSInteger, One_Off_Play_Type) {
    One_Off_Play_Type_Unkown      = -1,
    One_Off_Play_Type_Manually      = 0,
    One_Off_Play_Type_Auto_Play       = 1,
    One_Off_Play_Type_Auto_Play_Loop   = 2,
};

@interface PlayViewControllerV2 : UIViewController

@property (strong, nonatomic) Pack *currentPack;

@property (assign, nonatomic) BOOL previewOnly;

@property (assign, nonatomic) BOOL isFromPackList;

@property (assign, nonatomic) One_Off_Play_Type oneOffPlayType;

- (void) text2SpeechFinished:(NSNumber*)isQuestionShowing;

@end
