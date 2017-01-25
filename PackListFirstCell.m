//
//  PackListFirstCell.m
//  FFC
//
//  Created by Bourne Wang on 7/17/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "PackListFirstCell.h"
#import "MutipleTargetHelper.h"

@implementation PackListFirstCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        {
            self.addNewPackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(85.0f, 0.0f, 80, 80)];
            self.addNewPackImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.addNewPackImageView.layer.cornerRadius = 10;
            self.addNewPackImageView.layer.masksToBounds = YES;
            
            if ([MutipleTargetHelper isFullVersion]) {
                self.addNewPackImageView.image = [UIImage imageNamed:@"create_new_pack.png"];
            } else {
                self.addNewPackImageView.image = [UIImage imageNamed:@"create_new_pack.png"];
                self.addNewPackImageView.alpha = 0.6;
            }
            
            [self.contentView addSubview:self.addNewPackImageView];
            
            UILabel *desLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, 250, 20)];
            desLabel.textAlignment = NSTextAlignmentCenter;
            desLabel.font = [UIFont boldSystemFontOfSize:20];
            desLabel.text = NSLocalizedString(@"Title_Create_A_Pack",@"");
            desLabel.numberOfLines = 1;
            
            if ([MutipleTargetHelper isFullVersion]) {
                desLabel.textColor = [UIColor whiteColor];
                desLabel.alpha = 1;
            } else {
                desLabel.textColor = [UIColor darkGrayColor];
                desLabel.alpha = 0.7;
            }
            
            desLabel.backgroundColor = [UIColor clearColor];
            [self.contentView addSubview:desLabel];
        }
        
        {
            self.libraryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(85.0f, 120.0f, 80, 80)];
            self.libraryImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.libraryImageView.layer.cornerRadius = 10;
            self.libraryImageView.layer.masksToBounds = YES;
            
            if ([MutipleTargetHelper isFullVersion]) {
                self.libraryImageView.image = [UIImage imageNamed:@"ffc_library.png"];
            } else {
                self.libraryImageView.image = [UIImage imageNamed:@"ffc_library.png"];
                self.libraryImageView.alpha = 0.6;
            }
            
            [self.contentView addSubview:self.libraryImageView];
            
            UILabel *desLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 210, 250, 20)];
            desLabel.textAlignment = NSTextAlignmentCenter;
            desLabel.font = [UIFont boldSystemFontOfSize:20];
            desLabel.text = NSLocalizedString(@"Title_FFC_Library",@"");
            desLabel.numberOfLines = 1;
            
            if ([MutipleTargetHelper isFullVersion]) {
                desLabel.textColor = [UIColor whiteColor];
                desLabel.alpha = 1;
            } else {
                desLabel.textColor = [UIColor darkGrayColor];
                desLabel.alpha = 0.7;
            }
            
            desLabel.backgroundColor = [UIColor clearColor];
            [self.contentView addSubview:desLabel];

        }
        
        
    }
    return self;
}

@end
