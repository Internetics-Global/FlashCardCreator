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

@synthesize isIncludePackListView = _isIncludePackListView;

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
    self.title = @"Save to new or existing pack?";
    
    _packNameText = [[UITextField alloc] initWithFrame:CGRectMake(170, 50, 200, 30)];
    _packNameText.textAlignment = UITextAlignmentCenter;
    _packNameText.backgroundColor = [UIColor clearColor];
    _packNameText.text = @"New Pack Name";
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
    
    _packHeaderText = [[UITextField alloc] initWithFrame:CGRectMake(0, 300, 540, 30)];
    _packHeaderText.textAlignment = UITextAlignmentCenter;
    _packHeaderText.backgroundColor = [UIColor clearColor];
    _packHeaderText.text = @"Select current packs";
    _packHeaderText.font = [UIFont systemFontOfSize:16];
    
    _seperatorLineImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 320,540,25)];
    _seperatorLineImage.contentMode = UIViewContentModeScaleAspectFit;
    _seperatorLineImage.userInteractionEnabled = NO;
    _seperatorLineImage.image =[UIImage imageNamed:@"create_pack_seperator.png"];
    
    _packListViewController = [[PackListViewController alloc] initWithNibName:@"PackListViewController" bundle:nil];
    _packListViewController.view.frame = CGRectMake(0, 330, 540, 262);
    _packListViewController.view.clipsToBounds = YES;
    _packListViewController.view.layer.cornerRadius = 0;
    _packListViewController.view.backgroundColor =[UIColor clearColor];
    
    _newPack.coverImageURL = [NSString stringWithFormat:@"%@/default_pack_cover_image.png", [[NSBundle mainBundle] resourcePath]];
    
    UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibrary:)];
    [_coverImageView addGestureRecognizer:imageSingeTap];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (_isIncludePackListView) {
        [self.view addSubview:_seperatorLineImage];
        [self.view addSubview:_packHeaderText];
    }
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_isIncludePackListView ) {
        [self addChildViewController:_packListViewController];
        [self.view addSubview:_packListViewController.view];
    }
    
}


- (void) closeCreatePackView {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) saveAndCloseCreatePackView {
    if ([self isNewPack]) {
        _newPack.packName = _packNameText.text;
        [[User defaultUser] addPack:_newPack];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_PACK_ADDED_NOTIFICATION object:_newPack];
    } else {
        
        [Common alertViewCommon:@"Existing Pack name, please input a different one"];
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
    
    if (_packNameText.text == PUBLIC_PACK_NAME)
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
    UIImage *origialmage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
    NSString *savedFullPath = [FileOperationHelper generateUniquePNGImageFilePath];
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
