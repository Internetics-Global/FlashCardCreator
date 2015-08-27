//
//  CreatePackViewController2.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 20/04/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Pack;
@class TPKeyboardAvoidingScrollView;
@class ASValueTrackingSlider;

@interface CreateEditPackViewController2 : UIViewController

@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollview;


@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;

@property (weak, nonatomic) IBOutlet UITextField *packNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *sidebarTextField;
@property (weak, nonatomic) IBOutlet UITextField *creatorTextField;
@property (weak, nonatomic) IBOutlet UITextField *jobTitleTextField;

@property (weak, nonatomic) IBOutlet UITextField *adminPasswordTextField;

@property (weak, nonatomic) IBOutlet UITextField *cofirmAminPasswordTextField;

@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *autoPlaySpeedSlider;




@property (strong, nonatomic)  Pack *currentPack;

/*
 * this is used to determine whether it's a new pack(create pack) nor existing pack (edit pack)
 * if false, or no assignment, new pack
 * if true, editing a current pack
 */
@property (assign, nonatomic)  BOOL isEditPack;

@end
