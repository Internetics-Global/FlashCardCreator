    //
//  SimpleWebBrowserController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 22/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "SimpleWebBrowserController.h"
#import "MBProgressHUD.h"


@implementation SimpleWebBrowserController

@synthesize webView = _webView;
@synthesize initialURL = _initialURL;
@synthesize hidesToolbar = _hidesToolbar;
@synthesize initialHTML;

#pragma mark -
#pragma mark Initialization

- (id)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _haveRequested = NO;
        _haveLoadURLFinished = NO;
        self.initialURL = url;
        self.hidesBottomBarWhenPushed = YES;
        _hidesToolbar = NO;
    }
    
    return self;
}

- (id)initWithHTML:(NSString *)html {
    if (self = [super init]) {
        self.initialHTML = html;
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    NSLog(@"%s",__FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize size = self.view.bounds.size;
    UIWebView *v = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height - (_hidesToolbar ? 0 : 44))];
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    v.delegate = self;
    v.scalesPageToFit = YES;
    [self.view addSubview:v];
    self.webView = v;
    
    if (!_hidesToolbar) {
        UIToolbar *bar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, size.height-44, size.width, 44)];
        bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        bar.barStyle = UIBarStyleBlackOpaque;
        
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil action:nil];
        
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"leftArrow.png"]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(backButtonClicked:)];
        backButton.enabled = NO;
        
        forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"rightArrow.png"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(forwardButtonClicked:)];
        forwardButton.enabled = NO;
        
        refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self
                                                                      action:@selector(refreshButtonClicked:)];
        
        closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(closeButtonClicked:)];
        
        bar.items = [NSArray arrayWithObjects:
                     backButton,
                     flexSpace,
                     forwardButton,
                     flexSpace,
                     refreshButton,
                     flexSpace,
                     closeButton,
                     nil];
        [self.view addSubview:bar];
    }
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_haveRequested) {
        _haveRequested = YES;
        if (self.initialURL) {
            [self.webView loadRequest:[NSURLRequest requestWithURL:self.initialURL]];
        } else if (self.initialHTML) {
            [self.webView loadHTMLString:initialHTML baseURL:nil];
        }        
    }
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _isViewShowing = YES;

    if (_loadingView == nil) {
        if (_loadingView == nil) {
            _loadingView = [[MBProgressHUD alloc] initWithView:self.view];
        }
        [self.view addSubview:_loadingView];
        _loadingView.mode = MBProgressHUDModeText;
        _loadingView.labelText = @"Loading...";
        [_loadingView show:YES];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:YES];
    _isViewShowing = NO;
	[self.webView stopLoading];
}


-(void)zoomToFit
{
    if ([self.webView respondsToSelector:@selector(scrollView)])
    {
        UIScrollView *scroll=[self.webView scrollView];
        float zoom=self.webView.bounds.size.width/scroll.contentSize.width;
        [scroll setZoomScale:zoom animated:NO];
    }
}


#pragma mark -
#pragma mark Webview delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webview {
    [self.view addSubview:_loadingView];
}


- (void)webViewDidFinishLoad:(UIWebView *)webview {
    [self zoomToFit];
    _haveLoadURLFinished = YES;
    [_loadingView removeFromSuperview];
    
	NSString *str = [webview stringByEvaluatingJavaScriptFromString:@"document.title"];
	if ([str length] > 0) {
		self.navigationItem.title = str;
	}
    
    backButton.enabled = [webview canGoBack];
    forwardButton.enabled = [webview canGoForward];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [_loadingView removeFromSuperview];
    NSLog(@"%s",__FUNCTION__);
    NSLog(@"error:%@",error);
    if (!([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)) {
        if (_isViewShowing) {
            [Common alertViewCommon:@"Check the network status"];
        }
    }
}


#pragma mark -
#pragma mark Toolbar delegate

- (void)backButtonClicked:(id)sender {
    [self.webView goBack];
}

- (void)forwardButtonClicked:(id)sender {
    [self.webView goForward];
}

- (void)refreshButtonClicked:(id)sender {
    [self.webView reload];
}

- (void)closeButtonClicked:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark - Memory Management

// will not be called in iOS 6
// will not be called when it's current view
- (void)viewDidUnload
{
    [super viewDidUnload];
    [self my_viewDidUnload];
}

// in iOS 6, view is no longer unloaded so do it manually
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && [self.view window] == nil) {
        self.view = nil;
        [self my_viewDidUnload];
    }
}

- (void)my_viewDidUnload
{
    
}

#pragma mark -
#pragma mark Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight));
}

- (BOOL)shouldAutorotate {
    
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskLandscape;
}



@end
