//
//  TipHelper_iPad.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 20/11/2014.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "TipHelper.h"

@interface TipHelper ()

@property (nonatomic, strong) AMPopTip *popTipLogo;  //on logo
@property (nonatomic, strong) AMPopTip *popTipImage; //on Image

@property (nonatomic, strong) AMPopTip *popTipSegmentQuestion; //on Segment
@property (nonatomic, strong) AMPopTip *popTipSegmentAnswer; //on Segment

@property (nonatomic, strong) AMPopTip *popTipCreateNewCard;  //on create card button
@property (nonatomic, strong) AMPopTip *popTipLinkButton;  //on main textView in the card

@property (nonatomic, strong) AMPopTip *popTipToolbarBottomRightChangeTemplate; //on Bottom Toolbar Right
@property (nonatomic, strong) AMPopTip *popTipToolbarBottomRightChangeBackground; //on Bottom Toolbar Right
@property (nonatomic, strong) AMPopTip *popTipToolbarBottomRightRecordSound; //on Bottom Toolbar Right

@property (nonatomic, strong) AMPopTip *popTipLeftNaviBarItemOpenPack;  //on Top Navigationbar Left
@property (nonatomic, strong) AMPopTip *popTipLeftNaviBarItemCreatePack;  //on Top Navigationbar Left
@property (nonatomic, strong) AMPopTip *popTipLeftNaviBarItemEditPack;  //on Top Navigationbar Left


@property (nonatomic, strong) AMPopTip *popTipRightNaviBarItemPalette; //on Top Navigationbar Right
@property (nonatomic, strong) AMPopTip *popTipRightNaviBarItemHelp; //on Top Navigationbar Right
@property (nonatomic, strong) AMPopTip *popTipRightNaviBarItemSetting; //on Top Navigationbar Right
@property (nonatomic, strong) AMPopTip *popTipRightNaviBarItemShare; //on Top Navigationbar Right
@property (nonatomic, strong) AMPopTip *popTipRightNaviBarItemPlay; //on Top Navigationbar Right

@end

@implementation TipHelper

+ (instancetype)defaultHelper {
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        
    });
    
    return sharedInstance;
}

- (void) showTipForCreateCardInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipCreateNewCard isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipCreateNewCard == nil) {
        _popTipCreateNewCard = [AMPopTip popTip];
        _popTipCreateNewCard.popoverColor = [UIColor colorWithRed:0.95 green:0.65 blue:0.21 alpha:1];
        _popTipCreateNewCard.shouldDismissOnTap = YES;
        _popTipCreateNewCard.shouldDismissOnTapOutside = NO;
        _popTipCreateNewCard.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_Master];
        };
    }
    [_popTipCreateNewCard showText:@"Create a new card" direction:AMPopTipDirectionUp maxWidth:200 inView:view fromFrame:frame duration:0];
    
}


- (void) showTipForLogoInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipLogo isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipLogo == nil) {
        _popTipLogo = [AMPopTip popTip];
        _popTipLogo.arrowSize = CGSizeMake(8, 20);
        _popTipLogo.popoverColor = [UIColor colorWithRed:0.95 green:0.65 blue:0.21 alpha:1];
        _popTipLogo.shouldDismissOnTap = YES;
        _popTipLogo.shouldDismissOnTapOutside = NO;
        _popTipLogo.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_FlashCard];
        };
    }
    [_popTipLogo showText:@"Edit logo" direction:AMPopTipDirectionDown maxWidth:200 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForImageInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipImage isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipImage == nil) {
        _popTipImage = [AMPopTip popTip];
        _popTipImage.popoverColor = [UIColor colorWithRed:0.95 green:0.65 blue:0.21 alpha:1];
        _popTipImage.shouldDismissOnTap = YES;
        _popTipImage.shouldDismissOnTapOutside = NO;
        _popTipImage.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_FlashCard];
        };
    }
    [_popTipImage showText:@"Click to select an image/video from library, or insert a YouTube video linkage" direction:AMPopTipDirectionDown maxWidth:180 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForToolbarBottomRightChangeTemplateInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipToolbarBottomRightChangeTemplate isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipToolbarBottomRightChangeTemplate == nil) {
        _popTipToolbarBottomRightChangeTemplate = [AMPopTip popTip];
        _popTipToolbarBottomRightChangeTemplate.arrowSize = CGSizeMake(8, 80);
        _popTipToolbarBottomRightChangeTemplate.popoverColor = [UIColor colorWithRed:0.31 green:0.57 blue:0.87 alpha:1];
        _popTipToolbarBottomRightChangeTemplate.shouldDismissOnTap = YES;
        _popTipToolbarBottomRightChangeTemplate.shouldDismissOnTapOutside = NO;
        _popTipToolbarBottomRightChangeTemplate.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_FlashCard];
        };
    }
    [_popTipToolbarBottomRightChangeTemplate showText:@"Change template" direction:AMPopTipDirectionUp maxWidth:150 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForToolbarBottomRightChangeBackgroundInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipToolbarBottomRightChangeBackground isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipToolbarBottomRightChangeBackground == nil) {
        _popTipToolbarBottomRightChangeBackground = [AMPopTip popTip];
        _popTipToolbarBottomRightChangeBackground.arrowSize = CGSizeMake(8, 45);
        _popTipToolbarBottomRightChangeBackground.popoverColor = [UIColor colorWithRed:0 green:0.3 blue:0.87 alpha:1];
        _popTipToolbarBottomRightChangeBackground.shouldDismissOnTap = YES;
        _popTipToolbarBottomRightChangeBackground.shouldDismissOnTapOutside = NO;
        _popTipToolbarBottomRightChangeBackground.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_FlashCard];
        };
    }
    [_popTipToolbarBottomRightChangeBackground showText:@"Change background" direction:AMPopTipDirectionUp maxWidth:150 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForToolbarBottomRightRecordSoundInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipToolbarBottomRightRecordSound isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipToolbarBottomRightRecordSound == nil) {
        _popTipToolbarBottomRightRecordSound = [AMPopTip popTip];
        _popTipToolbarBottomRightRecordSound.arrowSize = CGSizeMake(8, 10);
        _popTipToolbarBottomRightRecordSound.popoverColor = [UIColor colorWithRed:1 green:0.57 blue:0.87 alpha:1];
        _popTipToolbarBottomRightRecordSound.shouldDismissOnTap = YES;
        _popTipToolbarBottomRightRecordSound.shouldDismissOnTapOutside = NO;
        _popTipToolbarBottomRightRecordSound.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_FlashCard];
        };
    }
    [_popTipToolbarBottomRightRecordSound showText:@"Record sound or voice" direction:AMPopTipDirectionUp maxWidth:150 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForLinkButtonInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipLinkButton isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipLinkButton == nil) {
        _popTipLinkButton = [AMPopTip popTip];
        _popTipLinkButton.arrowSize = CGSizeMake(100, 8);
        _popTipLinkButton.popoverColor = [UIColor colorWithRed:0.73 green:0.91 blue:0.55 alpha:1];
        _popTipLinkButton.shouldDismissOnTap = YES;
        _popTipLinkButton.shouldDismissOnTapOutside = NO;
        _popTipLinkButton.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_FlashCard];
        };
    }
    [_popTipLinkButton showText:@"Add a link" direction:AMPopTipDirectionLeft maxWidth:200 inView:view fromFrame:frame duration:0];
    
}




- (void) showTipForLeftNaviBarItemOpenPackInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipLeftNaviBarItemOpenPack isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipLeftNaviBarItemOpenPack == nil) {
        _popTipLeftNaviBarItemOpenPack = [AMPopTip popTip];
        _popTipLeftNaviBarItemOpenPack.popoverColor = [UIColor colorWithRed:1 green:0.5 blue:0.17 alpha:1];
        _popTipLeftNaviBarItemOpenPack.shouldDismissOnTap = YES;
        _popTipLeftNaviBarItemOpenPack.shouldDismissOnTapOutside = NO;
        _popTipLeftNaviBarItemOpenPack.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_Master];
        };
    }
    [_popTipLeftNaviBarItemOpenPack showText:@"Open pack viewer" direction:AMPopTipDirectionDown maxWidth:150 inView:view fromFrame:frame duration:0];
    
}


- (void) showTipForLeftNaviBarItemCreatePackInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipLeftNaviBarItemCreatePack isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipLeftNaviBarItemCreatePack == nil) {
        _popTipLeftNaviBarItemCreatePack = [AMPopTip popTip];
        _popTipLeftNaviBarItemCreatePack.arrowSize = CGSizeMake(8, 90);
        _popTipLeftNaviBarItemCreatePack.popoverColor = [UIColor colorWithRed:0.5 green:0 blue:0.5 alpha:1];
        _popTipLeftNaviBarItemCreatePack.shouldDismissOnTap = YES;
        _popTipLeftNaviBarItemCreatePack.shouldDismissOnTapOutside = NO;
        _popTipLeftNaviBarItemCreatePack.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_Master];
        };
    }
    [_popTipLeftNaviBarItemCreatePack showText:@"Create a new pack" direction:AMPopTipDirectionDown maxWidth:150 inView:view fromFrame:frame duration:0];
    
}


- (void) showTipForLeftNaviBarItemEditPackInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipLeftNaviBarItemEditPack isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipLeftNaviBarItemEditPack == nil) {
        _popTipLeftNaviBarItemEditPack = [AMPopTip popTip];
        _popTipLeftNaviBarItemEditPack.arrowSize = CGSizeMake(8, 50);
        _popTipLeftNaviBarItemEditPack.popoverColor = [UIColor colorWithRed:0.31 green:0.57 blue:0.87 alpha:1];
        _popTipLeftNaviBarItemEditPack.shouldDismissOnTap = YES;
        _popTipLeftNaviBarItemEditPack.shouldDismissOnTapOutside = NO;
        _popTipLeftNaviBarItemEditPack.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_Master];
        };
    }
    [_popTipLeftNaviBarItemEditPack showText:@"Edit a pack" direction:AMPopTipDirectionDown maxWidth:150 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForSegmentQuestionInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipSegmentQuestion isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipSegmentQuestion == nil) {
        _popTipSegmentQuestion = [AMPopTip popTip];
        _popTipSegmentQuestion.arrowSize = CGSizeMake(8, 80);
        _popTipSegmentQuestion.popoverColor = [UIColor colorWithRed:0.21 green:0.57 blue:0.87 alpha:1];
        _popTipSegmentQuestion.shouldDismissOnTap = YES;
        _popTipSegmentQuestion.shouldDismissOnTapOutside = NO;
        _popTipSegmentQuestion.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_FlashCard];
        };
    }
    [_popTipSegmentQuestion showText:@"Click here to see the question side of the card" direction:AMPopTipDirectionUp maxWidth:150 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForSegmentAnswerInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipSegmentAnswer isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipSegmentAnswer == nil) {
        _popTipSegmentAnswer = [AMPopTip popTip];
        _popTipSegmentAnswer.arrowSize = CGSizeMake(8, 10);
        _popTipSegmentAnswer.popoverColor = [UIColor colorWithRed:0.71 green:0.57 blue:0.87 alpha:1];
        _popTipSegmentAnswer.shouldDismissOnTap = YES;
        _popTipSegmentAnswer.shouldDismissOnTapOutside = NO;
        _popTipSegmentAnswer.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_FlashCard];
        };
    }
    [_popTipSegmentAnswer showText:@"Click here to see the answer side of the card" direction:AMPopTipDirectionUp maxWidth:150 inView:view fromFrame:frame duration:0];
    
}


- (void) setTootipActiveFlag: (Where_Tooltip_Type) whereTooltip {
    
    if (whereTooltip == Where_Tooltip_Master) {
        
        if (isUserInterfaceIdiomPhone) {
            
            if ([self isMasterTipVisible_iPhone]) {
            } else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES  forKey:K_Tooltip_Master_Not_Allow];
                [defaults synchronize];
            }
            
        } else {
            
            if ([self isMasterTipVisible_iPad]) {
                
            } else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES  forKey:K_Tooltip_Master_Not_Allow];
                [defaults synchronize];
            }
            
        }
        
    } else if (whereTooltip == Where_Tooltip_FlashCard) {
        
        if (isUserInterfaceIdiomPhone) {
            
            if ([self isFlashCardTipVisible]) {
                
            } else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES  forKey:K_Tooltip_FlashCard_Not_Allow];
                [defaults synchronize];
            }
        } else {
            
            if ([self isFlashCardTipVisible]) {
                
            } else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES  forKey:K_Tooltip_FlashCard_Not_Allow];
                [defaults synchronize];
            }
            
        }
        
    } else {
        
        if (isUserInterfaceIdiomPhone) {
            
            if ([self isFlashCardTipVisible]) {
                
            } else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES  forKey:K_Tooltip_FlashCard_Not_Allow];
                [defaults synchronize];
            }
        } else {
            
            if ([self isFlashCardTipVisible]) {
                
            } else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES  forKey:K_Tooltip_FlashCard_Not_Allow];
                [defaults synchronize];
            }
            
        }
        
    }

}

- (void) showTipForRightNaviBarItemPaletteInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipRightNaviBarItemPalette isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipRightNaviBarItemPalette == nil) {
        _popTipRightNaviBarItemPalette = [AMPopTip popTip];
        _popTipRightNaviBarItemPalette.arrowSize = CGSizeMake(8, 10);
        _popTipRightNaviBarItemPalette.popoverColor = [UIColor colorWithRed:1 green:0.5 blue:0.17 alpha:1];
        _popTipRightNaviBarItemPalette.shouldDismissOnTap = YES;
        _popTipRightNaviBarItemPalette.shouldDismissOnTapOutside = NO;
        _popTipRightNaviBarItemPalette.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:Where_Tooltip_Detail];
        };
    }
    [_popTipRightNaviBarItemPalette showText:@"Change the color palette" direction:AMPopTipDirectionDown maxWidth:200 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForRightNaviBarItemHelpInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipRightNaviBarItemHelp isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipRightNaviBarItemHelp == nil) {
        _popTipRightNaviBarItemHelp = [AMPopTip popTip];
        _popTipRightNaviBarItemHelp.arrowSize = CGSizeMake(8, 50);
        _popTipRightNaviBarItemHelp.popoverColor = [UIColor colorWithRed:0 green:0.5 blue:0.17 alpha:1];
        _popTipRightNaviBarItemHelp.shouldDismissOnTap = YES;
        _popTipRightNaviBarItemHelp.shouldDismissOnTapOutside = NO;
        _popTipRightNaviBarItemHelp.dismissHandler = ^() {
            if (isUserInterfaceIdiomPhone) {
                [weakSelf setTootipActiveFlag:Where_Tooltip_Master];
            } else {
                [weakSelf setTootipActiveFlag:Where_Tooltip_Detail];
            }
        };
    }
    [_popTipRightNaviBarItemHelp showText:@"Toggle help tips on and off" direction:AMPopTipDirectionDown maxWidth:200 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForRightNaviBarItemSettingInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipRightNaviBarItemSetting isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipRightNaviBarItemSetting == nil) {
        _popTipRightNaviBarItemSetting = [AMPopTip popTip];
        _popTipRightNaviBarItemSetting.arrowSize = CGSizeMake(8, 90);
        _popTipRightNaviBarItemSetting.popoverColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.17 alpha:1];
        _popTipRightNaviBarItemSetting.shouldDismissOnTap = YES;
        _popTipRightNaviBarItemSetting.shouldDismissOnTapOutside = NO;
        _popTipRightNaviBarItemSetting.dismissHandler = ^() {
            if (isUserInterfaceIdiomPhone) {
                [weakSelf setTootipActiveFlag:Where_Tooltip_Master];
            } else {
                [weakSelf setTootipActiveFlag:Where_Tooltip_Detail];
            }
        };
    }
    [_popTipRightNaviBarItemSetting showText:@"App setting" direction:AMPopTipDirectionDown maxWidth:200 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForRightNaviBarItemShareInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipRightNaviBarItemShare isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipRightNaviBarItemShare == nil) {
        _popTipRightNaviBarItemShare = [AMPopTip popTip];
        if (isUserInterfaceIdiomPhone) {
            _popTipRightNaviBarItemShare.arrowSize = CGSizeMake(8, 130);
        } else {
            _popTipRightNaviBarItemShare.arrowSize = CGSizeMake(8, 200);
        }
        _popTipRightNaviBarItemShare.popoverColor = [UIColor colorWithRed:1 green:0.5 blue:0 alpha:1];
        _popTipRightNaviBarItemShare.shouldDismissOnTap = YES;
        _popTipRightNaviBarItemShare.shouldDismissOnTapOutside = NO;
        _popTipRightNaviBarItemShare.dismissHandler = ^() {
            if (isUserInterfaceIdiomPhone) {
              [weakSelf setTootipActiveFlag:Where_Tooltip_Master];
            } else {
                [weakSelf setTootipActiveFlag:Where_Tooltip_Detail];
            }
            
        };
    }
    [_popTipRightNaviBarItemShare showText:@"Share this pack" direction:AMPopTipDirectionDown maxWidth:200 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForRightNaviBarItemPlayInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipRightNaviBarItemPlay isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipRightNaviBarItemPlay == nil) {
        _popTipRightNaviBarItemPlay = [AMPopTip popTip];
        if (isUserInterfaceIdiomPhone) {
            _popTipRightNaviBarItemPlay.arrowSize = CGSizeMake(8, 170);
        } else {
            _popTipRightNaviBarItemPlay.arrowSize = CGSizeMake(8, 240);
        }
        _popTipRightNaviBarItemPlay.popoverColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.17 alpha:1];
        _popTipRightNaviBarItemPlay.shouldDismissOnTap = YES;
        _popTipRightNaviBarItemPlay.shouldDismissOnTapOutside = NO;
        _popTipRightNaviBarItemPlay.dismissHandler = ^() {
            if (isUserInterfaceIdiomPhone) {
                [weakSelf setTootipActiveFlag:Where_Tooltip_Master];
            } else {
                [weakSelf setTootipActiveFlag:Where_Tooltip_Detail];
            }
        };
    }
    [_popTipRightNaviBarItemPlay showText:@"Play these cards" direction:AMPopTipDirectionDown maxWidth:200 inView:view fromFrame:frame duration:0];
    
}



- (BOOL) isMasterTipVisible {
    
    if (isUserInterfaceIdiomPhone) {
        return [self isMasterTipVisible_iPhone];
    } else {
        return [self isMasterTipVisible_iPad];
    }
    
}



- (BOOL) isMasterTipVisible_iPhone {
    
    if ((_popTipLeftNaviBarItemOpenPack.isVisible == YES) ||
        (_popTipLeftNaviBarItemCreatePack.isVisible == YES) ||
        (_popTipLeftNaviBarItemEditPack.isVisible == YES) ||
        (_popTipCreateNewCard.isVisible == YES) ||
        (_popTipRightNaviBarItemHelp.isVisible == YES)||
        (_popTipRightNaviBarItemSetting.isVisible == YES)||
        (_popTipRightNaviBarItemShare.isVisible == YES)||
        (_popTipRightNaviBarItemPlay.isVisible == YES)) {
        return YES;
    } else {
        return NO;
    }
    
    
}

- (BOOL) isMasterTipVisible_iPad {
    
    if ((_popTipLeftNaviBarItemOpenPack.isVisible == YES) ||
        (_popTipLeftNaviBarItemCreatePack.isVisible == YES) ||
        (_popTipLeftNaviBarItemEditPack.isVisible == YES) ||
        (_popTipCreateNewCard.isVisible == YES)) {
        return YES;
    } else {
        return NO;
    }
    
}


- (BOOL) isFlashCardTipVisible {
    if ((_popTipImage.isVisible == YES) ||
        (_popTipSegmentQuestion.isVisible == YES) ||
        (_popTipSegmentAnswer.isVisible == YES) ||
        (_popTipToolbarBottomRightChangeTemplate.isVisible == YES)||
        (_popTipToolbarBottomRightChangeBackground.isVisible == YES)||
        (_popTipToolbarBottomRightRecordSound.isVisible == YES)||
        (_popTipLinkButton.isVisible == YES) ||
        (_popTipLogo.isVisible == YES)) {
        return YES;
    } else {
        return NO;
    }
    
}

- (BOOL) isDetailTipVisible {
    if ((_popTipRightNaviBarItemPalette.isVisible == YES) ||
        (_popTipRightNaviBarItemHelp.isVisible == YES)||
        (_popTipRightNaviBarItemSetting.isVisible == YES)||
        (_popTipRightNaviBarItemShare.isVisible == YES)||
        (_popTipRightNaviBarItemPlay.isVisible == YES)) {
        return YES;
    } else {
        return NO;
    }
    
}

- (void) hideMasterTip {
    if (isUserInterfaceIdiomPhone) {
        [_popTipLeftNaviBarItemOpenPack hide];
        [_popTipLeftNaviBarItemCreatePack hide];
        [_popTipLeftNaviBarItemEditPack hide];
        [_popTipRightNaviBarItemHelp hide];
        [_popTipRightNaviBarItemSetting hide];
        [_popTipRightNaviBarItemShare hide];
        [_popTipRightNaviBarItemPlay hide];
        [_popTipCreateNewCard hide];
    } else {
        [_popTipLeftNaviBarItemOpenPack hide];
        [_popTipLeftNaviBarItemCreatePack hide];
        [_popTipLeftNaviBarItemEditPack hide];
        [_popTipCreateNewCard hide];
        
    }
    
}



- (void)hideFlashCardTip {
    
    [_popTipImage hide];
    [_popTipLinkButton hide];
    [_popTipSegmentQuestion hide];
    [_popTipSegmentAnswer hide];
    [_popTipLogo hide];
    [_popTipToolbarBottomRightChangeTemplate hide];
    [_popTipToolbarBottomRightChangeBackground hide];
    [_popTipToolbarBottomRightRecordSound hide];
    
}

- (void)hideDetailCardTip {
    
    if (isUserInterfaceIdiomPhone) {
        
    } else {
        
        [_popTipRightNaviBarItemPalette hide];
        [_popTipRightNaviBarItemHelp hide];
        [_popTipRightNaviBarItemSetting hide];
        [_popTipRightNaviBarItemShare hide];
        [_popTipRightNaviBarItemPlay hide];
        
    }
    
}

- (void) hideEverything {
    [self hideMasterTip];
    [self hideDetailCardTip];
    [self hideFlashCardTip];
}

@end
