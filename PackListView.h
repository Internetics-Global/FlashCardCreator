//
//  PackListView.h
//  PackList
//
//  Created by Wang Bourne on 4/01/13.
//  Copyright (c) 2013 temp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PackThumbImageView.h"

@interface PackListView : UIView <UIScrollViewDelegate, PackThumbImageViewDelegate> {
    UIScrollView    *_scrollView;
    UIPageControl   *_pageControl;
    BOOL            _showPageControl;
    NSMutableArray *_imageArray;
}

@property (strong, nonatomic) NSMutableArray *imageArray;

@end
