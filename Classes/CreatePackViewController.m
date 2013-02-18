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
        
        _newPack = [[Pack alloc] init];
        
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"create_pack_background"]];
    self.title = NSLocalizedString(@"Title_Add_A_New_Pack", nil);
    
    _packNameText = [[UITextField alloc] initWithFrame:CGRectMake(170, 50, 200, 30)];
    _packNameText.textAlignment = UITextAlignmentCenter;
    _packNameText.backgroundColor = [UIColor clearColor];
    _packNameText.text = NSLocalizedString(@"Label_New_Pack_Name", nil);
    _packNameText.font = [UIFont systemFontOfSize:20];
    _packNameText.delegate = self;
    _packNameText.borderStyle = UITextBorderStyleRoundedRect;
    [_packNameText setClearsOnBeginEditing:YES];
    _packNameText.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:_packNameText];
    
    _coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(170, 100,200,200)];
    _coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    _coverImageView.layer.cornerRadius = 10;
    _coverImageView.layer.masksToBounds = YES;
    _coverImageView.userInteractionEnabled = YES;
    _coverImageView.image =[UIImage imageNamed:@"default_pack_cover_image.png"];
    [self.view addSubview:_coverImageView];
    
    _newPack.coverImageURL = [NSString stringWithFormat:@"%@/default_pack_cover_image.png", [[NSBundle mainBundle] resourcePath]];
    
    UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibrary:)];
    [_coverImageView addGestureRecognizer:imageSingeTap];
    
}

- (void) closeCreatePackView {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) saveAndCloseCreatePackView {
    if ([self isNewPack]) {
        _newPack.packName = _packNameText.text;
        [[User defaultUser] addPack:_newPack];
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_PACK_ADDED_NOTIFICATION object:_newPack];
        [[NSUserDefaults standardUserDefaults] setInteger:_newPack.packID forKey:@"lastCreatedPackID"]; //packID is a time related unique id
        [[NSUserDefaults standardUserDefaults] setInteger:([[[User defaultUser] packs] count] -1) forKey:@"lastPackIndex"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self dismissModalViewControllerAnimated:YES];
    } else {
        
        [Common alertViewCommon:@"Existing pack name, please input a different one"];
    }
    
}

- (BOOL) isNewPack {
    if (_packNameText.text == nil) {
        return NO;
    }
    
    for (Pack *pack in [[User defaultUser] packs]) {
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
    
    if (!_imagePickerPopover) {
        _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
    }
    
    [_imagePickerPopover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [_imagePickerPopover dismissPopoverAnimated:YES];
    UIImage *origialmage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
    NSString *savedFullPath = [FileOperationHelper generateUniquePNGImageFilePath];
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
