//
//  UITextField+AutoResizeFont.m
//  FlashCardCreator
//
//  Created by Internetics on 4/01/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "UITextField+AutoResizeFont.h"

@implementation UITextField (AutoResizeFont)


- (void)adjustFontSizeToFitVertically:(BOOL) isVertically {
    
    UIFont *originalfont = self.font;
    UIFont *newFont      = originalfont;
    
    CGSize frameSize = self.frame.size;
    
    for (CGFloat maxSize = self.font.pointSize; maxSize >= self.minimumFontSize; maxSize -= 1.f) {
        
        newFont = [originalfont fontWithSize:maxSize];
        
        NSAttributedString *attributedText =  [[NSAttributedString alloc] initWithString:self.text
                                                                              attributes:@ { NSFontAttributeName: newFont  }];
        
        
        //我们认为，无论isVertically如何，在计算时，取小的
        CGRect labelRect = [attributedText boundingRectWithSize:(CGSize){CGFLOAT_MAX, MIN(frameSize.height, frameSize.width)} options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        
        BOOL isResizeNecessary = NO;
        if (isVertically) {
            //在竖直的文本中， frameSize是个类似的值(width = 60, height = 400),而labelSize是（width = 760, height = 23)。两者方向不一样
            if(labelRect.size.width >= frameSize.height) {
                isResizeNecessary = YES;
                
                //NSLog(@"%f-- %f",labelRect.size.width,frameSize.height);
            }
        } else {
            if(labelRect.size.width >= frameSize.width) {
                isResizeNecessary = YES;
                //NSLog(@"%f-- %f",labelRect.size.width,frameSize.height);
            }
            
        }
        if(isResizeNecessary) {
            
        } else {
            break;
        }
    }
    
    self.font = newFont;
    [self setNeedsLayout];
    return;
    
}

- (void)adjustFontSizeToFit {
    [self adjustFontSizeToFitVertically:false];
}

@end
