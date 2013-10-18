//
//  PackListViewController.M
//  SwipeViewExample
//
//  Created by Nick Lockwood on 28/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PackListViewController.h"

#import "Pack.h"
#import "User.h"
#import "FileOperationHelper.h"
#import "UIImage+Scale.h"


@implementation PackListViewController

@synthesize swipeView = _swipeView;
@synthesize pageControl = _pageControl;
@synthesize packArray = _packArray;

#pragma mark -
#pragma mark - Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        
        _sortTypeEnum = SortTypeLastVisitedDescend;
        _packArray = [[User defaultUser] sortPacks:_sortTypeEnum];
        
        //From: click "add pack" button on navigation bar
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePackListNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
        
        //From: add downloaded pack
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePackListNotification:) name:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:nil];
        
        //Don't need the back button when on iPad 
        if (isUserInterfaceIdiomPhone) {
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
            self.navigationItem.leftBarButtonItem = backButton;
        }
        
        _editBtnItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Create_New_Pack", @"") style:UIBarButtonItemStylePlain target:self action:@selector(createNewPackButtonClicked:)];
        self.navigationItem.rightBarButtonItem = _editBtnItem;
        
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

        
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [self.swipeView reloadData];    
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"isPackListOpenedBefore"
     ];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        //self.automaticallyAdjustsScrollViewInsets = NO;//we will add this back when xcode5 is finally released
    }
    
    //configure swipe view
    _swipeView.alignment = SwipeViewAlignmentCenter;
    _swipeView.pagingEnabled = YES;
    _swipeView.wrapEnabled = NO;
    
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        _swipeView.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    }
    
    _swipeView.truncateFinalPage = YES;
    int packSize = [[[User defaultUser] packs] count];
    if (packSize == 1) {
        _swipeView.itemsPerPage = 1;
    } else if (packSize == 2)
        _swipeView.itemsPerPage = 2;
    else {
        _swipeView.itemsPerPage = 3;
        _swipeView.alignment = SwipeViewAlignmentEdge;
    }
    
    
    //configure page control
    _pageControl.numberOfPages = [_packArray count];
    _pageControl.defersCurrentPageDisplay = YES;
    
    [_userNewButton addTarget:self action:@selector(showIntroduction:) forControlEvents:UIControlEventTouchDown];
    [_sortedButton addTarget:self action:@selector(switchSort:) forControlEvents:UIControlEventTouchDown];
    
    self.title = @"Pack List";
    
    [self resetPackContent];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.automaticallyAdjustsScrollViewInsets = FALSE;
        self.edgesForExtendedLayout = UIRectEdgeNone;
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

#pragma mark -
#pragma mark - SwipeViewDelegate and SwipeViewDataSource

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return [self.packArray count] + 1;
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UIView *contentView = view;
    UIImageView *coverImageView ;
    UITextField *packNameText;
    UIButton *deleteButton;
    UIButton *changeImageButton;
     
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 370)];
    contentView.backgroundColor = [UIColor clearColor];
    view = contentView;

    
    if (index ==0) {
        UIImageView *addNewPackImageView ;
        addNewPackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 90, 180.0f, 150.0f)];
        addNewPackImageView.contentMode = UIViewContentModeScaleAspectFit;
        addNewPackImageView.layer.cornerRadius = 10;
        addNewPackImageView.layer.masksToBounds = YES;
        addNewPackImageView.image = [UIImage imageNamed:@"create_new_pack.png"];
        [view addSubview:addNewPackImageView];
        [view layoutSubviews];
    } else {
        index = index -1;
        _currentPack = (Pack *)[[[User defaultUser] packs] objectAtIndex:index];
        
        packNameText = [[UITextField alloc] initWithFrame:CGRectMake(10.0f, 50.0f, 180, 25.0f)];
        packNameText.textAlignment = UITextAlignmentCenter;
        packNameText.font = [UIFont systemFontOfSize:16];
        packNameText.returnKeyType = UIReturnKeyDone;
        packNameText.text = _currentPack.packName;
        packNameText.layer.cornerRadius = 5;
        packNameText.layer.masksToBounds = YES;
        packNameText.delegate = self;
        packNameText.tag = index;
        packNameText.userInteractionEnabled = YES;
        if (_currentIndex == index) {
            packNameText.layer.borderColor = [[UIColor whiteColor] CGColor];
            packNameText.layer.borderWidth = 1;
            packNameText.userInteractionEnabled = TRUE;
            packNameText.backgroundColor = [UIColor whiteColor];
            packNameText.textColor = [UIColor blackColor];
        } else {
            packNameText.layer.borderWidth = 0;
            packNameText.userInteractionEnabled = FALSE;
            packNameText.backgroundColor = [UIColor clearColor];
            packNameText.textColor = [UIColor whiteColor];
        }
        [view addSubview:packNameText];
        
        UIView *imageViewBackGround = [[UIView alloc] initWithFrame:CGRectMake(5.0f, 85, 190.0f, 160.0f)];
        imageViewBackGround.userInteractionEnabled = FALSE;
        [view addSubview:imageViewBackGround];
        if (_currentIndex == index) {
            //highlighted color
            imageViewBackGround.backgroundColor = [UIColor orangeColor];
            imageViewBackGround.alpha = 0.2;
            imageViewBackGround.layer.cornerRadius = 10;
            imageViewBackGround.layer.masksToBounds = YES;
        } else {
            imageViewBackGround.backgroundColor = [UIColor clearColor];
        }
        
        coverImageView = [[UIImageView alloc] initWithFrame:CGRectInset(imageViewBackGround.frame, 5, 5)];
        coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        coverImageView.layer.cornerRadius = 10;
        coverImageView.layer.masksToBounds = YES;
        [view addSubview:coverImageView];
        UIImage *image = [UIImage imageWithContentsOfFile:((Pack *)[_packArray objectAtIndex:index]).coverImageURL];
        if (image == NULL) {
            coverImageView.image = [UIImage imageNamed:@"default_pack_cover_image.png"];
        } else {
            coverImageView.image = image;
        }
        
        
        UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        playButton.frame = CGRectMake(130, 170, 60, 60);
        playButton.backgroundColor = [UIColor clearColor];
        packNameText.tag = index;
        [playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        playButton.userInteractionEnabled = FALSE;
        [view addSubview:playButton];
        
        
        deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [deleteButton setTitle:NSLocalizedString(@"NavigationBarItem_Delete", @"") forState:UIControlStateNormal];
        [deleteButton setBackgroundImage:[[UIImage imageNamed:@"redButton.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal];
        deleteButton.titleLabel.font = [UIFont systemFontOfSize:12];
        deleteButton.tag = index;
        deleteButton.userInteractionEnabled = TRUE;
        deleteButton.frame = CGRectMake(10.0f, 255.0f, 85, 25);
        [deleteButton addTarget:self action:@selector(deleteCurrentPack:) forControlEvents:UIControlEventTouchDown];
        if (_currentIndex ==index) {
            [view addSubview:deleteButton];
        }
        
        //change image and edit cards share common button
        changeImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [changeImageButton setBackgroundImage:[[UIImage imageNamed:@"grayButton.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal];
        changeImageButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [changeImageButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        changeImageButton.tag = index;
        changeImageButton.userInteractionEnabled = TRUE;
        changeImageButton.frame = CGRectMake(105.0f, 255.0f, 85.0, 25);
        [changeImageButton setTitle:NSLocalizedString(@"NavigationBarItem_Edit_Cards", @"") forState:UIControlStateNormal];
        if ([_currentPack.creator isEqualToString:[OpenUDID value]]) {
            [view addSubview:changeImageButton];
        }
        if (_currentIndex == index) {
            [changeImageButton setTitle:NSLocalizedString(@"NavigationBarItem_Change", @"") forState:UIControlStateNormal];
            [changeImageButton addTarget:self action:@selector(selectFromImageLibrary:) forControlEvents:UIControlEventTouchDown];
        } else {
            [changeImageButton setTitle:@"Edit cards" forState:UIControlStateNormal];
            [changeImageButton addTarget:self action:@selector(editCardsButtonClicked:) forControlEvents:UIControlEventTouchDown];
            
        }
        
        [view layoutSubviews];
    }
    
    return view;
}

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    //update page control page
    _pageControl.currentPage = swipeView.currentPage;
}

-  (void)swipeView:(SwipeView *)swipeView didSelectItemPlayButtonAtIndex:(NSInteger)index {
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
       //dismiss popover view in notification
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLAY_NOTIFICATION object:[NSNumber numberWithInt:index -1]]; //begin from second (first is the add pack button)
    
    if (index == 0) {
        //do nothing
    } else {
        Pack *selectedPack = [_packArray objectAtIndex:index -1];
        selectedPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
        [selectedPack save];
    }
}

- (void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"Selected item at index %d", index);
    
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        //dismiss popover view in notification
    }
    
    if (index == 0) {
        [self createNewPackButtonClicked:nil];
    } else {
        Pack *selectedPack = [_packArray objectAtIndex:index -1];
        selectedPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
        [selectedPack save];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_PACK_SELECTED_NOTIFICATION object:[NSString stringWithFormat:@"%d",index -1]];
    }
}


#pragma mark -
#pragma mark - Reset DataSource

- (void) resetPackContent {
    _packArray = [[User defaultUser] sortPacks:_sortTypeEnum];

}

#pragma mark -
#pragma mark - Notification related

-(void)updatePackListNotification:(NSNotification *)notification{
	[self resetPackContent];
    [self.swipeView reloadData];
}

#pragma mark -
#pragma mark - Control touch event

- (void) editCardsButtonClicked: (id) sender {
    
    UIButton *editCardsButton = (UIButton *) sender;
    _currentIndex = editCardsButton.tag;
    _editBtnItem.title = NSLocalizedString(@"NavigationBarItem_Done", @"");
    
    [_swipeView reloadData];
    
    [_swipeView scrollToItemAtIndex:(_currentIndex) duration:0];

}

- (void) switchSort:(id)sender {
    UIButton *button = (UIButton *) sender;
    
    switch (button.tag) {
        case 0:
            button.tag = 1;
            _sortTypeEnum = SortTypeLastCreatedDescend;
            [self resetPackContent];
            [button setTitle:@"Sorted by recently created first" forState:UIControlStateNormal];
            [self.swipeView reloadData];
            break;
        case 1:
            button.tag = 0;
            _sortTypeEnum = SortTypeLastVisitedDescend;
            [self resetPackContent];
            [button setTitle:@"Sorted by recently viewed first" forState:UIControlStateNormal];
            [self.swipeView reloadData];
            break;
            
        default:
            break;
    }
    
}


- (void) showIntroduction:(id)sender {
    if (isUserInterfaceIdiomPhone) {
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_VIDEO_NOTIFICATION object:self];
}

- (IBAction)pageControlTapped
{
    //update swipe view page
    [_swipeView scrollToPage:_pageControl.currentPage duration:0.4];
}
                                           
- (void) editBtnItemClicked:(id)sender {
    if ([_editBtnItem.title isEqualToString:NSLocalizedString(@"NavigationBarItem_Edit", @"")]) {
        _editBtnItem.title = NSLocalizedString(@"NavigationBarItem_Done", @"");
        [_swipeView reloadData];
    } else {
        _editBtnItem.title = NSLocalizedString(@"NavigationBarItem_Edit", @"");
        if ([[User defaultUser] packs].count <= 1) {
            self.navigationItem.rightBarButtonItem = nil;
        } else {
            self.navigationItem.rightBarButtonItem = _editBtnItem;
        }
        [_swipeView reloadData];
        
    }
    
}

- (void) createNewPackButtonClicked:(id)sender {
    
    if ([_editBtnItem.title isEqualToString:NSLocalizedString(@"NavigationBarItem_Done", @"")]) {
        [_editBtnItem setTitle:NSLocalizedString(@"NavigationBarItem_Create_New_Pack", @"")];
        _currentIndex = -1;
        [self.swipeView reloadData];
        
    } else {
        
        if (isUserInterfaceIdiomPhone) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissModalViewControllerAnimated:YES];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TO_CREATE_NEW_PACK_NOTIFICATION object:self];
    }
    
        
}

- (void) backButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) deleteCurrentPack:(id) sender {
    
    _currentIndex = ((UIButton *)sender).tag;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                    message:NSLocalizedString(@"DIALOG_DELETE_PACK",@"")
                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Cancel",@"")
                                          otherButtonTitles:NSLocalizedString(@"Keyboard_Delete",@""), nil];
    alert.delegate = self;
    [alert show];
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
    
    Pack *selectedPack = [_packArray objectAtIndex:index];
    selectedPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
    [selectedPack save];
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
        if (([_currentPack.coverImageURL rangeOfString:@".png"].location == NSNotFound) || ([_currentPack.coverImageURL hasSuffix:@"default_pack_cover_image.png"])||((_currentPack.coverImageURL.length == 0))) {
            _currentPack.coverImageURL = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
        }
        [imageData writeToFile:_currentPack.coverImageURL atomically:YES];
        [_currentPack save];
        [self resetPackContent];
        [self.swipeView reloadData];
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
        
        [_swipeView reloadData];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
