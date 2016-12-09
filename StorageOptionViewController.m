//
//  PlayOptionViewController.m
//  FlashCardCreator
//
//  Created by Internetics on 4/12/2015.
//  Copyright © 2015 Internetics. All rights reserved.
//

#import "StorageOptionViewController.h"
#import "Common.h"
#import <DropboxSDK/DropboxSDK.h>
#import "GoogleDriveHelper.h"
#import "AppDelegate.h"

@interface StorageOptionViewController () <UITableViewDelegate, UITableViewDataSource,DBSessionDelegate>{
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLinkedNotification:) name:DROPBOX_LINKED_NOTIFICATION object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
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
        BOOL b = [[DBSession sharedSession] isLinked];
        [mySwitch setOn:b];
        
        
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Google_Drive",@"");
        
        UISwitch *mySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [mySwitch addTarget:self action:@selector(dropboxLogInOutAction:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = mySwitch;
        BOOL b = [[GoogleDriveHelper sharedHelper] isLinked];
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


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}


- (void) dropboxLogInOutAction:(UISwitch *) myswitch {
    
    
    if (![[DBSession sharedSession] isLinked]) {
        [DBSession sharedSession].delegate = self;
        [[DBSession sharedSession] linkFromController:self];
        APP_DELEGATE.isAllowToShareAfterDropboxLogIn = NO;
    } else {
        
        [[DBSession sharedSession] unlinkAll];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
    }
}


#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
    [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
}



#pragma mark -
#pragma mark - DROPBOX_LINKED_NOTIFICATION

- (void) dropboxLinkedNotification:(id)notification
{
    [iConsole info:@"%s",__FUNCTION__];
    NSNumber *linkedNum = [[notification userInfo] objectForKey:@"linked"];
    
    if(![linkedNum boolValue])
    {
        
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
    } else
    {
    }
    
    [_alertTable reloadData];
}

@end
