//
//  MultimediaView.h
//  FlashCardCreator
//
//  Created by internetics on 20/10/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ImageView,
    Video,
    YoutubeVideo,
} FFCMultimediaType;


@class FLAnimatedImageView;
@class AVPlayerViewController;
@class AVPlayerLayer;



@interface MultimediaView : UIView

@property (strong, nonatomic) FLAnimatedImageView     *animtableImageView;
@property (strong, nonatomic) AVPlayerLayer           *avPlayer;

- (void) setMultimediaType:(FFCMultimediaType) multimediaType;

- (void) setVideoURL:(NSURL*) movieUrl;
- (void) playVideo;
- (void) pauseVideo;
- (void) clean;

@end
