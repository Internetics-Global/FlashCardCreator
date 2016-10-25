//
//  CycleScrollView.m
//  FFC
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
    
    /**
     *  在fixed delay模式下的使用。在smart delay模式（即文本读完后才到下一张卡片）不使用

     */
    NSTimer        * _autoScrollTimerForFixedDelay;
    
    /**
     *  triggered by dwellSeconds
     */
    NSTimer        * _dwellOnQuestionExpireTimer;

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
        self.isFixedDelayAutoScroll = NO;
        self.isCycle = YES;
        self.dwellSecondsTotally = kDefault_Auto_Play_Speed;
        
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

- (void) setFixedDelayAutoScroll:(BOOL)isFixedDelayAutoScroll {
    _isFixedDelayAutoScroll = isFixedDelayAutoScroll;
    [self resetAutoScrollTimer];
}

- (void)setDwellSecondsTotally:(float)dwellSeconds{
    _dwellSecondsTotally = dwellSeconds;
    
    //因为_dwellSecondsTotally会影响最终的auto scroll timer的时间计算
    [self resetAutoScrollTimer];
    
}

- (void)setDwellSecondsOnQuestion:(float)dwellSecondsOnQuestion {
    _dwellSecondsOnQuestion = dwellSecondsOnQuestion;
}

/**
 *  Only for fixed delay mode;在auto delay mode中，我们是另外处理
 */
- (void)setIntervalBetweenCardSeconds:(float)intervalBetweenCardSeconds{
    _intervalBetweenCardSeconds = intervalBetweenCardSeconds;
    [self resetAutoScrollTimer];
}

/**
 *  Used in fixed delay mode only
 */
- (void) resetDwellOnQuestionExpireTimerForFixedDelay {
    
    if (_dwellOnQuestionExpireTimer) {
        [_dwellOnQuestionExpireTimer invalidate];
        _dwellOnQuestionExpireTimer = nil;
    }
    
    if (_isFixedDelayAutoScroll && self.isAutoScroll) {
        _dwellOnQuestionExpireTimer = [NSTimer scheduledTimerWithTimeInterval:(_dwellSecondsOnQuestion) target:self selector:@selector(dwellOnQuestionExpireTimerForFixedDelay) userInfo:nil repeats:NO];
    } else {
        
    }
    
}

- (void) resetAutoScrollTimer {
    if (_autoScrollTimerForFixedDelay) {
        [_autoScrollTimerForFixedDelay invalidate];
        _autoScrollTimerForFixedDelay = nil;
    }
    
    if (_isFixedDelayAutoScroll && self.isAutoScroll) {
        _autoScrollTimerForFixedDelay = [NSTimer scheduledTimerWithTimeInterval:(_dwellSecondsTotally + _intervalBetweenCardSeconds) target:self selector:@selector(autoScrollViewTimerForFixedDelay) userInfo:nil repeats:YES];
    } else {
       //当_isFixedDelayAutoScroll == NO时，在text2Speech 完成后，callback调用[scrollview scrollNow]，而不是采用NSTimer的方式
    }
    
    [self resetDwellOnQuestionExpireTimerForFixedDelay];
    

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
    
    [self resetPageViewAtIndex:_curPage withDirectionToNextPage:isToNextPage];
    
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
 *  实际上会load 3个卡片，其中前后作为一种缓存形式（用于提前auto resize)
 */
- (void)resetPageViewAtIndex:(NSInteger)page withDirectionToNextPage:(BOOL) isToNextPage {
    
    [self cleanupPageViews];
    
    NSInteger pre = [self validPageValue:_curPage-1];
    NSInteger next = [self validPageValue:_curPage+1];
    
    if (!_curViews) {
        _curViews = [[NSMutableArray alloc] init];
    }
    
    [_curViews removeAllObjects];
    
    if (isToNextPage) {
        
        //previous
        _previousCard = [_datasource pageAtIndex:pre withPosition:Type_Card_Position_Previous];
        _previousCard.tag = PREVIOUS_FLASHCARDVIEW_TAG;
        [_curViews addObject:_previousCard];
        
        //current
        if (_nextCard != nil) {
            _nextCard.tag = CURRENT_FLASHCARDVIEW_TAG;
            _nextCard.frame = _previousCard.frame; //this is very important
            [(FlashCard *)_nextCard updateQuestionAnswerAllTextViewVeriticalAlignment];
            [_curViews addObject:_nextCard];
        } else {
            UIView *card = [_datasource pageAtIndex:page withPosition:Type_Card_Position_Current];
            card.tag = CURRENT_FLASHCARDVIEW_TAG;
            [_curViews addObject:card];
        }
        
        //next
        _nextCard = [_datasource pageAtIndex:next withPosition:Type_Card_Position_Next];
        _nextCard.tag = NEXT_FLASHCARDVIEW_TAG;
        [_curViews addObject:_nextCard];
        
    } else {
        
        //next
        _nextCard = [_datasource pageAtIndex:next withPosition:Type_Card_Position_Next];
        _nextCard.tag = NEXT_FLASHCARDVIEW_TAG;
        [_curViews addObject:_nextCard];
        
        //current
        if (_previousCard != NULL) {
            _previousCard.tag = CURRENT_FLASHCARDVIEW_TAG;
            _previousCard.frame = _nextCard.frame; //this is very important
            [(FlashCard *)_previousCard updateQuestionAnswerAllTextViewVeriticalAlignment];
            [_curViews insertObject:_previousCard atIndex:0];
        } else {
            UIView *card = [_datasource pageAtIndex:page withPosition:Type_Card_Position_Current];
            card.tag = CURRENT_FLASHCARDVIEW_TAG;
            [_curViews insertObject:card atIndex:0];
        }
        
        //previous
        _previousCard = [_datasource pageAtIndex:pre withPosition:Type_Card_Position_Previous];
        _previousCard.tag = PREVIOUS_FLASHCARDVIEW_TAG;
        [_curViews insertObject:_previousCard atIndex:0];
        
    }
    
}

- (UIView *) getCurrentView {
    if ([_curViews count] != 3) {
       // [iConsole info:@"%s:Unexpeced",__FUNCTION__];
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
    
    if ([self.delegate respondsToSelector:@selector(didScroll:)]) {
        [self.delegate didScroll:_curPage];
    }
    
    if (self.isCycle == false) {
        if (_totalPages == 1) {
            CGPoint point = _scrollView.contentOffset;
            if (_scrollView.contentOffset.x != self.bounds.size.width) {
                point.x = self.bounds.size.width;
                [_scrollView setScrollEnabled:NO];
                double delayInSeconds = 0.5;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [_scrollView setScrollEnabled:YES];
                });
            }
        } else if (_curPage == 0) {
            CGPoint point = _scrollView.contentOffset;
            if (_scrollView.contentOffset.x <= self.bounds.size.width) {
                point.x = self.bounds.size.width;
                [_scrollView setScrollEnabled:NO];
                double delayInSeconds = 0.5;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [_scrollView setScrollEnabled:YES];
                });
            }
        } else if (_curPage == _totalPages - 1) {
            CGPoint point = _scrollView.contentOffset;
            if (_scrollView.contentOffset.x >= self.bounds.size.width) {
                point.x = self.bounds.size.width;
                [_scrollView setScrollEnabled:NO];
                double delayInSeconds = 0.5;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [_scrollView setScrollEnabled:YES];
                });
            }
        }
    }
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
    
    if (self.isFixedDelayAutoScroll == FALSE) {
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

/**
 *  通过定时器调用，仅仅当_isFixedDelayAutoScroll ＝ YES下使用
 *  在smart delay模式下，当Text2Speech完成后，调用[self scrollNow]自动切换到下张卡片
 */
- (void) autoScrollViewTimerForFixedDelay {
    
    //由于是个延时调用，所以需要重新check
    if (self.isAutoScroll == FALSE || (self.isAutoScroll && (self.isFixedDelayAutoScroll == FALSE))) {
        return;
    }
    
    [self scrollNow];
    
    //每次通过定时器scroll到下一个page时，都需要重新设置
    [self resetDwellOnQuestionExpireTimerForFixedDelay];
}

- (void) dwellOnQuestionExpireTimerForFixedDelay {
    if ([self.delegate respondsToSelector:@selector(didFinishDwellOnQuestionCard)]) {
        [self.delegate didFinishDwellOnQuestionCard];
    }
}


- (void)scrollNow
{
    //cleanup 
    [self cleanupPageViews];
    
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

/**
 *  _curViews中的有些资源需要释放，尤其是在执行resetPageViewAtIndex时，因为如果不释放就会成为野指针
 *  注意同cleanupNSTimer 区别
 */
- (void) cleanupPageViews {
    
    for (UIView *myView in _curViews) {
        if ([myView isKindOfClass:[FlashCard class]]) {
            [(FlashCard *) myView  stopTextToSpeechNow];
            [(FlashCard *) myView  stopAudio];
        }
    }
}

- (void) cleanupNSTimer {
    [_autoScrollTimerForFixedDelay invalidate];
    _autoScrollTimerForFixedDelay = nil;
    
    [_dwellOnQuestionExpireTimer invalidate];
    _dwellOnQuestionExpireTimer = nil;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"frame"];
    
    [_autoScrollTimerForFixedDelay invalidate];
    _autoScrollTimerForFixedDelay = nil;
    
    [_dwellOnQuestionExpireTimer invalidate];
    _dwellOnQuestionExpireTimer = nil;
}



@end
