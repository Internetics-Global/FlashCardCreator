//
//  SimpleWebBrowserController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 22/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HUDActivityView;
@class MBProgressHUD;

@interface SimpleWebBrowserController:UIViewController <UIWebViewDelegate> {
    UIBarItem               *backButton;
    UIBarItem               *forwardButton;
    UIBarItem               *refreshButton;
    UIBarItem               *closeButton;
    
    UIWebView               *_webView;
    NSURL                   *_initialURL;
    MBProgressHUD         *_loadingView;
    
    NSString                *initialHTML;
    
    BOOL                    _hidesToolbar;
    BOOL                    _haveRequested;
    BOOL                    _haveLoadURLFinished;
    BOOL                    _isViewShowing;
}

- (id)initWithURL:(NSURL *)url;
- (id)initWithHTML:(NSString *)html;

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSURL *initialURL;
@property (nonatomic, assign) BOOL hidesToolbar;
@property (nonatomic, retain) NSString *initialHTML;

@end
