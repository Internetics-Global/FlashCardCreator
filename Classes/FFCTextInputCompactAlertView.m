//
//  FFCAlertView.m
//  CustomIOSAlertView
//
//  Created by Liang Wang on 2/22/17.
//  Copyright © 2017 Wimagguc. All rights reserved.
//

#import "FFCTextInputCompactAlertView.h"
#import "CustomIOSAlertView.h"

@interface FFCTextInputCompactAlertView () {
    UITextView *_textInputView;
    NSString   *_message;
}

@end

@implementation FFCTextInputCompactAlertView


- (void) showAlertViewWithMessage:(NSString *)message buttonTitles:(NSArray *)buttonTitles {
    
    _message = message;
    
    CustomIOSAlertView *alertView = [[CustomIOSAlertView alloc] init];
    
    [alertView setContainerView:[self createDemoView]];
    
    [alertView setButtonTitles:buttonTitles];
    
    [alertView setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
        NSString *textInputStr = _textInputView.text;
        [alertView close];
        if (self.completion) {
            [_textInputView resignFirstResponder];
            self.completion(buttonIndex,textInputStr);
        }
    }];
    alertView.useMotionEffects = true;
    
    [alertView show];
}




- (UIView *)createDemoView
{
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 110)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 270, 40)];
    [titleLabel setTextColor:[UIColor blackColor]];
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = _message;
    titleLabel.backgroundColor = [UIColor clearColor];
    [demoView addSubview:titleLabel];
    
    _textInputView = [[UITextView alloc] initWithFrame:CGRectMake(10, 60, 270, 30)];
    _textInputView.layer.borderColor = [UIColor blackColor].CGColor;
    _textInputView.layer.borderWidth = 1;
    _textInputView.text = _defaultTextInputValue;
    [_textInputView becomeFirstResponder];
    [demoView addSubview:_textInputView];
    
    return demoView;
}

- (void)dealloc {
    
}

@end
