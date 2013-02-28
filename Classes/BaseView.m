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
#import "Pack.h"
#import "CSS.h"
#import "SimpleWebBrowserController.h"

#import "UINavigationController+DismissKeyboard.h"  //used to restrict to be landscaped.

@class QuestionView;

@implementation BaseView

@synthesize currentCard = _currentCard;
@synthesize currentPack = _currentPack;
@synthesize logoImage = _logoImage;
@synthesize logoLinkURL = _logoLinkURL;
@synthesize logoImageFullPath = _logoImageFullPath;
@synthesize logoLinkageButton = _logoLinkageButton;
@synthesize packName = _packName;
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
@synthesize verticalScrollView = _verticalScrollView;

#pragma mark -
#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _logoLinkURL = @"http://www.";
        _subheadingSize = 20;
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
    
    //Section 1
    
    UIImageView *titleBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_title_background.png"]];
    titleBackgroundView.frame = CGRectMake(0, 0, 800, 110);
    titleBackgroundView.userInteractionEnabled = FALSE;
    [self addSubview:titleBackgroundView];
    
    _logoImage = [[UIImageView  alloc] init];
    _logoImage.contentMode = UIViewContentModeScaleAspectFit;
    _logoImage.frame = CGRectMake(680, 0, 100, 100);
    _logoImage.clipsToBounds = YES;
    _logoImage.backgroundColor = [UIColor clearColor];
    _logoImage.userInteractionEnabled = TRUE; //alway true
    _logoImage.layer.cornerRadius = 8;
    _logoImage.layer.masksToBounds = YES;
    [self addSubview:_logoImage];
    //Default logic
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    _logoLinkageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _logoLinkageButton.frame = CGRectMake(680, 95, 100, 30);
    [_logoLinkageButton setTitle:@"Edit linkage" forState:UIControlStateNormal];
    _logoLinkageButton.backgroundColor = [UIColor clearColor];
    [_logoLinkageButton addTarget:self action:@selector(editLogoLinkageURL:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:_logoLinkageButton];
    
    UIImageView *sidebarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_sidebar.png"]];
    sidebarImageView.frame = CGRectMake(0, 0, 60, 550);
    sidebarImageView.userInteractionEnabled = FALSE;
    [self addSubview:sidebarImageView];
    
    _title = [[UITextView alloc]init];
    _title.frame = CGRectMake(300, 30, 200, 110);
    _title.backgroundColor = [UIColor clearColor];
    _title.font =[UIFont systemFontOfSize:30];
    _title.textAlignment = NSTextAlignmentCenter;
    _title.text =NSLocalizedString(@"ToolbarItem_Question",nil);
    _title.userInteractionEnabled = FALSE;
    [self addSubview:_title];
    
    //Section 2
    
    _verticalScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(60, 110, 740, 440)];
    _verticalScrollView.backgroundColor = [UIColor clearColor];
    [self addSubview:_verticalScrollView];
    
    _image= [[UIImageView  alloc] init];
    _image.userInteractionEnabled = FALSE;
    _image.contentMode = UIViewContentModeScaleAspectFit;
    _image.clipsToBounds = YES;
    _image.backgroundColor = [UIColor clearColor];
    _image.layer.cornerRadius = 15;
    _image.layer.masksToBounds = YES;
    [_verticalScrollView addSubview:_image];
    
    UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
    [_image addGestureRecognizer:imageSingeTap];
    
    _subheading = [[UITextView alloc]init];
    _subheading.text = @"Example";
    _subheading.tag = 100;
    _subheading.userInteractionEnabled = FALSE;
    _subheading.backgroundColor = [UIColor yellowColor];
    _subheading.keyboardType = UIKeyboardAppearanceDefault;
     _subheading.returnKeyType = UIReturnKeyDefault;
    _subheading.delegate = self;
    [_verticalScrollView addSubview:_subheading];
    
    _main = [[UITextView alloc]init];
    _main.text = @"Type";
    _main.tag = 101;
    _main.userInteractionEnabled = FALSE;
    _main.backgroundColor = [UIColor orangeColor];
    _main.keyboardType = UIKeyboardAppearanceDefault;
    _main.returnKeyType = UIReturnKeyDefault;
    _main.delegate = self;
    [_verticalScrollView addSubview:_main];
    
    _sub = [[UITextView alloc]init];
    _sub.text = @"Sub";
    _sub.tag = 102;
    _sub.userInteractionEnabled = FALSE;
    _sub.backgroundColor = [UIColor greenColor];
    _sub.keyboardType = UIKeyboardAppearanceDefault;
    _sub.returnKeyType = UIReturnKeyDefault;
    _sub.delegate = self;
    [_verticalScrollView addSubview:_sub];
    
    //Section 3
    
    _packName = [[UILabel alloc] init];
    _packName.frame = CGRectMake(0, 0, 400, 60);
    [_packName setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    _packName.center = CGPointMake(30, 275);
    _packName.text = @"This is the pack name";
    _packName.textAlignment = NSTextAlignmentCenter;
    _packName.backgroundColor = [UIColor clearColor];
    _packName.font = [UIFont systemFontOfSize:20];
    _packName.textColor = [UIColor whiteColor];
    [self addSubview:_packName];
}

- (void) loadViewForiPhone {
    
    //Section 1
    
    UIImageView *titleBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_title_background.png"]];
    titleBackgroundView.frame = CGRectMake(0, 0, kFlashCardViewWidth_Detail_iPhone,40);
    titleBackgroundView.contentMode = UIViewContentModeScaleToFill;
    titleBackgroundView.userInteractionEnabled = FALSE;
    [self addSubview:titleBackgroundView];
    
    UIImageView *sidebarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_sidebar.png"]];
    sidebarImageView.frame = CGRectMake(0, 0, 30, kFlashCardViewHeight_Detail_iPhone-45);
    sidebarImageView.userInteractionEnabled = FALSE;
    [self addSubview:sidebarImageView];
    
    
    _title = [[UITextView alloc]init];
    _title.frame = CGRectMake(40, 0, 300, 30);
    _title.text =NSLocalizedString(@"ToolbarItem_Question",nil);
    _title.font =[UIFont systemFontOfSize:20];
    _title.textAlignment = NSTextAlignmentCenter;
    _title.backgroundColor = [UIColor clearColor];
    _title.userInteractionEnabled = FALSE;
    [self addSubview:_title];
    
    _logoImage = [[UIImageView  alloc] init];
    _logoImage.contentMode = UIViewContentModeScaleAspectFit;
    _logoImage.frame = CGRectMake(350, 5, 30, 30);
    _logoImage.clipsToBounds = YES;
    _logoImage.backgroundColor = [UIColor clearColor];
    _logoImage.userInteractionEnabled = TRUE;
    _logoImage.tag = 0;
    _logoImage.layer.cornerRadius = 5;
    _logoImage.layer.masksToBounds = YES;
    [self addSubview:_logoImage];
    
    //Default logic
    UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
    [_logoImage addGestureRecognizer:logoSingeTap];
    
    _logoLinkageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _logoLinkageButton.frame = CGRectMake(350, 30, 30, 10);
    [_logoLinkageButton setTitle:@"edit" forState:UIControlStateNormal];
    _logoLinkageButton.titleLabel.font = [UIFont systemFontOfSize:10];
    _logoLinkageButton.backgroundColor = [UIColor clearColor];
    [_logoLinkageButton addTarget:self action:@selector(editLogoLinkageURL:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:_logoLinkageButton];
    
    //Section 2
    
    _verticalScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(30, 40, 370, 175)];
    _verticalScrollView.backgroundColor = [UIColor clearColor];
    [self addSubview:_verticalScrollView];
    
    _image= [[UIImageView  alloc] init];
    _image.userInteractionEnabled = FALSE;
    _image.contentMode = UIViewContentModeScaleAspectFit;
    _image.clipsToBounds = YES;
    _image.backgroundColor = [UIColor clearColor];
    _image.tag = 1;
    _image.layer.cornerRadius = 10;
    _image.layer.masksToBounds = YES;
    [_verticalScrollView addSubview:_image];
    
    UITapGestureRecognizer *imageSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByImage:)];
    [_image addGestureRecognizer:imageSingeTap];
    
    _subheading = [[UITextView alloc]init];
    _subheading.text = @"Example";
    _subheading.tag = 100;
    _subheading.userInteractionEnabled = FALSE;
    _subheading.backgroundColor = [UIColor yellowColor];
    _subheading.keyboardType = UIKeyboardAppearanceDefault;
    _subheading.returnKeyType = UIReturnKeyDefault;
    _subheading.delegate = self;
    [_verticalScrollView addSubview:_subheading];
    
    _main = [[UITextView alloc]init];
    _main.userInteractionEnabled = FALSE;
    _main.backgroundColor = [UIColor orangeColor];
    _main.keyboardType = UIKeyboardAppearanceDefault;
    _main.returnKeyType = UIReturnKeyDefault;
    _main.delegate = self;
    [_verticalScrollView addSubview:_main];
    
    _sub = [[UITextView alloc]init];
    _sub.userInteractionEnabled = FALSE;
    _sub.backgroundColor = [UIColor greenColor];
    _sub.keyboardType = UIKeyboardAppearanceDefault;
    _sub.returnKeyType = UIReturnKeyDefault;
    _sub.delegate = self;
    [_verticalScrollView addSubview:_sub];
    
    //Section 3
    
    _packName = [[UILabel alloc] init];
    _packName.frame = CGRectMake(0, 0, 200, 30);
    [_packName setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    _packName.center = CGPointMake(15, 112);
    _packName.text = @"This is the pack name";
    _packName.textAlignment = NSTextAlignmentCenter;
    _packName.backgroundColor = [UIColor clearColor];
    _packName.font = [UIFont systemFontOfSize:12];
    _packName.textColor = [UIColor whiteColor];
    [self addSubview:_packName];
}

#pragma mark -
#pragma mark - Update CSS (only CSS) and Logo

- (void) switchLogoStatus {
    
    if (([_currentCard.creator isEqualToString:[OpenUDID value]]) && ([self isMemberOfClass:[QuestionView class]])) {
        //We don't need to show logoLinkageButton in AnswerView
        _logoLinkageButton.hidden = FALSE;
        UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromImageLibraryByLogo:)];
        [_logoImage addGestureRecognizer:logoSingeTap];
    } else {
        _logoLinkageButton.hidden = TRUE;
        UITapGestureRecognizer *logoSingeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWebviewViaLogoURL:)];
        [_logoImage addGestureRecognizer:logoSingeTap];
    }
}

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
    //Step1: Get keyboard height
    NSDictionary* info = [aNotification userInfo];
    NSValue *aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    _keyboardHeight = [aValue CGRectValue].size.height;
    //NSLog(@"Keyboard height is %f",_keyboardHeight);
    
    //Step2: Get cursor Y value relative to view
    UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
    CGFloat cursorY = [responderTextView caretRectForPosition:responderTextView.selectedTextRange.start].origin.y;
    //NSLog(@"Y position for current cursorY is %f",cursorY);
    
    //Step3: Get view's Y value relative to screen
    CGFloat yInScrren;
    if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight) {
        yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].x;    
    } else {
        //Since we convert to point based on UIWindow
        if (isUserInterfaceIdiomPhone) {
            yInScrren = IPHONE_UI_HEIGHT - [responderTextView convertPoint:CGPointZero toView:nil].x;
        } else {
            yInScrren = IPAD_UI_HEIGHT -[responderTextView convertPoint:CGPointZero toView:nil].x;
        }
    }
    
    //Step4: calculate the offset and gap value
    CGPoint offset = _verticalScrollView.contentOffset;
    CGFloat gap;
    if (isUserInterfaceIdiomPhone) {
        gap = _keyboardHeight -(IPHONE_UI_HEIGHT - yInScrren - cursorY);
    } else {
        gap = _keyboardHeight -(IPAD_UI_HEIGHT - yInScrren - cursorY);
    }
    
    if (gap >5) {
        offset.y = gap+20;
    }
    
    //Step5: move scrollview
    [_verticalScrollView setContentOffset:offset animated:YES];
    
    if (_keyboardShown)
        return;
    
    _keyboardShown = YES;
}


- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    _keyboardShown = NO;
    
    CGPoint offset = _verticalScrollView.contentOffset;
    offset.y = 0;
    [_verticalScrollView setContentOffset:offset animated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_AFTER_CARD_EDIT_NOTIFICATION object:nil];
    
}

- (void) setInputAccessoryViewDone  {
    
    UIBarButtonItem *sizeSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Size",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(sizeUpDownAction)];
    
    UIBarButtonItem *colorSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectColorAction)];
    
    UIBarButtonItem *alignSelect = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignAction)];
    
    UIBarButtonItem * btnSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Keyboard_Done",nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyBoard)];
    
    
    _buttonArray = [NSArray arrayWithObjects:alignSelect,sizeSelect,colorSelect,btnSpace,btnSpace,btnSpace,doneButton,nil];
    
    //Back Button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Back",nil) style:UIBarButtonItemStyleDone target:self action:@selector(backAction:)];
    
    //Font Array
    UIBarButtonItem *fontSize12 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size12",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize16 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size16",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize20 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size20",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize24 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size24",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    UIBarButtonItem *fontSize28 = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Size28",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeFontSize:)];
    
    if (_fontSizeArray == nil) {
        _fontSizeArray = [NSArray arrayWithObjects:backButton,fontSize12,fontSize16,fontSize20,fontSize24,fontSize28,nil];
    }
    
    //Color Array
    UIBarButtonItem *redButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Red",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *blueButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Blue",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *blackButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Black",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *yelloButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Yellow",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    UIBarButtonItem *greenButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Color_Green",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(changeColor:)];
    
    if (_colorArray == nil) {
        _colorArray = [NSArray arrayWithObjects:backButton,redButton,blueButton,blackButton,yelloButton,greenButton,nil];
    }
    
    //Align Array
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Left",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    UIBarButtonItem *centerButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Center",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"ToolbarItem_Align_Right",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(alignPosition:)];
    
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
    // we comment it and hope to execute scrrenshot capture only after keyboard disappear, othervise, the captured image is not right
    //[[NSNotificationCenter defaultCenter] postNotificationName:SAVE_AFTER_CARD_EDIT_NOTIFICATION object:nil];
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
    NSData *imageData = UIImageJPEGRepresentation([origialmage scaleToSize:CGSizeMake(400, 400)], kJPEGQualityFactor);

    if (_isLogoImageViewClicked) {
        if (([_logoImageFullPath rangeOfString:@".jpg"].location == NSNotFound) || ([_logoImageFullPath hasSuffix:@"question_placeholder_logo.jpg"])||((_logoImageFullPath == nil))) {
            _logoImageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePath];
        }
        
        [imageData writeToFile:_logoImageFullPath atomically:YES];
        _logoImage.image = [UIImage imageWithData:imageData];
        [_delegate updatelogoImageForAllCards:_logoImageFullPath];
        
    } else {
        if (([_imageFullPath rangeOfString:@".jpg"].location == NSNotFound) || ([_imageFullPath hasSuffix:@"answer_placeholder_content.jpg"]) || ((_logoImageFullPath == nil))) {
            _imageFullPath = [FileOperationHelper generateUniqueJPEGImageFilePath];
        }
        [imageData writeToFile:_imageFullPath atomically:YES];
        _image.image = [UIImage imageWithData:imageData];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_AFTER_CARD_EDIT_NOTIFICATION object:nil];
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


#pragma mark -
#pragma mark - Text edit function

- (UITextView *) getFirstResponderUITextViewUnderVerticalScrollView {
    //we put all the editable UITextView as subview of verticalScrollView
    for(UIView *view in [self.verticalScrollView subviews])
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
    
    UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
    
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size12",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:12];
        selectFontSize = 12;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size16",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:16];
        selectFontSize = 16;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size20",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:20];
        selectFontSize = 20;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size24",nil)]) {
        responderTextView.font = [UIFont systemFontOfSize:24];
        selectFontSize = 24;
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Size28",nil)]) {
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
    
    CGRect frame = responderTextView.frame;
    frame.size.height = responderTextView.contentSize.height;
    responderTextView.frame = frame;
    
    // we comment it and hope to execute scrrenshot capture only after keyboard disappear, othervise, the captured image is not right
    //[[NSNotificationCenter defaultCenter] postNotificationName:SAVE_AFTER_CARD_EDIT_NOTIFICATION object:nil];
    
    [_keyboardTopView setItems:_buttonArray];
}

- (void) alignPosition:(id) sender{
    
     NSString *selectAlignStr = nil;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Left",nil)]) {
        responderTextView.textAlignment = NSTextAlignmentLeft;
        selectAlignStr = @"Left";
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Center",nil)]) {
        responderTextView.textAlignment = NSTextAlignmentCenter;
        selectAlignStr = @"Center";
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Align_Right",nil)]) {
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
    
    // we comment it and hope to execute scrrenshot capture only after keyboard disappear, othervise, the captured image is not right
    //[[NSNotificationCenter defaultCenter] postNotificationName:SAVE_AFTER_CARD_EDIT_NOTIFICATION object:nil];
    
    [_keyboardTopView setItems:_buttonArray];
}

- (void) changeColor:(id) sender{

    NSString *selectColorStr = nil;
    
    NSString *title = ((UIBarButtonItem *) sender).title;
    UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
    if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Black",nil)]) {
        responderTextView.textColor = [UIColor blackColor];
        selectColorStr = @"Black";
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Yellow",nil)]) {
        responderTextView.textColor = [UIColor yellowColor];
        selectColorStr = @"Yellow";
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Blue",nil)]) {
        responderTextView.textColor = [UIColor blueColor];
        selectColorStr = @"Blue";
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Red",nil)]) {
        responderTextView.textColor = [UIColor redColor];
        selectColorStr = @"Red";
    } else if ([title isEqualToString:NSLocalizedString(@"ToolbarItem_Color_Green",nil)]) {
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
    
    // we comment it and hope to execute scrrenshot capture only after keyboard disappear, othervise, the captured image is not right
    //[[NSNotificationCenter defaultCenter] postNotificationName:SAVE_AFTER_CARD_EDIT_NOTIFICATION object:nil];
    
    [_keyboardTopView setItems:_buttonArray];
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

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    if ( [text isEqualToString:@"\n"] ) {
        UITextView *responderTextView = [self getFirstResponderUITextViewUnderVerticalScrollView];
        CGFloat cursorY = [responderTextView caretRectForPosition:responderTextView.selectedTextRange.start].origin.y;
        NSLog(@"Y position for current cursorY is %f",cursorY);
        
        CGFloat yInScrren = [responderTextView convertPoint:CGPointZero toView:nil].x;
        
        CGPoint offset = _verticalScrollView.contentOffset;
        CGFloat gap;
        if (isUserInterfaceIdiomPhone) {
            gap = _keyboardHeight -(IPHONE_UI_HEIGHT - yInScrren - cursorY);
        } else {
            gap = _keyboardHeight -(IPAD_UI_HEIGHT - yInScrren - cursorY);
        }
        
        if (gap >0) {
            offset.y = offset.y + responderTextView.font.lineHeight;
        }
        [_verticalScrollView setContentOffset:offset animated:YES];

    }
    return YES;
}

#pragma mark -
#pragma mark - Add logo linkage relate

- (void) editLogoLinkageURL:(id) sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Set URL"
                                                    message:[NSString stringWithFormat:@"Enter a valid URL"]
                                                   delegate:self cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Ok", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    if ([[_currentPack cards] count]  >0) {
        _logoLinkURL = ((Card *)[_currentPack cards][0]).question.logoURLLinkage;
    }
    [alert textFieldAtIndex:0].text = _logoLinkURL;
    alert.delegate = self;
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex ==1) {
        NSString *temp = [alertView textFieldAtIndex:0].text;
        
        if (![temp isEqualToString:_logoLinkURL]) {
            _logoLinkURL = temp;
            _currentCard.question.logoURLLinkage = temp;
            
            [_delegate updatelogoURLForAllCards:temp];
        } 
    }
}

- (void)openWebviewViaLogoURL:(UITapGestureRecognizer *)sender {

    NSURL *url = [NSURL URLWithString:_logoLinkURL];
    
    if (url) {
        SimpleWebBrowserController *controller = [[SimpleWebBrowserController alloc] initWithURL:url];
        controller.hidesToolbar = NO;
        
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navController animated:YES];

    } else {
        [Common alertViewCommon:@"Incorrect URL format or empty "];
    }
}

@end
