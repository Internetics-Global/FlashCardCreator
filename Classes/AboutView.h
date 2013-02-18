//
//  AboutView.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutView : UIView {
	UITextView *textView;
	UIButton *linkButton;
	UIButton *background;
}

@property (nonatomic, readonly) UIButton *linkButton;

@end
