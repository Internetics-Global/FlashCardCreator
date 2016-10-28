//
//  AnimatedGifViewController.m
//  FlashCardCreator
//
//  Created by internetics on 28/10/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "AnimatedGifViewController.h"
#import "FLAnimatedImageView.h"
#import "UIButton+Extensions.h"

@interface AnimatedGifViewController () {
    FLAnimatedImageView  *_animatedImageView;
}



@end

@implementation AnimatedGifViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    {
        _animatedImageView = [[FLAnimatedImageView alloc] init];
        [_animatedImageView setContentMode:UIViewContentModeScaleAspectFit];
        _animatedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        _animatedImageView.frame = self.view.bounds;
        _animatedImageView.isAllowAutoPlayWhenVisible = true;
        [self.view addSubview:_animatedImageView];
        
        _animatedImageView.animatedImage = self.animatedImage;
    }
    
    {
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        closeButton.backgroundColor = [UIColor clearColor];
        [closeButton setImage:[UIImage imageNamed:@"close_button.png"] forState:UIControlStateNormal];
        
        closeButton.titleLabel.text = nil;
        closeButton.showsTouchWhenHighlighted = YES;
        [closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        closeButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) - 60, 15, 45, 45);
        closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:closeButton];
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dismiss {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
