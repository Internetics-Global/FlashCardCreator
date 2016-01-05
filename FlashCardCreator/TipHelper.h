//
//  TipHelper_iPad.h
//  FFC
//
//  Created by Bourne Wang on 20/11/2014.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPopTip.h"

typedef NS_ENUM(NSInteger, Where_Tooltip_Type) {
    Where_Tooltip_Master      = -1,
    Where_Tooltip_Detail       = 1,
    Where_Tooltip_FlashCard   = 2,
    Where_Tooltip_Unkown    = 3,
};

@interface TipHelper : NSObject

+ (instancetype)defaultHelper;


- (void) showTipForLogoInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForLinkButtonInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForImageInView:(UIView *)view fromFrame:(CGRect) frame;

- (void) showTipForToolbarBottomRightChangeTemplateInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForToolbarBottomRightChangeBackgroundInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForToolbarBottomRightRecordSoundInView:(UIView *)view fromFrame:(CGRect) frame;

- (void) showTipForSegmentQuestionInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForSegmentAnswerInView:(UIView *)view fromFrame:(CGRect) frame;

- (void) showTipForLeftNaviBarItemOpenPackInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForLeftNaviBarItemEditPackInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForLeftNaviBarItemCreatePackInView:(UIView *)view fromFrame:(CGRect) frame;

- (void) showTipForRightNaviBarItemPlayInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForRightNaviBarItemShareInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForRightNaviBarItemSettingInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForRightNaviBarItemHelpInView:(UIView *)view fromFrame:(CGRect) frame;
- (void) showTipForRightNaviBarItemPaletteInView:(UIView *)view fromFrame:(CGRect) frame;



- (void) showTipForCreateCardInView:(UIView *)view fromFrame:(CGRect) frame;


- (BOOL) isMasterTipVisible;

- (void) hideMasterTip;
- (void)hideFlashCardTip;

- (void) hideEverything;

- (BOOL) isAllInvisible;

@end
