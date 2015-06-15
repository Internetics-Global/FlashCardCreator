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

@property (nonatomic,assign,setter = setCycle:               ) BOOL                      isCycle;



@property (nonatomic,assign,setter = setAutoScroll:          ) BOOL                      isAutoScroll;

/**
 * 如果是smartDelay，则autoScroll是在text2speech结束后，调用scrollNow执行，而不是通过_autoScrollTimer进行执行
 */
@property (assign, nonatomic)                                  BOOL                      isSmartDelay;

@property (nonatomic,assign,setter = setAutoPlayDelaySeconds:) float                     autoPlayDelaySeconds;

@property (nonatomic,readonly                                ) UIScrollView              *scrollView;

- (UIView *) getCurrentView;

/**
 *  This is not an elegant way to clean resource, especially for NSTimer, but this is the only way we can do currently.
 */
- (void) cleanup;

/**
 *  trigger and scroll to next page
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
