//
//  UIImage+Scale.m
//  FFC
//
//  Created by Wang Bourne on 21/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (Scale)

//in order not to distore, we only use size.height
- (UIImage *)scaleToSize:(CGSize)size{
    CGFloat ratio = self.size.width/self.size.height;
    CGFloat ratio2 = size.width/size.height;
    CGSize realSize;
    if (ratio > ratio2) {
      realSize = CGSizeMake(size.width, size.width/ratio );
    } else {
      realSize = CGSizeMake(size.height*ratio, size.height);
    }
    
    //确保最终的图片至少大于size
    float widthRatio = size.width/realSize.width;
    float heightRatio = size.height/realSize.height;
    if (widthRatio >1 || heightRatio > 1) {
        float finalRatio = widthRatio > heightRatio ? widthRatio:heightRatio;
        realSize.width = realSize.width * finalRatio;
        realSize.height = realSize.height * finalRatio;
    }
    
    CGSize roundedRealSize;
    roundedRealSize.width = (int)realSize.width;
    roundedRealSize.height = (int) realSize.height;
    
    UIGraphicsBeginImageContext(roundedRealSize);
    [self drawInRect:CGRectMake(0, 0, roundedRealSize.width, roundedRealSize.height)];

    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return scaledImage;
}

@end
