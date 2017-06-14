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
 * result can directly be used by AVSpeechSynthesisVoice
*/
+ (NSString *) getSelectedText2SpeechLanguageFromSetting;
+ (void)       setSelectedText2SpeechLanguageForSetting:(AVSpeechSynthesisVoice *) languageVoice;

+ (NSString *) getText2SpeechDescriptionForDisplayFromVoiceLanguage:(NSString *) voiceLanguage;

+ (NSArray *)  getAllAvailableAVSpeechSynthesisVoiceArray;
+ (NSArray *)  getAllAvailableText2SpeechDescriptionArrayForDisplay;

+ (NSString *) getDefaultText2SpeechVoiceLanguage;
+ (NSString *) getDefaultText2SpeechDescriptionForDisplay;

@end
