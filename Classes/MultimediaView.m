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
#import "UIView+FindUIViewController.h"
#import "PlayViewControllerV2.h"
#import "AnimatedGifViewController.h"

#import <AVFoundation/AVFoundation.h>

#import "AppDelegate.h"


NSString *const Key_Path_AnimatedImage = @"self.animtableImageView.animatedImage";
NSString *const Key_Path_Image = @"self.animtableImageView.image";

@interface MultimediaView () <UIGestureRecognizerDelegate> {
    
    UIView   *_videoHolderView;
    UIView   *_gifHolderView;
    
    UIButton *_videoButton;
    UIButton *_videoFullScreenButton;
    
    UIButton *_gifButton;
    UIButton *_gifFullScreenButton;
    
    /*
     * the only usage is for videoFullScreenButtonDidClicked
    */
    NSURL              *_videoUrl;
    
    /*
     * the only usage is for gifFullScreenButtonDidClicked
     */
    id                  _gifImagePointer;
    
    FFCMultimediaType   _currentMultimediaType;
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
    _currentMultimediaType = Unkown;
}

- (void) setVideoURL:(NSURL*) videoUrl {
    if (self.avPlayer) {
        
        NSError *err;
        if ([videoUrl checkResourceIsReachableAndReturnError:&err] == false) {
            NSLog(@"this videoUrl does not exit: %@",videoUrl);
            
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"The requested video does not exsit" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            [alertView show];
//            
            return;
            
        }
        
        _videoUrl = videoUrl;
        
        AVPlayer *video=[AVPlayer playerWithURL:videoUrl];
        video.volume = 1;
        video.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        self.avPlayer.player = video;
        
        _videoButton.hidden = false;
        _videoFullScreenButton.hidden = false;
    }
}




- (void) playGif {
    if (self.animtableImageView) {
        
        if ([self isPlayingVideo]) {
            // player is playing
            return;
        } else {
            [_gifButton setImage:[UIImage imageNamed:@"pause_button"] forState:UIControlStateNormal];
            [self.animtableImageView startAnimating];
        }
        
    }
}

- (BOOL) isPlayingGif {
    if (self.animtableImageView != nil && [self.animtableImageView isAnimating]) {
        // player is playing
        return true;
    } else {
        return false;
    }
}

- (void) pauseGif {
    if (self.animtableImageView && [self.animtableImageView isAnimating]) {
        [_gifButton setImage:[UIImage imageNamed:@"play_multimedia"] forState:UIControlStateNormal];
        [self.animtableImageView stopAnimating];
    }
}

/*
 * please don't use this method. The reason why it's here is I want to highlight its difference with Android counterpart.
 * In Android, since screenshot does not work well, so we have to stop gif and setMutimediaType to ImageView, after screenshot
 * we will resume to gif type
*/
- (void) stopGif {
    NSAssert(false, @"should not come here");
}

/*
 * please don't use this method. The reason why it's here is I want to highlight its difference with Android counterpart.
 * In Android, since screenshot does not work well, so we have to stop video and setMutimediaType to ImageView, after screenshot
 * we will resume to video type
 */
- (void) stopVideo {
    NSAssert(false, @"should not come here");
}

- (void) playVideo {
    if (self.avPlayer) {
        
        if ([self isPlayingVideo]) {
            // player is playing
            return;
        } else {
            [_videoButton setImage:[UIImage imageNamed:@"pause_button"] forState:UIControlStateNormal];
            [self.avPlayer.player play];
            _videoButton.hidden = true;
            _videoFullScreenButton.hidden = true;
        }
        
    }
}

- (BOOL) isPlayingVideo {
    if ((self.avPlayer.player.rate != 0) && (self.avPlayer.player.error == nil)) {
        // player is playing
        return true;
    } else {
        return false;
    }
}

- (void) pauseVideo {
    if (self.avPlayer) {
        [_videoButton setImage:[UIImage imageNamed:@"play_multimedia"] forState:UIControlStateNormal];
        [self.avPlayer.player pause];
        _videoButton.hidden = false;
        _videoFullScreenButton.hidden = false;
    }
}

- (void) pauseVideoAndGif {
    [self pauseVideo];
    [self pauseGif];
}

- (void) clean {
    
    _currentMultimediaType = Unkown;
    
    @try {
        [self removeObserver:self forKeyPath:@"self.animtableImageView.animatedImage"];
    } @catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
    
    @try {
        [self removeObserver:self forKeyPath:@"self.animtableImageView.image"];
    } @catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.animtableImageView = nil;
    
    _avPlayer = nil;
    
    _videoHolderView = nil;
    _gifHolderView = nil;
    
    _gifImagePointer = nil;
}

- (void) setMultimediaType:(FFCMultimediaType) multimediaType {
    
    if (multimediaType == _currentMultimediaType) {
        
        if (multimediaType == Video) {
            
            /*
             * This is quite tricky part. if we don't rebuild avPlayer and use set frame again, there will be a animation from CGSizeZero to full view, that's not good user experience.
             *
            */
            
            
            [self.avPlayer removeFromSuperlayer];
            self.avPlayer = nil;
            
            self.avPlayer = [[AVPlayerLayer alloc] init];
            self.avPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
            self.avPlayer.frame = _videoHolderView.bounds;
            //self.avPlayer.backgroundColor = [UIColor orangeColor].CGColor;
            [_videoHolderView.layer addSublayer:self.avPlayer];
            
            //this is necessary since it could hide following two buttons when insert a new CALayer
            [_videoHolderView bringSubviewToFront:_videoButton];
            [_videoHolderView bringSubviewToFront:_videoFullScreenButton];
        }
        
        return;
    }
    
    [self clean];
    
    switch (multimediaType) {
        case Video: {
            
            //In Android,since Android system does not support thumbnail preview, so we have to create
            //another ImageView to hold thumbnail. In iOS, we don't need to do this.
            
            {
                
                _videoHolderView = [[UIView alloc] init];
                [_videoHolderView setFrame:self.bounds];
                //_videoHolderView.backgroundColor = [UIColor greenColor];
                _videoHolderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;;
                
                self.avPlayer = [[AVPlayerLayer alloc] init];
                self.avPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
                self.avPlayer.frame = _videoHolderView.bounds;
                //self.avPlayer.backgroundColor = [UIColor orangeColor].CGColor;
                
                self.avPlayer.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:[self.avPlayer.player currentItem]];
                
            
                [_videoHolderView.layer addSublayer:self.avPlayer];
                
                [self addSubview:_videoHolderView];
            }
            
            
            {
                _videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
                _videoButton.frame = CGRectMake(CGRectGetWidth(_videoHolderView.frame) - 48, CGRectGetHeight(_videoHolderView.frame) - 48, 48, 48);
                _videoButton.contentMode = UIViewContentModeCenter;
                _videoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
                [_videoButton setImage:[UIImage imageNamed:@"play_multimedia"] forState:UIControlStateNormal];
                [_videoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                [_videoButton addTarget:self action:@selector(videoButtonDidClicked) forControlEvents:UIControlEventTouchUpInside];
                
                _videoButton.hidden = true;
                
                [_videoHolderView addSubview:_videoButton];
            }
            
            
            {
                _videoFullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
                _videoFullScreenButton.frame = CGRectMake(CGRectGetWidth(_videoHolderView.frame) - 96, CGRectGetHeight(_videoHolderView.frame) - 48, 48, 48);
                _videoFullScreenButton.contentMode = UIViewContentModeCenter;
                _videoFullScreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
                [_videoFullScreenButton setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
                [_videoFullScreenButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                [_videoFullScreenButton addTarget:self action:@selector(videoFullScreenButtonDidClicked) forControlEvents:UIControlEventTouchUpInside];
                
                _videoFullScreenButton.hidden = true;
                
                [_videoHolderView addSubview:_videoFullScreenButton];
            }
        
            
            break;
        }
        case ImageView: {
            
            {
                _gifHolderView = [[UIView alloc] init];
                [_gifHolderView setFrame:self.bounds];
                _gifHolderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;;
                //_gifHolderView.backgroundColor = [UIColor redColor];
                [self addSubview:_gifHolderView];
            }
            
            {
                self.animtableImageView = [[FLAnimatedImageView alloc] init];
                self.animtableImageView.frame = self.bounds;
                self.animtableImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
                self.animtableImageView.contentMode = UIViewContentModeScaleAspectFit;
                self.animtableImageView.clipsToBounds = YES;
                //self.animtableImageView.backgroundColor = [UIColor greenColor];
                self.animtableImageView.layer.cornerRadius = 15;
                self.animtableImageView.layer.masksToBounds = true;
//                self.animtableImageView.layer.borderColor = [UIColor redColor].CGColor;
//                self.animtableImageView.layer.borderWidth = 2;
                self.animtableImageView.isAllowAutoPlayWhenVisible = false;
                
                [_gifHolderView addSubview:self.animtableImageView];
            }
            
            {
                _gifButton = [UIButton buttonWithType:UIButtonTypeCustom];
                _gifButton.frame = CGRectMake(CGRectGetWidth(_gifHolderView.frame) - 48, CGRectGetHeight(_gifHolderView.frame) - 48, 48, 48);
                _gifButton.contentMode = UIViewContentModeCenter;
                _gifButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
                [_gifButton setImage:[UIImage imageNamed:@"play_multimedia"] forState:UIControlStateNormal];
                [_gifButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                [_gifButton addTarget:self action:@selector(gifButtonDidClicked) forControlEvents:UIControlEventTouchUpInside];
                
                _gifButton.hidden = true;
                
                [_gifHolderView addSubview:_gifButton];
            }
            
            
            {
                _gifFullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
                _gifFullScreenButton.frame = CGRectMake(CGRectGetWidth(_gifHolderView.frame) - 96, CGRectGetHeight(_gifHolderView.frame) - 48, 48, 48);
                _gifFullScreenButton.contentMode = UIViewContentModeCenter;
                _gifFullScreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
                [_gifFullScreenButton setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
                [_gifFullScreenButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                [_gifFullScreenButton addTarget:self action:@selector(gifFullScreenButtonDidClicked) forControlEvents:UIControlEventTouchUpInside];
                
                _gifFullScreenButton.hidden = true;
                
                [_gifHolderView addSubview:_gifFullScreenButton];
            }
            
            
            [self addObserver:self
                         forKeyPath:Key_Path_AnimatedImage
                            options:NSKeyValueObservingOptionNew
                            context:nil];
            [self addObserver:self
                   forKeyPath:Key_Path_Image
                      options:NSKeyValueObservingOptionNew
                      context:nil];
            
            break;
        }
        case YoutubeVideo:
            break;
            
        default:
            break;
    }
    
    _currentMultimediaType = multimediaType;
}

- (void) gifFullScreenButtonDidClicked {
    
    if (_gifImagePointer == nil) {
        return;
    }
    
    AnimatedGifViewController *playerViewController = [[AnimatedGifViewController alloc] init];
    playerViewController.animatedImage = _gifImagePointer;
    
    PlayViewControllerV2 *controller = [self findPlayViewControllerV2];
    
    if (controller) {
        //means this is called from play mode
        //iPad
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [controller presentModalViewController:playerViewController animated:YES];
    } else {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:playerViewController animated:YES];
    }
    
}

- (void) gifButtonDidClicked {
    
    if ([self isPlayingGif]) {
        
        [self pauseGif];
    } else {
        [self playGif];
    }
    
}

- (void) videoFullScreenButtonDidClicked {
    
    if (_videoUrl == nil) {
        return;
    }
    
    
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    AVPlayer *player = [[AVPlayer alloc] initWithURL:_videoUrl];
    player.volume = 1.0;
    playerViewController.player = player;
    
    PlayViewControllerV2 *controller = [self findPlayViewControllerV2];
    
    if (controller) {
        //means this is called from play mode
        //iPad
        [controller presentViewController:playerViewController animated:true completion:^{
            [playerViewController.player play];
        }];
    } else {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:playerViewController animated:true completion:^{
            [playerViewController.player play];
        }];
    }
    
    
}


- (void) videoButtonDidClicked {
    
    if ([self isPlayingVideo]) {
        
        [self pauseVideo];
    } else {
        [self playVideo];
    }
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:Key_Path_AnimatedImage]) {
        
        UIImage *image = [change objectForKey: NSKeyValueChangeNewKey];
        if (image == nil || [image isKindOfClass:[NSNull class]]) {
            _gifButton.hidden = true;
            _gifFullScreenButton.hidden = true;
            
        } else {
            _gifButton.hidden = false;
            _gifFullScreenButton.hidden = false;
            [self.animtableImageView stopAnimating];
        }
        
        _gifImagePointer = image;
        
        
    } else if ([keyPath isEqualToString:Key_Path_Image]) {
        
        _gifButton.hidden = true;
        _gifFullScreenButton.hidden = true;
        
    } else {
        
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
    [self pauseVideo];
    _videoButton.hidden = false;
    _videoFullScreenButton.hidden = false;
}




- (void)dealloc {
    
    [self clean];

}




@end
