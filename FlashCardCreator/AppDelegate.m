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
        self.masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController_iPad" bundle:nil];
        UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:self.masterViewController];
        
        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController_iPad" bundle:nil];
        UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:_detailViewController];
    	self.masterViewController.detailViewController = _detailViewController;
        self.splitViewController = [[UISplitViewController alloc] init];
        self.splitViewController.delegate = _detailViewController;
        self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
        self.window.rootViewController = self.splitViewController;
        
    }
    
    //6. Get last created pack/card and set to master and detail view
    [self getLastCreatedCardPack];
    self.masterViewController.currentCard = _lastCreatedCard;
    self.masterViewController.currentPack = _lastCreatedPack;
    self.masterViewController.isCurrentPackPublic = (_lastCreatedCard == nil);
    self.masterViewController.indexCard = _indexCard;
    
    if (isUserInterfaceIdiomPhone) {
        self.detailViewController.currentPack = _lastCreatedPack;
        self.detailViewController.currentCard = _lastCreatedCard;
        self.detailViewController.indexCard = _indexCard;
    }
    
    //6. Get public packs
    PublicPackRequest *publicPackRequest = [[PublicPackRequest alloc] init];
    [publicPackRequest requestPublicPack];
    publicPackRequest.delegate = self.masterViewController;
    
    //7.Golbal UI setting
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    //8. Show UI
    [self.window makeKeyAndVisible];
    
    
    //Test code, only for test
    
    return YES;
}

#pragma mark -
#pragma mark - Handle when call from outside like safari

//url is kind of: fcc://www.dropbox.com/s/pe2v96gaxpsrety/A.zip?from=Clive&cardname=Happy New Year&packname=hello
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[url scheme] isEqualToString:@"fcc"]) {
        NSString *httpURL = [[url absoluteString] stringByReplacingOccurrencesOfString:@"fcc" withString:@"http"];
        NSString *downloadableURL = [httpURL stringByReplacingOccurrencesOfString:@"www" withString:@"dl"];
        NSDictionary *params = [NSString queryParamsFromString:[url absoluteString]];
        NSString *fromWho = params[@"from"];
        NSString *packName = params[@"packname"];
        NSString *cardName = params[@"cardname"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:[NSString stringWithFormat:@"From:%@:\n download this card(%@) and save to pack(%@)",fromWho,cardName,packName]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } 
    
    return YES;
}


- (void) getLastCreatedCardPack {
    int lastCreatedPackID = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCreatedPackID"];

    if ((lastCreatedPackID == PUBLIC_PACK_ID) || (lastCreatedPackID == 0)) {
        _lastCreatedPack = nil;
        _lastCreatedCard = nil;
        _indexCard = -1;
    } else {
        for (Pack *pack in [[User defaultUser] packs]) {
            if (lastCreatedPackID == pack.packID) {
                _lastCreatedPack = pack;
                break;
            }
        }
        int lastCreatedCardID = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCreatedCardID"];
        int index = -1;
        for (Card *card in [_lastCreatedPack cards]){
            index ++;
            if (lastCreatedCardID == card.cardID) {
                _lastCreatedCard = card;
                break;
            }
        }
        
        _indexCard = [[NSUserDefaults standardUserDefaults] integerForKey:@"indexCard"];
    }
}


#pragma mark -
#pragma mark - Test code, only for test

@end
