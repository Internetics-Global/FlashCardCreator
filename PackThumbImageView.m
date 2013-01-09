//
//  PackThumbImageView.m
//  PackList
//
//  Created by Wang Bourne on 5/01/13.
//  Copyright (c) 2013 temp. All rights reserved.
//

#import "PackThumbImageView.h"

@implementation PackThumbImageView

@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if ([touch tapCount] == 1) {
        [self.delegate ClickBegin:self.tag];
    }
    
}


@end
