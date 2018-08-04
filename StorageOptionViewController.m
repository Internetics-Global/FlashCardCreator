//
//  PlayOptionViewController.m
//  FlashCardCreator
//
//  Created by Internetics on 4/12/2015.
//  Copyright © 2015 Internetics. All rights reserved.
//

#import "StorageOptionViewController.h"
#import "Common.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>
#import "GoogleDriveSession.h"
#import "AppDelegate.h"
#import "FirebaseSignInViewController.h"

@import Firebase;

@interface StorageOptionViewController () <UITableViewDelegate, UITableViewDataSource>{
    UITableView *_alertTable;
}

@end

@implementation StorageOptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _alertTable = [[UITableView alloc] initWithFrame:self.view.bounds];
    _alertTable.delegate = self;
    _alertTable.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _alertTable.dataSource = self;
    _alertTable.opaque = NO;
    _alertTable.backgroundView = nil;
    _alertTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    _alertTable.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    [self.view addSubview:_alertTable];
    
    self.title = @"Storage";
    
//    UITapGestureRecognizer *fiveTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideFFCDrive)];
//    fiveTap.numberOfTapsRequired = 5;
//    [self.view addGestureRecognizer:fiveTap];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLinkedNotification:) name:DROPBOX_LINKED_NOTIFICATION object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int showFFC = [[NSUserDefaults standardUserDefaults] boolForKey:@"K_Show_FFC_Drive"];
    if (showFFC) {
        return 3;
    } else {
        return 2;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Dropbox",@"");
        
        UISwitch *mySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [mySwitch addTarget:self action:@selector(dropboxLogInOutAction:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = mySwitch;
        BOOL b = ([DropboxClientsManager authorizedClient] != nil || [DropboxClientsManager authorizedTeamClient] != nil);
        [mySwitch setOn:b];
        
        
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Google_Drive",@"");
        
        UISwitch *mySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [mySwitch addTarget:self action:@selector(googeDriveLogInOutAction:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = mySwitch;
        BOOL b = [[GoogleDriveSession sharedSession] isLinked];
        [mySwitch setOn:b];

    }
    
    else if (indexPath.row == 2)
    {
        cell.textLabel.text = NSLocalizedString(@"Table_Item_AWS",@"");
        
        UISwitch *mySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [mySwitch addTarget:self action:@selector(awsAction:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = mySwitch;
        BOOL b = [FIRAuth auth].currentUser != nil;
        [mySwitch setOn:b];
        
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        cell.tintColor = [UIColor whiteColor];
    }
    
    cell.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
}

- (void) hideFFCDrive {
    int showFFC = [[NSUserDefaults standardUserDefaults] boolForKey:@"K_Show_FFC_Drive"];
    [[NSUserDefaults standardUserDefaults] setBool:!showFFC forKey:@"K_Show_FFC_Drive"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_alertTable reloadData];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void) awsAction :(UISwitch *) myswitch {
    
    if ([FIRAuth auth].currentUser != nil) {
        
        NSError *signOutError;
        BOOL status = [[FIRAuth auth] signOut:&signOutError];
        if (!status) {
            NSLog(@"Error signing out: %@", signOutError);
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:signOutError.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
            [alertView show];
            
            return;
        } else {

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_AWS_DISCONNECTED",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
            [alertView show];
            
            
        }
        
        [_alertTable reloadData];
        
        
    } else {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"firebase" bundle:nil];
        FirebaseSignInViewController  *viewController = [storyboard instantiateViewControllerWithIdentifier:@"FirebaseSignInViewController"];
        
        UINavigationController *naviController = [[UINavigationController alloc] initWithRootViewController:viewController];
        
        if (isUserInterfaceIdiomPhone) {
            [self.navigationController popViewControllerAnimated:true];
        } else {
            [self dismissViewControllerAnimated:true completion:nil];
            [self.navigationController popViewControllerAnimated:true];
            naviController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:naviController animated:true completion:nil];
        
    }
    
    
}


- (void) googeDriveLogInOutAction :(UISwitch *) myswitch {
    
    __weak __typeof(&*self)weakSelf = self;
    
    [DropboxClientsManager unlinkClients];
    
    if (![[GoogleDriveSession sharedSession] isLinked]) {
        
        APP_DELEGATE.isAllowToShareAfterDropboxLogIn = NO;
        APP_DELEGATE.isAllowToShowPackList = NO;
        
        __weak __typeof(&*self)weakSelf = self;
        
        if (isUserInterfaceIdiomPhone) {
            
            double delayInSeconds = 0.4;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                
                [[GoogleDriveSession sharedSession] authWithSuccessCompletion:^{
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_GOOGLE_DRIVE_LOGIN_SUCCESS",@"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alertView show];
                    });
                    
                    [_alertTable reloadData];
                }];
            });
            
        } else {
            [self dismissViewControllerAnimated:true completion:^{
                [[GoogleDriveSession sharedSession] authWithSuccessCompletion:^{
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_GOOGLE_DRIVE_LOGIN_SUCCESS",@"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alertView show];
                    });
                    
                    [_alertTable reloadData];
                }];
            }];
        }
        
        APP_DELEGATE.isAllowToShareAfterDropboxLogIn = NO;
        APP_DELEGATE.isAllowToShowPackList = NO;
    } else {
        
        [[GoogleDriveSession sharedSession] unlinkAll];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_GOOGLE_DRIVE_DISCONNECTED",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CLOSE",@"") otherButtonTitles:nil, nil];
        [alertView show];
        
         [_alertTable reloadData];
    }
}

- (void) dropboxLogInOutAction:(UISwitch *) myswitch {
    
    [[GoogleDriveSession sharedSession] unlinkAll];
    

    
    if ([DropboxClientsManager authorizedClient] == nil && [DropboxClientsManager authorizedTeamClient] == nil) {
        
        __weak __typeof(&*self)weakSelf = self;
        
        [DropboxClientsManager authorizeFromController:[UIApplication sharedApplication]
                                            controller:weakSelf
                                               openURL:^(NSURL *url) {
                                                   [[UIApplication sharedApplication] openURL:url];
                                               }
                                           browserAuth:NO];
        
        
        APP_DELEGATE.isAllowToShareAfterDropboxLogIn = NO;
        APP_DELEGATE.isAllowToShowPackList = NO;
        
        
    } else {
        
        [DropboxClientsManager unlinkClients];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_DROPBOX_DISCONNECTED",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CLOSE",@"") otherButtonTitles:nil, nil];
        [alertView show];
        
        [_alertTable reloadData];
    }
}


//#pragma mark -
//#pragma mark DBSessionDelegate methods
//
//- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
//    [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
//}



#pragma mark -
#pragma mark - DROPBOX_LINKED_NOTIFICATION

- (void) dropboxLinkedNotification:(id)notification
{
    [iConsole info:@"%s",__FUNCTION__];
    NSNumber *linkedNum = [[notification userInfo] objectForKey:@"linked"];
    
//    if(![linkedNum boolValue])
//    {
//        
//        [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
//    } else
//    {
//    }
    
    [_alertTable reloadData];
}

@end
