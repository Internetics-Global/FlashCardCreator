//
//  ImageTableViewCell.h
//  NSOperationTest
//
//  Created by jhwang on 11-10-30.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ImageTableViewCell : UITableViewCell {
    UILabel *txtLabel;
    UIImageView *imageView;
}
@property(nonatomic, retain)IBOutlet UILabel *txtLabel;
@property(nonatomic, retain)IBOutlet UIImageView *imageView;

- (void)setCell:(UIImage *)image text:(NSString *)text;

@end
