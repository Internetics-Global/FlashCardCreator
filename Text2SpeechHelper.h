//
//  Text2SpeechHelper.h
//  FlashCardCreator
//
//  Created by Demo on 6/5/17.
//  Copyright © 2017 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Text2SpeechHelper : NSObject

+ (NSArray *) getAllText2SpeechArray;

+ (NSArray *) getRawText2SpeechArrayForCurrentLocale;

+ (NSString *) getSelectedText2SpeechLanguageFromSetting;
+ (void)       setSelectedText2SpeechLanguageForSetting:(NSString *) languageName;
+ (NSString *) getLanguageLocalFromCode:(NSString *) code ;

@end
