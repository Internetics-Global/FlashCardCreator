//
//  CycleScrollView.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 23/03/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import "CycleScrollView.h"

@interface CycleScrollView () {
    NSInteger         _totalPages;
    NSInteger         _curPage;
    NSMutableArray   *_curViews;
    NSTimer          *_autoScrollTimer;
}

@property (nonatomic,readonly) UIScrollView   *scrollView;

@end

@implementation CycleScrollView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.isAutoScroll = NO;
        self.isCycle = YES;
        _curPage = 0;
        self.autoPlayDelaySeconds = k_Default_AutoPlayDelaySeconds;
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.delegate = self;
        _scrollView.bounces = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.alwaysBounceVertical = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        _scrollView.pagingEnabled = YES;
        [self addSubview:_scrollView];
        
        //Auto scroll function
        _autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(autoScrollView) userInfo:nil repeats:YES];
        
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionOld context:NULL];
    }
    return self;
}


- (void)setDataSource:(id<CycleScrollViewDatasource>)datasource
{
    _datasource = datasource;
    [self reloadData];
}

- (void) setCycle:(BOOL)isCycle {
    _isCycle = isCycle;
    
    
}

- (void) setAutoScroll:(BOOL)isAutoScroll {
    
    _isAutoScroll = isAutoScroll;
    
    [self resetTimer];
    
}

- (void)setAutoPlayDelaySeconds:(float)autoPlayDelaySeconds {
    
    _autoPlayDelaySeconds = autoPlayDelaySeconds;
    
    [self resetTimer];
    
}

- (void) resetTimer {
    if (_autoScrollTimer) {
        [_autoScrollTimer invalidate];
        _autoScrollTimer = nil;
    }
    
    if (_isAutoScroll) {
        _autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:_autoPlayDelaySeconds target:self selector:@selector(autoScrollView) userInfo:nil repeats:YES];
    }

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
    
    NSArray *subViews = [_scrollView subviews];
    if([subViews count] != 0) {
        [subViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    [self getPageViewAtIndex:_curPage];
    
    for (int i = 0; i < 3; i++) {
        UIView *v = [_curViews objectAtIndex:i];
        v.userInteractionEnabled = YES;
        v.frame = CGRectOffset(v.frame, self.frame.size.width * i, 0);
        [_scrollView addSubview:v];
        [self addGesture:v];
    }
    
    [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0)];
    
}

- (void)getPageViewAtIndex:(NSInteger)page {
    
    NSInteger pre = [self validPageValue:_curPage-1];
    NSInteger last = [self validPageValue:_curPage+1];
    
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

- (NSInteger)validPageValue:(NSInteger)value {
    
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
    } else {
         [iConsole error:@"%s:_delegate is empty",__FUNCTION__];
    }
}

- (void)gestureUpAction:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    if ([_delegate respondsToSelector:@selector(gestureUpAction:atPageIndex:)]) {
        [_delegate gestureUpAction:self atPageIndex:_curPage];
    } else {
        [iConsole error:@"%s:_delegate is empty",__FUNCTION__];
    }
}

- (void)gestureDownAction:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    if ([_delegate respondsToSelector:@selector(gestureDownAction:atPageIndex:)]) {
        [_delegate gestureDownAction:self atPageIndex:_curPage];
    } else {
        [iConsole error:@"%s:_delegate is empty",__FUNCTION__];
    }
}



#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    
    //如果没有dispatch_async，则会导致view jolt的表现的
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        int x = aScrollView.contentOffset.x;
        
        if (self.isCycle == FALSE) {
            
            if (((_curPage == 0) && (x < self.frame.size.width)) ||
                ((_curPage == _totalPages - 1) && (x > self.frame.size.width))){
                
                [aScrollView setScrollEnabled:NO];
                double delayInSeconds = 0.8;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [aScrollView setScrollEnabled:YES];
                });
                
            } else {
                if(x >= (2*self.frame.size.width)) {
                    _curPage = [self validPageValue:_curPage+1];
                    [self loadData];
                    if ([self.delegate respondsToSelector:@selector(didScrollToPage:)]) {
                        [self.delegate didScrollToPage:_curPage];
                    }
                }
                
                //previous page
                if(x <= 0) {
                    _curPage = [self validPageValue:_curPage-1];
                    [self loadData];
                    if ([self.delegate respondsToSelector:@selector(didScrollToPage:)]) {
                        [self.delegate didScrollToPage:_curPage];
                    }
                }
            }
            
            
        } else {
            //next page
            if(x >= (2*self.frame.size.width)) {
                _curPage = [self validPageValue:_curPage+1];
                [self loadData];
                if ([self.delegate respondsToSelector:@selector(didScrollToPage:)]) {
                    [self.delegate didScrollToPage:_curPage];
                }
            }
            
            //previous page
            if(x <= 0) {
                _curPage = [self validPageValue:_curPage-1];
                [self loadData];
                if ([self.delegate respondsToSelector:@selector(didScrollToPage:)]) {
                    [self.delegate didScrollToPage:_curPage];
                }
            }
        }
        
    });
    
    
    
    
}

//scrollViewDidEndDecelerating won't be called for scrollRectToVisible or setContentOffset (i.e, scrolling programmatically)
- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
    
    if (self.isAutoScroll == FALSE) {
        [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:YES];
    }
    
}

#pragma mark – Gesture function

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
    if (_isCycle) {
        [_scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.frame)*(2),0) animated:YES];
    } else {
        if (_curPage < _totalPages -1) {
            [_scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.frame)*(2),0) animated:YES];
        } else {
            
        }
    }
    
}

#pragma mark – view.frame
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if([keyPath isEqualToString:@"frame"]) {
        _scrollView.contentSize = CGSizeMake(self.bounds.size.width * 3, self.bounds.size.height);
    }
}


#pragma mark – Memory management

- (void) clean {
    [_autoScrollTimer invalidate];
    _autoScrollTimer = nil;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"frame"];
    [_autoScrollTimer invalidate];
    _autoScrollTimer = nil;
}



@end
