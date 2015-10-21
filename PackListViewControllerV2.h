//
//  PackListViewControllerV2.h
//  FFC
//
//  Created by Bourne Wang on 7/17/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PackListViewControllerV2 : UICollectionViewController

@property (nonatomic, assign) NSInteger packIDInMasterView;

@property (weak, nonatomic) UIPopoverController *popController;

@end
