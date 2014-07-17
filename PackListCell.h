//
//  PackListCell.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 7/17/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PackListCell : UICollectionViewCell

@property (strong, nonatomic) UIImageView *coverImageView;
@property (strong, nonatomic) UITextField *packNameText;
@property (strong, nonatomic) UIButton    *deleteButton;
@property (strong, nonatomic) UIButton    *changeImageButton;
@property (strong, nonatomic) UIButton    *playButton;

@end
