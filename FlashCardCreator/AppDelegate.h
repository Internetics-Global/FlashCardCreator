//
//  AppDelegate.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h> 
#import <AVFoundation/AVFoundation.h>

@class MasterViewController;
@class DetailViewController;
@class Pack;
@class Card;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    Pack *_lastCreatedPack;
    int _indexLastCreatedPack;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) MGSplitViewController *splitViewController;
@property (strong, nonatomic) MasterViewController *masterViewController;
@property (strong, nonatomic) DetailViewController *detailViewController;


@property (assign, nonatomic) int packIDForMasterViewPack;

@property (assign, nonatomic) BOOL isDownloadingPack;

@property (assign, nonatomic) BOOL isAllowToShowTooltip; //在第一次启动下载sample,packlist等对话框存在下，不允许显示

@property (assign, nonatomic) BOOL isAllowToShowPackList;


@property (strong, nonatomic) AVAudioRecorder *recorder;

/**
 *  true after finishing a record; false by default
 */
@property (assign, nonatomic) BOOL             isRecordFinished;

@property (strong, nonatomic) NSMutableArray   *rawMatchedText2SpeechArray;


- (UIView *)progressHUDHolderView;

@end
