//
//  PurchaseViewController.m
//  NoiseMeter
//
//  Created by Bourne Wang on 13-7-20.
//  Copyright (c) 2013年 Internetics Pty Ltd. All rights reserved.
//

#import "PurchaseViewController.h"
#import "MutipleTargetHelper.h"


#ifndef TARGET_PRO_VERSION
#import "RMStore.h"
#endif


@interface PurchaseViewController () <UIWebViewDelegate> {
    BOOL _localizedPriceUpdated;
    
    
}

@property (strong, nonatomic)  UIButton   *purchaseButton;
@property (strong, nonatomic)  UIButton   *purchase2Button;
@property (strong, nonatomic)  UIButton   *restoreButton;

@property (strong, nonatomic) UIWebView   *webview;

@end

@implementation PurchaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _localizedPriceUpdated = false;
    
    UIBarButtonItem *rightBarButtonItem  = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    
    self.webview =[[UIWebView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame),CGRectGetHeight(self.view.frame) - 57)];
    NSString *url=@"http://www.flipflashcards.com/promo/index.html";
    NSURL *nsurl=[NSURL URLWithString:url];
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
    [self.webview loadRequest:nsrequest];
    self.webview.delegate = self;
    self.webview.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webview];
    
    self.purchaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.purchaseButton.frame = CGRectMake(10, CGRectGetMaxY(self.webview.frame) + 10, 140, 37);
    self.purchaseButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin;
    [self.purchaseButton setTitle:@"No Ads" forState:UIControlStateNormal];
    [self.purchaseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.purchaseButton addTarget:self action:@selector(purchaseNow:) forControlEvents:UIControlEventTouchUpInside];
    self.purchaseButton.tag = 0;
    self.purchaseButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:self.purchaseButton];
    self.purchaseButton.backgroundColor = [UIColor grayColor];
    self.purchaseButton.layer.cornerRadius = 3;
    
    self.purchase2Button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.purchase2Button.frame = CGRectMake(CGRectGetWidth(self.view.frame)/2- 140/2, CGRectGetMaxY(self.webview.frame) + 10, 140, 37);
    self.purchase2Button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [self.purchase2Button setTitle:@"Full Version" forState:UIControlStateNormal];
    self.purchase2Button.titleLabel.font = [UIFont systemFontOfSize:13];
    self.purchase2Button.tag = 1;
    [self.purchase2Button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.purchase2Button addTarget:self action:@selector(purchaseNow:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.purchase2Button];
    self.purchase2Button.backgroundColor = [UIColor grayColor];
    self.purchase2Button.layer.cornerRadius = 3;
    
    self.restoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.restoreButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) - 140 - 10, CGRectGetMaxY(self.webview.frame) + 10, 140, 37);
    [self.restoreButton setTitle:@"Restore" forState:UIControlStateNormal];
    self.restoreButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
    [self.restoreButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.restoreButton addTarget:self action:@selector(restoreAction:) forControlEvents:UIControlEventTouchUpInside];
    self.restoreButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:self.restoreButton];
    self.restoreButton.backgroundColor = [UIColor grayColor];
    self.restoreButton.layer.cornerRadius = 3;
    
    //request product info
    NSSet *products =[NSSet setWithArray:@[IAPProductID_1_Dollar,IAPProductID_5_Dollar]];
    [[RMStore defaultStore] requestProducts:products success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
        NSLog(@"Products loaded");
        [self updateProduct:products withInvalidProductIdentifiers: invalidProductIdentifiers];
    } failure:^(NSError *error) {
        NSLog(@"%s:%@",__FUNCTION__,error);
    }];
    
    _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activity.frame = CGRectMake(self.view.frame.size.width/2 - 5, 30, 21, 21);
    [self.view addSubview:_activity];
    
    self.view.backgroundColor = [UIColor blackColor];
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.webview.alpha = 0;
    
    _activity.center = self.webview.center;

}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}


#pragma mark – Restore and buy

- (void) updateProduct:(NSArray *)products withInvalidProductIdentifiers:(NSArray *) invalidProductIdentifiers  {
    if (_backButton) {
        _backButton.enabled = YES;
    }
    
    if (products.count == 0) {
        
        NSLog(@"Fail to get product info (myProduct.count = 0)");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                            message:@"Failed to get product information, please try again later"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    
    if (products.count != 2) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                            message:@"IAP configuration is not expected, check iTunes Connect"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    if ([invalidProductIdentifiers count] > 0) {
        NSLog(@"Invalid product ID");
        return;
    }
    
    SKProduct *price1Product = [products firstObject];
    NSString *purchase1Price = [self localizedPrice:price1Product];
    [_purchaseButton setTitle:[NSString stringWithFormat:@"No Ads - %@ ",purchase1Price] forState:UIControlStateNormal];
    
    SKProduct *price2Product = [products lastObject];
    NSString *purchase2Price = [self localizedPrice:price2Product];
    [_purchase2Button setTitle:[NSString stringWithFormat:@"Full Version - %@ ",purchase2Price] forState:UIControlStateNormal];
    
    _localizedPriceUpdated = true;
    
}

- (IBAction)restoreAction:(id)sender {
    
    if (TARGET_IPHONE_SIMULATOR) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Can not test IAP in simulator" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [[RMStore defaultStore] restoreTransactionsOnSuccess:^(NSArray *transactions){
        NSLog(@"Transactions restored");
        
        [MutipleTargetHelper setFullVersionFlag:YES];
        
        [self dismiss];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Successfully restored" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    } failure:^(NSError *error) {
        NSLog(@"%s:%@",__FUNCTION__,error);
        
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Restore failed, please try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }];
    
}


#pragma mark – Purchase

- (void) purchaseNow:(UIButton *) button {
    
    if (_localizedPriceUpdated == false) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please wait for price to be fetched" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (TARGET_IPHONE_SIMULATOR) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Can not test IAP in simulator" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }

    
    NSString *productIdentifier;
    if (button.tag == 0) {
        //0.99$
        productIdentifier = IAPProductID_1_Dollar;
    } else {
        productIdentifier = IAPProductID_5_Dollar;
    }
    
    NSString *successDest = @"Thank you for upgrading, please restart your app to be effective";
    
    [[RMStore defaultStore] addPayment:productIdentifier success:^(SKPaymentTransaction *transaction) {
        NSLog(@"Product purchased");
        
        [MutipleTargetHelper setFullVersionFlag:YES];
        
        [self dismiss];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:successDest delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        NSLog(@"%s:%@",__FUNCTION__,error);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Purchase unsuccessfully, please try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }];
}



- (NSString *)localizedPrice: (SKProduct *) sk
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:sk.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:sk.price];
    return formattedString;
}


#pragma mark – UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_activity startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_activity stopAnimating];
    
    [UIView animateWithDuration:0.4f
                     animations:^{
                         self.webview.alpha = 1.0f;
                     }];
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [_activity stopAnimating];
}

- (void) dismiss {
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark – Memory management

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
