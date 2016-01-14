//
//  UIImageView+Extensions.h
//  NoiseMeter
//
//  Created by Bourne Wang on 26/02/2015.
//  Copyright (c) 2015 Internetics Pty Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Extensions)

@property(nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;


/**
 *  if the color at the point of view is transparent, we simple ignore it.
 *  By default, it's false. It's an addition to hitTestEdgeInsets
 */
@property(nonatomic, assign) BOOL     bypassTransparentColor;


@end
