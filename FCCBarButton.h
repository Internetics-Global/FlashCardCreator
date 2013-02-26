//
//  FCCBarButton.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 26/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FCCBarButton : UIButton

+ (UIButton*)buttonWithImage:(UIImage*)image target:(id)target action:(SEL)action;

@end
