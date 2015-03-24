//
//  CycleScrollView.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 23/03/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

#define k_Default_AutoPlayDelaySeconds  6.0

@protocol CycleScrollViewDelegate;
@protocol CycleScrollViewDatasource;

@interface CycleScrollView : UIView<UIScrollViewDelegate>

@property (nonatomic,assign,setter = setDataSource:) id<CycleScrollViewDatasource> datasource;
@property (nonatomic,assign,setter = setDelegate:)  id<CycleScrollViewDelegate>   delegate;

@property (nonatomic,assign,setter = setCycle:)       BOOL      isCycle;
@property (nonatomic,assign,setter = setAutoScroll:)  BOOL      isAutoScroll;
@property (nonatomic,assign,setter = setAutoPlayDelaySeconds:)  float     autoPlayDelaySeconds;


- (UIView *) getCurrentView;

/**
 *  This is not an elegant way to clean resource, especially for NSTimer, but this is the only way we can do currently.
 */
- (void) clean;

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
- (UIView *)pageAtIndex:(NSInteger)index;

@end
