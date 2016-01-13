//
//  AboutViewController.m
//  FFC
//
//  Created by Wang Bourne on 13/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "AboutViewController.h"
#import "SimpleWebBrowserController.h"

@implementation AboutViewController

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	[super loadView];
	
    self.title = NSLocalizedString(@"Title_About",@"");
	self.view.backgroundColor = [UIColor blackColor];
	
	AboutView *about;
    if (isUserInterfaceIdiomPhone) {
        scroller = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, IPHONE_UI_WIDTH, 300)];
        about = [[AboutView alloc] initWithFrame:CGRectMake(10, 0, IPHONE_UI_WIDTH - 20, 300)];
        scroller.contentSize = CGSizeMake(IPHONE_UI_WIDTH, 300);
    } else {
        scroller = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 300, 500)];
        about = [[AboutView alloc] initWithFrame:CGRectMake(10, 0, 300, 500)];
        scroller.contentSize = CGSizeMake(300, 500);
    }
    
	
	[about.linkButton addTarget:self action:@selector(web) forControlEvents:UIControlEventTouchUpInside];
	[scroller addSubview:about];
	[self.view addSubview:scroller];
    
    self.view.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *fiveTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(logEnableSwitch)];
    fiveTap.numberOfTapsRequired = 5;
    [self.view addGestureRecognizer:fiveTap];
}

- (void) logEnableSwitch {
    if ([iConsole sharedConsole].logLevel == iConsoleLogLevelNone) {
        [iConsole sharedConsole].logLevel = iConsoleLogLevelInfo;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Log function is enabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    } else {
        [iConsole sharedConsole].logLevel = iConsoleLogLevelNone;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Log function is disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

-(void)web{
	NSURL *url = [NSURL URLWithString:@"http://www.flipflashcards.com"];
    SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
    controller.hidesToolbar = NO;
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        controller.modalPresentationStyle = UIModalPresentationFormSheet;
        #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self presentModalViewController:controller animated:YES];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight));
}

@end
