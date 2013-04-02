//
//  MoreInfoTableViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 18/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "MoreInfoTableViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "SimpleWebBrowserController.h"
#import "AboutViewController.h"

BOOL isLoggingDropboxInSettingView = NO;

@interface MoreInfoTableViewController ()

@end

@implementation MoreInfoTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title =NSLocalizedString(@"Title_More",@"");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableViewNotification:) name:REFRESH_SETTING_TABLEVIEW_NOTIFICATION
 object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (isUserInterfaceIdiomPhone) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    self.tableView.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 1;
    } else if (section == 2) {
        return (([self isUserHasLoginInternectics] == YES)?1:2);
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor whiteColor];
    }

    
    if (_dropboxSwitch == nil) {
        _dropboxSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [_dropboxSwitch addTarget:self action:@selector(dropboxSwitchAction) forControlEvents:UIControlEventValueChanged];
    }
    
    if (_playModeSwitch == nil) {
        _playModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [_playModeSwitch addTarget:self action:@selector(playModeSwitchAction) forControlEvents:UIControlEventValueChanged];
    }
    
    if (indexPath.section ==0) {
        cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_Dropbox",nil);
        cell.accessoryType = UITableViewCellAccessoryNone;
        [_dropboxSwitch setOn:[[DBSession sharedSession] isLinked]];
        cell.accessoryView = _dropboxSwitch;

    } else if (indexPath.section ==1) {
        BOOL isRandomPlayMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRandomPlayMode"];
        if (isRandomPlayMode) {
            [_playModeSwitch setOn:YES];
        } else {
            [_playModeSwitch setOn:NO];
        }
        cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_RandomPlay",nil);
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = _playModeSwitch;
        
    } else if (indexPath.section ==2) {
        if ([self isUserHasLoginInternectics] == YES) {
            cell.textLabel.text = @"Submit new listing";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            if (indexPath.row ==0) {
                cell.textLabel.text = @"Register";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else if (indexPath.row ==1) {
                cell.textLabel.text = @"Submit new listing";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        
    } else if (indexPath.section ==3) {
        if (indexPath.row ==0) {
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_Help",nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_About",nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
        
    return cell;
}

- (void) dropboxSwitchAction {
    if (!_dropboxSwitch.on) {
        [[DBSession sharedSession] unlinkAll];
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_DROPBOX_HAS_BEEN_UNLINKED",@"")];
    } else {
        [[DBSession sharedSession] linkFromController:self];
        isLoggingDropboxInSettingView = YES;
    }
}

- (void) playModeSwitchAction {
    
    [[NSUserDefaults standardUserDefaults] setBool:_playModeSwitch.on forKey:@"isRandomPlayMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==0) {
        
    }else if (indexPath.section ==1) {
        
    }else if (indexPath.section ==2) {
        if (indexPath.row == 0) {
            NSURL *url;
            if ([self isUserHasLoginInternectics] == YES) {
                url = [NSURL URLWithString:@"http://internetics.net.au/fcc/add-new/"];
                
            } else {
                url = [NSURL URLWithString:@"http://internetics.net.au/fcc/register/"];
            }
            
            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
            controller.hidesToolbar = NO;
            
            if (isUserInterfaceIdiomPhone) {
                [self.navigationController pushViewController:controller animated:YES];
            } else {
                UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:controller];
                navController.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentModalViewController:navController animated:YES];
            }
            
        } else {
            NSURL *url = [NSURL URLWithString:@"http://internetics.net.au/fcc/add-new/"];
            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
            controller.hidesToolbar = NO;
            if (isUserInterfaceIdiomPhone) {
                [self.navigationController pushViewController:controller animated:YES];
            } else {
                controller.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentModalViewController:controller animated:YES];
            }
        }
        
    }else if (indexPath.section ==3) {
        if (indexPath.row ==0) {
            NSURL *url = [NSURL URLWithString:@"http://www.flipflashcards.com.au"];
            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
            controller.hidesToolbar = NO;
            if (isUserInterfaceIdiomPhone) {
                [self.navigationController pushViewController:controller animated:YES];
            } else {
                controller.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentModalViewController:controller animated:YES];
            }
        } else {
            AboutViewController *about = [[AboutViewController alloc] init];
            [self.navigationController pushViewController:about animated:YES];
        }
    }
}

#pragma mark -
#pragma mark - Others
//Indicate that user has log in http://internetics.net.au (judged by cookie)
- (BOOL) isUserHasLoginInternectics {
    NSArray *cookiesArray = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://internetics.net.au/fcc/add-new"]];
    for (NSHTTPCookie *cookie in cookiesArray) {
        NSDate *expiresDate = [cookie expiresDate];
        if ([expiresDate compare:[NSDate date]] == NSOrderedDescending) {
            return YES;
        }
    }
    return NO;
}

#pragma mark -
#pragma mark - UICtonrol Action
- (void) backButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark - Notification

- (void) refreshTableViewNotification:(NSNotification *) notification {
    [self.tableView reloadData];
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
