//
//  UIImage+Scale.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 21/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (Scale)

//in order not to distore, we only use size.height
- (UIImage *)scaleToSize:(CGSize)size{
    CGFloat ratio = self.size.width/self.size.height;
    CGSize realSize = CGSizeMake(size.height*ratio, size.height);
    UIGraphicsBeginImageContext(realSize);
    [self drawInRect:CGRectMake(0, 0, realSize.width, realSize.height)];

    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return scaledImage;
}

@end
