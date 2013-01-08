//
//  DetailViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (retain, nonatomic) IBOutlet UILabel *questionTitleLabel;
@property (retain, nonatomic) IBOutlet UILabel *questionContentLabel;
@property (retain, nonatomic) IBOutlet UILabel *answerTitleLabel;
@property (retain, nonatomic) IBOutlet UILabel *answerContentLabel;

@end
