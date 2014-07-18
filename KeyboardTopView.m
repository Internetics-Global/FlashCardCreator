//
//  KeyboardTopView.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 7/18/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "KeyboardTopView.h"

#define K_Item_Width  80
#define K_Item_Font_Width  80

@interface KeyboardTopView() {
    Back_Type _backType;
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
    
    self.scrollView = [ [UIScrollView alloc ] initWithFrame:self.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.scrollView.userInteractionEnabled = YES;
    self.scrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    //    scrollView.contentOffset = CGPointMake(60, 0);
    self.scrollView.directionalLockEnabled = YES; //默认行为是允许用户同时进行横向和纵向的滚动。将这个属性设置为YES会导致将用户的滚动行为锁定成只允许横向或纵向进行，具体方向由初始姿态决定。
    self.scrollView.bounces = YES;
    self.scrollView.pagingEnabled = NO;
    [self addSubview:self.scrollView];
    
    self.sizeArray = @[@"Back",@12,@18,@24,@28,@32,@36,@40,@45,@50,@55,@60,@80,@100,@160,@260];
    self.colorArray = @[@"Back",@"Red",@"Blue",@"Black",@"Yellow",@"Green",@"White"];
    self.alignArray = @[@"Back",@"Left",@"Center",@"Right",@"Justify",@"Vertical"];
    self.fontArray = @[@"Back",@"Default",@"Arial-BoldMT",@"Chalkduster",@"Courier",@"Papyrus"];
    self.summaryArray = @[@"Align",@"Size",@"Color",@"Font",@"Symbol",@"Done"];
    
    _backType = Back_Type_Unkown;
    
}


- (void) removeAllScrollSubButtons {
    for (UIView *v in self.scrollView.subviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            [v removeFromSuperview];
        }
    }
}

#pragma mark – Font

- (void) setupFontArray {
    
    [self removeAllScrollSubButtons];
    
    _backType = Back_Type_Font;
    
    self.scrollView.contentSize = CGSizeMake(K_Item_Font_Width * [self.fontArray count], CGRectGetHeight(self.frame));
    
    for (int i = 0; i<[self.fontArray count]; i++) {
        UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        myButton.tag = i;
        myButton.frame = CGRectMake(i*K_Item_Font_Width, 0, K_Item_Font_Width, CGRectGetHeight(self.frame));
        [myButton titleLabel].font = [UIFont boldSystemFontOfSize:12];
        
        [myButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.scrollView addSubview:myButton];
        
        if (i ==0) {
            [myButton setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
            [myButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            [myButton addTarget:self action:@selector(didClickedBackButton:) forControlEvents:UIControlEventTouchDown];
        } else {
            NSString *title = self.fontArray[i];
            [myButton setTitle:NSLocalizedString(title,nil) forState:UIControlStateNormal];
            [myButton addTarget:self action:@selector(didClickedFontChangeButton:) forControlEvents:UIControlEventTouchDown];
        }
    
    }
    
    
}

- (void) didClickedFontChangeButton:(id) sender {
    if (self.delegate) {
        [self.delegate keyboardTopView:self didClickedFontChangeButtonAtIndex:sender];
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
        
        if (i ==0) {
            [myButton setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
            [myButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            [myButton addTarget:self action:@selector(didClickedBackButton:) forControlEvents:UIControlEventTouchDown];
        } else {
            NSString *title = [NSString stringWithFormat:@"ToolbarItem_Color_%@",self.colorArray[i]];
            [myButton setTitle:NSLocalizedString(title,nil) forState:UIControlStateNormal];
            [myButton addTarget:self action:@selector(didClickedColorChangeButton:) forControlEvents:UIControlEventTouchDown];
        }
        
    }
    
    
}

- (void) didClickedColorChangeButton:(id) sender {
    [self setupSummaryArray];
    if (self.delegate) {
        [self.delegate keyboardTopView:self didClickedColorChangeButtonAtIndex:sender];
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
        
        if (i ==0) {
            [myButton setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
            [myButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            [myButton addTarget:self action:@selector(didClickedBackButton:) forControlEvents:UIControlEventTouchDown];
        } else {
            NSString *title = [NSString stringWithFormat:@"ToolbarItem_Align_%@",self.alignArray[i]];
            [myButton setTitle:NSLocalizedString(title,nil) forState:UIControlStateNormal];
            [myButton addTarget:self action:@selector(didClickedAlignChangeButton:) forControlEvents:UIControlEventTouchDown];
        }
        
    }
    
    
}

- (void) didClickedAlignChangeButton:(id) sender {
    if (self.delegate) {
        [self.delegate keyboardTopView:self didClickedAlignChangeButtonAtIndex:sender];
    } else {
        //NSAssert(FALSE, @"You need to assign delete");
    }
}

#pragma mark – Size

- (void) setupSizeArray {
    
    [self removeAllScrollSubButtons];
    
    _backType = Back_Type_Size;
    
    self.scrollView.contentSize = CGSizeMake(K_Item_Width * [self.sizeArray count], CGRectGetHeight(self.frame));
    
    for (int i = 0; i<[self.sizeArray count]; i++) {
        UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        myButton.tag = i;
        myButton.frame = CGRectMake(i*K_Item_Width, 0, K_Item_Width, CGRectGetHeight(self.frame));
        [myButton titleLabel].font = [UIFont boldSystemFontOfSize:16];
        
        [myButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.scrollView addSubview:myButton];
        
        if (i ==0) {
            [myButton setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
            [myButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            [myButton addTarget:self action:@selector(didClickedBackButton:) forControlEvents:UIControlEventTouchDown];
        } else {
            NSString *title = [NSString stringWithFormat:@"ToolbarItem_Size%@",self.sizeArray[i]];
            [myButton setTitle:NSLocalizedString(title,nil) forState:UIControlStateNormal];
            [myButton addTarget:self action:@selector(didClickedSizeChangeButton:) forControlEvents:UIControlEventTouchDown];
        }
        
    }
    
    
}

- (void) didClickedSizeChangeButton:(id) sender {
    if (self.delegate) {
        [self.delegate keyboardTopView:self didClickedFontChangeButtonAtIndex:sender];
    } else {
        //NSAssert(FALSE, @"You need to assign delete");
    }
}

#pragma mark – Summary

- (void) setupSummaryArray {
    
    [self removeAllScrollSubButtons];
    
    _backType = Back_Type_Summary;
    
    self.scrollView.contentSize = self.frame.size;
    
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
        
        if (i == [self.summaryArray count] - 1) {
            CGRect rect = myButton.frame;
            rect.origin.x = CGRectGetWidth(self.frame) - CGRectGetWidth(myButton.frame) - 5;
            myButton.frame = rect;
            
        }
        
    }
    
    
}

- (void) didClickedSummaryButton:(id) sender {
    int index = ((UIButton *) sender).tag;
    
    switch (index) {
        case 0:
            [self setupAlignArray];
            break;
        case 1:
            [self setupSizeArray];
            break;
        case 2:
            [self setupColorArray];
            break;
        case 3:
            [self setupFontArray];
            break;
        case 4:
            if (self.delegate) {
                //TODO
                [self.delegate keyboardTopView:self didClickedSymbolButton:sender];
            } else {
                //NSAssert(FALSE, @"You need to assign delete");
            }
            break;
        case 5:
            if (self.delegate) {
                //TODO
                [self.delegate keyboardTopView:self didClickedDoneButton:sender];
            } else {
                //NSAssert(FALSE, @"You need to assign delete");
            }
            break;
        default:
            break;
    }
    
}


#pragma mark – Common 

- (void) didClickedBackButton:(id) sender {
    [self setupSummaryArray];
}


@end
