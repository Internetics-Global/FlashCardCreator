//
//  PackListCell.m
//  FFC
//
//  Created by Bourne Wang on 7/17/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "PackListCell.h"
#import "User.h"
#import "Pack.h"
#import "OpenUDID.h"
#import "FileOperationHelper.h"
#import "AppDelegate.h"
#import "MutipleTargetHelper.h"

@implementation PackListCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void) setupView{
    
    self.contentView.autoresizingMask = UIViewAutoresizingNone;
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 250, 250)];
    contentView.autoresizingMask = UIViewAutoresizingNone;
    contentView.backgroundColor = [UIColor clearColor];

    self.packNameText = [[UITextField alloc] initWithFrame:CGRectMake(40.0f, 10.0f, 250 -80, 25.0f)];
    self.packNameText.textAlignment = NSTextAlignmentCenter;
    self.packNameText.font = [UIFont systemFontOfSize:16];
    self.packNameText.returnKeyType = UIReturnKeyDone;
    self.packNameText.layer.cornerRadius = 5;
    self.packNameText.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.packNameText.layer.masksToBounds = YES;
    self.packNameText.textColor = [UIColor whiteColor];
    self.packNameText.userInteractionEnabled = YES;
    self.packNameText.autoresizingMask = UIViewAutoresizingNone;
    [contentView addSubview:    self.packNameText];

    
    self.coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(40.0f, 35, 250 - 80, 250 - 80)];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.coverImageView.layer.cornerRadius = 10;
    self.coverImageView.layer.masksToBounds = YES;
    self.coverImageView.autoresizingMask = UIViewAutoresizingNone;
    [contentView addSubview:self.coverImageView];
    
    self.maskImageView = [[UIImageView alloc] initWithFrame:self.coverImageView.frame];
    self.maskImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.maskImageView.layer.cornerRadius = 10;
    self.maskImageView.layer.masksToBounds = YES;
    self.maskImageView.backgroundColor =[UIColor clearColor];
    self.maskImageView.autoresizingMask = UIViewAutoresizingNone;
    [contentView addSubview:self.maskImageView];
    
    self.lockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.coverImageView.frame) - 31, CGRectGetMinY(self.coverImageView.frame) + 5, 24, 24)];
    self.lockImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.lockImageView.layer.cornerRadius = 10;
    self.lockImageView.layer.masksToBounds = YES;
    [self.lockImageView setImage:[UIImage imageNamed:@"lock"]];
    self.lockImageView.autoresizingMask = UIViewAutoresizingNone;
    [contentView addSubview:self.lockImageView];
    
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playButton.frame = CGRectMake(145, 140, 50, 50);
    self.playButton.backgroundColor = [UIColor clearColor];
    [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    self.playButton.autoresizingMask = UIViewAutoresizingNone;
    [contentView addSubview:self.playButton];
    
    self.gotoPackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.gotoPackButton.frame = CGRectMake(55, 140, 50, 50);
    self.gotoPackButton.backgroundColor = [UIColor clearColor];
    [self.gotoPackButton setImage:[UIImage imageNamed:@"editPackList"] forState:UIControlStateNormal];
    self.gotoPackButton.autoresizingMask = UIViewAutoresizingNone;
    [contentView addSubview:self.gotoPackButton];
    if ([MutipleTargetHelper isFullVersion] == false) {
        self.gotoPackButton.enabled = false;
        self.gotoPackButton.alpha = 0.5;
    }
    
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.deleteButton setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
    [self.deleteButton setBackgroundColor:[UIColor clearColor]];
//    self.deleteButton.layer.borderColor = [UIColor redColor].CGColor;
//    self.deleteButton.layer.borderWidth = 1;
    [self.deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.deleteButton.tag = index;
    self.deleteButton.userInteractionEnabled = TRUE;
    self.deleteButton.frame = CGRectMake(40.0f, 205.0f, 88, 25);
    [contentView addSubview:self.deleteButton];
    
    self.editPackSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.editPackSettingButton setImage:[UIImage imageNamed:@"edit_pack_button"] forState:UIControlStateNormal];
    [self.editPackSettingButton setBackgroundColor:[UIColor clearColor]];
    [self.editPackSettingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.editPackSettingButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.editPackSettingButton.tag = index;
    self.editPackSettingButton.userInteractionEnabled = TRUE;
    self.editPackSettingButton.frame = CGRectMake(self.bounds.size.width - 40.0f - 88, 205.0f, 88, 25);
    [contentView addSubview:self.editPackSettingButton];
    
    
    [self.contentView addSubview:contentView];
}

@end
