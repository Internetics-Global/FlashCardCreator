//
//  CardCell.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 16/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMMoveTableViewCell.h"

@interface CardCell : FMMoveTableViewCell {
    UILabel *_indexLabel;
    UIImageView *_cellImageView;
}

@property (strong, nonatomic) UILabel *indexLabel;
@property (strong, nonatomic) UIImageView *cellImageView;

@end
