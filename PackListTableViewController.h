//
//  PackListTableViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 18/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PackListDelegate
- (void)packListSelected:(int) index;
@end

@interface PackListTableViewController : UITableViewController {
    id<PackListDelegate> __weak _delegate;
}

@property (weak, nonatomic) id<PackListDelegate> delegate;


@end
