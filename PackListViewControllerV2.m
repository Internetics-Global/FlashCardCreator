//
//  PackListViewControllerV2.m
//  FlashCardCreator
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
#import "Common.h"
#import "OpenUDID.h"

@interface PackListViewControllerV2() <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIAlertViewDelegate> {
    UIImagePickerController * _picker;
    UIPopoverController     * _imagePickerPopover;

    UIBarButtonItem         * _createNewPackBtnItem;
    UIBarButtonItem         * _backBtnItem;
    UIBarButtonItem         * _editBtnItem;

    Pack                    * _currentPack;
    int                     _currentIndex;
    BOOL                    _isCollectionViewEditing;
}

@property (assign, nonatomic) SortTypeEnum       sortTypeEnum;
@property (strong, nonatomic) UISegmentedControl * sortSegmentedControl;
@property (strong, nonatomic) UIButton           *userNewButton;

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
        _sortTypeEnum = [[NSUserDefaults standardUserDefaults] integerForKey:@"sortTypeEnum"];
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
    
    
    _picker = [[UIImagePickerController alloc] init];
    _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _picker.contentSizeForViewInPopover = CGSizeMake(320, 400);
    _picker.delegate = self;
    
    
    if (isUserInterfaceIdiomPhone) {
        
    } else {
        if (_imagePickerPopover == nil) {
            _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
        }
    }
    
    _currentIndex = -1;
    
    
    [_userNewButton addTarget:self action:@selector(showIntroduction:) forControlEvents:UIControlEventTouchDown];
    
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
    
    self.title = @"Pack List";
    
    [self resetPackContent];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.automaticallyAdjustsScrollViewInsets = FALSE;
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.userNewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.userNewButton.frame = CGRectMake(14, 260, 84, 30);
    [self.userNewButton titleLabel].font = [UIFont systemFontOfSize:16];
    [self.userNewButton setTitle:@"New User?" forState:UIControlStateNormal];
    [self.userNewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:self.userNewButton];
    
    self.sortSegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"recently created",@"recently viewed", nil]];
    self.sortSegmentedControl.frame = CGRectMake(CGRectGetWidth(self.view.frame) - 240 -5, 260, 240, 29);
    self.sortSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
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
    
    
    [self.sortSegmentedControl addTarget:self action:@selector(switchSort:) forControlEvents:UIControlEventValueChanged];
    [self.userNewButton addTarget:self action:@selector(showIntroduction:) forControlEvents:UIControlEventTouchDown];
    

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
    int count =  [[User defaultUser].packs count] + 1;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == 0) {
        PackListFirstCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PackListFirstCell" forIndexPath:indexPath];
        return cell;
    } else {
        
        int index = indexPath.row - 1;
        
        Pack *pack = (Pack *)[[[User defaultUser] packs] objectAtIndex:index];
        
        PackListCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PackListCell" forIndexPath:indexPath];
        
        NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[((Pack *)[[User defaultUser].packs objectAtIndex:index]).coverImageURL lastPathComponent]];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        if (image == NULL) {
            cell.coverImageView.image = [UIImage imageNamed:@"default_pack_cover_image.jpg"];
        } else {
            cell.coverImageView.image = image;
        }
        
        
        cell.packNameText.text = pack.packName;
        
        if (_isCollectionViewEditing) {
            cell.deleteButton.hidden = NO;
            cell.changeImageButton.hidden = NO;
        } else {
            cell.deleteButton.hidden = YES;
            cell.changeImageButton.hidden = YES;
        }
        
        cell.deleteButton.tag = index;
        [cell.deleteButton addTarget:self action:@selector(deleteCurrentPack:) forControlEvents:UIControlEventTouchDown];
        
        cell.packNameText.tag = index;
        cell.packNameText.delegate = self;
        
        cell.changeImageButton.tag = index;
        [cell.changeImageButton addTarget:self action:@selector(selectFromImageLibrary:) forControlEvents:UIControlEventTouchDown];
        
        cell.playButton.tag = index;
        [cell.playButton addTarget:self action:@selector(playButtonClicked:) forControlEvents:UIControlEventTouchDown];
        
        if ((self.packIDInMasterView != pack.packID) && [pack.creator isEqualToString:[OpenUDID value]] && _isCollectionViewEditing) {
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
    
    int index = indexPath.row;
    
    DDLogInfo(@"Selected item at index %d", indexPath.row);
    
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        //dismiss popover view in notification
    }
    
    if (index == 0) {
        [self createNewPackButtonClicked:nil];
    } else {
        Pack *selectedPack = [[User defaultUser].packs objectAtIndex:index -1];
        selectedPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
        [selectedPack savePackOnly];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_PACK_SELECTED_NOTIFICATION object:[NSString stringWithFormat:@"%d",indexPath.row -1]];
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
    
    int index = ((UIButton *) sender).tag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLAY_NOTIFICATION object:[NSNumber numberWithInt:index]];
    
    Pack *selectedPack = [[User defaultUser].packs objectAtIndex:index];
    selectedPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
    [selectedPack savePackOnly];
    
    
    
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        //dismiss popover view in notification
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_PACK_SELECTED_NOTIFICATION object:[NSString stringWithFormat:@"%d",index]];
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


- (void) showIntroduction:(id)sender {
    if (isUserInterfaceIdiomPhone) {
    } else {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self dismissModalViewControllerAnimated:YES];
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
        [self dismissModalViewControllerAnimated:YES];
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
        [alert show];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"The pack is currently used" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    
    
}

- (void) selectFromImageLibrary: (id) sender {
    
    int index = ((UIButton *) sender).tag;
    
    _currentPack = (Pack *)[[[User defaultUser] packs] objectAtIndex:index];
    if (isUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:_picker animated:YES];
    } else {
        CGPoint point = ((UIButton *)sender).frame.origin;
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        [_imagePickerPopover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    }
    
    Pack *selectedPack = [[User defaultUser].packs objectAtIndex:index];
    selectedPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
    [selectedPack savePackOnly];
}


#pragma mark -
#pragma mark - Notification related

-(void)updatePackListNotification:(NSNotification *)notification{
	[self resetPackContent];
    [self.collectionView reloadData];
}


#pragma mark -
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (isUserInterfaceIdiomPhone) {
        [_picker dismissModalViewControllerAnimated:YES];
    } else {
        [_imagePickerPopover dismissPopoverAnimated:YES];
    }
    
    UIImage *origialmage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)], kJPEGQualityFactor);
    
    if (_currentPack) {
        if (([_currentPack.coverImageURL rangeOfString:@".jpg"].location == NSNotFound) || ([_currentPack.coverImageURL hasSuffix:@"default_pack_cover_image.jpg"])||((_currentPack.coverImageURL.length == 0))) {
            _currentPack.coverImageURL = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
        }
        [imageData writeToFile:_currentPack.coverImageURL atomically:YES];
        [_currentPack savePackOnly];
        [self resetPackContent];
        [self.collectionView reloadData];
    } else {
        [Common alertViewCommon:@"error: _currentPack is nil"];
    }
    
    
}

#pragma mark -
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
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
            [[NSUserDefaults standardUserDefaults] setInteger:latestPack.packID forKey:@"lastCreatedPackID"]; //packID is a time related unique id
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



//iOS7 special for UIImagePickerController
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
