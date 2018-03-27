//
//  EmoticonView.m
//  FFC
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "EmoticonView.h"

#define EMOTICON_VIEW_DEFAULT_WIDTH 40  
#define EMOTICON_VIEW_DEFAULT_HEIGHT 60

@implementation EmoticonView


- (id)initWithEmoticon:(Emoticon *)emoticon atPage:(int) page{
    
    int width;
    if (page == 0) {
        if ([emoticon.code.lowercaseString isEqualToString:K_Space_Bar.lowercaseString] || [emoticon.code.lowercaseString isEqualToString:K_Line_Break.lowercaseString] ||
            [emoticon.code.lowercaseString isEqualToString:K_Delete.lowercaseString]) {
            width = EMOTICON_VIEW_DEFAULT_WIDTH * 2 + 10;
        } else {
            width = EMOTICON_VIEW_DEFAULT_WIDTH;
        }
    } else {
        width = EMOTICON_VIEW_DEFAULT_WIDTH;
    }
    
    if (self = [super initWithFrame:CGRectMake(0, 0, width, EMOTICON_VIEW_DEFAULT_HEIGHT)]) {
        //_emoticon = [emoticon retain];
        _emoticon = emoticon;
    
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 4, width - 4*2, EMOTICON_VIEW_DEFAULT_HEIGHT - 4*2)];
        
        if (isUserInterfaceIdiomPhone) {
             _titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        } else {
             _titleLabel.font = [UIFont boldSystemFontOfSize:28.0];
        }
        _titleLabel.text = emoticon.title;
        
        
        
        if ([self isPureNumberOrSpaceBar:_titleLabel.text]) {
            _titleLabel.backgroundColor = [UIColor colorWithRed:134.0/255 green:135.0/255 blue:139.0/255 alpha:1];
            
        } else {
            _titleLabel.backgroundColor = [UIColor colorWithRed:194.0/255 green:195.0/255 blue:199.0/255 alpha:1];
        }
        
        
        _titleLabel.clipsToBounds = YES;
        _titleLabel.layer.cornerRadius = 6;
        _titleLabel.layer.masksToBounds = YES;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_titleLabel];
    }
    return self;
}

- (BOOL) isPureNumberOrSpaceBar:(NSString *)string {
    
    if ([string.lowercaseString isEqualToString:K_Space_Bar.lowercaseString]) {
        return YES;
    }
    
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([string rangeOfCharacterFromSet:notDigits].location == NSNotFound)
    {
        // newString consists only of the digits 0 through 9
        return YES;
    } else {
        return NO;
    }
}


@end
