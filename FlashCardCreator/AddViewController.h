//
//  AddViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 17/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pack.h"
#import "Card.h"

@interface AddViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate> {
    BOOL _isNewPack;
    Pack *_pack;
    Card *_card;
    NSMutableArray *_availablePackNameArray;
    NSMutableArray *_availablePackArray;
}

@property (strong, nonatomic) IBOutlet UIPickerView *myPackPickerView;
@property (strong, nonatomic) IBOutlet UITextField *packTextField;


@end
