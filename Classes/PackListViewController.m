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
        //From: click "add pack" button on navigation bar
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePackListNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
        
        //From: add downloaded pack
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePackListNotification:) name:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:nil];
        
        //Don't need the back button when on iPad 
        if (isUserInterfaceIdiomPhone) {
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
            self.navigationItem.leftBarButtonItem = backButton;
        }
        
        _editBtnItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Edit", @"") style:UIBarButtonItemStylePlain target:self action:@selector(editBtnItemClicked:)];
        self.navigationItem.rightBarButtonItem = _editBtnItem;
        
        _hideDeleteButton = TRUE;
        
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
        
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [self.swipeView reloadData];    
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
    
    self.title = @"Pack List";
    
    [self resetPackContent];
    

}

#pragma mark -
#pragma mark - Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark - SwipeViewDelegate and SwipeViewDataSource

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return [self.packArray count];
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UIView *contentView = view;
    UIImageView *coverImageView ;
    UITextField *packNameText;
    UITextField *packCreatorText;
    UIButton *deleteButton;
    UIButton *changeImageButton;
     
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 370)];
    contentView.backgroundColor = [UIColor clearColor];
    view = contentView;

    
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
    if ([_editBtnItem.title isEqualToString:NSLocalizedString(@"NavigationBarItem_Done", @"")] && ([_currentPack.creator isEqualToString:[OpenUDID value]])) {
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
    
    coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 90, 180.0f, 150.0f)];
    coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    coverImageView.layer.cornerRadius = 10;
    coverImageView.layer.masksToBounds = YES;
    [view addSubview:coverImageView];
    UIImage *image = [UIImage imageWithContentsOfFile:[_packArray objectAtIndex:index]];
    if (image == NULL) {
        coverImageView.image = [UIImage imageNamed:@"default_pack_cover_image.png"];
    } else {
        coverImageView.image = image;
    }

    
    deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [deleteButton setTitle:NSLocalizedString(@"NavigationBarItem_Delete", @"") forState:UIControlStateNormal];
    [deleteButton setBackgroundImage:[[UIImage imageNamed:@"redButton.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [UIFont systemFontOfSize:12];
    deleteButton.tag = index;
    deleteButton.userInteractionEnabled = TRUE;
    deleteButton.frame = CGRectMake(10.0f, 255.0f, 85, 25);
    [deleteButton addTarget:self action:@selector(deleteCurrentPack:) forControlEvents:UIControlEventTouchDown];
    NSInteger packID = ((Pack *)[[[User defaultUser] packs] objectAtIndex:index]).packID;
    if ((!_hideDeleteButton) && !(_packIDInMasterView == packID) && (_packArray.count > 1)) {
        [view addSubview:deleteButton];
        
    }
    
    changeImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [changeImageButton setTitle:NSLocalizedString(@"NavigationBarItem_Change", @"") forState:UIControlStateNormal];
    [changeImageButton setBackgroundImage:[[UIImage imageNamed:@"grayButton.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal];
    changeImageButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [changeImageButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    changeImageButton.tag = index;
    changeImageButton.userInteractionEnabled = TRUE;
    changeImageButton.frame = CGRectMake(105.0f, 255.0f, 85.0, 25);
    [changeImageButton addTarget:self action:@selector(selectFromImageLibrary:) forControlEvents:UIControlEventTouchDown];
    
    if ([_editBtnItem.title isEqualToString:NSLocalizedString(@"NavigationBarItem_Done", @"")] && ([_currentPack.creator isEqualToString:[OpenUDID value]])) {
        [view addSubview:changeImageButton];    
    } else {
        if (changeImageButton.superview) {
            [changeImageButton removeFromSuperview];
        }
    }
    
    
    [view layoutSubviews];
    
    return view;
}

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    //update page control page
    _pageControl.currentPage = swipeView.currentPage;
}

- (void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"Selected item at index %d", index);
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];    
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_PACK_SELECTED_NOTIFICATION object:[NSString stringWithFormat:@"%d",index]];
}

#pragma mark -
#pragma mark - Reset DataSource

- (void) resetPackContent {
    NSMutableArray *imageArray = [NSMutableArray array];
    
    NSMutableArray *packArray = [[User defaultUser] packs];
    for (Pack *pack in packArray) {
        [imageArray addObject:pack.coverImageURL];
    }
    self.packArray = imageArray;
}

#pragma mark -
#pragma mark - Notification related

-(void)updatePackListNotification:(NSNotification *)notification{
	[self resetPackContent];
    [self.swipeView reloadData];
}

#pragma mark -
#pragma mark - Control touch event

- (IBAction)pageControlTapped
{
    //update swipe view page
    [_swipeView scrollToPage:_pageControl.currentPage duration:0.4];
}
                                           
- (void) editBtnItemClicked:(id)sender {
    if ([_editBtnItem.title isEqualToString:NSLocalizedString(@"NavigationBarItem_Edit", @"")]) {
        _editBtnItem.title = NSLocalizedString(@"NavigationBarItem_Done", @"");
        _hideDeleteButton = FALSE;
        [_swipeView reloadData];
    } else {
        _editBtnItem.title = NSLocalizedString(@"NavigationBarItem_Edit", @"");
        _hideDeleteButton = YES;
        if ([[User defaultUser] packs].count <= 1) {
            self.navigationItem.rightBarButtonItem = nil;
        } else {
            self.navigationItem.rightBarButtonItem = _editBtnItem;
        }
        [_swipeView reloadData];
        
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
    _currentPack = (Pack *)[[[User defaultUser] packs] objectAtIndex:((UIButton *) sender).tag];
    if (isUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:_picker animated:YES];
    } else {
        CGPoint point = ((UIButton *)sender).frame.origin;
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        [_imagePickerPopover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    }
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
