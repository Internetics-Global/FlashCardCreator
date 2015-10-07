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

#import <DropboxSDK/DropboxSDK.h>

@interface MoreInfoTableViewController () <DBSessionDelegate, DBNetworkRequestDelegate>

@end

@implementation MoreInfoTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title =NSLocalizedString(@"Title_Settings",@"");
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLinkedNotification:) name:DROPBOX_LINKED_NOTIFICATION object:nil];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 8;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SwitchCell";
    
    if (indexPath.row == 2) {
        CellIdentifier = @"CommonCell";
    } else if (indexPath.row == 6) {
        CellIdentifier = @"SlideCell";
    } else {
        CellIdentifier = @"SwitchCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CellIdentifier"];
        cell.backgroundColor = [UIColor whiteColor];
    }

    
    
    if (indexPath.row ==0) {
        
        if (_playModeSwitch == nil) {
            _playModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
            [_playModeSwitch addTarget:self action:@selector(playModeSwitchAction) forControlEvents:UIControlEventValueChanged];
        }
        
        BOOL isRandomPlayMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRandomPlayMode"];
        if (isRandomPlayMode) {
            [_playModeSwitch setOn:YES];
        } else {
            [_playModeSwitch setOn:NO];
        }
        cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_RandomPlay",nil);
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = _playModeSwitch;
        
        
    } else if (indexPath.row ==1) {
        
        _muteSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [_muteSwitch addTarget:self action:@selector(muteSwitchAction) forControlEvents:UIControlEventValueChanged];
        
        BOOL isMuteMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"isMuteMode"];
        if (isMuteMode) {
            [_muteSwitch setOn:YES];
        } else {
            [_muteSwitch setOn:NO];
        }
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Mute_Sound_Recording",@"");
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = _muteSwitch;
        
        
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_About",nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 3) {
        cell.textLabel.text = NSLocalizedString(@"Table_Item_TTS",@"");
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *textToSpeechSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [textToSpeechSwitch addTarget:self action:@selector(textToSpeechSwitchAction) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = textToSpeechSwitch;
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"];
        [textToSpeechSwitch setOn:b];
    } else if (indexPath.row == 4) {
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Show_Question_Only",@"");
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *showQuestionOnlySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [showQuestionOnlySwitch addTarget:self action:@selector(showQuestionOnlyAction) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = showQuestionOnlySwitch;
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isShowQuestionOnly"];
        [showQuestionOnlySwitch setOn:b];
    } else if (indexPath.row == 5) {
        
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Male_Female",@"");
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *voiceSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [voiceSwitch addTarget:self action:@selector(voiceSwitchAction) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = voiceSwitch;
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isMaleVoice"];
        [voiceSwitch setOn:b];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 6) {
        
        UIView *baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 40)];
        baseView.backgroundColor = [UIColor clearColor];
        
        UISlider *countDownSlider= [[UISlider alloc] initWithFrame:CGRectMake(35, 0, 100, 40)];
        countDownSlider.backgroundColor = [UIColor clearColor];
        [[UISlider appearance] setThumbImage:[UIImage imageNamed:@"slide_thumb"] forState:UIControlStateNormal];
        countDownSlider.minimumValue = kMIN_CountDown_Slider_Value;
        countDownSlider.maximumValue = kMAX_CountDown_Slider_Value;
        countDownSlider.continuous = YES;
        countDownSlider.tintColor = [UIColor greenColor];
        [countDownSlider addTarget:self action:@selector(countDownSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [countDownSlider setBackgroundColor:[UIColor clearColor]];
        [baseView addSubview:countDownSlider];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *countDownNumber = [defaults objectForKey:@"K_CountDown_Val"];
        if (countDownNumber) {
            countDownSlider.value = [countDownNumber integerValue];
            
        } else {
            countDownSlider.value = kDEFAULT_CountDown_Slider_Value;
            
            [defaults setObject:[NSNumber numberWithInt:kDEFAULT_CountDown_Slider_Value] forKey:@"K_CountDown_Val"];
            [defaults synchronize];
        }
        
        
        UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 35, 40)];
        leftLabel.textAlignment = NSTextAlignmentLeft;
        leftLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        leftLabel.text = NSLocalizedString(@"Title_None",@"");
        leftLabel.numberOfLines = 1;
        leftLabel.textColor = [UIColor lightGrayColor];
        leftLabel.backgroundColor = [UIColor clearColor];
        [baseView addSubview:leftLabel];
        
        UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(115, 0, 35, 40)];
        rightLabel.textAlignment = NSTextAlignmentRight;
        rightLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        rightLabel.text = [NSString stringWithFormat:@"%d",kMAX_CountDown_Slider_Value];
        rightLabel.numberOfLines = 1;
        rightLabel.textColor = [UIColor lightGrayColor];
        rightLabel.backgroundColor = [UIColor clearColor];
        [baseView addSubview:rightLabel];
        
        cell.accessoryView = baseView;
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",NSLocalizedString(@"Table_Item_Count_Down",@""),(int)countDownSlider.value];
        
    } else if (indexPath.row == 7) {
        
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Amazon_Or_Dropbox",@"");
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *storageProviderSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [storageProviderSwitch addTarget:self action:@selector(storageProviderAction) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = storageProviderSwitch;
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isDropboxAsStorage"];
        [storageProviderSwitch setOn:b];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    
    return cell;
}


- (void) countDownSliderValueChanged:(UISlider *) slider {
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:2]];
    cell.textLabel.text = cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",NSLocalizedString(@"Table_Item_Count_Down",@""),(int) (slider.value)];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:(int)slider.value] forKey:@"K_CountDown_Val"];
    [defaults synchronize];
    
}

- (void) muteSwitchAction {
    [[NSUserDefaults standardUserDefaults] setBool:(_muteSwitch.on) forKey:@"isMuteMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) playModeSwitchAction {
    
    [[NSUserDefaults standardUserDefaults] setBool:_playModeSwitch.on forKey:@"isRandomPlayMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (void) showQuestionOnlyAction {
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isShowQuestionOnly"];
    [[NSUserDefaults standardUserDefaults] setBool:!b forKey:@"isShowQuestionOnly"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void) textToSpeechSwitchAction {
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"];
    [[NSUserDefaults standardUserDefaults] setBool:!b forKey:@"isTextToSpeech"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //see here
    if ((TARGET_IPHONE_SIMULATOR) && (SYSTEM_VERSION_GREATER_THAN(@"8.0"))) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:@"The iOS 8 simulators do not support text-to-speech. However, the iOS 7 simulators do still support text-to-speech (at least as of Xcode 6.1)," delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil];
        [alert show];
    }
    
    
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==1) {
        if (indexPath.row ==0) {
//            NSURL *url = [NSURL URLWithString:@"http://www.flipflashcards.com.au"];
//            SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
//            controller.hidesToolbar = NO;
//            if (isUserInterfaceIdiomPhone) {
//                [self.navigationController pushViewController:controller animated:YES];
//            } else {
//                controller.modalPresentationStyle = UIModalPresentationFormSheet;
//                #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
//                [self presentModalViewController:controller animated:YES];
//            }
        } else {
            AboutViewController *about = [[AboutViewController alloc] init];
            [self.navigationController pushViewController:about animated:YES];
        }
    } else if (indexPath.section == 2) {
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

- (void) storageProviderAction {
    
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isDropboxAsStorage"];
    
    if (!b) {
        if (![[DBSession sharedSession] isLinked]) {
            [DBSession sharedSession].delegate = self;
            [[DBSession sharedSession] linkFromController:self];
        } else {
            
            [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"isDropboxAsStorage"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self.tableView reloadData];
        }
    } else {
        
        [[DBSession sharedSession] unlinkAll];
        
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"isDropboxAsStorage"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.tableView reloadData];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_USE_AMAZON_AS_STORAGE",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    
    

    
}

- (void) voiceSwitchAction {
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isMaleVoice"];
    [[NSUserDefaults standardUserDefaults] setBool:!b forKey:@"isMaleVoice"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark - Notification

- (void) refreshTableViewNotification:(NSNotification *) notification {
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"isDropboxAsStorage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
}


#pragma mark -
#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted {
    outstandingRequests++;
    if (outstandingRequests == 1) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)networkRequestStopped {
    outstandingRequests--;
    if (outstandingRequests == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}


#pragma mark -
#pragma mark - DROPBOX_LINKED_NOTIFICATION

- (void) dropboxLinkedNotification:(id)notification
{
    [iConsole info:@"%s",__FUNCTION__];
    NSNumber *linkedNum = [[notification userInfo] objectForKey:@"linked"];
    
    if(![linkedNum boolValue])
    {
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"isDropboxAsStorage"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_FAIL_TO_LOG_DROPBOX",@"")];
    } else
    {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"isDropboxAsStorage"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
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
