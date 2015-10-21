//
//  CardCell.m
//  FFC
//
//  Created by Wang Bourne on 16/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "CardCell.h"

@implementation CardCell

@synthesize indexLabel = _indexLabel;
@synthesize cellImageView = _cellImageView;


#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        if (isUserInterfaceIdiomPhone) {
            [self setupViewForiPhone];
        } else {
            [self setupViewForiPad];
        }
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setupViewForiPhone {
    
    UIView *contentView =
    [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height)];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:contentView];
    
    _indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kCellSizeHeight_iPhone/2-10, 30, 20)];
    _indexLabel.text = @"N";
    _indexLabel.textColor = [UIColor grayColor];
    _indexLabel.font = [UIFont systemFontOfSize:17];
    _indexLabel.backgroundColor = [UIColor clearColor];
    _indexLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_indexLabel];
    
    _cellImageView = [[UIImageView alloc] initWithFrame:CGRectMake(30, 10, 100, kCellSizeHeight_iPhone-20)];
    _cellImageView.layer.cornerRadius = 5;
    _cellImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:_cellImageView];
}

- (void) setupViewForiPad {
    
    UIView *contentView =
    [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height)];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:contentView];
    
    _indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kCellSizeHeight_iPad/2-10, 30, 20)];
    _indexLabel.text = @"N";
    _indexLabel.textColor = [UIColor grayColor];
    _indexLabel.font = [UIFont systemFontOfSize:17];
    _indexLabel.backgroundColor = [UIColor clearColor];
    _indexLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_indexLabel];
    
    _cellImageView = [[UIImageView alloc] initWithFrame:CGRectMake(30, 10, (kCellSizeWidth-40), (kCellSizeHeight_iPad-26))];
    _cellImageView.layer.cornerRadius = 10;
    _cellImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:_cellImageView];
}

@end
