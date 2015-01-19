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
#import "FileOperationHelper.h"
#import "CreatePackViewController.h"

#import "Common.h"

#import <Appsee/Appsee.h>
#import "TestFlight.h"

extern BOOL isLoggingDropboxInSettingView; //we have two places log into dropbox: 1. from setting; 2. from share button
BOOL _isDownloadingSamplePack;


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[Appsee start:@"556562735fb44188885a874b63449621"];
    
    [self setupLog];
    
    self.isAllowToShowPackList = YES;
    
    [TestFlight takeOff:@"f4a521b6-66f1-406b-97fc-cfa6f60c1be6"];
    
    [iConsole info:@"%s:%@",__FUNCTION__,[Common userAgentInfo]];
    
    //1. check database
    [SQLiteHelper verifyDatabase];
    
    //move old files
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        NSString *oldImagesPath = [FileOperationHelper cachesPathForFileNamed:@"Images"];
        NSArray *allFiles = [FileOperationHelper listFilesAtPath:oldImagesPath];
        for (NSString *fileName in allFiles) {
            if (([fileName rangeOfString:@".jpg"].length > 0) || ([fileName rangeOfString:@".png"].length > 0)) {
                NSString *dest = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:fileName];
                NSString *from = [oldImagesPath stringByAppendingPathComponent:fileName];
                
                if([[NSFileManager defaultManager] fileExistsAtPath:dest] == false) {
                    [[NSFileManager defaultManager] moveItemAtPath:from toPath:dest error:&error];
                    if (error) {
                        [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
                    }
                }
            }
        }
    });
    
    //skip iCloud backup
    [FileOperationHelper addSkipBackupAttributeToFileAtPath:[FileOperationHelper dataDocumentDirectory]];
    
    
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
        
        _packIDForMasterViewPack = _lastCreatedPack.packID;
        
    } else {    
       //do nothing, it will be empty
    }

    
    //8.Golbal UI setting

    UIImage *buttonImage = [[UIImage imageNamed:@"background_navigationbar.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
    [[UINavigationBar appearance] setBackgroundImage:buttonImage forBarMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    NSDictionary *attributes;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        //[[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"bar_button_black.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        
        attributes = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[UIColor whiteColor],[UIFont boldSystemFontOfSize:16], nil] forKeys:[NSArray arrayWithObjects:UITextAttributeTextColor,UITextAttributeFont, nil]];
        [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
        
        attributes = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[UIColor whiteColor],[UIFont boldSystemFontOfSize:20], nil] forKeys:[NSArray arrayWithObjects:UITextAttributeTextColor,UITextAttributeFont, nil]];
        [[UINavigationBar appearance] setTitleTextAttributes:attributes];
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            self.window.tintColor = [UIColor whiteColor];
        }
        
        //used to change the cursor color (in iOS7, the default cursor color is white)
        [[UITextView appearance] setTintColor:[UIColor blueColor]];
        

    }
    
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
    
    //UISegmentedControl related
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],UITextAttributeTextColor,
                  [UIFont systemFontOfSize:14.0f],UITextAttributeFont,nil];
    [[UISegmentedControl appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor],UITextAttributeTextColor,
                  [UIFont systemFontOfSize:14.0f],UITextAttributeFont,nil];
    [[UISegmentedControl appearance] setTitleTextAttributes:highlightedAttributes forState:UIControlStateHighlighted];
    [[UISegmentedControl appearance] setTitleTextAttributes:highlightedAttributes forState:UIControlStateSelected];
    
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
    //not use share kit any more
    

    //10. Show UI
    [self.window makeKeyAndVisible];
    
    //11. Get example packs (online) and save to local
    BOOL isExamplePackDownloadedSuccessful = [[NSUserDefaults standardUserDefaults] boolForKey:@"isExamplePackDownloadedSuccessful"];
    if (isExamplePackDownloadedSuccessful ==NO) {
        _isDownloadingSamplePack = TRUE;
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOAD_PACK_NOTIFICATION object:@"https://www.dropbox.com/s/szccw743kb41xol/Pack1421026646333651989.zip?type=demo"];
    } else {
        _isDownloadingSamplePack = FALSE;
    }
    
    return YES;
}

#pragma mark -
#pragma mark - Handle when call from outside like safari

//url is kind of: fcc://www.dropbox.com/s/pe2v96gaxpsrety/A.zip?from=Clive&cardname=Happy New Year&packname=hello
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [iConsole info:@"%s",__FUNCTION__];
    if (_isDownloadingSamplePack) {
        _isDownloadingSamplePack = FALSE;
        return NO;
    }
    
    if ([[url scheme] isEqualToString:@"fcc"]) {
        
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
    [iConsole info:@"%s",__FUNCTION__];
    int lastCreatedPackID = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCreatedPackID"];

    _indexLastCreatedPack =0;
    if (!lastCreatedPackID) {
        // Means that we have NO record for last card or pack create
        _lastCreatedPack = nil;
    } else {
        NSMutableArray *packArray = [[User defaultUser] packs];
        for (Pack *pack in packArray) {
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
    [iConsole info:@"%s",__FUNCTION__];
    NSNumber *linkedNum = [[notification userInfo] objectForKey:@"linked"];
    
    if(![linkedNum boolValue])
    {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
    } else
    {
        //[Common alertViewCommon:@"Dropbox is linked now"];
        
        if (isLoggingDropboxInSettingView == NO) {
            
//            if (isUserInterfaceIdiomPhone) {
//                [self.masterViewController shareButtonClicked:nil];
//            }  else {
//                [self.detailViewController shareButtonClicked:nil];
//            }
            
        }
    }
    
    isLoggingDropboxInSettingView = NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [iConsole info:@"%s:%@",__FUNCTION__,[Common userAgentInfo]];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [iConsole info:@"%s",__FUNCTION__];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.isDownloadingPack = FALSE;
}

- (void) setupLog {
    
    //[iConsole sharedConsole].logLevel = iConsoleLogLevelNone;
    
    [[iConsole sharedConsole] setMaxLogItems:1000];

}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
    return UIInterfaceOrientationMaskAll;
}


- (UIView *)progressHUDHolderView {
    if (isUserInterfaceIdiomPhone) {
        return self.navigationController.view;
    } else {
        return self.splitViewController.view;
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
