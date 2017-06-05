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
    
    NSArray     *_allAVSpeechSynthesisVoiceArray;
    NSArray     *_allText2SpeechDescriptionArrayForDisplay;
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
    
    _allAVSpeechSynthesisVoiceArray = [Text2SpeechHelper getAllAvailableAVSpeechSynthesisVoiceArray];
    _allText2SpeechDescriptionArrayForDisplay = [Text2SpeechHelper getAllAvailableText2SpeechDescriptionArrayForDisplay];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_allAVSpeechSynthesisVoiceArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSString *title = _allText2SpeechDescriptionArrayForDisplay[indexPath.row];
    cell.textLabel.text = title;
    
    int selectedIndex = [self getSelectedIndexForSettingDisplayOnly];
    if (indexPath.row == selectedIndex) {
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
    AVSpeechSynthesisVoice *item = _allAVSpeechSynthesisVoiceArray[indexPath.row];
    
    [Text2SpeechHelper setSelectedText2SpeechLanguageForSetting:item];
    
    [_alertTable reloadData];
}

- (int) getSelectedIndexForSettingDisplayOnly {
    NSString *selectedLanguageName = [Text2SpeechHelper getSelectedText2SpeechLanguageFromSetting];
    
    int i = 0;
    for (AVSpeechSynthesisVoice *item in _allAVSpeechSynthesisVoiceArray) {
        if ([item.language.lowercaseString isEqualToString:selectedLanguageName.lowercaseString]) {
            return i;
        }
        i++;
    }
    
    return -1;
    
}

@end
