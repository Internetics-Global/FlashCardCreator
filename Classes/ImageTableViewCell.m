//
//  ImageTableViewCell.m
//  NSOperationTest
//
//  Created by jhwang on 11-10-30.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "ImageTableViewCell.h"


@implementation ImageTableViewCell
@synthesize imageView;
@synthesize txtLabel;


- (void)dealloc
{
    [imageView release];
    [txtLabel release];
    [super dealloc];
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}

- (void)setCell:(UIImage *)image text:(NSString *)text
{
    if (image != nil)
    {
        self.imageView.image = image;
    }
    
    self.txtLabel.text = text;
}

@end
