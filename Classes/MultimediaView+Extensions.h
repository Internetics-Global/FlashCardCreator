//
//  MultimediaView+MultimediaView___Extensions.h
//  FlashCardCreator
//
//  Created by internetics on 21/10/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

// ***** important notice *****
// the logic is Same as UIImageView+Extensions.h
// ***** important notice *****

#import <UIKit/UIKit.h>
#import "MultimediaView.h"

@interface MultimediaView (Extensions)

@property(nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;


/**
 *  if the color at the point of view is transparent, we simple ignore it.
 *  By default, it's false. It's an addition to hitTestEdgeInsets
 */
@property(nonatomic, assign) BOOL     bypassTransparentColor;


@end
