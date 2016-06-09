//
//  PackInfoView.h
//  FlashCardCreator
//
//  Created by Internetics on 8/06/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Pack;
@class PackInfoView;


@protocol PackInfoViewDelegate <NSObject>
@optional
- (void)packInfoView:(PackInfoView *)packInfoVIew didScrollToPack:(Pack *)pack;
- (void)playButtonClickedOnPackInfoView;
@end


@interface PackInfoView : UIView <UIScrollViewDelegate>

- (id)initWithFrame:(CGRect)frame;

@property (strong, nonatomic) Pack *currentPack;

@property (weak, nonatomic) id<PackInfoViewDelegate> delegate;


- (void) scrollTo:(Pack *) pack WithRebuildScrollView:(BOOL) isRebuildScrollView;
- (void) refreshWithRebuildScrollView:(BOOL)isRebuildScrollView;

@end
