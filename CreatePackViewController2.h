//
//  CreatePackViewController2.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 20/04/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreatePackViewController2 : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;

@property (weak, nonatomic) IBOutlet UITextField *packNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *sidebarTextField;
@property (weak, nonatomic) IBOutlet UITextField *creatorTextField;
@property (weak, nonatomic) IBOutlet UITextField *jobTitleTextField;
@property (weak, nonatomic) IBOutlet UITextField *autoPlaySpeedTextField;

@end
