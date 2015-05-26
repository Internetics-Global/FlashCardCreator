//
//  MoreInfoTableViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 18/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "MoreInfoTableViewController.h"
#import "SimpleWebBrowserController.h"
#import "AboutViewController.h"
#import "FileOperationHelper.h"

#import "ZipArchive.h"

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
    self.tableView.separatorColor = [UIColor colorWithRed:67.0/255 green:67.0/255 blue:67.0/255 alpha:0.95];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        if (isUserInterfaceIdiomPhone == FALSE) {
            if (isUserInterfaceIdiomPhone == FALSE) {
                [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            }
        }
    }
    
    UITapGestureRecognizer *fiveTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendLog)];
    fiveTap.numberOfTapsRequired = 5;
    [self.view addGestureRecognizer:fiveTap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void) sendLog {
  [[iConsole sharedConsole] sendLogViaMail];
}



#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    if (error) {
        NSLog(@"%@", error);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return 0.2;
    } else {
        return 0.1;
    }
}




- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else if (section == 1) {
#ifdef CLIENT_DEBUG_MODE
        return (3);
#else
        return (2);
#endif
    } else if (section == 2) {
        return 1;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SwitchCell";
    
    if ((indexPath.section == 0) || (indexPath.section == 1)) {
        CellIdentifier = @"SwitchCell";    
    } else {
        CellIdentifier = @"CommonCell";  
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
    if (cell == nil) {
        if ([CellIdentifier isEqualToString:@"SwitchCell"]) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SwitchCell"];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CommonCell"];    
        }
        cell.backgroundColor = [UIColor whiteColor];
    }

    
    if (_playModeSwitch == nil) {
        _playModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [_playModeSwitch addTarget:self action:@selector(playModeSwitchAction) forControlEvents:UIControlEventValueChanged];
    }
    
    if (indexPath.section ==0) {
        BOOL isRandomPlayMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRandomPlayMode"];
        if (isRandomPlayMode) {
            [_playModeSwitch setOn:YES];
        } else {
            [_playModeSwitch setOn:NO];
        }
        cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_RandomPlay",nil);
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = _playModeSwitch;
        
        
    } else if (indexPath.section ==1) {
        if (indexPath.row ==0) {
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_Help",nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_About",nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 2){
            cell.textLabel.text = @"Always editable";
            cell.accessoryType = UITableViewCellAccessoryNone;
            UISwitch *editableSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
            [editableSwitch addTarget:self action:@selector(editableSwitchAction) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = editableSwitch;
            BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isCardEditableForDebugMode"];
            [editableSwitch setOn:b];
            
        }
    } else if (indexPath.section ==2) {
        if (indexPath.row ==0) {
            cell.textLabel.text = @"Text to Speech";
            cell.accessoryType = UITableViewCellAccessoryNone;
            UISwitch *textToSpeechSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
            [textToSpeechSwitch addTarget:self action:@selector(textToSpeechSwitchAction) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = textToSpeechSwitch;
            BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"];
            [textToSpeechSwitch setOn:b];
        }    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
        
    return cell;
}


- (void) playModeSwitchAction {
    
    [[NSUserDefaults standardUserDefaults] setBool:_playModeSwitch.on forKey:@"isRandomPlayMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}



- (void) editableSwitchAction {
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isCardEditableForDebugMode"];
    [[NSUserDefaults standardUserDefaults] setBool:!b forKey:@"isCardEditableForDebugMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [Common alertViewCommon:@"Note: re-select packs to take effect."];
}

- (void) textToSpeechSwitchAction {
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"];
    [[NSUserDefaults standardUserDefaults] setBool:!b forKey:@"isTextToSpeech"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //see here
    if ((TARGET_IPHONE_SIMULATOR) && (SYSTEM_VERSION_GREATER_THAN(@"8.0"))) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"The iOS 8 simulators do not support text-to-speech. However, the iOS 7 simulators do still support text-to-speech (at least as of Xcode 6.1)," delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==1) {
        if (indexPath.row ==0) {
            NSURL *url = [NSURL URLWithString:@"http://www.flipflashcards.com.au"];
            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
            controller.hidesToolbar = NO;
            if (isUserInterfaceIdiomPhone) {
                [self.navigationController pushViewController:controller animated:YES];
            } else {
                controller.modalPresentationStyle = UIModalPresentationFormSheet;
                #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
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
