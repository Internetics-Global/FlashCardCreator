//
//  Text2SpeechHelper.m
//  FlashCardCreator
//
//  Created by Demo on 6/5/17.
//  Copyright © 2017 Internetics. All rights reserved.
//

#import "Text2SpeechHelper.h"

@implementation Text2SpeechHelper

+ (NSArray *) getAllAvailableAVSpeechSynthesisVoiceArray {
    
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

+ (NSArray *) getAllAvailableText2SpeechDescriptionArrayForDisplay {
    NSArray *voiceArray = [self getAllAvailableAVSpeechSynthesisVoiceArray];
    NSMutableArray *returnarray = [NSMutableArray array];
    for (AVSpeechSynthesisVoice *item in voiceArray) {
        NSString *description = [self getText2SpeechDescriptionForDisplayFromVoiceLanguage:item.language];
        [returnarray addObject:description];
    }
    
    return returnarray;
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


/*
 * used for [AVSpeechSynthesisVoice voiceWithLanguage:text2SpeechLanguage]
*/
+ (NSString *) getSelectedText2SpeechLanguageFromSetting {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *defaultLanguage = [userDefaults objectForKey:@"Selected_Text2Speech_Language"];
    
    if (defaultLanguage.length == 0 || [defaultLanguage.lowercaseString rangeOfString:@"null"].location != NSNotFound) {
        defaultLanguage = [self getDefaultText2SpeechVoiceLanguage];
    }
    
    return defaultLanguage;
    
}

+ (void) setSelectedText2SpeechLanguageForSetting:(AVSpeechSynthesisVoice *) languageVoice {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:languageVoice.language forKey:@"Selected_Text2Speech_Language"];
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

+ (NSString *) getText2SpeechDescriptionForDisplayFromVoice:(AVSpeechSynthesisVoice *) voice {
    NSString *language = voice.language;
    return [self getText2SpeechDescriptionForDisplayFromVoiceLanguage:language];
}


/**
 *  Since there's no way to automatically mapping this relationship. review should be done when upgrading iOS
 */
+ (NSString *) getText2SpeechDescriptionForDisplayFromVoiceLanguage:(NSString *) voiceLanguage {
    
    NSString *normalizedVoiceLanguage;
    NSArray *array = [voiceLanguage componentsSeparatedByString:@"-"];
    if ([array count] != 2) {
        return nil;
    } else {
        NSString *first = array[0];
        NSString *second = array[1];
        normalizedVoiceLanguage = [NSString stringWithFormat:@"%@-%@",first.lowercaseString,second.uppercaseString];
    }
    
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
    
    NSString *str = [dict objectForKey:normalizedVoiceLanguage];
    return str;
}


@end
