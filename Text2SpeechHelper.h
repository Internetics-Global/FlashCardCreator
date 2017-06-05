//
//  Text2SpeechHelper.h
//  FlashCardCreator
//
//  Created by Demo on 6/5/17.
//  Copyright © 2017 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Text2SpeechHelper : NSObject

/*
 * Array of AVSpeechSynthesisVoice
*/
+ (NSArray *) getAllText2SpeechArray;

/*
 * result can directly be used by AVSpeechSynthesisVoice
*/
+ (NSString *) getSelectedText2SpeechLanguageFromSetting;

+ (void)       setSelectedText2SpeechLanguageForSetting:(AVSpeechSynthesisVoice *) languageVoice;

/*
 * description and used to show on screen
*/
+ (NSString *) getLocalText2SpeechLanguageDescriptionFromCode:(NSString *) code ;

@end
