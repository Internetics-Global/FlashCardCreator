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


NSString *const Key_Path_AnimatedImage = @"self.animtableImageView.animatedImage";
NSString *const Key_Path_Image = @"self.animtableImageView.image";

@interface MultimediaView () <UIGestureRecognizerDelegate> {
    
    UIView   *_avHolderView;
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

- (void) setVideoURL:(NSURL*) videoUrl {
    if (self.avPlayer) {
        
        NSError *err;
        if ([videoUrl checkResourceIsReachableAndReturnError:&err] == false) {
            NSLog(@"this videoUrl does not exit: %@",videoUrl);
            
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"The requested video does not exsit" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            [alertView show];
            
            return;
            
        }
        
        _videoUrl = videoUrl;
        
        AVPlayer *video=[AVPlayer playerWithURL:videoUrl];
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
        [_gifButton setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
        [self.animtableImageView stopAnimating];
    }
}

- (void) playVideo {
    if (self.avPlayer) {
        
        if ([self isPlayingVideo]) {
            // player is playing
            return;
        } else {
            [_videoButton setImage:[UIImage imageNamed:@"pause_button"] forState:UIControlStateNormal];
            [self.avPlayer.player play];
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
        [_videoButton setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
        [self.avPlayer.player pause];
    }
}

- (void) pauseVideoAndGif {
    [self pauseVideo];
    [self pauseGif];
}

- (void) clean {
    
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
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.animtableImageView = nil;
    
    _avPlayer = nil;
    
    _avHolderView = nil;
    _gifHolderView = nil;
    
    _gifImagePointer = nil;
}

- (void) setMultimediaType:(FFCMultimediaType) multimediaType {
    
    [self clean];
    
    self.autoresizesSubviews = true;
    
    switch (multimediaType) {
        case Video: {
            
            {
                
                _avHolderView = [[UIView alloc] init];
                [_avHolderView setFrame:self.bounds];
                _avHolderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;;
                self.avPlayer = [[AVPlayerLayer alloc] init];
                self.avPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
                self.avPlayer.frame = _avHolderView.bounds;
                [_avHolderView.layer addSublayer:self.avPlayer];
                
                [self addSubview:_avHolderView];
            }
            
            
            {
                _videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
                _videoButton.frame = CGRectMake(CGRectGetWidth(_avHolderView.frame) - 48, CGRectGetHeight(_avHolderView.frame) - 48, 48, 48);
                _videoButton.contentMode = UIViewContentModeCenter;
                _videoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
                [_videoButton setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
                [_videoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                [_videoButton addTarget:self action:@selector(videoButtonDidClicked) forControlEvents:UIControlEventTouchUpInside];
                
                _videoButton.hidden = true;
                
                [_avHolderView addSubview:_videoButton];
            }
            
            
            {
                _videoFullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
                _videoFullScreenButton.frame = CGRectMake(CGRectGetWidth(_avHolderView.frame) - 96, CGRectGetHeight(_avHolderView.frame) - 48, 48, 48);
                _videoFullScreenButton.contentMode = UIViewContentModeCenter;
                _videoFullScreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
                [_videoFullScreenButton setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
                [_videoFullScreenButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                [_videoFullScreenButton addTarget:self action:@selector(videoFullScreenButtonDidClicked) forControlEvents:UIControlEventTouchUpInside];
                
                _videoFullScreenButton.hidden = true;
                
                [_avHolderView addSubview:_videoFullScreenButton];
            }
        
            
            break;
        }
        case ImageView: {
            
            {
                _gifHolderView = [[UIView alloc] init];
                [_gifHolderView setFrame:self.bounds];
                _gifHolderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;;
//                _gifHolderView.backgroundColor = [UIColor greenColor];
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
                [_gifButton setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
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
    
    MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:_videoUrl];
    [[playerViewController moviePlayer] play];
    
    
    
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


- (void)dealloc {
    
    [self clean];

}


@end
