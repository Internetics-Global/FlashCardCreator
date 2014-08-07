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

typedef NS_ENUM(NSInteger, Type_Toolbar_State) {
    Type_Toolbar_State_Main           = -1,
    Type_Toolbar_State_Font      = 1,
    Type_Toolbar_State_Size = 2,
    Type_Toolbar_State_Align      = 3,
    Type_Toolbar_State_Color = 4,
    Type_Toolbar_State_Unkown = 5,
};

@class KeyboardTopView;

@protocol KeyboardTopViewDelegate <NSObject>

- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedAlignChangeButton:(id) sender;
- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedSizeChangeButton:(id) sender;
- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedColorChangeButton:(id) sender;
- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedFontChangeButton:(id) sender;

- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedSaveButton:(id) sender;

/**
 *  指第一级的button, symbol， align, size, color, font,但是不包括save
 */
- (void) keyboardTopView:(KeyboardTopView *)keyboardTopView didClickedMainButton:(id) sender;

@end


@interface KeyboardTopView : UIView

@property (strong, nonatomic) UIScrollView* scrollView;

@property (weak, nonatomic) id<KeyboardTopViewDelegate> delegate;

/**
 *  keyboard inputview上现实的值，在iPhone上 ＝ 真实值；在iPad则不等于
 */
@property (strong, nonatomic) NSArray *nominalSizeArray;
/**
 *  实际font size大小，与nominalSizeArray一一对应。实际的字体大小等于realSizeArray ＝ nominalSizeArray[i] * scale
 */
@property (strong, nonatomic,getter = getRealSizeArray) NSArray *realSizeArray;

@property (strong, nonatomic) NSArray *colorArray;
@property (strong, nonatomic) NSArray *fontArray;
@property (strong, nonatomic) NSArray *alignArray;
@property (strong, nonatomic) NSArray *summaryArray;

@property (assign, nonatomic) Type_Toolbar_State     toolbarState;

/**
 *  从nominalSize到realSize
 */
- (int) getRealSizeFromNominalSize:(int) nominalSize;

/**
 *  从realSize到nominalSize
 */
- (int) getNominalSizeFromRealSize:(int) realSize;

- (void) setupFontArray;
- (void) setupAlignArray;
- (void) setupSizeArray;
- (void) setupColorArray;
- (void) setupSummaryArray;

-(NSArray *) getCurrentButtonArray;

- (void) scrollToButtonIndex:(int) index;


@end
