//
//  ColorPageControl.m
//  taobao4iphone
//
//  Created by Xu Jiwei on 11-4-22.
//  Copyright 2011 Taobao.com. All rights reserved.
//

#import "ColorPageControl.h"


#define kPageBallWidth      8.0

#define kPageBallGap        6.0


@implementation ColorPageControl

@synthesize currentPage;
@synthesize numberOfPages;
@synthesize hidesForSinglePage;
@synthesize normalPageColor;
@synthesize currentPageColor;
@synthesize type;
@synthesize width;
@synthesize height;
@synthesize gap;

#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.normalPageColor = [UIColor colorWithWhite:185/255.0 alpha:1.0];
        self.currentPageColor = [UIColor colorWithWhite:133/255.0 alpha:1.0];
        self.backgroundColor = [UIColor clearColor];
        width = kPageBallWidth;
        height = kPageBallWidth;
        gap = kPageBallGap;
    }
    
    return self;
}


#pragma mark -
#pragma mark Properties

- (void)setCurrentPage:(NSInteger)page {
    currentPage = page;
    [self setNeedsDisplay];
}


- (void)setNumberOfPages:(NSInteger)count {
    numberOfPages = count;
    [self setNeedsDisplay];
}


- (void)setHidesForSinglePage:(BOOL)hides {
    hidesForSinglePage = hides;
    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch) {
        CGPoint point = [touch locationInView:self];
        CGSize size = self.bounds.size;
        float x = ceil((size.width - (width * numberOfPages) - (gap * (numberOfPages-1))) / 2.0);
        float currentPageX = x + currentPage * (width + gap);
        int offset = 0;
        if (point.x > currentPageX + width) {
            offset = 1;
        } else if (point.x < currentPageX) {
            offset = -1;
        }
        
        if (offset != 0 && (currentPage + offset >= 0 && currentPage + offset < numberOfPages)) {
            currentPage += offset;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
}


#pragma mark -
#pragma mark View

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!hidesForSinglePage || numberOfPages > 1) {
        CGSize size = rect.size;
        float x = ceil((size.width - (width * numberOfPages) - (gap * (numberOfPages-1))) / 2.0);
        float y = ceil((size.height - height) / 2.0);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        for (int i = 0; i < numberOfPages; ++i) {
            CGContextSaveGState(context);
            
            UIColor *ballColor = (i == currentPage) ? currentPageColor : normalPageColor;
            [ballColor setFill];
            
            if (type == kRoundPageControl) {
                CGContextFillEllipseInRect(context, CGRectMake(x, y, width, height));                
            } else {
                CGContextFillRect(context, CGRectMake(x, y, width, height));
            }

            
            CGContextRestoreGState(context);
            
            x += width + gap;
        }
    }
}


@end
