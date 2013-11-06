//
//  CreatePackViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 15/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "CreatePackViewController.h"
#import "Pack.h"
#import "User.h"
#import "FileOperationHelper.h"
#import "UIImage+Scale.h"
#import "PackListViewController.h"

@interface CreatePackViewController ()

@end

@implementation CreatePackViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeCreatePackView)];
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveAndCloseCreatePackView)];
        self.navigationItem.leftBarButtonItem = closeButton;
        self.navigationItem.rightBarButtonItem = saveButton;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        if (isUserInterfaceIdiomPhone) {
            label.font = [UIFont boldSystemFontOfSize:16.0];
        }else {
            label.font = [UIFont boldSystemFontOfSize:20.0];
        }
        label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor]; // change this color
        label.text = NSLocalizedString(@"Title_Add_A_New_Pack", nil);
        [label sizeToFit];
        [self.navigationItem setTitleView:label];
        
        _newPack = [[Pack alloc] init];
        
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)loadView {
    [super loadView];

    if (isUserInterfaceIdiomPhone) {
        _packNameText = [[UITextField alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-190)/2, 10, 190, 24)];
    } else {
        _packNameText = [[UITextField alloc] initWithFrame:CGRectMake(170, 50, 200, 24)];
    }
    _packNameText.textAlignment = UITextAlignmentCenter;
    _packNameText.backgroundColor = [UIColor whiteColor];
    _packNameText.text = NSLocalizedString(@"Label_New_Pack_Name", nil);
    _packNameText.font = [UIFont systemFontOfSize:14];
    _packNameText.delegate = self;
    _packNameText.borderStyle = UITextBorderStyleNone;
    _packNameText.layer.cornerRadius = 5;
    _packNameText.layer.masksToBounds = YES;
    [_packNameText setClearsOnBeginEditing:YES];
    _packNameText.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:_packNameText];
    
    if (isUserInterfaceIdiomPhone) {
         _sidebarTitle = [[UITextField alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-190)/2, 45, 190, 24)];
    } else {
        _sidebarTitle = [[UITextField alloc] initWithFrame:CGRectMake(170, 100, 200, 24)];
    }
    _sidebarTitle.textAlignment = UITextAlignmentCenter;
    _sidebarTitle.backgroundColor = [UIColor whiteColor];
    _sidebarTitle.text = @"Side bar title";
    _sidebarTitle.font = [UIFont systemFontOfSize:14];
    _sidebarTitle.delegate = self;
    _sidebarTitle.borderStyle = UITextBorderStyleNone;
    _sidebarTitle.layer.cornerRadius = 5;
    _sidebarTitle.layer.masksToBounds = YES;
    [_sidebarTitle setClearsOnBeginEditing:YES];
    _sidebarTitle.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:_sidebarTitle];
    
    if (isUserInterfaceIdiomPhone) {
        _creatorText = [[UITextField alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-190)/2, 80, 190, 24)];
    } else {
        _creatorText = [[UITextField alloc] initWithFrame:CGRectMake(170, 150, 200, 24)];
    }
    _creatorText.textAlignment = UITextAlignmentCenter;
    _creatorText.backgroundColor = [UIColor whiteColor];
    _creatorText.text = NSLocalizedString(@"Label_Creator", nil);
    _creatorText.font = [UIFont systemFontOfSize:14];
    _creatorText.delegate = self;
    _creatorText.borderStyle = UITextBorderStyleNone;
    _creatorText.layer.cornerRadius = 5;
    _creatorText.layer.masksToBounds = YES;
    [_creatorText setClearsOnBeginEditing:YES];
    _creatorText.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:_creatorText];
    
    if (isUserInterfaceIdiomPhone){
        _coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-190)/2, 95,190,190)];
    } else {
        _coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(170, 200,200,200)];
    }
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    _coverImageView.layer.masksToBounds = YES;
    _coverImageView.layer.cornerRadius = 10;
    _coverImageView.userInteractionEnabled = YES;
    _coverImageView.image =[UIImage imageNamed:@"default_pack_cover_image.jpg"];
    [self.view addSubview:_coverImageView];
    
    _newPack.coverImageURL = [NSString stringWithFormat:@"%@/default_pack_cover_image.jpg", [[NSBundle mainBundle] resourcePath]];
    
    UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibrary:)];
    [_coverImageView addGestureRecognizer:imageSingeTap];
    
    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = _coverImageView.frame;
    rect.origin.y = _creatorText.frame.origin.y + 40;
    _coverImageView.frame = rect;
}

- (void) closeCreatePackView {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) saveAndCloseCreatePackView {
    if ([self isNewPack]) {
        _newPack.packName = _packNameText.text;
        _newPack.sidebarTitle = _sidebarTitle.text;
        _newPack.creator = [OpenUDID value];
        _newPack.createDate = (int)[[NSDate date] timeIntervalSince1970];
        _newPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
        _newPack.creatorNickName = _creatorText.text;
        [[User defaultUser] addPack:_newPack];
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_PACK_ADDED_NOTIFICATION object:_newPack];
        
        [[NSUserDefaults standardUserDefaults] setInteger:_newPack.packID forKey:@"lastCreatedPackID"]; //packID is a time related unique id
        //Update_date info
        NSString *updateDate = [FileOperationHelper getTodayString];
        NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_newPack.packName];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
        [dict setObject:updateDate forKey:@"update_date"];
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:_newPack.packName];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self dismissModalViewControllerAnimated:YES];
    } else {
        
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_EXISTING_PACK_NAME",@"")];
    }
    
}

- (BOOL) isNewPack {
    if (_packNameText.text == nil) {
        return NO;
    }
    
    NSMutableArray *packArray = [[User defaultUser] packs];
    for (Pack *pack in packArray) {
        if ([pack.packName isEqualToString:_packNameText.text])
            return NO;
    }
    
    return YES;
}

- (void)selectFromImageLibrary:(UITapGestureRecognizer *)sender {
    
    CGPoint point = [sender locationInView:self.view];
    CGRect rect = CGRectMake(point.x, point.y, 50, 50);
    
    if (!_picker) {
         //We can not make UIImagePickerController in landscape since it's illegal
        _picker = [[UIImagePickerController alloc] init];    
    }
    _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _picker.contentSizeForViewInPopover = CGSizeMake(320, 400);
    _picker.delegate = self;
    
    if (isUserInterfaceIdiomPhone) {
        [self presentModalViewController:_picker animated:YES];
    } else {
        if (!_imagePickerPopover) {
            _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
        }
        [_imagePickerPopover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (isUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [_imagePickerPopover dismissPopoverAnimated:YES];    
    }
    UIImage *origialmage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)], kJPEGQualityFactor);
    NSString *savedFullPath = [FileOperationHelper generateUniqueJPEGImageFilePathUnderImagesFolder];
    [imageData writeToFile:savedFullPath atomically:YES];
    _coverImageView.image = [UIImage imageWithContentsOfFile:savedFullPath];
    _newPack.coverImageURL = savedFullPath;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

//iOS7 special for UIImagePickerController
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
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
