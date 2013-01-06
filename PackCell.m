//
//  PackCell.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 16/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "PackCell.h"

@implementation PackCell

#pragma mark -
#pragma mark Initialization

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

    // Configure the view for the selected state
}

@end
