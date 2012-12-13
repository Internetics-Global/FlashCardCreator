//
//  DetailViewController.h
//  FlashCardCreator
//
//  Created by Clive France on 13/12/2012.
//  Copyright (c) 2012 Clive France. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
