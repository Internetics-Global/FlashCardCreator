//
//  PackListViewController.h
//  PackList
//
//  Created by Wang Bourne on 3/01/13.
//  Copyright (c) 2013 temp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PackListView.h"

@interface PackListViewController : UIViewController <UIScrollViewDelegate> {
    NSMutableArray *_imageArray;
    PackListView     *_packListView;
}

@property (strong, nonatomic) NSMutableArray *imageArray;;

@end
