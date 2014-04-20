//
//  CreateAlarmSoundViewController.h
//  NoiseMeter
//
//  Created by Bourne Wang on 14-2-13.
//  Copyright (c) 2014年 Internetics Pty Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Card.h"
#import "Question.h"
#import "Answer.h"
#import "Pack.h"
#import <AVFoundation/AVFoundation.h>

@interface CreateSoundViewController : UIViewController <AVAudioRecorderDelegate,AVAudioPlayerDelegate>

@property (strong, nonatomic) Card *card;
@property (strong, nonatomic) Pack *pack;
@property (assign, nonatomic) BOOL  isOnQuestion;

@end
