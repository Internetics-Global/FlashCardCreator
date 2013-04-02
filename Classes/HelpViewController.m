//
//  ScrollingViewController.m
//
//  Created by Wang Bourne on 04/03/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "HelpViewController.h"

@implementation HelpViewController
@synthesize scrollView = _scrollView;
@synthesize pageControl = _pageControl;

#pragma mark -
#pragma mark UIView boilerplate
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Title_Help",@"");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self setupPage];
}

#pragma mark -
#pragma mark The Guts
- (void)setupPage
{
	_scrollView.delegate = self;

	[self.scrollView setBackgroundColor:[UIColor blackColor]];
	[_scrollView setCanCancelContentTouches:NO];
	
	_scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	_scrollView.clipsToBounds = YES;
	_scrollView.scrollEnabled = YES;
	_scrollView.pagingEnabled = YES;
	
	NSUInteger nimages = 0;
	CGFloat cx = 0;
	for (; ; nimages++) {
		NSString *imageName = [NSString stringWithFormat:@"help%d.jpg", (nimages + 1)];
		UIImage *image = [UIImage imageNamed:imageName];
		if (image == nil) {
			break;
		}
		UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
		
		CGRect rect = CGRectMake(0, 0, 486, 260);
		rect.origin.x = 0 + cx;
		rect.origin.y = 0;
		imageView.frame = rect;
        [_scrollView addSubview:imageView];
        
        UITextView *helpText = [[UITextView alloc] initWithFrame:CGRectZero];
        NSString *localizedStr = [NSString stringWithFormat:@"HelpText%d", (nimages + 1)];
        helpText.text = NSLocalizedString(localizedStr,@"");
        helpText.backgroundColor = [UIColor clearColor];
        if (isUserInterfaceIdiomPhone) {
            helpText.font = [UIFont systemFontOfSize:16];    
        } else {
            helpText.font = [UIFont systemFontOfSize:20];
        }
        helpText.textColor = [UIColor whiteColor];
        rect = CGRectMake(0, 265, 486, 245);
        rect.origin.x = 0 + cx;
        helpText.frame = rect;
        [_scrollView addSubview:helpText];
        
		cx += _scrollView.frame.size.width;
	}
	
	self.pageControl.numberOfPages = nimages;
	[_scrollView setContentSize:CGSizeMake(cx, [_scrollView bounds].size.height)];
}

#pragma mark -
#pragma mark UIScrollViewDelegate stuff
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (pageControlIsChangingPage) {
        return;
    }

    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _pageControl.currentPage = page;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView 
{
    pageControlIsChangingPage = NO;
}

#pragma mark -
#pragma mark PageControl stuff
- (IBAction)changePage:(id)sender 
{
    CGRect frame = _scrollView.frame;
    frame.origin.x = frame.size.width * _pageControl.currentPage;
    frame.origin.y = 0;
	
    [_scrollView scrollRectToVisible:frame animated:YES];

    pageControlIsChangingPage = YES;
}


#pragma mark -
#pragma mark Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (BOOL)shouldAutorotate {
    
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskLandscapeLeft;
}

@end
