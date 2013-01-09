//
//  AddViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 17/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "AddViewController.h"
#import "User.h"
#import "Question.h"
#import "Answer.h"
#import "SQLiteHelper.h"

@interface AddViewController ()

@end

@implementation AddViewController

#pragma mark -
#pragma mark Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isNewPack = FALSE;
        _pack = [[Pack alloc] init];
        _card = [[Card alloc] init];
        _availablePackNameArray = [[NSMutableArray alloc] init];
        _availablePackArray = [[User defaultUser] packs];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveNewCard:)];
    self.navigationItem.rightBarButtonItem = saveButton;

    
    [self createPicker];
    
    _packTextField.delegate =self;
    
}


- (void)saveNewCard:(id)sender
{
    [self checkNewPack];
    if (_isNewPack == TRUE) {
        _pack.languageName = @"French "; //test purpose
        _pack.coverImageURL = [self createPackCoverImage];
        [[User defaultUser] addPack:_pack];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_PACK_ADDED_NOTIFICATION object:nil];
    }
    
    //warning: need to be completed, ccaa
    _card.packID = _pack.packID;
    _card.cardName = [NSString stringWithFormat:@"card name(pack_%@): %d",_pack.packName,rand()];
    _card.cardID = [SQLiteHelper getMaxValueForColumn:@"card_id" inTable:@"Cards_Tables"] + 1;
    
    _card.question.title = [NSString stringWithFormat:@"title%d", rand()];
    _card.question.cardID = _card.cardID;
    _card.question.content = [NSString stringWithFormat:@"contentcontentcontentcontent%d", rand()];
    //warning, need to be completed
    NSString *imageStr = [NSString stringWithFormat:@"question%d.png",arc4random()%7];
    _card.question.imageName = imageStr;
    
    _card.answer.title = [NSString stringWithFormat:@"answer%d", rand()];
    _card.answer.cardID = _card.cardID;
    _card.answer.content = [NSString stringWithFormat:@"answeransweransweransweranswer%d", rand()];
    imageStr = [NSString stringWithFormat:@"answer%d.png",arc4random()%7];
    _card.answer.imageName = imageStr;
    
    [_pack addCard:_card];
    
    [[NSUserDefaults standardUserDefaults] setInteger:([[_pack cards] count]-1) forKey:@"indexCard"];
    [[NSUserDefaults standardUserDefaults] setInteger:_pack.packID forKey:@"lastCreatedPackID"];
    [[NSUserDefaults standardUserDefaults] setInteger:_card.cardID forKey:@"lastCreatedCardID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    [self.navigationController popViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NEW_CARD_ADDED_NOTIFICATION object:nil];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self checkNewPack];
    return YES;
}

- (void) checkNewPack {
    if (self.packTextField.text == nil) {
        _isNewPack = FALSE;
        return;
    }
    
    NSUInteger index = [_availablePackNameArray indexOfObject:self.packTextField.text];
    
    if (index == NSNotFound) {
        _isNewPack = TRUE;
        _pack.packName = self.packTextField.text;
    } else {
        _isNewPack = FALSE;
        _pack = _availablePackArray[index];
    }
}

- (void)createPicker
{
    for (Pack *pack in _availablePackArray) {
        [_availablePackNameArray addObject:pack.packName];
    }
    
	_myPackPickerView.showsSelectionIndicator = YES;	// note this is default to NO
	
	// this view controller is the data source and delegate
	_myPackPickerView.delegate = self;
	_myPackPickerView.dataSource = self;
    
    
}


#pragma mark -
#pragma mark UIPickerViewDelegate and UIPickerViewDataSource

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	if (pickerView == _myPackPickerView)	// don't show selection for the custom picker
	{
		// report the selection to the UI label
		_pack = _availablePackArray[[pickerView selectedRowInComponent:0]];
        NSLog(@"%s:selected pack is: %@",__FUNCTION__,_pack.packName);
	}
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	NSString *returnStr = @"";
	
	// note: custom picker doesn't care about titles, it uses custom views
	if (pickerView == _myPackPickerView)
	{
		if (component == 0)
		{
			returnStr= _availablePackNameArray[row];
		}
		else
		{
			returnStr = [@(row) stringValue];
		}
	}
	
	return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	CGFloat componentWidth = 0.0;
    
	if (component == 0)
		componentWidth = 240.0;	// first column size is wider to hold names
	else
		componentWidth = 40.0;	// second column is narrower to show numbers
    
	return componentWidth;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [_availablePackArray count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 2;
}

- (NSString *) createPackCoverImage {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,    NSUserDomainMask ,YES );
    NSString *packCoverImageDir = [paths[0] stringByAppendingPathComponent:@"Pack Cover Image"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:packCoverImageDir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:packCoverImageDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", packCoverImageDir);
        }
    }
    
    NSString *packCoverImageName = [NSString stringWithFormat:@"%f%d.png", [[NSDate date] timeIntervalSince1970], [[User defaultUser] userID]];
    
    //warning: need to be completed
    NSString *coverImageFile = [NSString stringWithFormat:@"%@/image2.png", [[NSBundle mainBundle] resourcePath]];
    return coverImageFile;
}

#pragma mark -
#pragma mark Memory Management


- (void)viewDidUnload {
    [self setMyPackPickerView:nil];
    [self setPackTextField:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
