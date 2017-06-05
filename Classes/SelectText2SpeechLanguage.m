//
//  SelectText2SpeechLanguage.m
//  FlashCardCreator
//
//  Created by Internetics.net.au on 11/08/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "SelectText2SpeechLanguage.h"
#import <AVFoundation/AVFoundation.h>
#import "Text2SpeechHelper.h"

@interface SelectText2SpeechLanguage () <UITableViewDelegate, UITableViewDataSource>{
    UITableView *_alertTable;
    
    NSArray     *_allText2SpeechArray;
}

@end

@implementation SelectText2SpeechLanguage

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _alertTable = [[UITableView alloc] initWithFrame:self.view.bounds];
    _alertTable.delegate = self;
    _alertTable.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _alertTable.dataSource = self;
    _alertTable.opaque = NO;
    _alertTable.backgroundView = nil;
    _alertTable.separatorColor = [UIColor colorWithRed:83.0/255 green:83.0/255 blue:83.0/255 alpha:1];
    _alertTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _alertTable.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    [self.view addSubview:_alertTable];
    
    self.title = @"Select Language";
    
    _allText2SpeechArray = [Text2SpeechHelper getAllText2SpeechArray];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_allText2SpeechArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    AVSpeechSynthesisVoice *item = _allText2SpeechArray[indexPath.row];
    
    cell.textLabel.text = [Text2SpeechHelper getLocalText2SpeechLanguageDescriptionFromCode:item.language];
    
    NSString *selectedLanguageName = [Text2SpeechHelper getSelectedText2SpeechLanguageFromSetting];
    if (indexPath.row == [self indexOfText2SpeechArray:selectedLanguageName]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        cell.tintColor = [UIColor whiteColor];
    }
    
    cell.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AVSpeechSynthesisVoice *item = _allText2SpeechArray[indexPath.row];
    
    [Text2SpeechHelper setSelectedText2SpeechLanguageForSetting:item];
    
    [_alertTable reloadData];
}


- (NSInteger) indexOfText2SpeechArray:(NSString *) languageName {
    
    int i = 0;
    for (AVSpeechSynthesisVoice *item in _allText2SpeechArray) {
        if ([item.language.lowercaseString isEqualToString:languageName.lowercaseString]) {
            return i;
        }
        i++;
    }
    
    return -1;
    
}



@end
