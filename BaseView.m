//
//  BaseView.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 10/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "BaseView.h"
#import "UIImagePickerController+NoRotate.h"
#import "QuestionView.h"
#import "FileOperationHelper.h"
#import "UIImage+Scale.h"

@implementation BaseView

@synthesize currentCard = _currentCard;
@synthesize logoImage = _logoImage;
@synthesize logoImageFullPath = _logoImageFullPath;
@synthesize content = _content;
@synthesize title = _title;
@synthesize image = _image;
@synthesize imageFullPath = _imageFullPath;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasHidden:)
                                                     name:UIKeyboardDidHideNotification object:nil];
        [self loadView];
        _keyboardShown = FALSE;
        [self setInputAccessoryViewDone];
        
        _picker = [[UIImagePickerController alloc] init];
        _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _picker.contentSizeForViewInPopover = CGSizeMake(320, 400);
        _picker.delegate = self;
        
        if (_imagePickerPopover == nil) {
            _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
        }
    }
    return self;
}

- (void) loadView {
    _title = [[UITextView alloc]init];
    _title.frame = CGRectMake(0, 0, 600, 60);
    _title.text =@"Question";
    _title.font =[UIFont systemFontOfSize:30];
    _title.textAlignment = NSTextAlignmentCenter;
    _title.backgroundColor = [UIColor clearColor];
    _title.userInteractionEnabled = FALSE;
    [self addSubview:_title];
    
    _logoImage = [[UIImageView  alloc] init];
    _logoImage.contentMode = UIViewContentModeScaleAspectFit;
    _logoImage.frame = CGRectMake(550, 10, 120, 120);
    _logoImage.clipsToBounds = YES;
    _logoImage.backgroundColor = [UIColor clearColor];
    _logoImage.userInteractionEnabled = FALSE;
    _logoImage.tag = 0;
    _logoImage.layer.cornerRadius = 5;
    _logoImage.layer.masksToBounds = YES;
    [self addSubview:_logoImage];
    
    _image= [[UIImageView  alloc] init];
    _image.userInteractionEnabled = FALSE;
    _image.contentMode = UIViewContentModeScaleAspectFit;
    _image.frame = CGRectMake(370, 150, 300, 300);
    _image.clipsToBounds = YES;
    _image.backgroundColor = [UIColor clearColor];
    _image.tag = 1;
    _image.layer.cornerRadius = 10;
    _image.layer.masksToBounds = YES;
    [self addSubview:_image];
    
    UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
    [_image addGestureRecognizer:imageSingeTap];
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    _content = [[UITextView alloc]init];
    _content.frame = CGRectMake(0, 100, 370, 500);
    _content.font =[UIFont systemFontOfSize:20];
    _content.userInteractionEnabled = FALSE;
    _content.backgroundColor = [UIColor clearColor];
    _content.keyboardType = UIKeyboardAppearanceDefault;
    _content.returnKeyType = UIReturnKeyDefault;
    [self addSubview:_content];
}

#pragma mark -
#pragma mark - Keyboard Notification and related

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    if (_keyboardShown)
        return;
    NSDictionary* info = [aNotification userInfo];
    
    // Get the size of the keyboard.
    NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
    
    _keyboardShown = YES;
    
    
}

- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    _keyboardShown = NO;
    
}

- (void) setInputAccessoryViewDone  {
    UIToolbar * topView = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, [ UIScreen mainScreen ].bounds.size.height, 30)];
    [topView setBarStyle:UIBarStyleBlack];
    
    UIBarButtonItem * btnSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyBoard)];
    
    
    NSArray * buttonsArray = [NSArray arrayWithObjects:btnSpace,doneButton,nil];
    
    
    [topView setItems:buttonsArray];
    [_content setInputAccessoryView:topView];
}

-(IBAction)dismissKeyBoard
{
    [_content resignFirstResponder];
}

#pragma mark -
#pragma mark - Memory Management

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)selectFromImageLibraryByLogo:(UITapGestureRecognizer *)sender {
    
    
    _isLogoImageViewClicked = YES;
    
    CGPoint point = [sender locationInView:self];
    CGRect rect = CGRectMake(point.x, point.y, 50, 50);
    
    [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

- (void)selectFromImageLibraryByImage:(UITapGestureRecognizer *)sender {
    
    _isLogoImageViewClicked = NO;
    
    CGPoint point = [sender locationInView:self];
    CGRect rect = CGRectMake(point.x, point.y, 50, 50);
    
    [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [_imagePickerPopover dismissPopoverAnimated:YES];
    
    UIImage *origialmage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)]);
    NSString *savedFullPath = [FileOperationHelper generateUniquePNGImageFilePath];
    [imageData writeToFile:savedFullPath atomically:YES];
    if (_isLogoImageViewClicked) {
        _logoImageFullPath = savedFullPath;
        _logoImage.image = [UIImage imageWithContentsOfFile:savedFullPath];
    } else {
        _imageFullPath = savedFullPath;
        _image.image = [UIImage imageWithContentsOfFile:savedFullPath];
    }
}

- (UIImage *)captureWholeViewAsImage {
    CGRect screenRect = self.bounds;
    UIGraphicsBeginImageContext(screenRect.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self.backgroundColor set];
    CGContextFillRect(ctx, screenRect);
    [self.layer renderInContext:ctx];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


@end
