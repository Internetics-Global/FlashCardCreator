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


NSString *const Key_Path_AnimatedImage = @"self.animtableImageView.animatedImage";
NSString *const Key_Path_Image = @"self.animtableImageView.image";

@interface MultimediaView () <UIGestureRecognizerDelegate> {
    
    UIView   *_avHolderView;
    UIView   *_gifHolderView;
    
    UIButton *_videoButton;
    UIButton *_gifButton;
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
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"The requested video does not exsit" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            
            return;
            
        }
        
        AVPlayer *video=[AVPlayer playerWithURL:videoUrl];
        video.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        self.avPlayer.player = video;
        
        _videoButton.hidden = false;
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

//            _avHolderView.userInteractionEnabled = false;
            
            [self addSubview:_avHolderView];
            
            
            _videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _videoButton.frame = CGRectMake(CGRectGetWidth(_avHolderView.frame) - 40, CGRectGetHeight(_avHolderView.frame) - 40, 32, 32);
            _videoButton.contentMode = UIViewContentModeCenter;
            _videoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
            [_videoButton setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
            [_videoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            [_videoButton addTarget:self action:@selector(videoButtonDidClicked) forControlEvents:UIControlEventTouchUpInside];
            
            _videoButton.hidden = true;
            
            [_avHolderView addSubview:_videoButton];
        
            
            break;
        }
        case ImageView: {
            
            _gifHolderView = [[UIView alloc] init];
            [_gifHolderView setFrame:self.bounds];
            _gifHolderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|
            UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            
            [self addSubview:_gifHolderView];
            
            self.animtableImageView = [[FLAnimatedImageView alloc] init];
            self.animtableImageView.frame = _gifHolderView.bounds;
            self.animtableImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|
                UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            self.animtableImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.animtableImageView.clipsToBounds = YES;
            //self.animtableImageView.backgroundColor = [UIColor greenColor];
            self.animtableImageView.layer.cornerRadius = 15;
            self.animtableImageView.layer.masksToBounds = true;
            
            self.animtableImageView.isAllowAutoPlayWhenVisible = false;
            
            [_gifHolderView addSubview:self.animtableImageView];
            
            _gifButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _gifButton.frame = CGRectMake(CGRectGetWidth(_gifHolderView.frame) - 40, CGRectGetHeight(_gifHolderView.frame) - 40, 32, 32);
            _gifButton.contentMode = UIViewContentModeCenter;
            _gifButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
            [_gifButton setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
            [_gifButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            [_gifButton addTarget:self action:@selector(gifButtonDidClicked) forControlEvents:UIControlEventTouchUpInside];
            
            _gifButton.hidden = true;
            
//            _gifButton.backgroundColor = [UIColor greenColor];
            
            [_gifHolderView addSubview:_gifButton];
            
            
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

- (void) gifButtonDidClicked {
    
    if ([self isPlayingGif]) {
        
        [self pauseGif];
    } else {
        [self playGif];
    }
    
}

- (void) videoButtonDidClicked {
    
    if ([self isPlayingVideo]) {
        
        [self pauseVideo];
    } else {
        [self playVideo];
    }
    
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (_gifHolderView) {
        _gifHolderView.frame = self.bounds;
    }
    
    if (_avHolderView) {
        _avHolderView.frame = self.bounds;
//        _avHolderView.backgroundColor = [UIColor orangeColor];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:Key_Path_AnimatedImage]) {
        
        UIImage *image = [change objectForKey: NSKeyValueChangeNewKey];
        if (image == nil || [image isKindOfClass:[NSNull class]]) {
            _gifButton.hidden = true;
            
        } else {
            _gifButton.hidden = false;
            [self.animtableImageView stopAnimating];
        }
        
       
        
        
    } else if ([keyPath isEqualToString:Key_Path_Image]) {
        
        _gifButton.hidden = true;
        
    } else {
        
    }
}


- (void)dealloc {
    
    [self clean];

}


@end
