    //
//  SimpleWebBrowserController.m
//  FFC
//
//  Created by Wang Bourne on 22/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "SimpleWebBrowserController.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"

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
    [iConsole info:@"%s",__FUNCTION__];
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
        bar.barStyle = UIBarStyleBlackTranslucent;
        bar.tintColor = [UIColor whiteColor];
        
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
        
        refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh2.png"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(refreshButtonClicked:)];
        
        
        closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close2_button.png"]
                                                       style:UIBarButtonItemStylePlain
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
    
    APP_DELEGATE.isInAppWebSite = YES;
}


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:YES];
    _isViewShowing = NO;
	[self.webView stopLoading];
    
    APP_DELEGATE.isInAppWebSite = NO;
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
    
    [iConsole info:@"URL: %@", [[request URL] absoluteString]];
    NSString *curUrl = [NSString stringWithFormat:@"%@%@", [[self.webView.request URL] host], [[self.webView.request URL] path]];
    NSString *newUrl = [NSString stringWithFormat:@"%@%@", [[request URL] host], [[request URL] path]];
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked && ![newUrl isEqualToString:curUrl]) {
        //[Common alertViewCommon:@"Link is clicked "];
    }
    
    if ((navigationType == UIWebViewNavigationTypeFormSubmitted || navigationType == UIWebViewNavigationTypeFormResubmitted) && (![newUrl isEqualToString:curUrl]) )  {
        //[Common alertViewCommon:@"Form is submitted(Creat account)"];
        
        if (1) { //we have to update this logic later when requirement is freezed (liang wang)
            NSURL *url = [NSURL URLWithString:@"http://internetics.net.au/fcc/add-new/"];
            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
            controller.hidesToolbar = NO;
            [self.navigationController pushViewController:controller animated:YES];
        }
    }

    return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webview {
    self.title = @"Loading...";
}

- (void)webViewDidFinishLoad:(UIWebView *)webview {
    //[self zoomToFit];
    _haveLoadURLFinished = YES;
    
	NSString *str = [webview stringByEvaluatingJavaScriptFromString:@"document.title"];
	if ([str length] > 0) {
		self.navigationItem.title = str;
	}
    
    backButton.enabled = [webview canGoBack];
    forwardButton.enabled = [webview canGoForward];

    //The following code is just for test
    //[webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('text required')[0].value='Clive';"];
    //[webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('text required')[1].value='clive@internetics.net.au';"];

    
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [iConsole error:@"error:%@",error];
//    if (!([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)) {
//        if (_isViewShowing) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_TITLE_NO_NETWORK",@"")
//                                                            message:NSLocalizedString(@"DIALOG_PLEASE_CHECK_YOUR_NETWORK",@"")
//                                                           delegate:nil
//                                                  cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"")
//                                                  otherButtonTitles:nil];
//            [alert show];
//        }
//    }
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

    
    
    if (isUserInterfaceIdiomPhone) {
        
        if ([self.navigationController.viewControllers count] > 1) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:true completion:nil];
        }
        
    } else {
        [self dismissViewControllerAnimated:true completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_PACK_LIST_AFTER_DISMISS" object:nil userInfo:nil];
        }];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_SETTING_TABLEVIEW_NOTIFICATION object:nil];
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskLandscape;
}



@end
