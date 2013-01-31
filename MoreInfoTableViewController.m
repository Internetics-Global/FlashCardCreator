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

@interface MoreInfoTableViewController ()

@end

@implementation MoreInfoTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title =@"Setting";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (isUserInterfaceIdiomPhone) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
            cell.textLabel.text = @"Dropbox";
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
            cell.textLabel.text = @"Random play";
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = _playModeSwitch;
            break;
        }
        case 2:
            cell.textLabel.text = @"Register";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 3:
            cell.textLabel.text = @"Help";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 4:
            cell.textLabel.text = @"About";
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
            NSURL *url = [NSURL URLWithString:@"http://www.internetics.net.au"];
            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
            controller.hidesToolbar = NO;
            [self.navigationController pushViewController:controller animated:YES];
            break;    
        }
        case 2:
        {
            break;
        }
        case 3:
        {
            break;
        }
        case 4:
        {
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

@end
