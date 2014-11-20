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
@property (nonatomic, strong) AMPopTip *popTipSegment; //on Segment
@property (nonatomic, strong) AMPopTip *popTipNavigationbarLeft;  //on Top Navigationbar Left
@property (nonatomic, strong) AMPopTip *popTipNavigationbarRight; //on Top Navigationbar Right
@property (nonatomic, strong) AMPopTip *popTipToolbarBottomRight; //on Bottom Toolbar Right
@property (nonatomic, strong) AMPopTip *popTipCreateNewCard;  //on create card button
@property (nonatomic, strong) AMPopTip *popTipMain;  //on main textView in the card

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
        _popTipCreateNewCard.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:YES];
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
        _popTipLogo.popoverColor = [UIColor colorWithRed:0.95 green:0.65 blue:0.21 alpha:1];
        _popTipLogo.shouldDismissOnTap = YES;
        _popTipLogo.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:NO];
        };
    }
    [_popTipLogo showText:@"Edit logo image" direction:AMPopTipDirectionDown maxWidth:200 inView:view fromFrame:frame duration:0];
    
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
        _popTipImage.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:NO];
        };
    }
    [_popTipImage showText:@"Click to select an image/video from library, or insert a YouTube video linkage" direction:AMPopTipDirectionDown maxWidth:180 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForToolbarBottomRightInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipToolbarBottomRight isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipToolbarBottomRight == nil) {
        _popTipToolbarBottomRight = [AMPopTip popTip];
        _popTipToolbarBottomRight.popoverColor = [UIColor colorWithRed:0.31 green:0.57 blue:0.87 alpha:1];
        _popTipToolbarBottomRight.shouldDismissOnTap = YES;
        _popTipToolbarBottomRight.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:NO];
        };
    }
    [_popTipToolbarBottomRight showText:@"Toolbar to change template, background image and record sound" direction:AMPopTipDirectionUp maxWidth:150 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForMainInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipMain isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipMain == nil) {
        _popTipMain = [AMPopTip popTip];
        _popTipMain.popoverColor = [UIColor colorWithRed:0.73 green:0.91 blue:0.55 alpha:1];
        _popTipMain.shouldDismissOnTap = YES;
        _popTipMain.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:NO];
        };
    }
    [_popTipMain showText:@"Click to select an image/video from library, or insert a YouTube video linkage" direction:AMPopTipDirectionDown maxWidth:200 inView:view fromFrame:frame duration:0];
    
}


//only for iPad
- (void) showTipForNavigationBarRightInView_iPad:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipNavigationbarRight isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipNavigationbarRight == nil) {
        _popTipNavigationbarRight = [AMPopTip popTip];
        _popTipNavigationbarRight.popoverColor = [UIColor colorWithRed:0.31 green:0.57 blue:0.87 alpha:1];
        _popTipNavigationbarRight.shouldDismissOnTap = YES;
        _popTipNavigationbarRight.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:NO];
        };
    }
    [_popTipNavigationbarRight showText:@"Toolbar to play, share packs and change the colour palette of your cards" direction:AMPopTipDirectionDown maxWidth:200 inView:view fromFrame:frame duration:0];
    
}

//only for iPhone
- (void) showTipForNavigationBarRightInView_iPhone:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipNavigationbarRight isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipNavigationbarRight == nil) {
        _popTipNavigationbarRight = [AMPopTip popTip];
        _popTipNavigationbarRight.popoverColor = [UIColor colorWithRed:0.31 green:0.57 blue:0.87 alpha:1];
        _popTipNavigationbarRight.shouldDismissOnTap = YES;
        _popTipNavigationbarRight.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:YES];
        };
    }
    [_popTipNavigationbarRight showText:@"Toolbar to play and share packs" direction:AMPopTipDirectionDown maxWidth:100 inView:view fromFrame:frame duration:0];
    
}


- (void) showTipForNavigationBarLeftInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipNavigationbarLeft isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipNavigationbarLeft == nil) {
        _popTipNavigationbarLeft = [AMPopTip popTip];
        _popTipNavigationbarLeft.popoverColor = [UIColor colorWithRed:0.31 green:0.57 blue:0.87 alpha:1];
        _popTipNavigationbarLeft.shouldDismissOnTap = YES;
        _popTipNavigationbarLeft.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:YES];
        };
    }
    [_popTipNavigationbarLeft showText:@"Toolbar to select, edit and create packs" direction:AMPopTipDirectionDown maxWidth:100 inView:view fromFrame:frame duration:0];
    
}

- (void) showTipForSegmentInView:(UIView *)view fromFrame:(CGRect) frame {
    
    if ([_popTipSegment isVisible]) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_popTipSegment == nil) {
        _popTipSegment = [AMPopTip popTip];
        _popTipSegment.popoverColor = [UIColor colorWithRed:0.71 green:0.57 blue:0.87 alpha:1];
        _popTipSegment.shouldDismissOnTap = YES;
        _popTipSegment.dismissHandler = ^() {
            [weakSelf setTootipActiveFlag:NO];
        };
    }
    [_popTipSegment showText:@"Switch to question/answer part of a card" direction:AMPopTipDirectionUp maxWidth:200 inView:view fromFrame:frame duration:0];
    
}


- (void) setTootipActiveFlag: (BOOL) isOnMasterView {
    
    if (isOnMasterView) {
        
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
        
    } else {
        
        if (isUserInterfaceIdiomPhone) {
            
            if ([self isDetailTipVisible_iPhone]) {
                
            } else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES  forKey:K_Tooltip_Detail_Not_Allow];
                [defaults synchronize];
            }
        } else {
            
            if ([self isDetailTipVisible_iPad]) {
                
            } else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES  forKey:K_Tooltip_Detail_Not_Allow];
                [defaults synchronize];
            }
            
        }
        
    }

}

- (BOOL) isMasterTipVisible {
    
    if (isUserInterfaceIdiomPhone) {
        return [self isMasterTipVisible_iPhone];
    } else {
        return [self isMasterTipVisible_iPad];
    }
    
}

- (BOOL) isDetailTipVisible{
    
    if (isUserInterfaceIdiomPhone) {
        return [self isDetailTipVisible_iPhone];
    } else {
        return [self isDetailTipVisible_iPad];
    }
    
}


- (BOOL) isMasterTipVisible_iPhone {
    
    if ((_popTipNavigationbarLeft.isVisible == YES) ||
        (_popTipCreateNewCard.isVisible == YES) ||
        (_popTipNavigationbarRight.isVisible == YES)) {
        return YES;
    } else {
        return NO;
    }
    
    
}

- (BOOL) isMasterTipVisible_iPad {
    
    if ((_popTipNavigationbarLeft.isVisible == YES) ||
        (_popTipCreateNewCard.isVisible == YES)) {
        return YES;
    } else {
        return NO;
    }
    
}


- (BOOL) isDetailTipVisible_iPhone {
    
    if ((_popTipImage.isVisible == YES) ||
        (_popTipSegment.isVisible == YES) ||
        (_popTipToolbarBottomRight.isVisible == YES)||
        (_popTipMain.isVisible == YES) ||
        (_popTipImage.isVisible == YES)) {
        return YES;
    } else {
        return NO;
    }
    
}

- (BOOL) isDetailTipVisible_iPad {
    if ((_popTipImage.isVisible == YES) ||
        (_popTipSegment.isVisible == YES) ||
        (_popTipToolbarBottomRight.isVisible == YES)||
        (_popTipMain.isVisible == YES) ||
        (_popTipLogo.isVisible == YES) ||
        (_popTipNavigationbarRight.isVisible == YES)) {
        return YES;
    } else {
        return NO;
    }
    
}

- (void) hideMasterTip {
    if (isUserInterfaceIdiomPhone) {
        [_popTipNavigationbarLeft hide];
        [_popTipNavigationbarRight hide];
        [_popTipCreateNewCard hide];
    } else {
        
        [_popTipNavigationbarLeft hide];
        [_popTipCreateNewCard hide];
        
    }
    
}

- (void)hideDetailTip {
    
    if (isUserInterfaceIdiomPhone) {
        
        [_popTipImage hide];
        [_popTipMain hide];
        [_popTipLogo hide];
        [_popTipSegment hide];
        [_popTipToolbarBottomRight hide];
        
    } else {
        
        [_popTipNavigationbarRight hide];
        [_popTipImage hide];
        [_popTipMain hide];
        [_popTipSegment hide];
        [_popTipLogo hide];
        [_popTipToolbarBottomRight hide];
        
    }
    
}

@end
