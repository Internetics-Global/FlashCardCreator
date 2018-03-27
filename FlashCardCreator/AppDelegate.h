//
//  AppDelegate.h
//  FFC
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

@protocol OIDAuthorizationFlowSession;

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

@property (assign, nonatomic) BOOL isInAppWebSite;

@property (assign, nonatomic) BOOL isToShowShareActinSheet_Google_Drive;
@property (assign, nonatomic) BOOL isToShowShareActinSheet_Dropbox;
@property (assign, nonatomic) BOOL isToShowShareActinSheet_AWS;

@property (assign, nonatomic) BOOL isDownloadingSamplePack;

@property (assign, nonatomic) BOOL isAllowToShowTooltip; 

@property (assign, nonatomic) BOOL isAllowToShowPackList;

@property (assign, nonatomic) BOOL isAllowToShareAfterDropboxLogIn;

@property (assign, nonatomic) BOOL isNotAllowDownloadSamplePack;


@property (strong, nonatomic) AVAudioRecorder *recorder;

/**
 *  true after finishing a record; false by default
 */
@property (assign, nonatomic) BOOL             isRecordFinished;


/*! @brief The authorization flow session which receives the return URL from
 \SFSafariViewController.
 @discussion We need to store this in the app delegate as it's that delegate which receives the
 incoming URL on UIApplicationDelegate.application:openURL:options:. This property will be
 nil, except when an authorization flow is in progress.
 */
@property(nonatomic, strong, nullable) id<OIDAuthorizationFlowSession> currentGoogleDriveAuthorizationFlow;


- (void) setupAudioWithoutRecord;
- (void) setupAudioWithRecord;

- (UIView *)progressHUDHolderView;

@end
