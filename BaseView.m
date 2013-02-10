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
#import "Question.h"
#import "Answer.h"
#import "Card.h"
#import "CSS.h"

@implementation BaseView

@synthesize currentCard = _currentCard;
@synthesize logoImage = _logoImage;
@synthesize logoImageFullPath = _logoImageFullPath;
@synthesize subheading = _subheading;
@synthesize main = _main;
@synthesize sub = _sub;
@synthesize title = _title;
@synthesize image = _image;
@synthesize imageFullPath = _imageFullPath;
@synthesize delegate = _delegate;

@synthesize subheadingAlign = _subheadingAlign;
@synthesize subheadingColor = _subheadingColor;
@synthesize subheadingSize = _subheadingSize;
@synthesize mainAlign = _mainAlign;
@synthesize mainColor = _mainColor;
@synthesize mainSize = _mainSize;
@synthesize subAlign = _subAlign;
@synthesize subSize = _subSize;
@synthesize subColor = _subColor;

#pragma mark -
#pragma mark - Life cycle

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
        
        _subheadingSize = 40;
        _subheadingColor = @"Black";
        _subheadingAlign = @"Right";
        _mainSize = 16;
        _mainColor = @"Black";;
        _mainAlign = @"Center";;
        _subSize = 16;
        _subColor = @"Black";;
        _subAlign = @"Center";;
        
        if (isUserInterfaceIdiomPhone) {
            [self loadViewForiPhone];
        } else {
            [self loadViewForiPad];
        }
        
        _keyboardShown = FALSE;
        [self setInputAccessoryViewDone];
        
        //We can not make UIImagePickerController in landscape since it's illegal
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

#pragma mark -
#pragma mark - Layout view

- (void) loadViewForiPad {
    
    UIImageView *titleBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_title_background.png"]];
    titleBackgroundView.frame = CGRectMake(0, 0, 800, 110);
    [self addSubview:titleBackgroundView];
    
    UIImageView *sidebarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_sidebar.png"]];
    sidebarImageView.frame = CGRectMake(0, 0, 60, 550);
    [self addSubview:sidebarImageView];
    
//    UILabel *packName = [[UILabel alloc] init];
//    packName.frame = CGRectMake(0, 0, 550, 60);
//    [packName setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
//    [packName setText:@"dfdfdfdfdsfdfsdfdfdsfffffffffffffffffffffffffffffffffffffffffffffffffff"];
//    packName.backgroundColor = [UIColor redColor];
//    packName.textColor = [UIColor whiteColor];
//    [self addSubview:packName];
    
    _title = [[UITextView alloc]init];
    _title.frame = CGRectMake(300, 30, 200, 110);
    _title.backgroundColor = [UIColor clearColor];
    _title.font =[UIFont systemFontOfSize:30];
    _title.textAlignment = NSTextAlignmentCenter;
    _title.userInteractionEnabled = FALSE;
    [self addSubview:_title];
    
    _logoImage = [[UIImageView  alloc] init];
    _logoImage.contentMode = UIViewContentModeScaleAspectFit;
    _logoImage.frame = CGRectMake(680, 10, 100, 100);
    _logoImage.clipsToBounds = YES;
    _logoImage.backgroundColor = [UIColor clearColor];
    _logoImage.userInteractionEnabled = FALSE;
    _logoImage.layer.cornerRadius = 8;
    _logoImage.layer.masksToBounds = YES;
    [self addSubview:_logoImage];
    
    _image= [[UIImageView  alloc] init];
    _image.userInteractionEnabled = FALSE;
    _image.contentMode = UIViewContentModeScaleAspectFit;
    _image.frame = CGRectMake(480, 150, 300, 300);
    _image.clipsToBounds = YES;
    _image.backgroundColor = [UIColor clearColor];
    _image.layer.cornerRadius = 15;
    _image.layer.masksToBounds = YES;
    [self addSubview:_image];
    
    UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
    [_image addGestureRecognizer:imageSingeTap];
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    _subheading = [[UITextView alloc]init];
    _subheading.tag = 100;
    _subheading.frame = CGRectMake(0, 50, 570, 50);
    _subheading.userInteractionEnabled = FALSE;
    _subheading.backgroundColor = [UIColor yellowColor];
    _subheading.keyboardType = UIKeyboardAppearanceDefault;
     _subheading.returnKeyType = UIReturnKeyDefault;
    _subheading.delegate = self;
    [self addSubview:_subheading];
    
    _main = [[UITextView alloc]init];
    _main.tag = 101;
    _main.frame = CGRectMake(0, 100, 470, 200);
    _main.userInteractionEnabled = FALSE;
    _main.backgroundColor = [UIColor orangeColor];
    _main.keyboardType = UIKeyboardAppearanceDefault;
    _main.returnKeyType = UIReturnKeyDefault;
    _main.delegate = self;
    [self addSubview:_main];
    
    _sub = [[UITextView alloc]init];
    _sub.tag = 102;
    _sub.frame = CGRectMake(0, 300, 470, 220);
    _sub.userInteractionEnabled = FALSE;
    _sub.backgroundColor = [UIColor greenColor];
    _sub.keyboardType = UIKeyboardAppearanceDefault;
    _sub.returnKeyType = UIReturnKeyDefault;
    _sub.delegate = self;
    [self addSubview:_sub];
}

- (void) loadViewForiPhone {
    _title = [[UITextView alloc]init];
    _title.frame = CGRectMake(40, 0, 300, 30);
    _title.text =@"Question";
    _title.font =[UIFont systemFontOfSize:20];
    _title.textAlignment = NSTextAlignmentCenter;
    _title.backgroundColor = [UIColor clearColor];
    _title.userInteractionEnabled = FALSE;
    [self addSubview:_title];
    
    _logoImage = [[UIImageView  alloc] init];
    _logoImage.contentMode = UIViewContentModeScaleAspectFit;
    _logoImage.frame = CGRectMake(350, 10, 30, 30);
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
    _image.frame = CGRectMake(300, 120, 80, 80);
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
    
    _main = [[UITextView alloc]init];
    _main.frame = CGRectMake(0, 20, 300, 100);
    _main.userInteractionEnabled = FALSE;
    _main.backgroundColor = [UIColor clearColor];
    _main.keyboardType = UIKeyboardAppearanceDefault;
    _main.returnKeyType = UIReturnKeyDefault;
    [self addSubview:_main];
    
    _sub = [[UITextView alloc]init];
    _sub.frame = CGRectMake(0, 120, 300, 100);
    _sub.userInteractionEnabled = FALSE;
    _sub.backgroundColor = [UIColor clearColor];
    _sub.keyboardType = UIKeyboardAppearanceDefault;
    _sub.returnKeyType = UIReturnKeyDefault;
    [self addSubview:_sub];
}

#pragma mark -
#pragma mark - Update CSS (only CSS) 

//CSS part which is included in three main parts: CSS, template(position) and content
- (void) updateCSS {
    
    if (_currentCard == nil) {
        [Common alertViewCommon:@"Need to set currentCard beforehand"];
    }
    
    //1. subheading
    _subheading.font = [UIFont systemFontOfSize:_subheadingSize];
    
    if ([_subheadingColor isEqualToString:@"Blue"]) {
        _subheading.textColor = [UIColor blueColor];
    } else if ([_subheadingColor isEqualToString:@"Red"]) {
        _subheading.textColor = [UIColor redColor];
    } else if ([_subheadingColor isEqualToString:@"Yellow"]) {
        _subheading.textColor = [UIColor yellowColor];
    } else if ([_subheadingColor isEqualToString:@"Black"]) {
        _subheading.textColor = [UIColor blackColor];
    } else if ([_subheadingColor isEqualToString:@"Green"]) {
        _subheading.textColor = [UIColor greenColor];
    }
    
    if ([_subheadingAlign isEqualToString:@"Left"]) {
        _subheading.textAlignment = NSTextAlignmentLeft;
    } else if ([_subheadingAlign isEqualToString:@"Center"]) {
        _subheading.textAlignment = NSTextAlignmentCenter;
    }else if ([_subheadingAlign isEqualToString:@"Right"]) {
        _subheading.textAlignment = NSTextAlignmentRight;
    }
    
    //2. main
    _main.font = [UIFont systemFontOfSize:_mainSize];
    
    if ([_mainColor isEqualToString:@"Blue"]) {
        _main.textColor = [UIColor blueColor];
    } else if ([_mainColor isEqualToString:@"Red"]) {
        _main.textColor = [UIColor redColor];
    } else if ([_mainColor isEqualToString:@"Yellow"]) {
        _main.textColor = [UIColor yellowColor];
    } else if ([_mainColor isEqualToString:@"Black"]) {
        _main.textColor = [UIColor blackColor];
    } else if ([_mainColor isEqualToString:@"Green"]) {
        _main.textColor = [UIColor greenColor];
    }
    
    if ([_mainAlign isEqualToString:@"Left"]) {
        _main.textAlignment = NSTextAlignmentLeft;
    } else if ([_mainAlign isEqualToString:@"Center"]) {
        _main.textAlignment = NSTextAlignmentCenter;
    }else if ([_mainAlign isEqualToString:@"Right"]) {
        _main.textAlignment = NSTextAlignmentRight;
    }
    
    //3. sub
    _sub.font = [UIFont systemFontOfSize:_subSize];
    
    if ([_subColor isEqualToString:@"Blue"]) {
        _sub.textColor = [UIColor blueColor];
    } else if ([_subColor isEqualToString:@"Red"]) {
        _sub.textColor = [UIColor redColor];
    } else if ([_subColor isEqualToString:@"Yellow"]) {
        _sub.textColor = [UIColor yellowColor];
    } else if ([_subColor isEqualToString:@"Black"]) {
        _sub.textColor = [UIColor blackColor];
    } else if ([_subColor isEqualToString:@"Green"]) {
        _sub.textColor = [UIColor greenColor];
    }
    
    if ([_subAlign isEqualToString:@"Left"]) {
        _sub.textAlignment = NSTextAlignmentLeft;
    } else if ([_subAlign isEqualToString:@"Center"]) {
        _sub.textAlignment = NSTextAlignmentCenter;
    }else if ([_subAlign isEqualToString:@"Right"]) {
        _sub.textAlignment = NSTextAlignmentRight;
    }
    
    
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
    
    UIBarButtonItem *sizeSelect = [[UIBarButtonItem alloc] initWithTitle:@"Size" style:UIBarButtonItemStyleBordered target:self action:@selector(sizeUpDownAction)];
    
    UIBarButtonItem *colorSelect = [[UIBarButtonItem alloc] initWithTitle:@"Color" style:UIBarButtonItemStyleBordered target:self action:@selector(selectColorAction)];
    
    UIBarButtonItem *alignSelect = [[UIBarButtonItem alloc] initWithTitle:@"Align" style:UIBarButtonItemStyleBordered target:self action:@selector(alignAction)];
    
    UIBarButtonItem * btnSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyBoard)];
    
    
    _buttonArray = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,btnSpace,btnSpace,btnSpace,doneButton,nil];
    
    
    
    //Back Button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(backAction:)];
    
    
    //Font Array
    UIBarButtonItem *fontSize12 = [[UIBarButtonItem alloc] initWithTitle:@"Size 12" style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize16 = [[UIBarButtonItem alloc] initWithTitle:@"Size 16" style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize20 = [[UIBarButtonItem alloc]initWithTitle:@"Size 20" style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize24 = [[UIBarButtonItem alloc]initWithTitle:@"Size 24" style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize28 = [[UIBarButtonItem alloc]initWithTitle:@"Size 28" style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    if (_fontSizeArray == nil) {
        _fontSizeArray = [NSArray arrayWithObjects:backButton,fontSize12,fontSize16,fontSize20,fontSize24,fontSize28,nil];
    }
    
    //Color Array
    UIBarButtonItem *redButton = [[UIBarButtonItem alloc] initWithTitle:@"Red" style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *blueButton = [[UIBarButtonItem alloc] initWithTitle:@"Blue" style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *blackButton = [[UIBarButtonItem alloc]initWithTitle:@"Black" style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *yelloButton = [[UIBarButtonItem alloc]initWithTitle:@"Yellow" style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *greenButton = [[UIBarButtonItem alloc]initWithTitle:@"Green" style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    if (_colorArray == nil) {
        _colorArray = [NSArray arrayWithObjects:backButton,redButton,blueButton,blackButton,yelloButton,greenButton,nil];
    }
    
    //Align Array
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Left" style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    UIBarButtonItem *centerButton = [[UIBarButtonItem alloc] initWithTitle:@"Center" style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]initWithTitle:@"Right" style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    if (_alignArray == nil) {
        _alignArray = [NSArray arrayWithObjects:backButton,leftButton,centerButton,rightButton,nil];
    }
    
    
    //Keyboard top view
    if (_keyboardTopView == nil) {
        _keyboardTopView = [[UIToolbar alloc]init];
    }
    
    if (isUserInterfaceIdiomPhone) {
        _keyboardTopView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_TOOL_BAR_HEIGHT);
    } else {
        _keyboardTopView.frame = CGRectMake(0, 0, IPAD_UI_WIDTH, IPAD_UI_TOOL_BAR_HEIGHT);
    }
    [_keyboardTopView setBarStyle:UIBarStyleBlackTranslucent];
    
    [_keyboardTopView setItems:_buttonArray];
    [_subheading setInputAccessoryView:_keyboardTopView];
    [_main setInputAccessoryView:_keyboardTopView];
    [_sub setInputAccessoryView:_keyboardTopView];
}

-(IBAction)dismissKeyBoard
{
    [_subheading resignFirstResponder];
    [_main resignFirstResponder];
    [_sub resignFirstResponder];
    [_delegate save];
}

#pragma mark -
#pragma mark - UIImagePickerController related

- (void)selectFromImageLibraryByLogo:(UITapGestureRecognizer *)sender {
    
    _isLogoImageViewClicked = YES;
    
    if (isUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:_picker animated:YES];    
    } else {
        CGPoint point = [sender locationInView:self];
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];    
    }
    
}

- (void)selectFromImageLibraryByImage:(UITapGestureRecognizer *)sender {
    
    _isLogoImageViewClicked = NO;
    
    if (isUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:_picker animated:YES];
    } else {
        CGPoint point = [sender locationInView:self];
        CGRect rect = CGRectMake(point.x, point.y, 50, 50);
        
        [_imagePickerPopover presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (isUserInterfaceIdiomPhone) {
        [_picker dismissModalViewControllerAnimated:YES];
    } else {
        [_imagePickerPopover dismissPopoverAnimated:YES];
    }
    
    
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
    
    [_delegate save];
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


#pragma mark -
#pragma mark - Text edit function

- (UITextView *) getFirstResponderUITextView {
    for(UIView *view in [self subviews])
    {
        if([view isKindOfClass:[UITextView class]])
        {
            if (view.isFirstResponder)
                return (UITextView *)view;
        }
    }
    return nil;
}

- (void) sizeUpDownAction {
    [_keyboardTopView setItems:_fontSizeArray];
}

- (void) selectColorAction {
    [_keyboardTopView setItems:_colorArray];
}

- (void) alignAction {
    [_keyboardTopView setItems:_alignArray];
}

- (void) changeFontSize:(id) sender{
    
    NSUInteger selectFontSize;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    
    UITextView *responderTextView = [self getFirstResponderUITextView];
    
    if ([title isEqualToString:@"Size 12"]) {
        responderTextView.font = [UIFont systemFontOfSize:12];
        selectFontSize = 12;
    } else if ([title isEqualToString:@"Size 16"]) {
        responderTextView.font = [UIFont systemFontOfSize:16];
        selectFontSize = 16;
    } else if ([title isEqualToString:@"Size 20"]) {
        responderTextView.font = [UIFont systemFontOfSize:20];
        selectFontSize = 20;
    } else if ([title isEqualToString:@"Size 24"]) {
        responderTextView.font = [UIFont systemFontOfSize:24];
        selectFontSize = 24;
    } else if ([title isEqualToString:@"Size 28"]) {
        responderTextView.font = [UIFont systemFontOfSize:28];
        selectFontSize = 28;
    }
    
    if (responderTextView.tag == 100){
        _subheadingSize = selectFontSize;
    } else if (responderTextView.tag == 101) {
        _mainSize = selectFontSize;
    } else if (responderTextView.tag == 102) {
        _subSize = selectFontSize;
    }
    
    [_delegate save];
}

- (void) alignPosition:(id) sender{
    
     NSString *selectAlignStr = nil;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    UITextView *responderTextView = [self getFirstResponderUITextView];
    if ([title isEqualToString:@"Left"]) {
        responderTextView.textAlignment = NSTextAlignmentLeft;
        selectAlignStr = @"Left";
    } else if ([title isEqualToString:@"Center"]) {
        responderTextView.textAlignment = NSTextAlignmentCenter;
        selectAlignStr = @"Center";
    } else if ([title isEqualToString:@"Right"]) {
        responderTextView.textAlignment = NSTextAlignmentRight;
        selectAlignStr = @"Right";
    }
    
    if (responderTextView.tag == 100){
        _subheadingAlign = selectAlignStr;
    } else if (responderTextView.tag == 101) {
        _mainAlign = selectAlignStr;
    } else if (responderTextView.tag == 102) {
        _subAlign = selectAlignStr;
    }
    
    [_delegate save];
}

- (void) changeColor:(id) sender{

    NSString *selectColorStr = nil;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    UITextView *responderTextView = [self getFirstResponderUITextView];
    if ([title isEqualToString:@"Black"]) {
        responderTextView.textColor = [UIColor blackColor];
        selectColorStr = @"Black";
    } else if ([title isEqualToString:@"Yellow"]) {
        responderTextView.textColor = [UIColor yellowColor];
        selectColorStr = @"Yellow";
    } else if ([title isEqualToString:@"Blue"]) {
        responderTextView.textColor = [UIColor blueColor];
        selectColorStr = @"Blue";
    } else if ([title isEqualToString:@"Red"]) {
        responderTextView.textColor = [UIColor redColor];
        selectColorStr = @"Red";
    } else if ([title isEqualToString:@"Green"]) {
        responderTextView.textColor = [UIColor greenColor];
        selectColorStr = @"Green";
    }
    
    if (responderTextView.tag == 100){
        _subheadingColor = selectColorStr;
    } else if (responderTextView.tag == 101) {
         _mainColor = selectColorStr;
    } else if (responderTextView.tag == 102) {
        _subColor = selectColorStr;
    }
    
    [_delegate save];
}


- (void) backAction:(id) sender{
    [_keyboardTopView setItems:_buttonArray];
}


#pragma mark -
#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    CGRect frame = textView.frame;
    frame.size.height = textView.contentSize.height;
    textView.frame = frame;
}


#pragma mark -
#pragma mark - Memory Management

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
