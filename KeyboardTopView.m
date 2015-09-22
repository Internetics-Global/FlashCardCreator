//
//  KeyboardTopView.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 7/18/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "KeyboardTopView.h"

#define K_Item_Width  80

#define K_SummaryArray     @[@"Align",@"Size",@"Color",@"Font",@"Symbol"]
#define K_NominalSizeArray @[@10,@11,@12,@14,@16,@18,@20,@24,@28,@32,@36,@40,@45,@50,@55,@60,@80,@100,@130]
#define K_ColorArray       @[@"Red",@"Blue",@"Black",@"Yellow",@"Green",@"White"]
#define K_AlignArray       @[@"Left",@"Center",@"Right",@"Justify",@"Vertical"]
#define K_FontArray        @[@"Default",@"Arial-BoldMT",@"Chalkduster",@"Courier",@"Papyrus",@"Zapfino"]

#define K_FontScale_iPhone     1.0
#define K_FontScale_iPad       2.0

@interface KeyboardTopView() {
    Back_Type _backType;
    
    UIImageView *_backImageView;
    UIButton *_saveButton;
}

@end


@implementation KeyboardTopView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self baseInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self baseInit];
    }
    return self;
}

- (void)baseInit {
    _toolbarState = Type_Toolbar_State_Main;
    _backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"back_button"]];
    _backImageView.contentMode = UIViewContentModeScaleAspectFit;
    _backImageView.frame = CGRectMake(0, 0, K_Item_Width, CGRectGetHeight(self.frame));
    _backImageView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    [self addSubview:_backImageView];
    _backImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickedBackButton)];
    oneTap.numberOfTapsRequired = 1;
    [_backImageView addGestureRecognizer:oneTap];
    
    self.scrollView = [ [UIScrollView alloc ] initWithFrame:self.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.scrollView.userInteractionEnabled = YES;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    //    scrollView.contentOffset = CGPointMake(60, 0); //内容区域，决定了是否可以滚动
    self.scrollView.directionalLockEnabled = YES; //默认行为是允许用户同时进行横向和纵向的滚动。将这个属性设置为YES会导致将用户的滚动行为锁定成只允许横向或纵向进行，具体方向由初始姿态决定。
    self.scrollView.bounces = YES;
    self.scrollView.pagingEnabled = NO;
    [self addSubview:self.scrollView];
    
    self.summaryArray = K_SummaryArray;
    self.nominalSizeArray = K_NominalSizeArray;
    self.colorArray = K_ColorArray;
    self.alignArray = K_AlignArray;
    self.fontArray = K_FontArray;
    
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    
    _backType = Back_Type_Unkown;
    
}


- (void) removeAllScrollSubButtons {
    for (UIView *v in self.scrollView.subviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            [v removeFromSuperview];
        }
    }
}

- (float) scale {
    
    if (isUserInterfaceIdiomPhone) {
        return K_FontScale_iPhone;
    } else {
        return K_FontScale_iPad;
    }
    
}

- (NSArray *) getRealSizeArray {
    NSMutableArray *returnArray = [NSMutableArray array];
    for (NSString *item in self.nominalSizeArray) {
        float val = ([item integerValue] * [self scale]);
        [returnArray addObject:[NSString stringWithFormat:@"%d",(int)val]];
    }
    
    return returnArray;
}

- (int) getRealSizeFromNominalSize:(int) nominalSize {
    BOOL isFound = FALSE;
    BOOL targetIndex = 0;
    for (int i= 0; i < [self.nominalSizeArray count]; i++) {
        NSString *item = [self.nominalSizeArray objectAtIndex:i];
        if ([item integerValue] == nominalSize) {
            targetIndex = i;
            isFound = YES;
            break;
        }
    }
    
    if (isFound) {
        NSString *foundItem = [self.realSizeArray objectAtIndex:targetIndex];
        return [foundItem intValue];
    } else {
        [iConsole error:@"%s: can not found related realsize value. nominal value = %d",__FUNCTION__,nominalSize];
        
        int nearestIndex = [Common nearestIndexForStringArray:self.nominalSizeArray withElement:nominalSize];
        NSString *foundItem = [self.realSizeArray objectAtIndex:nearestIndex];
        return [foundItem intValue];
    }
    
}

- (int) getNominalSizeFromRealSize:(int) realSize {
    BOOL isFound = FALSE;
    int targetIndex = 0;
    for (int i= 0; i < [self.realSizeArray count]; i++) {
        NSString *item = [self.realSizeArray objectAtIndex:i];
        if ([item integerValue] == realSize) {
            targetIndex = i;
            isFound = YES;
            break;
        }
        
    }
    
    if (isFound) {
        NSString *foundItem = [self.nominalSizeArray objectAtIndex:targetIndex];
        return [foundItem intValue];
    } else {
        [iConsole error:@"%s: can not find related nomimal value. realSize value = %d",__FUNCTION__,realSize];
        
        int nearestIndex = [Common nearestIndexForStringArray:self.realSizeArray withElement:realSize];
        NSString *foundItem = [self.nominalSizeArray objectAtIndex:nearestIndex];
        return [foundItem intValue];
    }
    
}

#pragma mark – Font

- (void) setupFontArray {
    
    [self removeAllScrollSubButtons];
    
    _backType = Back_Type_Font;
    
    self.scrollView.contentSize = CGSizeMake(K_Item_Width * [self.fontArray count], CGRectGetHeight(self.frame));
    
    for (int i = 0; i<[self.fontArray count]; i++) {
        UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        myButton.tag = i;
        myButton.frame = CGRectMake(i*K_Item_Width, 0, K_Item_Width, CGRectGetHeight(self.frame));
        [myButton titleLabel].font = [UIFont boldSystemFontOfSize:12];
        
        [myButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.scrollView addSubview:myButton];
        
        NSString *title = self.fontArray[i];
        [myButton setTitle:NSLocalizedString(title,nil) forState:UIControlStateNormal];
        [myButton addTarget:self action:@selector(didClickedFontChangeButton:) forControlEvents:UIControlEventTouchUpInside];
    
    }
    
    self.scrollView.frame = CGRectMake(K_Item_Width, 0, CGRectGetWidth(self.frame) - 2 * K_Item_Width, CGRectGetHeight(self.frame));
    _backImageView.hidden = NO;
    
    [self setupSaveButton];
}

- (void) didClickedFontChangeButton:(id) sender {
    if (self.delegate) {
        [self.delegate keyboardTopView:self didClickedFontChangeButton:sender];
    } else {
        //NSAssert(FALSE, @"You need to assign delete");
    }
}

#pragma mark – Color

- (void) setupColorArray {
    
    [self removeAllScrollSubButtons];
    
    _backType = Back_Type_Color;
    
    self.scrollView.contentSize = CGSizeMake(K_Item_Width * [self.colorArray count], CGRectGetHeight(self.frame));
    
    for (int i = 0; i<[self.colorArray count]; i++) {
        UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        myButton.tag = i;
        myButton.frame = CGRectMake(i*K_Item_Width, 0, K_Item_Width, CGRectGetHeight(self.frame));
        [myButton titleLabel].font = [UIFont boldSystemFontOfSize:16];
        
        [myButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.scrollView addSubview:myButton];
        
        NSString *title = [NSString stringWithFormat:@"ToolbarItem_Color_%@",self.colorArray[i]];
        [myButton setTitle:NSLocalizedString(title,nil) forState:UIControlStateNormal];
        [myButton addTarget:self action:@selector(didClickedColorChangeButton:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    self.scrollView.frame = CGRectMake(K_Item_Width, 0, CGRectGetWidth(self.frame) - 2 * K_Item_Width, CGRectGetHeight(self.frame));
    _backImageView.hidden = NO;
    
    [self setupSaveButton];
    
}

- (void) didClickedColorChangeButton:(id) sender {
    if (self.delegate) {
        [self.delegate keyboardTopView:self didClickedColorChangeButton:sender];
    } else {
        //NSAssert(FALSE, @"You need to assign delete");
    }
}

#pragma mark – Align

- (void) setupAlignArray {
    
    [self removeAllScrollSubButtons];
    
    _backType = Back_Type_Align;
    
    self.scrollView.contentSize = CGSizeMake(K_Item_Width * [self.alignArray count], CGRectGetHeight(self.frame));
    
    for (int i = 0; i<[self.alignArray count]; i++) {
        UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        myButton.tag = i;
        myButton.frame = CGRectMake(i*K_Item_Width, 0, K_Item_Width, CGRectGetHeight(self.frame));
        [myButton titleLabel].font = [UIFont boldSystemFontOfSize:16];
        
        [myButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.scrollView addSubview:myButton];
        
        NSString *title = [NSString stringWithFormat:@"ToolbarItem_Align_%@",self.alignArray[i]];
        [myButton setTitle:NSLocalizedString(title,nil) forState:UIControlStateNormal];
        [myButton addTarget:self action:@selector(didClickedAlignChangeButton:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    self.scrollView.frame = CGRectMake(K_Item_Width, 0, CGRectGetWidth(self.frame) - 2 * K_Item_Width, CGRectGetHeight(self.frame));
    _backImageView.hidden = NO;
    
    [self setupSaveButton];
}

- (void) didClickedAlignChangeButton:(id) sender {
    if (self.delegate) {
        [self.delegate keyboardTopView:self didClickedAlignChangeButton:sender];
    } else {
        //NSAssert(FALSE, @"You need to assign delete");
    }
}

#pragma mark – Size

- (void) setupSizeArray {
    
    [self removeAllScrollSubButtons];
    
    _backType = Back_Type_Size;
    
    self.scrollView.contentSize = CGSizeMake(K_Item_Width * [self.nominalSizeArray count], CGRectGetHeight(self.frame));
    
    for (int i = 0; i<[self.nominalSizeArray count]; i++) {
        UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        myButton.tag = i;
        myButton.frame = CGRectMake(i*K_Item_Width, 0, K_Item_Width, CGRectGetHeight(self.frame));
        [myButton titleLabel].font = [UIFont boldSystemFontOfSize:16];
        
        [myButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.scrollView addSubview:myButton];
        
        NSString *sizeStr = [NSString stringWithFormat:@"%d",[self.nominalSizeArray[i] intValue]];
        [myButton setTitle:sizeStr forState:UIControlStateNormal];
        [myButton addTarget:self action:@selector(didClickedSizeChangeButton:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    self.scrollView.frame = CGRectMake(K_Item_Width, 0, CGRectGetWidth(self.frame) - 2 * K_Item_Width, CGRectGetHeight(self.frame));
    _backImageView.hidden = NO;
    
    [self setupSaveButton];
    
}

- (void) didClickedSizeChangeButton:(id) sender {
    if (self.delegate) {

        [self.delegate keyboardTopView:self didClickedSizeChangeButton:sender];
    } else {
        //NSAssert(FALSE, @"You need to assign delete");
    }
}

#pragma mark – Summary

- (void) setupSummaryArray {
    
    [self removeAllScrollSubButtons];
    
    _backType = Back_Type_Summary;
    
    _toolbarState = Type_Toolbar_State_Main;
    
    self.scrollView.contentSize = CGSizeMake(K_Item_Width * [self.summaryArray count], CGRectGetHeight(self.frame));;
    
    for (int i = 0; i<[self.summaryArray count]; i++) {
        UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        myButton.tag = i;
        myButton.frame = CGRectMake(i*K_Item_Width, 0, K_Item_Width, CGRectGetHeight(self.frame));
        [myButton titleLabel].font = [UIFont boldSystemFontOfSize:16];
        
        [myButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.scrollView addSubview:myButton];
    
        NSString *str = [NSString stringWithFormat:@"ToolbarItem_%@",self.summaryArray[i]];
        [myButton setTitle:NSLocalizedString(str,nil) forState:UIControlStateNormal];
        [myButton addTarget:self action:@selector(didClickedSummaryButton:) forControlEvents:UIControlEventTouchDown];
        
    }
    self.scrollView.frame = self.bounds;
    _backImageView.hidden = YES;
    
    [self setupSaveButton];
    
}

- (void) setupSaveButton {
    if (_saveButton == nil) {
        _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveButton.frame = CGRectMake(CGRectGetWidth(self.frame) - K_Item_Width +10, 0, K_Item_Width - 20, CGRectGetHeight(self.frame));
        [_saveButton setTitle:NSLocalizedString(@"Title_Save",@"") forState:UIControlStateNormal];
        _saveButton.backgroundColor = [UIColor clearColor];
        [_saveButton addTarget:self action:@selector(didClickedSaveButton:) forControlEvents:UIControlEventTouchDown];
    }
    if (_saveButton.superview == nil) {
        [self addSubview:_saveButton];
    }
    
}


- (void) didClickedSaveButton:(id) sender {
    
    if (self.delegate) {
        [self.delegate keyboardTopView:self didClickedSaveButton:sender];
    } else {
        //NSAssert(FALSE, @"You need to assign delete");
    }
    
}

- (void) didClickedSummaryButton:(id) sender {
    long index = ((UIButton *) sender).tag;
    
    switch (index) {
        case 0:
            _toolbarState = Type_Toolbar_State_Align;
            [self setupAlignArray];
            break;
        case 1:
            _toolbarState = Type_Toolbar_State_Size;
            [self setupSizeArray];
            break;
        case 2:
            _toolbarState = Type_Toolbar_State_Color;
            [self setupColorArray];
            break;
        case 3:
            _toolbarState = Type_Toolbar_State_Font;
            [self setupFontArray];
            break;
        case 4:
            break;
        case 5:
            
            break;
        default:
            break;
    }
    
    if (self.delegate) {
        //TODO
        [self.delegate keyboardTopView:self didClickedMainButton:sender];
    } else {
        //NSAssert(FALSE, @"You need to assign delete");
    }
    
}


#pragma mark – Common

- (void) didClickedBackButton {
    [self setupSummaryArray];
}

-(NSArray *) getCurrentButtonArray {
    NSMutableArray *returnArray = [NSMutableArray array];
    
    for (UIView *v in self.scrollView.subviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            [returnArray addObject:v];
        }
    }
    
    return returnArray;
}

- (void) scrollToButtonIndex:(int) index {
    
    int offsetX = 0;
    int screenWidth = [Common getScreenWidthInLandscape];
    
    if (self.scrollView.contentSize.width <= screenWidth) {
        self.scrollView.contentOffset = CGPointMake(0,0);
    } else {
        if (index*K_Item_Width > screenWidth/2) {
            offsetX = index*K_Item_Width - screenWidth/2;
        }
        self.scrollView.contentOffset = CGPointMake(offsetX,0);
    }
 
}


@end
