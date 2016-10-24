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

@interface MultimediaView () {
    
    UIView   *_avHolderView;
}

@end

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
    self.translatesAutoresizingMaskIntoConstraints = false;
}

- (void) setVideoURL:(NSURL*) movieUrl {
    if (self.avPlayer) {
        
        NSError *err;
        if ([movieUrl checkResourceIsReachableAndReturnError:&err] == false) {
            NSLog(@"this movieUrl does not exit: %@",movieUrl);
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"The requested video does not exsit" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            
            return;
            
        }
        
        AVPlayer *video=[AVPlayer playerWithURL:movieUrl];
        video.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        self.avPlayer.player = video;
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[video currentItem]];
    }
}

- (void) playVideo {
    if (self.avPlayer) {
        
        if ((self.avPlayer.player.rate != 0) && (self.avPlayer.player.error == nil)) {
            // player is playing
            return;
        } else {
            [self.avPlayer.player play];
        }
        
    }
}

- (void) pauseVideo {
    if (self.avPlayer) {
        [self.avPlayer.player pause];
    }
}

- (void) clean {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.animtableImageView = nil;
    
    _avHolderView = nil;
    _avPlayer = nil;
}

- (void) setMultimediaType:(FFCMultimediaType) multimediaType {
    
    [self clean];
    
    self.autoresizesSubviews = true;
    
    switch (multimediaType) {
        case Video: {
            
            _avHolderView = [[UIView alloc] init];
            [_avHolderView setFrame:self.bounds];
            _avHolderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|
            UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            self.avPlayer = [[AVPlayerLayer alloc] init];
            self.avPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
            self.avPlayer.frame = _avHolderView.bounds;
            [_avHolderView.layer addSublayer:self.avPlayer];

            _avHolderView.userInteractionEnabled = false;
            
            [self addSubview:_avHolderView];
        
            
            break;
        }
        case ImageView: {
            
            self.animtableImageView = [[FLAnimatedImageView alloc] init];
            self.animtableImageView.frame = self.bounds;
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
    
    if (_avHolderView) {
        _avHolderView.frame = self.bounds;
//        _avHolderView.backgroundColor = [UIColor orangeColor];
    }
}



- (void)dealloc {
    
    self.animtableImageView = nil;
    
    _avPlayer = nil;
    _avHolderView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
