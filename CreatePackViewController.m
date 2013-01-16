//
//  CreatePackViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 15/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "CreatePackViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Pack.h"
#import "User.h"
#import "FileOperationHelper.h"

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
    
    _packNameText = [[UITextField alloc] initWithFrame:CGRectMake(170, 50, 200, 50)];
    _packNameText.textAlignment = UITextAlignmentCenter;
    _packNameText.backgroundColor = [UIColor clearColor];
    _packNameText.text = @"New Pack Name";
    _packNameText.font = [UIFont systemFontOfSize:20];
    _packNameText.delegate = self;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}


- (void) closeCreatePackView {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) saveAndCloseCreatePackView {
    if ([self isNewPack]) {
        _newPack.languageName = @"French "; //test purpose
        _newPack.packName = _packNameText.text;
        [[User defaultUser] addPack:_newPack];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_PACK_ADDED_NOTIFICATION object:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:@"Existing Pack name, please input a different one"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }

    [self dismissModalViewControllerAnimated:YES];
    
}

- (BOOL) isNewPack {
    if (_packNameText.text == nil) {
        return NO;
    }
    
    for (Pack *pack in [[User defaultUser] packs]) {
        if ([pack.packName isEqualToString:_packNameText.text])
            return NO;
    }
    
    if (_packNameText.text == @"public pack")
        return NO;
    
    return YES;
    
    
}

- (void)selectFromImageLibrary:(UITapGestureRecognizer *)sender {
    
    CGPoint point = [sender locationInView:self.view];
    CGRect rect = CGRectMake(point.x, point.y, 50, 50);
    
    if (!_picker) {
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
    NSData *imageData = UIImagePNGRepresentation([info objectForKey:UIImagePickerControllerOriginalImage]);
    NSString *savedFullPath = [FileOperationHelper generateUniqueImageFilePath];
    [imageData writeToFile:savedFullPath atomically:YES];
    _coverImageView.image = [UIImage imageWithContentsOfFile:savedFullPath];
    _newPack.coverImageURL = savedFullPath;

}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}


@end
