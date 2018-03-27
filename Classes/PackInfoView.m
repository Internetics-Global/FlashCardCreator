//
//  PackInfoView.m
//  FlashCardCreator
//
//  Created by Internetics on 8/06/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "PackInfoView.h"
#import "Common.h"
#import "Pack.h"
#import "FileOperationHelper.h"
#import "User.h"

@interface PackInfoView () {
    UIScrollView *_packInfoScrollView;
    
    UILabel *_rightPackCardNo;
    
    UILabel *_shareCodeLabel;
    
    UIButton *_playPackNavButton;
    UIButton *_backPackNavButton;
    UIButton *_forwardPackNavButton;
    
    /**
     *  auto update if set currentPack
     */
    int       _currentPage;
    
    BOOL      _isDirtyScrollView; //used to detemrine whether to rebuild scroll view or not

    BOOL      _isUsingBackForwardNavButton;
}

@end

@implementation PackInfoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    
    _isDirtyScrollView = false;
    _isUsingBackForwardNavButton = false;
    
    int width = CGRectGetWidth(self.frame);
    
    
    _packInfoScrollView = [ [UIScrollView alloc ] initWithFrame:CGRectMake(0, 0, width, width)];
    _packInfoScrollView.bounces = YES;
    _packInfoScrollView.pagingEnabled = YES;
    _packInfoScrollView.delegate = self;
    _packInfoScrollView.showsHorizontalScrollIndicator = true;
//    _packInfoScrollView.backgroundColor = [UIColor blueColor];
    [self addSubview:_packInfoScrollView];
    
    _rightPackCardNo = [[UILabel alloc] init];
    _rightPackCardNo.textColor = [UIColor whiteColor];
    _rightPackCardNo.autoresizingMask =  UIViewAutoresizingNone;
    _rightPackCardNo.backgroundColor = [UIColor clearColor];
    _rightPackCardNo.textAlignment = NSTextAlignmentCenter;
    _rightPackCardNo.tag = 0;
    CGRect rect = _packInfoScrollView.frame;
    if (isUserInterfaceIdiomPhone) {
        rect.origin.y = CGRectGetMaxY(rect)+ 7;
        rect.size.height = 15;
        _rightPackCardNo.font = [UIFont systemFontOfSize: 14];
    } else {
        rect.origin.y = CGRectGetMaxY(rect)+16;
        rect.size.height = 25;
        _rightPackCardNo.font = [UIFont systemFontOfSize: 24];
    }
    _rightPackCardNo.frame = rect;
    [self addSubview:_rightPackCardNo];
    
    _shareCodeLabel = [[UILabel alloc] init];
    _shareCodeLabel.textColor = [UIColor whiteColor];
    _shareCodeLabel.autoresizingMask =  UIViewAutoresizingNone;
    _shareCodeLabel.backgroundColor = [UIColor clearColor];
    _shareCodeLabel.textAlignment = NSTextAlignmentCenter;

    _shareCodeLabel.tag = 1;
    rect = _packInfoScrollView.frame;
    if (isUserInterfaceIdiomPhone) {
        rect.origin.y = CGRectGetMaxY(rect)+ 7 + 15 + 5;
        rect.size.height = 15;
        _shareCodeLabel.font = [UIFont systemFontOfSize: 12];
    } else {
        rect.origin.y = CGRectGetMaxY(rect)+16 + 25+ 16;
        rect.size.height = 25;
        _shareCodeLabel.font = [UIFont systemFontOfSize: 16];
    }
    _shareCodeLabel.frame = rect;
    [self addSubview:_shareCodeLabel];
    
    
    _playPackNavButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playPackNavButton setImage:[UIImage imageNamed:@"play_nav"] forState:UIControlStateNormal];
    [_playPackNavButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_playPackNavButton addTarget:self action:@selector(playPackNavButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    if (isUserInterfaceIdiomPhone) {
        _playPackNavButton.frame = CGRectMake(0,0, 32, 32);
       _playPackNavButton.center = CGPointMake(CGRectGetMidX(_packInfoScrollView.frame), CGRectGetMaxY(_shareCodeLabel.frame) + 25);
    } else {
        _playPackNavButton.frame = CGRectMake(0,0, 48, 48);
        _playPackNavButton.center = CGPointMake(CGRectGetMidX(_packInfoScrollView.frame), CGRectGetMaxY(_shareCodeLabel.frame) + 40);
    }
    [self addSubview:_playPackNavButton];
    
    _backPackNavButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (isUserInterfaceIdiomPhone) {
        _backPackNavButton.frame = CGRectMake(0, 0, 24, 24);
    } else {
        _backPackNavButton.frame = CGRectMake(0, 0, 32, 32);
    }
    _backPackNavButton.center = CGPointMake(CGRectGetMinX(_playPackNavButton.frame) - 50, CGRectGetMidY(_playPackNavButton.frame));
    [_backPackNavButton setImage:[UIImage imageNamed:@"back_nav"] forState:UIControlStateNormal];
    [_backPackNavButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backPackNavButton addTarget:self action:@selector(backPackNavButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_backPackNavButton];
    
    
    
    _forwardPackNavButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (isUserInterfaceIdiomPhone) {
        _forwardPackNavButton.frame = CGRectMake(0, 0, 24, 24);
    } else {
        _forwardPackNavButton.frame = CGRectMake(0, 0, 32, 32);
    }
    _forwardPackNavButton.center = CGPointMake(CGRectGetMaxX(_playPackNavButton.frame) + 50, CGRectGetMidY(_playPackNavButton.frame));
    [_forwardPackNavButton setImage:[UIImage imageNamed:@"forward_nav"] forState:UIControlStateNormal];
    [_forwardPackNavButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_forwardPackNavButton addTarget:self action:@selector(forwardPackNavButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_forwardPackNavButton];

    
    
}

- (void)setCurrentPack:(Pack *)currentPack {
    _currentPack = currentPack;
    
    _isDirtyScrollView = true;
    
    NSArray *packs = [[User defaultUser] packs];
    for (int i = 0; i < [packs count]; i++) {
        Pack *item = packs[i];
        if (item.packID == currentPack.packID) {
            _currentPage = i;
            break;
        }
    }
}


- (UIImageView *) createImageView:(Pack *) pack {
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.autoresizingMask = UIViewAutoresizingNone;
    imageView.layer.opacity = 0.85;
    //        rightPackImageView.layer.shadowOpacity= 0.3;
    //        rightPackImageView.layer.shadowColor = [UIColor greenColor].CGColor;
    ////        rightPackImageView.layer.shadowOffset = CGSizeMake(0.f, 12.0f);
    //        rightPackImageView.layer.shadowRadius = 20;
    imageView.layer.masksToBounds = YES;
    imageView.backgroundColor = [UIColor clearColor];
    
    
    if ([Common isPlaceholderFilePathOrDirectory:pack.coverImageURL]) {
        imageView.image = [UIImage imageNamed:@"default_pack_cover_image_transparent"];
    } else {
        NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[pack.coverImageURL lastPathComponent]];
        imageView.image = [UIImage imageWithContentsOfFile:path];
    }
    
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    return imageView;
    
}

static NSInteger previousPage = -1;

/**
 *  We don't use this method, since it's called mutiple times
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
}

/**
 *  Only be called once and only when setContentOffset:animated: and scrollRectToVisible:animated:
 */
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
    if (_isUsingBackForwardNavButton == false) {
        
        return;
    } else {
        _isUsingBackForwardNavButton = false;
    }
    
    int page = scrollView.contentOffset.x / scrollView.frame.size.width;
    if (previousPage != page) {
        previousPage = page;
        
        self.currentPack = [[[User defaultUser] packs] objectAtIndex:page];
        
        [self refreshWithPage:(page)];
        
        if (self.delegate) {
            [self.delegate packInfoView:self didScrollToPack:_currentPack];
        }
        
    }
    
}

/**
 *  Only called when  scrolling movement
 *  scrollViewDidEndDecelerating won't be called for scrollRectToVisible or setContentOffset
 */
- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    int page = scrollView.contentOffset.x / scrollView.frame.size.width;
    if (previousPage != page) {
        previousPage = page;
        
        self.currentPack = [[[User defaultUser] packs] objectAtIndex:page];
        
        
        [self refreshWithPage:(page)];
        
        if (self.delegate) {
            [self.delegate packInfoView:self didScrollToPack:_currentPack];
        }
        
    }
    
}



- (void) refreshWithRebuildScrollView:(BOOL)isRebuildScrollView {
    
    _isDirtyScrollView = isRebuildScrollView;
    
    [self refreshWithPage:_currentPage];
}


/**
 *  refresh/update UIs
 */
- (void) refreshWithPage:(int)page {
    
    if (_currentPack != nil) {
        [_rightPackCardNo setText:[NSString stringWithFormat:@"%@: %ld",NSLocalizedString(@"Title_Total_Number_Card",@""),[_currentPack cards].count]];
        if ((self.currentPack.shareLink.length >0) && [Common isOwner:_currentPack]) {
            _shareCodeLabel.hidden = NO;
            _shareCodeLabel.text = [NSString stringWithFormat:@"%@:  %@",NSLocalizedString(@"Title_Share_Code",@""),[self.currentPack.shareLink lastPathComponent]];
        } else {
            _shareCodeLabel.hidden = YES;
        }
    }
    
    
    if (page <= 0) {
        _backPackNavButton.enabled = NO;
    } else {
        _backPackNavButton.enabled = YES;
    }
    
    if (page >= [[[User defaultUser] packs] count] - 1) {
        _forwardPackNavButton.enabled = NO;
    } else {
        _forwardPackNavButton.enabled = YES;
    }
    
    
    if (_isDirtyScrollView) {
        
        _isDirtyScrollView = false;
        
        NSArray *subViews = _packInfoScrollView.subviews;
        for (UIView *item in subViews) {
            [item removeFromSuperview];
        }
        int width = CGRectGetWidth(self.frame);
        CGFloat curXLoc = 0;
        NSArray *packs =  [User defaultUser].packs;
        for (int i = 0; i < [packs count]; i++)
        {
            UIImageView *imageView = [self createImageView:packs[i]];
            imageView.frame =CGRectMake(curXLoc, 0, width, width);
            [_packInfoScrollView addSubview:imageView];
            
            curXLoc += CGRectGetWidth(_packInfoScrollView.frame);
        }
        
        [_packInfoScrollView setContentSize:CGSizeMake(([packs count] * CGRectGetWidth(_packInfoScrollView.frame)), CGRectGetHeight(_packInfoScrollView.frame))];
    }
    
    
}

/**
 *  Also set current page
 */
- (void) scrollTo:(Pack *) pack WithRebuildScrollView:(BOOL) isRebuildScrollView {
    
    if (pack == nil) {
        return;
    }
    
    self.currentPack = pack;
    
    if (isRebuildScrollView) {
        _isDirtyScrollView = true;
    }

    [self scrollToPage:_currentPage];
    
}

/**
 *  Core
 */
- (void) scrollToPage:(int) page {
    
    self.currentPack = [[[User defaultUser] packs] objectAtIndex:page];
    
    [[NSUserDefaults standardUserDefaults] setInteger:_currentPack.packID forKey:@"lastCreatedPackID"];
    
    [self refreshWithPage:page];
    
    CGRect frame = _packInfoScrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [_packInfoScrollView scrollRectToVisible:frame animated:YES];
    
    
    
}


- (void) backPackNavButtonClicked {
    
    if (_currentPage == 0) {
        return;
    }
    
    self.currentPack = [[[User defaultUser] packs] objectAtIndex:_currentPage - 1];
    
     _isUsingBackForwardNavButton = true;
    [self scrollToPage:_currentPage];
   
    
    
    
    
}

- (void) forwardPackNavButtonClicked {
    
    if (_currentPage == [[[User defaultUser] packs] count] - 1) {
        return;
    }
    
    self.currentPack = [[[User defaultUser] packs] objectAtIndex:_currentPage + 1];
    
    _isUsingBackForwardNavButton = true;
    [self scrollToPage:_currentPage];
    
    
    
}


- (void) playPackNavButtonClicked {
    
    if (self.delegate) {
        [self.delegate playButtonClickedOnPackInfoView];
    }
    
}



@end
