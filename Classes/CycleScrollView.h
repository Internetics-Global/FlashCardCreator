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
 *  auto play的其中一种： 固定时间间隔的播放。 另外一种是isSmartDelay
 */
@property (nonatomic,assign,setter = setFixedDelayAutoScroll:) BOOL                      isFixedDelayAutoScroll;

/**
 * auto play的其中一种，另外一种是固定时间间隔的播放
 * 如果是smartDelay，则autoScroll是在text2speech结束后，调用scrollNow执行，而不是通过_autoScrollTimer进行执行
 */
@property (assign, nonatomic)                                  BOOL                      isSmartDelay;

/**
 *  在某一张卡片上的停留时间
 */
@property (nonatomic,assign,setter = setAutoPlayDelaySeconds:) float                     autoPlayDelaySeconds;

/**
 *  两张卡片之间的停留时间
 */
@property (nonatomic,assign,setter = setPauseForAnswerSeconds:) float                     pauseForAnswerSeconds;

@property (nonatomic,readonly                                ) UIScrollView              *scrollView;

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

@end

@protocol CycleScrollViewDatasource <NSObject>

@required
- (NSInteger)numberOfPages;

/**
 *  position: -1 previous card; 0 current card; 1 next card
 */
- (UIView *)pageAtIndex:(NSInteger)index withPosition:(int) position;


@end
