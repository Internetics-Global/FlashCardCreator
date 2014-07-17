//
//  PackListFirstCell.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 7/17/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "PackListFirstCell.h"

@implementation PackListFirstCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.addNewPackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 250, 250)];
        self.addNewPackImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.addNewPackImageView.layer.cornerRadius = 10;
        self.addNewPackImageView.layer.masksToBounds = YES;
        self.addNewPackImageView.image = [UIImage imageNamed:@"create_new_pack.png"];
        [self.contentView addSubview:self.addNewPackImageView];
    }
    return self;
}

@end
