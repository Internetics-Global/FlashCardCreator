//
//  AppDelegate.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "DetailViewController.h"
#import "SQLiteHelper.h"
#import "AFJSONRequestOperation.h"
#import "DataManager.h"
#import <DropboxSDK/DropboxSDK.h>

#import "Card.h"
#import "Pack.h"
#import "User.h"

#import "NSString+QueryString.h"

#import "MySHKConfigurator.h"
#import "SHKConfiguration.h"
#import "CreatePackViewController.h"

extern BOOL isLoggingDropboxInSettingView;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //1. check database
    [SQLiteHelper verifyDatabase];
    
    //2. check user has opened app (once open, a default user will be setup)
    [SQLiteHelper checkUserExist];
    
    //3. set notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLinkedNotification:) name:DROPBOX_LINKED_NOTIFICATION object:nil];
    
    //4. Initialized Dropbox session
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:DROPBOX_APP_KEY appSecret:DROPBOX_APP_SECRET root:kDBRootDropbox];
    [DBSession setSharedSession:dbSession];
    
    //5. Initialize user interface
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if (isUserInterfaceIdiomPhone) {
        self.masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController_iPhone" bundle:nil];
        self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.masterViewController];
        self.window.rootViewController = self.navigationController;
    } else {
        self.splitViewController = [[MGSplitViewController alloc] init];
        
        self.masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController_iPad" bundle:nil];
        UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:self.masterViewController];
        
        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController_iPad" bundle:nil];
        UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:_detailViewController];
    	self.masterViewController.detailViewController = _detailViewController;
        
        self.splitViewController.delegate = _detailViewController;
        self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
        self.window.rootViewController = self.splitViewController;
        
    }
    
    //6. Get last created pack/card(also include downloaded packs) and set to master and detail view
    _lastCreatedPack = [self getLastCreatedCardPack];
    if (_lastCreatedPack) {  // available pack
        if ([[_lastCreatedPack cards] count] > 0) {  //available cards in the pack
            self.masterViewController.currentCard = [_lastCreatedPack cards][0];
            self.detailViewController.currentCard = [_lastCreatedPack cards][0];
        }
        
        //We set default index of card as 0 in current pack
        self.masterViewController.indexCard = 0;
        self.detailViewController.indexCard = 0;
        
        self.masterViewController.indexPack = _indexLastCreatedPack;
        
        self.masterViewController.currentPack = _lastCreatedPack;
        self.detailViewController.currentPack = _lastCreatedPack;
        
    } else {    
       //do nothing, it will be empty
    }

    
    //8.Golbal UI setting

    UIImage *buttonImage = [[UIImage imageNamed:@"background_navigationbar.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
    [[UINavigationBar appearance] setBackgroundImage:buttonImage forBarMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
    
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    UIImage *segmentSelected =
    [UIImage imageNamed:@"segment_selected.png"];
    UIImage *segmentUnselected =
    [UIImage imageNamed:@"segment_unselected.png"];
    UIImage *segmentSelectedUnselected =
    [UIImage imageNamed:@"segment_seperator.png"];
    UIImage *segUnselectedSelected =
    [UIImage imageNamed:@"segment_seperator.png"];
    UIImage *segmentUnselectedUnselected =
    [UIImage imageNamed:@"segment_seperator.png"];
    
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[UIColor blackColor] forKey:UITextAttributeTextColor];
    [[UISegmentedControl appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
    [[UISegmentedControl appearance] setTitleTextAttributes:highlightedAttributes forState:UIControlStateHighlighted];
    
    [[UISegmentedControl appearance] setBackgroundImage:segmentUnselected
                                              forState: UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    [[UISegmentedControl appearance] setBackgroundImage:segmentSelected
                                              forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setDividerImage:segmentUnselectedUnselected
                                forLeftSegmentState:UIControlStateNormal
                                  rightSegmentState:UIControlStateNormal
                                         barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setDividerImage:segmentSelectedUnselected
                                forLeftSegmentState:UIControlStateSelected
                                  rightSegmentState:UIControlStateNormal
                                         barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setDividerImage:segUnselectedSelected
                                forLeftSegmentState:UIControlStateNormal
                                  rightSegmentState:UIControlStateSelected
                                         barMetrics:UIBarMetricsDefault];

    
    
    //9.Sharekit configuration
    //Sharekit configuration, should be put in method of "didFinishLaunchingWithOptions:"
    DefaultSHKConfigurator *configurator = [[MySHKConfigurator alloc] init];
    [SHKConfiguration sharedInstanceWithConfigurator:configurator];
    

    //10. Show UI
    [self.window makeKeyAndVisible];
    
    //11. Get example packs (online) and save to local
    BOOL isExamplePackDownloadedSuccessful = [[NSUserDefaults standardUserDefaults] boolForKey:@"isExamplePackDownloadedSuccessful"];
    if (isExamplePackDownloadedSuccessful ==NO) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOAD_PACK_NOTIFICATION object:@"https://www.dropbox.com/s/9i9mxswqdaxavzt/Pack1364361136-1492165620.zip"];
    }
    
    return YES;
}

#pragma mark -
#pragma mark - Handle when call from outside like safari

//url is kind of: fcc://www.dropbox.com/s/pe2v96gaxpsrety/A.zip?from=Clive&cardname=Happy New Year&packname=hello
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL isExamplePackDownloadedSuccessful = [[NSUserDefaults standardUserDefaults] boolForKey:@"isExamplePackDownloadedSuccessful"];
    if (!isExamplePackDownloadedSuccessful) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_DOWNLOAD_EXAMPLE_PACK_FIRST",@"")];
        return NO;
    }
    
    if ([[url scheme] isEqualToString:@"fcc"]) {
        //NSString *httpURL = [[url absoluteString] stringByReplacingOccurrencesOfString:@"fcc" withString:@"http"];
        //NSString *downloadableURL = [httpURL stringByReplacingOccurrencesOfString:@"www" withString:@"dl"];
        //NSDictionary *params = [NSString queryParamsFromString:[url absoluteString]];
        //NSString *fromWho = params[@"from"];
        //NSString *packName = params[@"packname"];
        //NSString *cardName = params[@"cardname"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOAD_PACK_NOTIFICATION object:[url absoluteString]];
        
        
        
        
        
    } else if ([[[url scheme] substringToIndex:3] isEqualToString:@"db-"]) {
        if ([[DBSession sharedSession] handleOpenURL:url])
        {
            if ([[DBSession sharedSession] isLinked])
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:DROPBOX_LINKED_NOTIFICATION object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"linked"]];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:DROPBOX_LINKED_NOTIFICATION object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"linked"]];
            }
            return YES;
        }
    
    }
    
    return YES;
}


- (Pack *) getLastCreatedCardPack {
    int lastCreatedPackID = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCreatedPackID"];

    _indexLastCreatedPack =0;
    if (!lastCreatedPackID) {
        // Means that we have NO record for last card or pack create
        _lastCreatedPack = nil;
    } else {
        for (Pack *pack in [[User defaultUser] packs]) {
            if (lastCreatedPackID == pack.packID) {
                return pack;
            }
            _indexLastCreatedPack ++;
        }
    }
    
    return nil;
}

#pragma mark -
#pragma mark - Notification

- (void) dropboxLinkedNotification:(id)notification
{
    NSNumber *linkedNum = [[notification userInfo] objectForKey:@"linked"];
    
    if(![linkedNum boolValue])
    {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
    } else
    {
        //[Common alertViewCommon:@"Dropbox is linked now"];
        
        if (isLoggingDropboxInSettingView == NO) {  //which means it's not just a single dropbox log in action
            [self.masterViewController shareButtonClicked];    
        }
    }
    
    isLoggingDropboxInSettingView = NO;
}


@end
