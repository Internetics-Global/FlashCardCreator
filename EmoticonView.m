//
//  EmoticonView.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "EmoticonView.h"


#define EMOTICON_VIEW_DEFAULT_WIDTH 40
#define EMOTICON_VIEW_DEFAULT_HEIGHT 60

#define EMOTICON_IMAGE_WIDTH 32
#define EMOTICON_IMAGE_HEIGHT 32

@implementation EmoticonView


- (id)initWithEmoticon:(Emoticon *)emoticon{
    if (self = [super initWithFrame:CGRectMake(0, 0, EMOTICON_VIEW_DEFAULT_WIDTH, EMOTICON_VIEW_DEFAULT_HEIGHT)]) {
        //_emoticon = [emoticon retain];
        _emoticon = emoticon;
        
        _emoticonView = [[UIImageView alloc] initWithImage:emoticon.image];
        _emoticonView.frame = CGRectMake(0, 0, EMOTICON_IMAGE_WIDTH, EMOTICON_IMAGE_HEIGHT);
        _emoticonView.center = CGPointMake(20, 20);
        _emoticonView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:_emoticonView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, 40, 20)];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont systemFontOfSize:12.0];
        _titleLabel.text = emoticon.title;
        _titleLabel.textAlignment = UITextAlignmentCenter;
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:_titleLabel];
    }
    return self;
}

@end
