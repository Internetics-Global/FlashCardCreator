//
//  BaseView.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 10/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "BaseView.h"

@implementation BaseView

@synthesize currentCard = _currentCard;

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
    }
    return self;
}

- (void) loadView {
    _title = [[UITextView alloc]init];
    _title.frame = CGRectMake(0, 0, 600, 60);
    _title.text =@"Question";
    _title.font =[UIFont systemFontOfSize:30];
    _title.textAlignment = NSTextAlignmentLeft;
    _title.backgroundColor = [UIColor clearColor];
    _title.userInteractionEnabled = FALSE;
    [self addSubview:_title];
    
    _logoImage = [[UIImageView  alloc] initWithImage:[UIImage imageNamed:@"question_logo.png"]];
    _logoImage.contentMode = UIViewContentModeScaleAspectFit;
    _logoImage.frame = CGRectMake(500, 0, 60, 60);
    _logoImage.clipsToBounds = YES;
    _logoImage.backgroundColor = [UIColor clearColor];
    [self addSubview:_logoImage];
    
    _image= [[UIImageView  alloc] init];
    _image.contentMode = UIViewContentModeScaleAspectFit;
    _image.frame = CGRectMake(270, 120, 300, 300);
    _image.clipsToBounds = YES;
    _image.backgroundColor = [UIColor clearColor];
    [self addSubview:_image];
    
    _content = [[UITextView alloc]init];
    _content.frame = CGRectMake(0, 60, 600, 500);
    _content.font =[UIFont systemFontOfSize:20];
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


@end
