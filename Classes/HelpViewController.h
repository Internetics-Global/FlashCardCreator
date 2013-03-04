//
//  ScrollingViewController.h
//
//  Created by Wang Bourne on 04/03/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController:UIViewController <UIScrollViewDelegate>
{
	IBOutlet UIScrollView *_scrollView;
	IBOutlet UIPageControl *_pageControl;
	
    BOOL pageControlIsChangingPage;
}

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl* pageControl;

@end

