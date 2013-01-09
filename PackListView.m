//
//  PackListView.m
//  PackList
//
//  Created by Wang Bourne on 4/01/13.
//  Copyright (c) 2013 temp. All rights reserved.
//

#import "PackListView.h"

#define kPageControlHeight      20
#define kScrollObjHeight        262.0
#define kScrollObjWidth         406.0
#define kScrollObjHorizonMargin	40.0
#define kScrollViewWidth        600.0

@implementation PackListView

@synthesize imageArray = _imageArray;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 446, 262)];
        _scrollView.delegate = self;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.clipsToBounds = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.bounces = NO;
        _scrollView.backgroundColor =[UIColor redColor];
        [self addSubview:_scrollView];
        
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, frame.size.height-kPageControlHeight, frame.size.width, kPageControlHeight)];
        
        [_pageControl addTarget:self action:@selector(pageChanged:) forControlEvents:UIControlEventValueChanged];
        _pageControl.hidesForSinglePage = YES;
        [self addSubview:_pageControl];
    }
    
    return self;
}


#pragma mark -
#pragma mark Data

- (void)removeAllImages
{
	for(UIView * v in [_scrollView subviews])
		[v removeFromSuperview];
}

- (void)setShowPageControl:(BOOL)show {
    _showPageControl = show;
    
    if (show) {
        [self addSubview:_pageControl];
    } else {
        [_pageControl removeFromSuperview];
    }
    
    [self layoutSubviews];
}

#pragma mark -
#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutScrollObjects];
}

- (void)layoutScrollObjects
{
    CGFloat curXLoc = 0;
    for (int index = 0; index < [_imageArray count]; index++)
	{
		PackThumbImageView *imageView = [[PackThumbImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:_imageArray[index]]];
        imageView.delegate = self;
        imageView.userInteractionEnabled = YES;
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.tag = index;
		CGRect rect = imageView.frame;
		rect.size.height = kScrollObjHeight;
		rect.size.width = kScrollObjWidth;
        rect.origin = CGPointMake(curXLoc, 0);
        imageView.frame = rect;
		[_scrollView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        label.text = [NSString stringWithFormat:@"%d", index];
        label.font = [UIFont systemFontOfSize:55];
        label.textColor = [UIColor blackColor];
        label.frame = CGRectMake(0, 0, 40, 40);
        label.center = CGPointMake(rect.origin.x+rect.size.width/2, rect.origin.y+rect.size.height/2);
        label.textAlignment = UITextAlignmentCenter;
        [_scrollView addSubview:label];
        
        curXLoc += (kScrollObjWidth+kScrollObjHorizonMargin);
	}
	
	// set the content size so it can be scrollable
	[_scrollView setContentSize:CGSizeMake(([_imageArray count] * (kScrollObjWidth+kScrollObjHorizonMargin)), kScrollObjHeight)];
    
}

#pragma mark -
#pragma mark hitTest

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *superView = [super hitTest:point withEvent:event];
    if (superView == self)
    {
        return _scrollView;
    }
    
    UIView* fromView = [[UIView alloc] init];
    [fromView convertPoint:point fromView:self];
    
    return superView;
}


#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    NSLog (@"current page is :%d", page);
    
}


#pragma mark -
#pragma mark UITouch Delegate

- (void)ClickBegin:(NSInteger)imageTag {
    NSLog(@"i will do.current image tage is: %d",imageTag);
    [[NSNotificationCenter defaultCenter] postNotificationName:NEW_SELECTED_PACK_NOTIFICATION object:[NSString stringWithFormat:@"%d",imageTag]];
}


@end
