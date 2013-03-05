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

@interface MoreInfoTableViewController ()

@end

@implementation MoreInfoTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title =@"More";
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
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
        
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_Dropbox",nil);
            cell.accessoryType = UITableViewCellAccessoryNone;
            [_dropboxSwitch setOn:[[DBSession sharedSession] isLinked]];
            cell.accessoryView = _dropboxSwitch;
            break;
        case 1:
        {
            BOOL isRandomPlayMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRandomPlayMode"];
            if (isRandomPlayMode) {
                [_playModeSwitch setOn:YES];
            } else {
                [_playModeSwitch setOn:NO];
            }
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_RandomPlay",nil);
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = _playModeSwitch;
            break;
        }
        case 2:
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_Register",nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 3:
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_Logo_In",nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 4:
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_Help",nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 5:
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_About",nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:
            break;
    }
    
    return cell;
}

- (void) dropboxSwitchAction {
    if (!_dropboxSwitch.on) {
        [[DBSession sharedSession] unlinkAll];
        [Common alertViewCommon:@"Your dropbox account has been unlinked"];
    } else {
        [[DBSession sharedSession] linkFromController:self];
    }
}

- (void) playModeSwitchAction {
    
    [[NSUserDefaults standardUserDefaults] setBool:_playModeSwitch.on forKey:@"isRandomPlayMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
        {
            break;    
        }
        case 1:
        {
            break;    
        }
        case 2:
        {
            NSURL *url = [NSURL URLWithString:@"http://internetics.net.au/fcc/register/"];
            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
            controller.hidesToolbar = NO;
            if (isUserInterfaceIdiomPhone) {
                [self.navigationController pushViewController:controller animated:YES];    
            } else {
                controller.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentModalViewController:controller animated:YES];
            }
            
            break;
        }
        case 3:
        {
            NSURL *url = [NSURL URLWithString:@"http://internetics.net.au/fcc/add-new/"];
            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
            controller.hidesToolbar = NO;
            if (isUserInterfaceIdiomPhone) {
                [self.navigationController pushViewController:controller animated:YES];
            } else {
                controller.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentModalViewController:controller animated:YES];
            }
            break;
        }
        case 4:
        {
            NSURL *url = [NSURL URLWithString:@"http://www.internetics.net.au"];
            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
            controller.hidesToolbar = NO;
            if (isUserInterfaceIdiomPhone) {
                [self.navigationController pushViewController:controller animated:YES];
            } else {
                controller.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentModalViewController:controller animated:YES];
            }
            break;
        }
        case 5:
        {
            AboutViewController *about = [[AboutViewController alloc] init];
            [self.navigationController pushViewController:about animated:YES];
            break;
        }
        default:
        {
            break;    
        }
            
    }
}

#pragma mark -
#pragma mark - Close current view
- (void) backButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
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

@end
