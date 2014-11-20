//
//  TipHelper_iPad.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 20/11/2014.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPopTip.h"

@interface TipHelper : NSObject

+ (instancetype)defaultHelper;


- (void) showTipForLogoInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForMainInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForImageInView:(UIView *)view fromFrame:(CGRect) frame;

- (void) showTipForToolbarBottomRightInView:(UIView *)view fromFrame:(CGRect) frame;

- (void) showTipForNavigationBarRightInView_iPad:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForNavigationBarRightInView_iPhone:(UIView *)view fromFrame:(CGRect) frame;

- (void) showTipForSegmentInView:(UIView *)view fromFrame:(CGRect) frame;

- (void) showTipForNavigationBarLeftInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForCreateCardInView:(UIView *)view fromFrame:(CGRect) frame;


- (BOOL) isMasterTipVisible;
- (BOOL) isDetailTipVisible;

- (void) hideMasterTip;
- (void)hideDetailTip;

@end
