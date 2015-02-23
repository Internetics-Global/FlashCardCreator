//
//  EmoticonView.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "EmoticonView.h"

#define EMOTICON_VIEW_DEFAULT_WIDTH 40  //不是最终值
#define EMOTICON_VIEW_DEFAULT_HEIGHT 60  //不是最终值

@implementation EmoticonView


- (id)initWithEmoticon:(Emoticon *)emoticon atPage:(int) page{
    
    int width;
    if (page == 0) {
        if ([emoticon.code isEqualToString:@" "]) {
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
    
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 14, width - 4*2, EMOTICON_VIEW_DEFAULT_HEIGHT - 14*2)];
        
        if (isUserInterfaceIdiomPhone) {
             _titleLabel.font = [UIFont systemFontOfSize:18.0];
        } else {
             _titleLabel.font = [UIFont systemFontOfSize:24.0];
        }
        _titleLabel.text = emoticon.title;
        
        
        
        if ([self isPureNumberOrEmpty:_titleLabel.text]) {
            _titleLabel.backgroundColor = [UIColor colorWithRed:134.0/255 green:135.0/255 blue:139.0/255 alpha:1];
            
        } else {
            _titleLabel.backgroundColor = [UIColor colorWithRed:194.0/255 green:195.0/255 blue:199.0/255 alpha:1];
        }
        
        //Rename
        if ([self isMadeOfSpace:_titleLabel.text]) {
          _titleLabel.text = @"Space bar";
        }
        
        _titleLabel.clipsToBounds = YES;
        _titleLabel.layer.cornerRadius = 6;
        _titleLabel.layer.masksToBounds = YES;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:_titleLabel];
    }
    return self;
}

- (BOOL) isPureNumberOrEmpty:(NSString *)string {
    
    if ([self isMadeOfSpace:string]) {
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

- (BOOL) isMadeOfSpace:(NSString *) string {
    
    if (string.length == 1 && ([string isEqualToString:@" "]))
    {
        // String contains only whitespace.
        return YES;
    } else {
        return NO;
    }
    
}

@end
