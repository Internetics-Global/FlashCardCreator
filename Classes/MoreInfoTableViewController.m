//
//  MoreInfoTableViewController.m
//  FFC
//
//  Created by Wang Bourne on 18/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "MoreInfoTableViewController.h"
#import "SimpleWebBrowserController.h"
#import "AboutViewController.h"
#import "FileOperationHelper.h"

#import "ZipArchive.h"

#import "AppDelegate.h"

#import <Social/Social.h>

#import "Common.h"

#import "PlayOptionViewController.h"

#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "PurchaseViewController.h"

#import "MutipleTargetHelper.h"

#import "SelectText2SpeechLanguage.h"
#import "StorageOptionViewController.h"

@interface MoreInfoTableViewController () <UIActionSheetDelegate>

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
    int offset = 0;
    if ([MutipleTargetHelper isFullVersion] == false) {
        offset = 1;
    }
    
    return 10 + offset;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SwitchCell";
    
    if (indexPath.row == 3 || indexPath.row == 10) {
        CellIdentifier = @"CommonCell";
    } else if (indexPath.row == 7 || indexPath.row == 9 || indexPath.row == 0) {
        CellIdentifier = @"SlideCell";
    } else {
        CellIdentifier = @"SwitchCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CellIdentifier"];
        cell.backgroundColor = [UIColor whiteColor];
    }

    if (indexPath.row == 0) {
        
        cell.textLabel.text = NSLocalizedString(@"Manual/Auto Play",nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    } else if (indexPath.row ==1) {
        
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
        
        
    } else if (indexPath.row ==2) {
        
        _notMuteSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [_notMuteSwitch addTarget:self action:@selector(notMuteSwitchAction) forControlEvents:UIControlEventValueChanged];
        
        BOOL isNotMuteMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"isNotMuteMode"];
        if (isNotMuteMode) {
            [_notMuteSwitch setOn:YES];
        } else {
            [_notMuteSwitch setOn:NO];
        }
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Personal_Recording",@"");
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = _notMuteSwitch;
        
        
    } else if (indexPath.row == 3) {
        cell.textLabel.text = NSLocalizedString(@"NavigationBarItem_More_About",nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 4) {
        cell.textLabel.text = NSLocalizedString(@"Table_Item_TTS",@"");
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *textToSpeechSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [textToSpeechSwitch addTarget:self action:@selector(textToSpeechSwitchAction) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = textToSpeechSwitch;
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"];
        [textToSpeechSwitch setOn:b];
    } else if (indexPath.row == 5) {
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Function_Prompt",@"");
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *functionPromptSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [functionPromptSwitch addTarget:self action:@selector(functionPromptSwitchAction) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = functionPromptSwitch;
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isFunctionPromptOff"];
        [functionPromptSwitch setOn:!b];
    } else if (indexPath.row == 6) {
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Show_Question_Only",@"");
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *showQuestionOnlySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [showQuestionOnlySwitch addTarget:self action:@selector(showQuestionOnlyAction) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = showQuestionOnlySwitch;
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isShowQuestionOnly"];
        [showQuestionOnlySwitch setOn:b];
    } else if (indexPath.row == 7) {
        
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Speech_Language_Select",nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 8) {
        
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

    } else if (indexPath.row == 9) {
        
        cell.textLabel.text = NSLocalizedString(@"Table_Item_Storage",@"");
        
        if ([MutipleTargetHelper isFullVersion]) {
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.alpha = 1;
        } else {
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.textLabel.alpha = 0.2;
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        
    } else if (indexPath.row == 10) {
        
        cell.textLabel.text = NSLocalizedString(@"Upgrade",nil);
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

- (void) notMuteSwitchAction {
    [[NSUserDefaults standardUserDefaults] setBool:(_notMuteSwitch.on) forKey:@"isNotMuteMode"];
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

- (void) functionPromptSwitchAction {
    
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isFunctionPromptOff"];
    [[NSUserDefaults standardUserDefaults] setBool:!b forKey:@"isFunctionPromptOff"];
    
    if (b == false) {
        
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"K_Transparent_Finger_Animation_Disabled_Question"];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"K_Transparent_Finger_Animation_Disabled_Answer"];
    }
    
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
    __weak __typeof(&*self)weakSelf = self;
    if (indexPath.row == 3) {
        AboutViewController *about = [[AboutViewController alloc] init];
        [self.navigationController pushViewController:about animated:YES];
//    } else if (indexPath.row == 9) {
//        
//        if ([PFUser currentUser]) {
//            [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
//                if (error) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_SOCIAL_MEDIA_LOG_OUT_FAILURE",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CLOSE",@"") otherButtonTitles:nil, nil];
//                        [alertView show];
//                        
//                    });
//                } else {
//                    if (isUserInterfaceIdiomPhone == false) {
//                        [self dismissViewControllerAnimated:YES completion:nil];
//                    }
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        
//                        [weakSelf.tableView reloadData];
//                    
//                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_SOCIAL_MEDIA_LOG_OUT_SUCCESS",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_CLOSE",@"") otherButtonTitles:nil, nil];
//                        [alertView show];
//                        
//                    });
//                }
//            }];
//            
//            
//        } else {
//            
//            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
//            logInController.fields = (PFLogInFieldsUsernameAndPassword
//                                      | PFLogInFieldsLogInButton
//                                      | PFLogInFieldsPasswordForgotten
//                                      | PFLogInFieldsFacebook
//                                      | PFLogInFieldsTwitter
//                                      | PFLogInFieldsSignUpButton
//                                      | PFLogInFieldsDismissButton);
//            logInController.fromSetting = YES;
//            
//            logInController.signUpController.fields = (PFSignUpFieldsUsernameAndPassword
//                                                       | PFSignUpFieldsEmail
//                                                       | PFSignUpFieldsAdditional
//                                                       | PFSignUpFieldsDismissButton
//                                                       | PFSignUpFieldsSignUpButton);
//            
//            logInController.signUpController.fromSetting = YES;
//            
//            
//            if (isUserInterfaceIdiomPhone) {
//                logInController.signUpController.delegate = self;
//                logInController.delegate = self;
//                [self presentViewController:logInController animated:YES completion:nil];
//            } else {
//                logInController.signUpController.delegate = APP_DELEGATE.masterViewController;
//                logInController.delegate = APP_DELEGATE.masterViewController;
//                [self dismissViewControllerAnimated:YES completion:^{
//                    
//                    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:logInController animated:YES completion:nil];
//                    
//                }];
//            }
//            
//            
//            APP_DELEGATE.isAllowToShowPackList = NO;
//        }
        
    } else if (indexPath.row == 10) {
        if (isUserInterfaceIdiomPhone == false) {
            [self dismissViewControllerAnimated:false completion:nil];
        }
        [MutipleTargetHelper showPurchaseView];
    } else if (indexPath.row == 9) {
        if ([MutipleTargetHelper isFullVersion]) {
            StorageOptionViewController *controller = [[StorageOptionViewController alloc] initWithNibName:nil bundle:nil];
            [self.navigationController pushViewController:controller animated:YES];
        }
        
    } else if (indexPath.row == 0) {
        PlayOptionViewController *controller = [[PlayOptionViewController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
    } else if (indexPath.row == 7) {
        SelectText2SpeechLanguage *controller = [[SelectText2SpeechLanguage alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
