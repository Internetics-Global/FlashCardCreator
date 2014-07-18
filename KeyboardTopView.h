//
//  KeyboardTopView.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 7/18/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, Back_Type) {
    Back_Type_Unkown      = -1,
    Back_Type_Font       = 1,
    Back_Type_Color   = 2,
    Back_Type_Size    = 3,
    Back_Type_Align    = 4,
    Back_Type_Summary    = 5,
};

@class KeyboardTopView;

@protocol KeyboardTopViewDelegate <NSObject>

- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedAlignChangeButtonAtIndex:(id) sender;
- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedSizeChangeButtonAtIndex:(id) sender;
- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedColorChangeButtonAtIndex:(id) sender;
- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedFontChangeButtonAtIndex:(id) sender;
/**
 *  指第一级的button，包括done, symbol， align, size, color, font
 */
- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedMainButton:(id) sender;

@end


@interface KeyboardTopView : UIView

@property (strong, nonatomic) UIScrollView* scrollView;

@property (weak, nonatomic) id<KeyboardTopViewDelegate> delegate;

@property (strong, nonatomic) NSArray *sizeArray;
@property (strong, nonatomic) NSArray *colorArray;
@property (strong, nonatomic) NSArray *fontArray;
@property (strong, nonatomic) NSArray *alignArray;
@property (strong, nonatomic) NSArray *summaryArray;



- (void) setupFontArray;
- (void) setupAlignArray;
- (void) setupSizeArray;
- (void) setupColorArray;
- (void) setupSummaryArray;

-(NSArray *) getCurrentButtonArray;


@end
