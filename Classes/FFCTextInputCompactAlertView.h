//
//  FFCAlertView.h
//  CustomIOSAlertView
//
//  Created by Liang Wang on 2/22/17.
//  Copyright © 2017 Wimagguc. All rights reserved.
//


@interface FFCTextInputCompactAlertView : NSObject

@property (copy, nonatomic) void (^completion)(NSInteger,NSString*);

@property (copy, nonatomic) NSString *defaultTextInputValue;

- (void) showAlertViewWithMessage:(NSString *)message buttonTitles:(NSArray *)buttonTitles;

@end
