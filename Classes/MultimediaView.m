//
//  MultimediaView.m
//  FlashCardCreator
//
//  Created by internetics on 20/10/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "MultimediaView.h"
#import "FLAnimatedImageView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@implementation MultimediaView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.translatesAutoresizingMaskIntoConstraints = true;
}

- (void) setVideoURL:(NSURL*) movieUrl {
    if (self.avPlayerController) {
        
        NSError *err;
        if ([movieUrl checkResourceIsReachableAndReturnError:&err] == false) {
            NSLog(@"this movieUrl does not exit: %@",movieUrl);
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"The requested video does not exsit" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            
            return;
            
        }
        
        AVPlayer *video=[AVPlayer playerWithURL:movieUrl];
        video.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        self.avPlayerController.player = video;
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[video currentItem]];
    }
}

- (void) playVideo {
    if (self.avPlayerController) {
        [self.avPlayerController.player play];
    }
}

- (void) pauseVideo {
    if (self.avPlayerController) {
        [self.avPlayerController.player pause];
    }
}

- (void) clean {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.animtableImageView = nil;
    self.avPlayerController = nil;
}

- (void) setMultimediaType:(FFCMultimediaType) multimediaType {
    
    [self clean];
    
    self.autoresizesSubviews = true;
    
    switch (multimediaType) {
        case Video: {

            self.avPlayerController = [[AVPlayerViewController alloc] init];
            self.avPlayerController.view.translatesAutoresizingMaskIntoConstraints = true;
            self.avPlayerController.videoGravity = AVLayerVideoGravityResizeAspect;
            self.avPlayerController.view.frame = self.bounds;
            
            self.avPlayerController.showsPlaybackControls = false;
            
            
            self.avPlayerController.view.userInteractionEnabled = false;
            
            [self addSubview:self.avPlayerController.view];
        
            
            break;
        }
        case ImageView: {
            
            self.animtableImageView = [[FLAnimatedImageView alloc] init];
            self.animtableImageView.frame = self.bounds;
            self.animtableImageView.translatesAutoresizingMaskIntoConstraints = true;
            self.animtableImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|
                UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            self.animtableImageView.userInteractionEnabled = FALSE;
            self.animtableImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.animtableImageView.clipsToBounds = YES;
            //self.animtableImageView.backgroundColor = [UIColor greenColor];
            self.animtableImageView.layer.cornerRadius = 15;
            self.animtableImageView.layer.masksToBounds = true;
            
            [self addSubview:self.animtableImageView];
            
            break;
        }
        case YoutubeVideo:
            break;
            
        default:
            break;
    }
    
    
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.animtableImageView) {
        self.animtableImageView.frame = self.bounds;
    }
    
    if (self.avPlayerController) {
        self.avPlayerController.view.frame = self.bounds;
    }
}



- (void)dealloc {
    
    self.avPlayerController = nil;
    self.animtableImageView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
