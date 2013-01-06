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

#import "ZipFileDownloadHelper.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //1. check database
    [SQLiteHelper verifyDatabase];
    
    //2. check user has opened app (once open, a default user will be setup)
    [SQLiteHelper checkUserExist];
    
    //3. check reachability
    [DataManager apiReachableAlert];
    
    //4. Initialized Dropbox session
    DBSession* dbSession = [[[DBSession alloc] initWithAppKey:DROPBOX_APP_KEY appSecret:DROPBOX_APP_SECRET root:kDBRootDropbox] autorelease];
    [DBSession setSharedSession:dbSession];
    
    //5. Create user interface
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    if (isUserInterfaceIdiomPhone) {
        MasterViewController *masterViewController = [[[MasterViewController alloc] initWithNibName:@"MasterViewController_iPhone" bundle:nil] autorelease];
        self.navigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
        self.window.rootViewController = self.navigationController;
    } else {
        MasterViewController *masterViewController = [[[MasterViewController alloc] initWithNibName:@"MasterViewController_iPad" bundle:nil] autorelease];
        UINavigationController *masterNavigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
        
        DetailViewController *detailViewController = [[[DetailViewController alloc] initWithNibName:@"DetailViewController_iPad" bundle:nil] autorelease];
        UINavigationController *detailNavigationController = [[[UINavigationController alloc] initWithRootViewController:detailViewController] autorelease];
    	masterViewController.detailViewController = detailViewController;
        self.splitViewController = [[[UISplitViewController alloc] init] autorelease];
        self.splitViewController.delegate = detailViewController;
        self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
        self.window.rootViewController = self.splitViewController;
        
    }
    [self.window makeKeyAndVisible];
    
    //Test code, test only, will be removed in production line
    ZipFileDownloadHelper *temp =[[ZipFileDownloadHelper alloc] init];
    [temp downloadZipFile:@"https://dl.dropbox.com/s/ecocdzmj4tmvlrh/1.zip"];

    
    return YES;
}


#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [_window release];
    [_navigationController release];
    [_splitViewController release];
    [super dealloc];
}


@end
