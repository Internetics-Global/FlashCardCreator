//
//  EmoticonGridView.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "EmoticonGridView.h"
#import "Emoticon.h"
#import "EmoticonView.h"
#import "Common.h"

#define DEFAULT_ROW_COUNT_IPHONE 4
#define DEFAULT_ROW_COUNT_IPAD 7
#define DEFAULT_COLUMN_COUNT_IPHONE 10
#define DEFAULT_COLUMN_COUNT_IPAD   12

#define CONTAINER_MARGIN 8

@implementation EmoticonGridView
@synthesize emoticonThumbSize = _emoticonThumbSize;

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

- (CGRect)_frameForEmoticonViewAtIndex:(NSInteger)index{
    CGFloat emoticonViewWidth = _gridContainerView.bounds.size.width / _columnCount;
    CGFloat emoticonViewHeight = (_gridContainerView.bounds.size.height - 20) / _rowCount;
    
    NSInteger row = index / _columnCount;
    NSInteger column = index % _columnCount;
    
    CGFloat startX = column * emoticonViewWidth;
    CGFloat startY = row * emoticonViewHeight;
    
    return CGRectMake(startX, startY, emoticonViewWidth, emoticonViewHeight);
}

- (Emoticon *)_emoticonAtPoint:(CGPoint)point{
    CGFloat emoticonViewWidth = _gridContainerView.bounds.size.width / _columnCount;
    CGFloat emoticonViewHeight = _gridContainerView.bounds.size.height / _rowCount;
    
    NSInteger row = point.y / emoticonViewHeight;
    NSInteger column = point.x / emoticonViewWidth;
    
    NSInteger index =  row * _columnCount + column;
    
    if ([_emoticons count] > index) {
        return [_emoticons objectAtIndex:index];
    }
    
    return nil;
}


- (void)handleTap:(UIGestureRecognizer *)sender{
    if( sender.state ==  UIGestureRecognizerStateEnded)
    {
        CGPoint point = [sender locationInView:self];
        Emoticon *emoticon = [self _emoticonAtPoint:point];
        DDLogInfo(@"单击 : %@",emoticon.title);
        if ([self.delegate respondsToSelector:@selector(emoticonGridView:didSelectEmoticon:)]) {
            [self.delegate emoticonGridView:self didSelectEmoticon:emoticon];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView

- (id)initWithEmoticons:(NSArray *)emoticons{
    int columnCount;
    int rowCount;
    if (isUserInterfaceIdiomPhone) {
        columnCount = DEFAULT_COLUMN_COUNT_IPHONE;
        rowCount = DEFAULT_ROW_COUNT_IPHONE;
    } else {
        columnCount = DEFAULT_COLUMN_COUNT_IPAD;
        rowCount = DEFAULT_ROW_COUNT_IPAD;
    }
    return [self initWithEmoticons:emoticons rowCount:rowCount columnCount:columnCount];
}


- (id)initWithEmoticons:(NSArray *)emoticons rowCount:(NSInteger)rowCount columnCount:(NSInteger)columnCount{
    
    int screenWidth = [Common getScreenWidthInLandscape];
    int height = 0;
    if (isUserInterfaceIdiomPhone) {
        height = 162;
    } else {
        height =350;
    }
    
    if (self = [super initWithFrame:CGRectMake(0, 0, screenWidth, height)]) {
        _rowCount = rowCount;
        _columnCount = columnCount;
        
        //_emoticons = [emoticons retain];
        _emoticons = emoticons;
        _emoticonViews = [[NSMutableArray alloc] initWithCapacity:[emoticons count]];
        
        _gridContainerView = [[UIView alloc] initWithFrame:CGRectMake(8, 4, screenWidth - 8, height)];
        _gridContainerView.backgroundColor = [UIColor clearColor];
        [self addSubview:_gridContainerView];
        
        for (Emoticon *emoticon in _emoticons) {
            EmoticonView *emoticonView = [[EmoticonView alloc] initWithEmoticon:emoticon];
            [_emoticonViews addObject:emoticonView];
            [_gridContainerView addSubview:emoticonView];
            //[emoticonView release];
        }
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [_gridContainerView addGestureRecognizer:_tapGestureRecognizer];
        
    }
    return self;
}


- (void)layoutSubviews{
    for (int i = 0; i < [_emoticonViews count]; i ++) {
        UIView *emoticonView = [_emoticonViews objectAtIndex:i];
        emoticonView.frame = [self _frameForEmoticonViewAtIndex:i];
        
        CGRect emoticonViewFrame = emoticonView.frame;
        emoticonViewFrame.origin.x = floorf(emoticonViewFrame.origin.x);
        if (isUserInterfaceIdiomPhone) {
            emoticonViewFrame.origin.y = floorf(emoticonViewFrame.origin.y) + 20;  // ccaa need to get to know why it's 20    
        } else {
            emoticonViewFrame.origin.y = floorf(emoticonViewFrame.origin.y) + 10;
        }
        
        emoticonView.frame = emoticonViewFrame;
    }
}

@end
