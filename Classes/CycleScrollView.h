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

@property (nonatomic,readonly) UIScrollView *scrollView;
@property (nonatomic,assign) NSInteger currentPage;
@property (nonatomic,assign,setter = setDataource:) id<CycleScrollViewDatasource> datasource;
@property (nonatomic,assign,setter = setDelegate:) id<CycleScrollViewDelegate> delegate;

- (void)reloadData;
- (void)setViewContent:(UIView *)view atIndex:(NSInteger)index;
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

@end

@protocol CycleScrollViewDatasource <NSObject>

@required
- (NSInteger)numberOfPages;
- (UIView *)pageAtIndex:(NSInteger)index;

@end
