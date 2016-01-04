//
//  UITextField+AutoResizeFont.h
//  FlashCardCreator
//
//  Created by Internetics on 4/01/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (AutoResizeFont)

/**
 *  We designed this logic because iOS does not support this(it's strange but it's true)
 *  Moreover, even iOS has provided setAdjustsFontSizeToFitWidth, but it seems it never works!!!!!
 */
- (void)adjustFontSizeToFit;
- (void)adjustFontSizeToFitVertically:(BOOL) isVertically;

@end
