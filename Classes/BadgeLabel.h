//
//  BadgeLabel.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum BadgeLabelStyle {
    BadgeLabelStyleAppIcon, // red background, white border, gloss and shadow
    BadgeLabelStyleMail     // gray background, minWidth
} BadgeLabelStyle;

@interface BadgeLabel : UILabel

@property (nonatomic) BOOL hasBorder;
@property (nonatomic) BOOL hasShadow;
@property (nonatomic) BOOL hasGloss;
@property (nonatomic) CGFloat minWidth;

- (void)setStyle:(BadgeLabelStyle)style;

@end
