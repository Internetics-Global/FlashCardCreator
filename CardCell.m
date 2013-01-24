//
//  CardCell.m
//  FlashCardCreator
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
    self.contentView.frame = CGRectMake(0, 0, 480, 100);
    
    _indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, 40, 20)];
    _indexLabel.text = @"N";
    _indexLabel.textColor = [UIColor whiteColor];
    _indexLabel.font = [UIFont systemFontOfSize:17];
    _indexLabel.backgroundColor = [UIColor clearColor];
    _indexLabel.textAlignment = UITextAlignmentCenter;
    [self.contentView addSubview:_indexLabel];
    
    _cellImageView = [[UIImageView alloc] initWithFrame:CGRectMake(60, 10, 80, 80)];
    _cellImageView.layer.cornerRadius = 10;
    _cellImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:_cellImageView];
}

- (void) setupViewForiPad {
    self.contentView.frame = CGRectMake(0, 0, 320, 200);
    
    _indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 40, 40)];
    _indexLabel.text = @"N";
    _indexLabel.textColor = [UIColor whiteColor];
    _indexLabel.font = [UIFont systemFontOfSize:17];
    _indexLabel.backgroundColor = [UIColor clearColor];
    _indexLabel.textAlignment = UITextAlignmentCenter;
    [self.contentView addSubview:_indexLabel];
    
    _cellImageView = [[UIImageView alloc] initWithFrame:CGRectMake(40, 10, 250, 180)];
    _cellImageView.layer.cornerRadius = 10;
    _cellImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:_cellImageView];
}

@end
