//
//  CycleScrollView.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 23/03/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import "CycleScrollView.h"

@interface CycleScrollView () {
    NSInteger       _totalPages;
    NSInteger       _curPage;
    NSMutableArray *_curViews;
    
    NSTimer        *_autoScrollTimer;
}

@end

@implementation CycleScrollView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.delegate = self;
        _scrollView.contentSize = CGSizeMake(self.bounds.size.width * 3, self.bounds.size.height);
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.contentOffset = CGPointMake(self.bounds.size.width, 0);
        _scrollView.pagingEnabled = YES;
        [self addSubview:_scrollView];
        
        //Auto scroll function
        _autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(autoScrollView) userInfo:nil repeats:YES];
        
        _curPage = 0;
    }
    return self;
}

- (void)setDataource:(id<CycleScrollViewDatasource>)datasource
{
    _datasource = datasource;
    [self reloadData];
}

- (void)reloadData
{
    _totalPages = [_datasource numberOfPages];
    if (_totalPages == 0) {
        return;
    }
    [self loadData];
}

- (void)loadData
{
    
    //从scrollView上移除所有的subview
    NSArray *subViews = [_scrollView subviews];
    if([subViews count] != 0) {
        [subViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    [self getPageViewAtIndex:_curPage];
    
    for (int i = 0; i < 3; i++) {
        UIView *v = [_curViews objectAtIndex:i];
        v.userInteractionEnabled = YES;
        
        [self addGesture:v];
        
        v.frame = CGRectOffset(v.frame, self.frame.size.width * i, 0);
        
//test code
//        if (i == 0) {
//            v.backgroundColor = [UIColor orangeColor];
//        } else if (i == 0) {
//            v.backgroundColor = [UIColor cyanColor];
//        } else {
//            v.backgroundColor = [UIColor redColor];
//        }
        
        [_scrollView addSubview:v];
    }
    
    [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0)];
}

- (void)getPageViewAtIndex:(int)page {
    
    int pre = [self validPageValue:_curPage-1];
    int last = [self validPageValue:_curPage+1];
    
    if (!_curViews) {
        _curViews = [[NSMutableArray alloc] init];
    }
    
    [_curViews removeAllObjects];
    
    [_curViews addObject:[_datasource pageAtIndex:pre]];
    [_curViews addObject:[_datasource pageAtIndex:page]];
    [_curViews addObject:[_datasource pageAtIndex:last]];
}

- (UIView *) getCurrentView {
    if ([_curViews count] != 3) {
        [iConsole info:@"%s:Unexpeced",__FUNCTION__];
        return nil;
    } else {
        return [_curViews objectAtIndex:1];
    }
}

- (int)validPageValue:(NSInteger)value {
    
    if(value == -1) value = _totalPages - 1;
    if(value == _totalPages) value = 0;
    
    return value;
    
}

- (void)setViewContent:(UIView *)view atIndex:(NSInteger)index
{
    if (index == _curPage) {
        [_curViews replaceObjectAtIndex:1 withObject:view];
        for (int i = 0; i < 3; i++) {
            UIView *v = [_curViews objectAtIndex:i];
            
            [self addGesture:v];
            
            v.frame = CGRectOffset(v.frame, v.frame.size.width * i, 0);
            [_scrollView addSubview:v];
        }
    }
}


#pragma mark – CycleScrollViewDelegate

- (void)tapDownAction:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    if ([_delegate respondsToSelector:@selector(tapDownAction:atPageIndex:)]) {
        [_delegate tapDownAction:self atPageIndex:_curPage];
    }
}

- (void)gestureUpAction:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    if ([_delegate respondsToSelector:@selector(gestureUpAction:atPageIndex:)]) {
        [_delegate gestureUpAction:self atPageIndex:_curPage];
    }
}

- (void)gestureDownAction:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    if ([_delegate respondsToSelector:@selector(gestureDownAction:atPageIndex:)]) {
        [_delegate gestureDownAction:self atPageIndex:_curPage];
    }
}



#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    int x = aScrollView.contentOffset.x;
    
    //往下翻一张
    if(x >= (2*self.frame.size.width)) {
        _curPage = [self validPageValue:_curPage+1];
        [self loadData];
    }
    
    //往上翻
    if(x <= 0) {
        _curPage = [self validPageValue:_curPage-1];
        [self loadData];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
    
    [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:YES];
    
}

- (void) addGesture:(UIView *) v {
    UISwipeGestureRecognizer * recognizerUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureUpAction:)];
    [recognizerUp setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [v addGestureRecognizer:recognizerUp];
    
    UISwipeGestureRecognizer * recognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDownAction:)];
    [recognizerDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [v addGestureRecognizer:recognizerDown];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDownAction:)];
    [v addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark – Autoscroll NSTimer

- (void)autoScrollView
{
    int page = _currentPage;
    [_scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.frame)*(page+2),0) animated:YES];
}


#pragma mark – Memory management

- (void) clean {
    [_autoScrollTimer invalidate];
    _autoScrollTimer = nil;
}

- (void)dealloc {
    [_autoScrollTimer invalidate];
    _autoScrollTimer = nil;
}

@end
