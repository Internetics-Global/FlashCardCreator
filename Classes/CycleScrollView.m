//
//  CycleScrollView.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 23/03/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import "CycleScrollView.h"
#import "FlashCard.h"

@interface CycleScrollView () <UIGestureRecognizerDelegate> {
    
    NSInteger      _totalPages;
    NSInteger      _curPage;
    NSMutableArray * _curViews;
    
    NSTimer        * _autoScrollTimer;

    UIView         * _previousCard;
    UIView         * _nextCard;

    /**
     *  used to avoid multiple excution
     */
    BOOL           _notAllowReloadData;
}

@end

@implementation CycleScrollView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isAutoScroll = NO;
        self.isCycle = YES;
        self.autoPlayDelaySeconds = kDefault_Auto_Play_Speed;
        
        _curPage = 0;
        
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
    [self resetAutoScrollTimer];
}

- (void)setAutoPlayDelaySeconds:(float)autoPlayDelaySeconds {
    _autoPlayDelaySeconds = autoPlayDelaySeconds;
    [self resetAutoScrollTimer];
    
}

- (void) resetAutoScrollTimer {
    if (_autoScrollTimer) {
        [_autoScrollTimer invalidate];
        _autoScrollTimer = nil;
    }
    
    if (_isAutoScroll) {
        _autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:_autoPlayDelaySeconds target:self selector:@selector(autoScrollViewTimer) userInfo:nil repeats:YES];
    }

}


- (void)reloadData
{
    _totalPages = [_datasource numberOfPages];
    if (_totalPages == 0) {
        return;
    }
    [self loadDataWithDirectionToNextPage:YES];
}

/**
 *  @param isToNextPage: swipe to next page or previous page
 */
- (void)loadDataWithDirectionToNextPage:(BOOL) isToNextPage;
{
    NSArray *subViews = [_scrollView subviews];
    if([subViews count] != 0) {
        [subViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    [self getPageViewAtIndex:_curPage withDirectionToNextPage:isToNextPage];
    
    for (int i = 0; i < 3; i++) {
        UIView *v = [_curViews objectAtIndex:i];
        v.userInteractionEnabled = YES;
        v.frame = CGRectOffset(v.frame, self.frame.size.width * i, 0);
        [_scrollView addSubview:v];
        [self addGesture:v];
        
        //NSLog(@"xbox:%@ -- %d",NSStringFromCGRect(v.frame),i);
    }
    
    [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0)];
    
}

/**
 *  @param isToNextPage:swipe to next page or previous page
 */
- (void)getPageViewAtIndex:(NSInteger)page withDirectionToNextPage:(BOOL) isToNextPage {
    
    NSInteger pre = [self validPageValue:_curPage-1];
    NSInteger next = [self validPageValue:_curPage+1];
    
    if (!_curViews) {
        _curViews = [[NSMutableArray alloc] init];
    }
    
    [_curViews removeAllObjects];
    
    if (isToNextPage) {
        
        //previous
        _previousCard = [_datasource pageAtIndex:pre withPosition:-1];
        [_curViews addObject:_previousCard];
        
        //current
        if (_nextCard != nil) {
            _nextCard.tag = CURRENT_FLASHCARDVIEW_TAG;
            _nextCard.frame = _previousCard.frame; //this is very important
            [(FlashCard *)_nextCard updateQuestionAnswerAllTextViewVeriticalAlignment];
            [_curViews addObject:_nextCard];
        } else {
            [_curViews addObject:[_datasource pageAtIndex:page withPosition:0]];
        }
        
        //next
        _nextCard = [_datasource pageAtIndex:next withPosition:1];
        [_curViews addObject:_nextCard];
        
    } else {
        
        //next
        _nextCard = [_datasource pageAtIndex:next withPosition:1];
        [_curViews addObject:_nextCard];
        
        //current
        if (_previousCard != NULL) {
            _previousCard.tag = CURRENT_FLASHCARDVIEW_TAG;
            _previousCard.frame = _nextCard.frame; //this is very important
            [(FlashCard *)_previousCard updateQuestionAnswerAllTextViewVeriticalAlignment];
            [_curViews insertObject:_previousCard atIndex:0];
        } else {
            [_curViews insertObject:[_datasource pageAtIndex:page withPosition:0] atIndex:0];
        }
        
        //previous
        _previousCard = [_datasource pageAtIndex:pre withPosition:-1];
        [_curViews insertObject:_previousCard atIndex:0];
        
    }
    
}

- (UIView *) getCurrentView {
    if ([_curViews count] != 3) {
        [iConsole info:@"%s:Unexpeced",__FUNCTION__];
        return nil;
    } else {
        return [_curViews objectAtIndex:1];
    }
}

/**
 *
 */
- (NSInteger)validPageValue:(NSInteger)rawPage {
    
    if(rawPage == -1) {
      rawPage = _totalPages - 1;
    }
    if(rawPage == _totalPages) {
      rawPage = 0;
    }
    
    return rawPage;
    
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
    
    //Be careful, don't put any logic that could take time here like "loadDataWithDirectionToNextPage". This will be called by system multiple during scrolling and could result into jigging
    
    
}

//scrollViewDidEndDecelerating won't be called for scrollRectToVisible or setContentOffset (i.e, scrolling programmatically)
- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
    
    //make sure scrollViewDidEndDecelerating is executed only once
    if (_notAllowReloadData) {
        return;
    }
    
    int x = aScrollView.contentOffset.x;
    
    if (self.isCycle == FALSE) {
        
        if (((_curPage == 0) && (x < self.frame.size.width)) ||
            ((_curPage == _totalPages - 1) && (x > self.frame.size.width))){
            
            //avoid empty page
            [aScrollView setScrollEnabled:NO];
            double delayInSeconds = 0.8;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [aScrollView setScrollEnabled:YES];
            });
            
        } else {
            if (x >= (2*self.frame.size.width)) {
                _notAllowReloadData = TRUE;
                _curPage = [self validPageValue:_curPage+1];
                [self loadDataWithDirectionToNextPage:YES];
                if ([self.delegate respondsToSelector:@selector(didScrollToPage:)]) {
                    [self.delegate didScrollToPage:_curPage];
                }
            }
            
            //previous page
            if (x <= 0) {
                _notAllowReloadData = TRUE;
                _curPage = [self validPageValue:_curPage-1];
                [self loadDataWithDirectionToNextPage:NO];
                if ([self.delegate respondsToSelector:@selector(didScrollToPage:)]) {
                    [self.delegate didScrollToPage:_curPage];
                }
            }
        }
        
        
    } else {
        //next page
        if (x >= (2*self.frame.size.width)) {
            _notAllowReloadData = TRUE;
            _curPage = [self validPageValue:_curPage+1];
            [self loadDataWithDirectionToNextPage:YES];
            if ([self.delegate respondsToSelector:@selector(didScrollToPage:)]) {
                [self.delegate didScrollToPage:_curPage];
            }
        }
        
        //previous page
        if (x <= 0) {
            _notAllowReloadData = TRUE;
            _curPage = [self validPageValue:_curPage-1];
            [self loadDataWithDirectionToNextPage:NO];
            if ([self.delegate respondsToSelector:@selector(didScrollToPage:)]) {
                [self.delegate didScrollToPage:_curPage];
            }
        }
    }
    
    if (self.isAutoScroll == FALSE) {
        [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:YES];
    }
    
}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _notAllowReloadData = FALSE;
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
    tapGestureRecognizer.delegate = self;
    [v addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark – Autoscroll NSTimer

- (void)autoScrollViewTimer
{
    //cleanup 
    for (UIView *myView in _curViews) {
        if ([myView isKindOfClass:[FlashCard class]]) {
            [(FlashCard *) myView  stopTextToSpeechNow];
            [(FlashCard *) myView  stopAudio];
        }
    }
    
    if (_isCycle) {
        _notAllowReloadData = FALSE;
        [_scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.frame)*(2),0) animated:TRUE];
        //这段delay是关键，因为setContentOffset是个动画过程，需要一段时间
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self scrollViewDidEndDecelerating:_scrollView];
        });
    } else {
        if (_curPage < _totalPages -1) {
            _notAllowReloadData = FALSE;
            [_scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.frame)*(2),0) animated:TRUE];
            //这段delay是关键，因为setContentOffset是个动画过程，需要一段时间
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self scrollViewDidEndDecelerating:_scrollView];
            });
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

#pragma mark – UIGestureRecognizerDelegate
/*
 * Why we need this:
 * In Play mode, there's an segmented control under the card.
 * If no this logic, click that part of card could switch question/answer card, rather than hide/show expected control panel 
*/
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[FlashCard class]] || [touch.view isKindOfClass:[UISegmentedControl class]]) {
        return false;
    } else {
        return true;
    }
}


#pragma mark – Memory management

- (void) cleanup {
    [_autoScrollTimer invalidate];
    _autoScrollTimer = nil;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"frame"];
    [_autoScrollTimer invalidate];
    _autoScrollTimer = nil;
}



@end
