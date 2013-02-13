//
//  AboutViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "AboutViewController.h"
#import "SimpleWebBrowserController.h"

@implementation AboutViewController

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	
	self.title = @"About Us";
	
	UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] applicationFrame].size.width, self.navigationController.view.frame.size.height - self.navigationController.navigationBar.frame.size.height)];
	self.view = contentView;
	self.view.backgroundColor = [UIColor blackColor];
	
	scroller = [[UIScrollView alloc] initWithFrame:self.view.frame];
	AboutView *about = [[AboutView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	scroller.contentSize = CGSizeMake(about.frame.size.width, about.frame.size.height);
	[about.linkButton addTarget:self action:@selector(web) forControlEvents:UIControlEventTouchUpInside];
	[scroller addSubview:about];
	[self.view addSubview:scroller];
}

-(void)web{
	NSURL *url = [NSURL URLWithString:@"http://www.internetics.net.au"];
    SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
    controller.hidesToolbar = NO;
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        controller.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:controller animated:YES];
    }
}


@end
