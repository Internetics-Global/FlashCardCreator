//
//  CycleScrollView.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 23/03/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CycleScrollViewDelegate;
@protocol CycleScrollViewDatasource;

@interface CycleScrollView : UIView<UIScrollViewDelegate>


@property (nonatomic,assign,setter = setDataSource:          ) id<CycleScrollViewDatasource> datasource;
@property (nonatomic,assign,setter = setDelegate:            ) id<CycleScrollViewDelegate  > delegate;

/**
 *  循环播放
 */
@property (nonatomic,assign,setter = setCycle:               ) BOOL                      isCycle;

/**
 *  auto play分两种，被isAutoScroll总控制
 *  1. YES:固定时间间隔的播放
 *  2. NO :isSmartDelay
 */
@property (nonatomic,assign,setter = setFixedDelayAutoScroll:) BOOL                      isFixedDelayAutoScroll;


/**
 *  总控制
 */
@property (nonatomic,assign                                  ) BOOL                      isAutoScroll;


/**
 *  在某一张卡片（包括question和answer)上的停留时间
 *  注意，包括_pauseForAnswer的值
 */
@property (nonatomic,assign,setter = setDwellSecondsTotally:) float                      dwellSecondsTotally;

/**
 *  仅在question上的停留时间，但注意，不包括_pauseForAnswer的值
 */
@property (nonatomic,assign,setter = setDwellSecondsOnQuestion:) float                   dwellSecondsOnQuestion;

/**
 *  两张卡片之间的停留时间
 */
@property (nonatomic,assign,setter = setIntervalBetweenCardSeconds:) float                intervalBetweenCardSeconds;



@property (nonatomic,readonly                                ) UIScrollView               *scrollView;

- (UIView *) getCurrentView;

/**
 *  This is not an elegant way to clean resource, especially for NSTimer, but this is the only way we can do currently.
 */
- (void) cleanup;

/**
 *  Trigger to scroll right now manually
 */
- (void) scrollNow;

@end

@protocol CycleScrollViewDelegate <NSObject>

@optional

- (void)tapDownAction:(CycleScrollView *)csView atPageIndex:(NSInteger)index;
- (void)gestureUpAction:(CycleScrollView *)csView atPageIndex:(NSInteger)index;
- (void)gestureDownAction:(CycleScrollView *)csView atPageIndex:(NSInteger)index;

- (void)didScrollToPage:(NSInteger)index;

/**
 *  当超过dwellSecondsOnQuestion后被触发
 */
- (void) didFinishDwellOnQuestionCard;

@end

@protocol CycleScrollViewDatasource <NSObject>

@required
- (NSInteger)numberOfPages;

/**
 *  position: -1 previous card; 0 current card; 1 next card
 */
- (UIView *)pageAtIndex:(NSInteger)index withPosition:(int) position;


@end
