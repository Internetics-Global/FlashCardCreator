//
//  CreatePackViewController2.m
//  FFC
//
//  Created by Bourne Wang on 20/04/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import "CreateEditPackViewController2.h"
#import "OpenUDID.h"
#import "FCCBarButton.h"
#import "Pack.h"
#import "User.h"
#import "FileOperationHelper.h"
#import "UIImage+Scale.h"
#import "ASValueTrackingSlider.h"
#import "Base64.h"

#import <BlocksKit/UIAlertView+BlocksKit.h>

#import "UITextField+AutoResizeFont.h"

@interface CreateEditPackViewController2 () <UIImagePickerControllerDelegate,UITextFieldDelegate,UINavigationControllerDelegate,ASValueTrackingSliderDataSource>{
    
    UIPopoverController *_imagePickerPopover;
    UIImagePickerController *_picker;
    
    UIButton *_saveButton;
}

@end

@implementation CreateEditPackViewController2

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self setupNavigationBar];
    
    
    _coverImageView.layer.borderWidth = 1;
    _coverImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _coverImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    _coverImageView.backgroundColor = [UIColor clearColor];
    CAShapeLayer *styleLayer = [CAShapeLayer layer];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:_coverImageView.bounds byRoundingCorners:(UIRectCornerBottomRight|UIRectCornerBottomLeft|UIRectCornerTopRight|UIRectCornerTopLeft) cornerRadii:CGSizeMake(15, 15.0)];
    styleLayer.path = shadowPath.CGPath;
    _coverImageView.layer.mask = styleLayer;
    
    UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickedImageSelectButton:)];
    _coverImageView.userInteractionEnabled = YES;
    [_coverImageView addGestureRecognizer:imageSingeTap];
    
    //configure UISlider
    [_autoPlaySpeedSlider setMaxFractionDigitsDisplayed:0];
    _autoPlaySpeedSlider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:0.7];
    _autoPlaySpeedSlider.font = [UIFont systemFontOfSize:12];
    _autoPlaySpeedSlider.popUpViewWidthPaddingFactor = 1.5;
    _autoPlaySpeedSlider.popUpViewCornerRadius = 3;
    _autoPlaySpeedSlider.popUpViewHeightPaddingFactor = 1;
    _autoPlaySpeedSlider.popUpViewArrowLength = 8;
    _autoPlaySpeedSlider.dataSource = self;
    _autoPlaySpeedSlider.popUpViewAnimatedColors = @[[UIColor orangeColor]];
    [_autoPlaySpeedSlider showPopUpViewAnimated:NO];
    _autoPlaySpeedSlider.textColor = [UIColor whiteColor];
    
    if (self.isEditPack == FALSE) {
        _currentPack = [[Pack alloc] init];
        _coverImageView.image =[UIImage imageNamed:@"default_pack_cover_image_transparent"];
        _autoPlaySpeedSlider.value = kMIN_Auto_Play_Speed;
        
        _packNameTextField.placeholder = NSLocalizedString(@"Label_New_Pack_Name",@"");
        _sidebarTextField.placeholder = NSLocalizedString(@"Label_Sidebar_Title",@"");
        _creatorTextField.placeholder = NSLocalizedString(@"Label_Creator",@"");
        _jobTitleTextField.placeholder = NSLocalizedString(@"Label_Job_Title",@"");
        _adminPasswordTextField.placeholder = NSLocalizedString(@"Label_Admin_Password",@"");
        _cofirmAminPasswordTextField.placeholder = NSLocalizedString(@"Label_Confirm_Admin_Password",@"");
        
    } else {
        _packNameTextField.text = _currentPack.packName;
        [_packNameTextField adjustFontSizeToFit];
        _sidebarTextField.text = _currentPack.sidebarTitle;
        [_sidebarTextField adjustFontSizeToFit];
        _creatorTextField.text = _currentPack.creatorNickName;
        [_creatorTextField adjustFontSizeToFit];
        _jobTitleTextField.text = _currentPack.jobTitle;
        [_jobTitleTextField adjustFontSizeToFit];
        if (_currentPack.autoPlaySpeed == 0) {
            _autoPlaySpeedSlider.value = kMIN_Auto_Play_Speed;
        } else {
            _autoPlaySpeedSlider.value = _currentPack.autoPlaySpeed;
        }
        
        NSString *path = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_currentPack.coverImageURL lastPathComponent]];
        BOOL isDirectory;
        BOOL isFileExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
        if (isDirectory || isFileExist == FALSE) {
            _coverImageView.image =[UIImage imageNamed:@"default_pack_cover_image_transparent"];
        } else {
            _coverImageView.image =[UIImage imageWithContentsOfFile:path];
        }

        
        
    }
    
    _packNameTextField.delegate = self;
    _sidebarTextField.delegate = self;
    _creatorTextField.delegate = self;
    _jobTitleTextField.delegate = self;
    
    if (self.isEditPack) {
        NSString *savedPassword = [_currentPack.restorePassword base64DecodedString];
        _adminPasswordTextField.text = savedPassword;
        _cofirmAminPasswordTextField.text = savedPassword;
    }
    
    if (isUserInterfaceIdiomPhone) {
        CGRect rect = CGRectMake(CGRectGetMinX(_coverImageView.frame) + (CGRectGetWidth(_coverImageView.frame) - 44)/2, CGRectGetMaxY(_coverImageView.frame) - 5, 88, 44);

        _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        _saveButton.frame = rect;
       
        [_saveButton setImage:[UIImage imageNamed:@"save_button"] forState:UIControlStateNormal];
        [_saveButton setTitle:NSLocalizedString(@"ToolbarItem_Save",@"") forState:UIControlStateNormal];
        _saveButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_saveButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -50, -40, 0)];//set ur title insects myButton
        [self.view addSubview:_saveButton];
        [_saveButton addTarget:self action:@selector(saveAndCloseCreatePackView) forControlEvents:UIControlEventTouchUpInside];
    } else {
        
        CGRect rect = CGRectMake(CGRectGetMaxX(self.view.frame)- 110, CGRectGetMaxY(self.view.frame)- 110, 88, 48);
        
        _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
        _saveButton.frame = rect;
        [_saveButton setImage:[UIImage imageNamed:@"save_button"] forState:UIControlStateNormal];
        [_saveButton setTitle:NSLocalizedString(@"ToolbarItem_Save",@"") forState:UIControlStateNormal];
        _saveButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_saveButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -50, -55, 0)];//set ur title insects myButton
        [self.view addSubview:_saveButton];
        [_saveButton addTarget:self action:@selector(saveAndCloseCreatePackView) forControlEvents:UIControlEventTouchUpInside];
    }
    
    
}




- (void) setupNavigationBar {
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]
                                    initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"close2_button"] target:self action:@selector(closeCreatePackView)]];
    
    self.navigationItem.rightBarButtonItem = closeButton;
    
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
    
    if (self.isEditPack) {
        label.text = NSLocalizedString(@"Title_Edit_Pack",@"");
    } else {
        label.text = NSLocalizedString(@"Title_Add_A_New_Pack", nil);
    }
    [label sizeToFit];
    [self.navigationItem setTitleView:label];
}

- (void) didClickedImageSelectButton:(UITapGestureRecognizer *)sender {
    
    CGPoint point = [sender locationInView:self.view];
    
    __weak __typeof(&*self)weakSelf = self;
    
    [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_PACK_LIST_IMAGE_SELECTION",@"") message:NSLocalizedString(@"Title_Image_Copyright",@"") cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"DIALOG_REMOVE_IMAGE",@""), NSLocalizedString(@"DIALOG_SELECT_FROM_LIBRARY",@""), nil] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
        if (buttonIndex == 0) {
            //cancel button
            
        } else if (buttonIndex == 1) {
            //remove
            _coverImageView.image = nil;
            _currentPack.coverImageURL = @"";
            
        } else if (buttonIndex == 2) {
            //select
            [weakSelf selectFromImageLibrary:point];
            
        }
        
    }];

    
}

- (void)selectFromImageLibrary:(CGPoint )point {
    
    CGRect rect = CGRectMake(point.x, point.y, 50, 50);
    
    if (!_picker) {
        //We can not make UIImagePickerController in landscape since it's illegal
        _picker = [[UIImagePickerController alloc] init];
    }
    _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _picker.contentSizeForViewInPopover = CGSizeMake(320, 400);
    _picker.delegate = self;
    
    if (isUserInterfaceIdiomPhone) {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self presentModalViewController:_picker animated:YES];
    } else {
        if (!_imagePickerPopover) {
            _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
        }
        [_imagePickerPopover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (isUserInterfaceIdiomPhone) {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [_imagePickerPopover dismissPopoverAnimated:YES];
    }
    UIImage *origialmage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
    NSString *savedFullPath = [FileOperationHelper generateUniquePNGImageFilePathUnderImagesFolder];
    [imageData writeToFile:savedFullPath atomically:YES];
    _coverImageView.image = [UIImage imageWithContentsOfFile:savedFullPath];
    _currentPack.coverImageURL = savedFullPath;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}


- (void) closeCreatePackView {
    if (self.isEditPack) {
        if (isUserInterfaceIdiomPhone) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self dismissModalViewControllerAnimated:YES];
        }
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
    
}

- (void) saveAndCloseCreatePackView {
    
    if (([_adminPasswordTextField.text isEqualToString:_cofirmAminPasswordTextField.text] == false)) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_WRONG_PASSWORD",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    
    if (_autoPlaySpeedSlider.value > kMAX_Auto_Play_Speed || _autoPlaySpeedSlider.value < kMIN_Auto_Play_Speed) {
        [Common alertViewCommon:@"The value of auto play speed should be between 4 and 60 seconds"];
        return;
    }
    
    if ((_isEditPack == FALSE) && ([self isNewPack] == FALSE)) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_EXISTING_PACK_NAME",@"")];
        return;
        
    }
    
//    if ([Common isAlphanumeric:_packNameTextField.text] == NO && _packNameTextField.text.length > 0) {
//       [Common alertViewCommon:NSLocalizedString(@"DIALOG_ONLY_ALPHANUMBER_PERMITTED",@"")];
//        return;
//    }
    
    _currentPack.packName = _packNameTextField.text;
    _currentPack.sidebarTitle = _sidebarTextField.text;
    _currentPack.lastVisitDate = (int)[[NSDate date] timeIntervalSince1970];
    _currentPack.creatorNickName = _creatorTextField.text;
    _currentPack.jobTitle = _jobTitleTextField.text;
    _currentPack.autoPlaySpeed = _autoPlaySpeedSlider.value;
    _currentPack.restorePassword = [_adminPasswordTextField.text base64EncodedString];
    
    if (_isEditPack == false) {
       _currentPack.fileNameOnAWS = [FileOperationHelper generateUniqueFileNameOnCloud:_currentPack];
    }
    
    
    if (_isEditPack) {
       [_currentPack savePackOnly];
        [[NSNotificationCenter defaultCenter] postNotificationName:EDIT_PACK_FINISHED_NOTIFICATION object:_currentPack];
    } else {
        _currentPack.creator = [OpenUDID value];
        _currentPack.createDate = (int)[[NSDate date] timeIntervalSince1970];
        [[User defaultUser] addPack:_currentPack];
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_PACK_ADDED_NOTIFICATION object:_currentPack];
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:_currentPack.packID forKey:@"lastCreatedPackID"]; //packID is a time related unique id
    //Update_date info
    NSString *updateDate = [FileOperationHelper getTodayString];
    NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
    [dict setObject:updateDate forKey:@"update_date"];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:_currentPack.packName];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (self.isEditPack) {
        if (isUserInterfaceIdiomPhone) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self dismissModalViewControllerAnimated:YES];
        }
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    if (_adminPasswordTextField.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_NO_ADMIN_PASSWORD_WARNING",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
        [alertView show];
    }
}

/*
 * Check the pack name is already in the packs list
*/
- (BOOL) isNewPack {
    if (_packNameTextField.text == nil) {
        return NO;
    }
    
    NSMutableArray *packArray = [[User defaultUser] packs];
    for (Pack *pack in packArray) {
        if ([pack.packName isEqualToString:_packNameTextField.text])
            return NO;
    }
    
    return YES;
}

#pragma mark – ASValueTrackingSliderDataSource
/**
 *  仅能用来更新indicator string，而不能做其它逻辑。原因在于这个方法会在重画/或重布局时被调用，而不是只有值改变时才被调用
 */
- (NSString *)slider:(ASValueTrackingSlider *)slider stringForValue:(float)value;
{
    NSString *s;
    if (value == kMIN_Auto_Play_Speed) {
        s = NSLocalizedString(@"Title_Auto",@"");
    } else {
        s = [NSString stringWithFormat:@"%d",(int)value];
    }
    return s;
}


#pragma mark – UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.text = @"";
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [textField adjustFontSizeToFit];
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


@end
