//
//  Text2SpeechHelper.m
//  FlashCardCreator
//
//  Created by Demo on 6/5/17.
//  Copyright © 2017 Internetics. All rights reserved.
//

#import "Text2SpeechHelper.h"
#import <AVFoundation/AVFoundation.h>

@implementation Text2SpeechHelper

+ (NSArray *) getAllText2SpeechArray {
    
    NSMutableArray *allText2SpeechArray = [NSMutableArray array];
    NSArray *array = [AVSpeechSynthesisVoice speechVoices];
    
    //remove duplicte
    for (AVSpeechSynthesisVoice *item in array) {
        BOOL exist =false;
        for (AVSpeechSynthesisVoice *subItem in allText2SpeechArray) {
            if ([item.language isEqualToString:subItem.language]) {
                exist = true;
                break;
            }
        }
        if (exist == false) {
            [allText2SpeechArray addObject:item];
        }
        
    }
    
    return allText2SpeechArray;
    
}

/**
 * return AVSpeechSynthesisVoice language arary for current locale
 * The reason why we do this is:
 *  NSLocale and NSLinguisticTagger both use ISO 681 codes to identify languages. AVSpeechSynthesisVoice, however, takes an IETF Language Tag, as specified BCP 47 Document Series. If an utterance string and voice aren’t in the same language, speech synthesis will fail.
 */
+ (NSArray *) getRawText2SpeechArrayForCurrentLocale {
    
    NSMutableArray *array = [NSMutableArray array];
    
    NSString * language2RegionStr = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *languageStr = [[language2RegionStr componentsSeparatedByString:@"-"] objectAtIndex:0];
    
    NSArray *text2SpeechArray = [AVSpeechSynthesisVoice speechVoices];
    for (AVSpeechSynthesisVoice *item in text2SpeechArray) {
        NSString *text2SpeechLanguageStr = [[item.language componentsSeparatedByString:@"-"] objectAtIndex:0];
        
        if ([text2SpeechLanguageStr isEqualToString:languageStr]) {
            [array addObject:item.language];
        }
        
    }
    
    NSArray *uniquearray = [[NSSet setWithArray:array] allObjects];
    
    
    return uniquearray;
    
}



+ (NSString *) getSelectedText2SpeechLanguageFromSetting {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *defaultLanguage = [userDefaults objectForKey:@"Selected_Text2Speech_Language"];
    
    if (defaultLanguage == nil) {
        defaultLanguage = [self getDefaultText2SpeechVoiceLanguage];
    }
    
    return defaultLanguage;
    
}

+ (void) setSelectedText2SpeechLanguageForSetting:(NSString *) languageName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:languageName forKey:@"Selected_Text2Speech_Language"];
    [userDefaults synchronize];
}



+ (NSString *) getDefaultText2SpeechVoiceLanguage {
    
    NSArray *rawArray = [Text2SpeechHelper getRawText2SpeechArrayForCurrentLocale];
    
    if ([rawArray count] == 0) {
        return @"en-GB";
    }
    
    if ([[[[rawArray objectAtIndex:0] componentsSeparatedByString:@"-"] firstObject] isEqualToString:@"nl"]) {
        
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isMaleVoice"];
        if (b) {
            return @"nl-NL";
        } else {
            return @"nl-BE";
        }
    }
    
    
    if ([[[[rawArray objectAtIndex:0] componentsSeparatedByString:@"-"] firstObject] isEqualToString:@"fr"]) {
        
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isMaleVoice"];
        if (b) {
            return @"fr-FR";
        } else {
            return @"fr-CA";
        }
    }
    
    if ([[[[rawArray objectAtIndex:0] componentsSeparatedByString:@"-"] firstObject] isEqualToString:@"en"]) {
        
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isMaleVoice"];
        if (b) {
            return @"en-GB";
        } else {
            return @"en-au";
        }
    }
    
    
    NSString * language2RegionStr = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *countryCode= [[language2RegionStr componentsSeparatedByString:@"-"] lastObject];
    
    for (NSString *item in rawArray) {
        NSString *itemStr = [[item componentsSeparatedByString:@"-"] lastObject];
        if ([itemStr.lowercaseString isEqualToString:countryCode.lowercaseString]) {
            return item;
        }
    }
    
    
    return [rawArray firstObject];
}


/**
 *  Since there's no way to automatically mapping this relationship. review should be done when upgrading iOS
 */
+ (NSString *) getLanguageLocalFromCode:(NSString *) code {
    NSDictionary *dict = @{
                           @"ar-SA"       :@"Arabic (Saudi Arabia) ",
                           @"cs-CZ"       :@"Czech (Czech Republic) ",
                           @"da-DK"       :@"Danish (Denmark) ",
                           @"de-DE"       :@"German(Germany) ",
                           @"el-GR"       :@"Modern Greek (Greece) ",
                           @"en-AU"       :@"English (Australia) ",
                           @"en-GB"       :@"English (United Kingdom) ",
                           @"en-IE"       :@"English (Ireland) ",
                           @"en-US"       :@"English (United States) ",
                           @"en-ZA"       :@"English (South Africa) ",
                           @"es-ES"       :@"Spanish (Spain) ",
                           @"es-MX"       :@"Spanish (Mexico) ",
                           @"fi-FI"       :@"Finnish (Finland) ",
                           @"fr-CA"       :@"French (Canada) ",
                           @"fr-FR"       :@"French (France) ",
                           @"he-IL"       :@"Hebrew (Israel) ",
                           @"hi-IN"       :@"Hindi (India) ",
                           @"hu-HU"       :@"Hungarian (Hungary) ",
                           @"id-ID"       :@"Indonesian (Indonesia) ",
                           @"it-IT"       :@"Italian (Italy) ",
                           @"ja-JP"       :@"Japanese (Japan) ",
                           @"ko-KR"       :@"Korean (Republic of Korea) ",
                           @"nl-BE"       :@"Dutch (Belgium) ",
                           @"nl-NL"       :@"Dutch (Netherlands) ",
                           @"no-NO"       :@"Norwegian (Norway) ",
                           @"pl-PL"       :@"Polish (Poland) ",
                           @"pt-BR"       :@"Portuguese (Brazil) ",
                           @"pt-PT"       :@"Portuguese (Portugal) ",
                           @"ro-RO"       :@"Romanian (Romania) ",
                           @"ru-RU"       :@"Russian (Russian Federation) ",
                           @"sk-SK"       :@"Slovak (Slovakia) ",
                           @"sv-SE"       :@"Swedish (Sweden) ",
                           @"th-TH"       :@"Thai (Thailand) ",
                           @"tr-TR"       :@"Turkish (Turkey) ",
                           @"zh-CN"       :@"Chinese (China) ",
                           @"zh-HK"       :@"Chinese (Hong Kong) ",
                           @"zh-TW"       :@"Chinese (Taiwan) "
                           };
    
    NSString *str = [dict objectForKey:code];
    return str;
}


@end
