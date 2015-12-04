//
//  PackListViewControllerV2.m
//  FFC
//
//  Created by Bourne Wang on 7/17/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "PackListViewControllerV2.h"
#import "PackListCell.h"
#import "PackListFirstCell.h"
#import "User.h"
#import "AppDelegate.h"
#import "UIImage+Scale.h"
#import "Pack.h"
#import "User.h"
#import "FileOperationHelper.h"
#import "OpenUDID.h"
#import "CreateEditPackViewController2.h"
#import "PlayViewControllerV2.h"
#import "PopoverView.h"
#import "Base64.h"

@interface PackListViewControllerV2() <UITextFieldDelegate, UINavigationControllerDelegate,UIAlertViewDelegate,PopoverViewDelegate> {

    UIBarButtonItem         * _createNewPackBtnItem;
    UIBarButtonItem         * _backBtnItem;
    UIBarButtonItem         * _editBtnItem;

    Pack                    * _currentPack;
    NSInteger                 _currentIndex;
    BOOL                    _isCollectionViewEditing;
}

@property (assign, nonatomic) SortTypeEnum       sortTypeEnum;
@property (strong, nonatomic) UISegmentedControl * sortSegmentedControl;
@property (strong, nonatomic) UIButton           *userNewButton;
@property (strong, nonatomic) UIButton           *visitStoreButton;

@end


@implementation PackListViewControllerV2


-(void)viewDidLoad
{
    [self.collectionView registerClass:[PackListCell class] forCellWithReuseIdentifier:@"PackListCell"];
    [self.collectionView registerClass:[PackListFirstCell class] forCellWithReuseIdentifier:@"PackListFirstCell"];
    
    self.view.backgroundColor = [UIColor colorWithRed:63.0/255 green:63.0/255 blue:63.0/255 alpha:0.3];
    
    _isCollectionViewEditing = NO;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"sortTypeEnum"] == nil) {
        _sortTypeEnum = SortTypeLastVisitedDescend; //default value
    } else {
        _sortTypeEnum = (SortTypeEnum) [[NSUserDefaults standardUserDefaults] integerForKey:@"sortTypeEnum"];
    }
    
    
    [[User defaultUser] sortPacks:_sortTypeEnum];
    
    //From: click "add pack" button on navigation bar
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePackListNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
    
    //From: add downloaded pack
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePackListNotification:) name:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:nil];
    
    //Don't need the back button when on iPad
    
    _editBtnItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Edit", @"") style:UIBarButtonItemStylePlain target:self action:@selector(editBtnItemClicked:)];
    
    if (isUserInterfaceIdiomPhone) {
        _backBtnItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:_backBtnItem,_editBtnItem, nil];
    } else {
        self.navigationItem.leftBarButtonItem = _editBtnItem;
    }
    
    _createNewPackBtnItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Create_New_Pack", @"") style:UIBarButtonItemStylePlain target:self action:@selector(createNewPackButtonClicked:)];
    self.navigationItem.rightBarButtonItem = _createNewPackBtnItem;
    
    _currentIndex = -1;
    
    
    [self.sortSegmentedControl addTarget:self action:@selector(switchSort:) forControlEvents:UIControlEventValueChanged];
    
    switch (_sortTypeEnum) {
        case SortTypeLastCreatedDescend:
            self.sortSegmentedControl.selectedSegmentIndex = 0;
            break;
        case SortTypeLastVisitedDescend:
            self.sortSegmentedControl.selectedSegmentIndex = 1;
            break;
            
        default:
            break;
    }
    
    self.title = NSLocalizedString(@"Title_Pack_List",@"");;
    
    [self resetPackContent];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.automaticallyAdjustsScrollViewInsets = FALSE;
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.userNewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.userNewButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
    self.userNewButton.frame = CGRectMake(14, CGRectGetHeight(self.view.frame) - 40, 84, 30);
    [self.userNewButton titleLabel].font = [UIFont systemFontOfSize:16];
    [self.userNewButton setTitle:NSLocalizedString(@"Label_New_User",@"") forState:UIControlStateNormal];
    [self.userNewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:self.userNewButton];
    
    
    self.sortSegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Label_Recently_Created",@""),NSLocalizedString(@"Label_Recently_Viewed",@""), nil]];
    self.sortSegmentedControl.frame = CGRectMake(CGRectGetWidth(self.view.frame) - 250 -5, CGRectGetHeight(self.view.frame) - 40, 250, 29);
    self.sortSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.sortSegmentedControl];
    
    switch (_sortTypeEnum) {
        case SortTypeLastCreatedDescend:
            self.sortSegmentedControl.selectedSegmentIndex = 0;
            break;
        case SortTypeLastVisitedDescend:
            self.sortSegmentedControl.selectedSegmentIndex = 1;
            break;
            
        default:
            break;
    }
    
    self.visitStoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if (isUserInterfaceIdiomPhone) {
        self.visitStoreButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        self.visitStoreButton.frame = CGRectOffset(_userNewButton.frame, CGRectGetWidth(_userNewButton.frame) + 20, 0);
    } else {
        self.visitStoreButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
        self.visitStoreButton.frame = CGRectMake((CGRectGetMaxX(self.userNewButton.frame) + CGRectGetMinX(self.sortSegmentedControl.frame) - 84)/2, CGRectGetMinY(self.userNewButton.frame), 84, 30);
    }
    [self.visitStoreButton titleLabel].font = [UIFont systemFontOfSize:16];
    [self.visitStoreButton setTitle:NSLocalizedString(@"Label_Visit_Store",@"") forState:UIControlStateNormal];
    [self.visitStoreButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:self.visitStoreButton];
    
    [self.sortSegmentedControl addTarget:self action:@selector(switchSort:) forControlEvents:UIControlEventValueChanged];
    [self.userNewButton addTarget:self action:@selector(showIntroduction:) forControlEvents:UIControlEventTouchDown];
    [self.visitStoreButton addTarget:self action:@selector(visitStoreButtonClicked:) forControlEvents:UIControlEventTouchDown];
    
    APP_DELEGATE.isAllowToShowTooltip = YES;

}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.collectionView reloadData];
    
    if (isUserInterfaceIdiomPhone == FALSE) {
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    }
    
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"isPackListOpenedBefore"
     ];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark – UICollectionView related

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    NSInteger count =  [[User defaultUser].packs count] + 1;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == 0) {
        PackListFirstCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PackListFirstCell" forIndexPath:indexPath];
        return cell;
    } else {
        
        NSInteger index = indexPath.row - 1;
        
        Pack *pack = (Pack *)[[[User defaultUser] packs] objectAtIndex:index];
        
        PackListCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PackListCell" forIndexPath:indexPath];
        
        NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[((Pack *)[[User defaultUser].packs objectAtIndex:index]).coverImageURL lastPathComponent]];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        if (image == NULL) {
            cell.coverImageView.image = [UIImage imageNamed:@"default_pack_cover_image"];
        } else {
            cell.coverImageView.image = image;
        }
        
        
        cell.packNameText.text = pack.packName;
        
        if (_isCollectionViewEditing) {
            cell.deleteButton.hidden = NO;
        } else {
            cell.deleteButton.hidden = YES;
        }
        
        if (_isCollectionViewEditing) {
            cell.changeImageButton.hidden = NO;
        } else {
            cell.changeImageButton.hidden = YES;
        }
        
        cell.deleteButton.tag = index;
        [cell.deleteButton addTarget:self action:@selector(deleteCurrentPack:) forControlEvents:UIControlEventTouchDown];
        
        cell.packNameText.tag = index;
        cell.packNameText.delegate = self;
        
        cell.changeImageButton.tag = index;
        [cell.changeImageButton addTarget:self action:@selector(editPackButtonClicked:) forControlEvents:UIControlEventTouchDown];
        
        cell.playButton.tag = index;
        [cell.playButton addTarget:self action:@selector(playButtonClicked:) forControlEvents:UIControlEventTouchDown];
        
        if (pack.packID == [self getPackIDForLastSelected]) {
            //cell.maskImageView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
            cell.coverImageView.layer.borderColor = [UIColor greenColor].CGColor;
            cell.coverImageView.layer.borderWidth = 3;
            cell.lockImageView.hidden = NO;
            
            
        } else {
            cell.maskImageView.backgroundColor = [UIColor clearColor];
            cell.coverImageView.layer.borderWidth = 0;
            cell.lockImageView.hidden = YES;
        }
        
        if ((self.packIDInMasterView != pack.packID) && [Common isOwner:pack] && _isCollectionViewEditing) {
            cell.packNameText.layer.borderColor = [[UIColor whiteColor] CGColor];
            cell.packNameText.layer.borderWidth = 1;
            cell.packNameText.userInteractionEnabled = TRUE;
            cell.packNameText.backgroundColor = [UIColor whiteColor];
            cell.packNameText.textColor = [UIColor blackColor];
        } else {
            cell.packNameText.layer.borderWidth = 0;
            cell.packNameText.userInteractionEnabled = FALSE;
            cell.packNameText.backgroundColor = [UIColor clearColor];
            cell.packNameText.textColor = [UIColor whiteColor];
        }
        
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index = indexPath.row;
    
    [iConsole info:@"Selected item at index %d", indexPath.row];
    
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.popController dismissPopoverAnimated:YES];
        [self.popController.delegate popoverControllerDidDismissPopover:self.popController];
    }
    
    if (index == 0) {
        [self createNewPackButtonClicked:nil];
    } else {
        Pack *selectedPack = [[User defaultUser].packs objectAtIndex:index -1];
        selectedPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
        [selectedPack savePackOnly];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_PACK_SELECTED_NOTIFICATION object:selectedPack];
        
        [self setPackIDForLastSelected:selectedPack.packID];
        
    }
    
    
}

#pragma mark -
#pragma mark - Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotate {
    
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark – Actions

-  (void) playButtonClicked:(id) sender {
    [iConsole info:@"%s",__FUNCTION__];
    
    NSInteger packIndex = ((UIButton *)sender).tag;
    
    One_Off_Play_Type oneOffType;
    
    switch ([Common getPlayOption]) {
        case 0:
            oneOffType = One_Off_Play_Type_Manually;
            break;
        case 1:
            oneOffType = One_Off_Play_Type_Auto_Play;
            break;
        case 2:
            oneOffType = One_Off_Play_Type_Auto_Play_Loop;
            break;
            
        default:
            oneOffType = One_Off_Play_Type_Unkown;
            break;
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLAY_NOTIFICATION object:@[[NSNumber numberWithInteger:oneOffType],[NSNumber numberWithInteger:packIndex]]];
    
    Pack *selectedPack = [[User defaultUser].packs objectAtIndex:packIndex];
    selectedPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
    [selectedPack savePackOnly];
    
    [self setPackIDForLastSelected:selectedPack.packID];
    
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.popController dismissPopoverAnimated:NO];
        [self.popController.delegate popoverControllerDidDismissPopover:self.popController];
    }
    
    double delayInSeconds = 0.4;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_PACK_SELECTED_NOTIFICATION object:selectedPack];
    });
    
    
    
}

- (void) resetPackContent {
    [[User defaultUser] sortPacks:_sortTypeEnum];
    
}


- (void) switchSort:(id)sender {
    
    switch (self.sortSegmentedControl.selectedSegmentIndex) {
        case 0: {
            _sortTypeEnum = SortTypeLastCreatedDescend;
            [self resetPackContent];
            
            [self.collectionView reloadData];
            break;
        }
        case 1: {
            _sortTypeEnum = SortTypeLastVisitedDescend;
            [self resetPackContent];
            
            [self.collectionView reloadData];
            break;
        }
            
        default:
            break;
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:_sortTypeEnum forKey:@"sortTypeEnum"
     ];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
}

- (void) visitStoreButtonClicked:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Not implemented" message:@"Not implemented" delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
    [alertView show];
}


- (void) showIntroduction:(id)sender {
    if (isUserInterfaceIdiomPhone) {
    } else {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self.popController dismissPopoverAnimated:YES];
        [self.popController.delegate popoverControllerDidDismissPopover:self.popController];

    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_VIDEO_NOTIFICATION object:self];
}

- (void) editBtnItemClicked:(id)sender {
    if ([_editBtnItem.title isEqualToString:NSLocalizedString(@"NavigationBarItem_Edit", @"")]) {
        _editBtnItem.title = NSLocalizedString(@"NavigationBarItem_Done", @"");
        _isCollectionViewEditing = YES;
        [self.collectionView reloadData];
    } else {
        _editBtnItem.title = NSLocalizedString(@"NavigationBarItem_Edit", @"");
        
        if (isUserInterfaceIdiomPhone) {
            self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:_backBtnItem,_editBtnItem, nil];
            
        } else {
            self.navigationItem.leftBarButtonItem = _editBtnItem;
        }
    
        _isCollectionViewEditing = NO;
        [self.collectionView reloadData];
        
    }
    
}

- (void) createNewPackButtonClicked:(id)sender {
    
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.popController dismissPopoverAnimated:YES];
        [self.popController.delegate popoverControllerDidDismissPopover:self.popController];
    }
    
    [self performSelector:@selector(sendNotificationAfterCreateNewPack) withObject:nil afterDelay:0.5]; // only in iOS7, you can not directly call without delay, otherwise, you will not be able to click navigation bar again
    
    
}

- (void) sendNotificationAfterCreateNewPack {
    [[NSNotificationCenter defaultCenter] postNotificationName:TO_CREATE_NEW_PACK_NOTIFICATION object:self];
}

- (void) backButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) deleteCurrentPack:(id) sender {
    _currentIndex = ((UIButton *)sender).tag;
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    Pack *pack = (Pack *)[[[User defaultUser] packs] objectAtIndex:_currentIndex];
    if (appDelegate.packIDForMasterViewPack != pack.packID) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:NSLocalizedString(@"DIALOG_DELETE_PACK",@"")
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Cancel",@"")
                                              otherButtonTitles:NSLocalizedString(@"Keyboard_Delete",@""), nil];
        alert.delegate = self;
        alert.tag = 1;
        [alert show];
        APP_DELEGATE.isAllowToShowPackList = NO;
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:NSLocalizedString(@"DIALOG_PACK_IS_BEING_USED",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    
    
}

- (void) editPackButtonClicked: (id) sender {
    
    NSInteger index = ((UIButton *) sender).tag;
    _currentPack = (Pack *)[[[User defaultUser] packs] objectAtIndex:index];
    
    if ([Common isOwner:_currentPack] == FALSE) {
        UIAlertView *alert;
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            alert = [[UIAlertView alloc] initWithTitle:nil
                                               message:@"Input admin password"
                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                     otherButtonTitles:NSLocalizedString(@"Keyboard_Cancel",@""), nil];
        } else {
            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"")
                                               message:@"Input admin password"
                                              delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                     otherButtonTitles:NSLocalizedString(@"Keyboard_Cancel",@""), nil];
        }
        alert.tag = 2;
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alert textFieldAtIndex:0].text = @"";
        alert.delegate = self;
        [alert show];
        
        return;
        
    }
    
    [self gotoPackEditView];
}

- (void) gotoPackEditView {
    
    CreateEditPackViewController2 * createPackController;
    if (isUserInterfaceIdiomPhone) {
        createPackController = [[CreateEditPackViewController2 alloc] initWithNibName:@"CreateEditPackViewController2_iPhone" bundle:nil];
    } else {
        createPackController = [[CreateEditPackViewController2 alloc] initWithNibName:@"CreateEditPackViewController2_iPad" bundle:nil];
    }
    createPackController.isEditPack = YES;
    createPackController.currentPack = _currentPack;
    
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:createPackController animated:YES];
    } else {
        
        [self.popController dismissPopoverAnimated:YES];
        [self.popController.delegate popoverControllerDidDismissPopover:self.popController];
        
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:createPackController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navController animated:YES];
    }
}


#pragma mark -
#pragma mark - Notification related

-(void)updatePackListNotification:(NSNotification *)notification{
	[self resetPackContent];
    [self.collectionView reloadData];
}


#pragma mark -
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {
        if (buttonIndex == 0) {
            //do nothing
        } else if (buttonIndex == 1) {
            // delete operation
            _currentPack = [[[User defaultUser] packs] objectAtIndex:_currentIndex];
            [[User defaultUser] removePack:_currentPack];
            [self resetPackContent];
            
            //Recalculate:
            Pack *latestPack = [[[User defaultUser] packs] lastObject];
            if (latestPack != nil) {
                //Update_date info
                NSString *updateDate = [FileOperationHelper getTodayString];
                NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:latestPack.packName];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
                [dict setObject:updateDate forKey:@"update_date"];
                [[NSUserDefaults standardUserDefaults] setObject:dict forKey:latestPack.packName];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            _currentIndex = -1;
            [_createNewPackBtnItem setTitle:NSLocalizedString(@"NavigationBarItem_Create_New_Pack", @"")];
            
            [self.collectionView reloadData];
        }
        
        APP_DELEGATE.isAllowToShowPackList = YES;
    } else if (alertView.tag == 2) {
    
        NSString *password = [alertView textFieldAtIndex:0].text;
        
        if (buttonIndex == 0) {
            if ([password isEqualToString:[_currentPack.restorePassword base64DecodedString]]) {
                [[alertView textFieldAtIndex:0] resignFirstResponder];
                
                if ([Common isOwner:_currentPack] == false) {
                    _currentPack.creator = [OpenUDID value];
                    [_currentPack savePackOnly];
                }
                
                double delayInSeconds = 0.4;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    //do something here
                    
                    [self gotoPackEditView];
                    
                });
                
                
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:NSLocalizedString(@"DIALOG_WRONG_PASSWORD",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
    }
}


- (long) getPackIDForLastSelected {
    
    NSInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCreatedPackID"];
    return val;
    
}

- (void) setPackIDForLastSelected:(int) packID {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:packID forKey:@"lastCreatedPackID"];
    [defaults synchronize];
}

#pragma mark -
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    Pack *currentPack = [[[User defaultUser] packs] objectAtIndex:textField.tag];
    currentPack.packName = textField.text;
    [currentPack save];
}


#pragma mark - PopoverViewDelegate Methods

- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
    
}



//iOS7 special for UIImagePickerController
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
