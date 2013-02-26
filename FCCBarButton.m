//
//  FCCBarButton.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 26/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "FCCBarButton.h"

@implementation FCCBarButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (UIButton*)buttonWithImage:(UIImage*)image target:(id)target action:(SEL)action {
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    [button setBackgroundImage:nil forState:UIControlStateNormal];
    [button setBackgroundImage:nil forState:UIControlStateHighlighted];
    [button setBackgroundImage:nil forState:UIControlStateSelected];
    [button setBackgroundImage:nil forState:UIControlStateDisabled];

    [button sizeToFit];
    CGRect rect = button.frame;
    rect.size.width = rect.size.width +16;
    rect.size.height = rect.size.height + 11;
    button.frame = rect;
    
    [button addTarget:target action:action forControlEvents:UIControlEventTouchDown];
    return button;
}


@end
