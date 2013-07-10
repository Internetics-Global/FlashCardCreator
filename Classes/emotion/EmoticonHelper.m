//
//  EmoticonHelper.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "EmoticonHelper.h"
#import "Emoticon.h"

@implementation EmoticonHelper

+ (NSArray *)defaultEmoticons{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"emotions" ofType:@"txt"];
    NSString* content = [NSString stringWithContentsOfFile:filePath
                              encoding:NSUTF8StringEncoding error:nil];
    NSString *filtedContent = [[[content stringByReplacingOccurrencesOfString:@" " withString:@""]
                                      stringByReplacingOccurrencesOfString:@"\n" withString:@""]
                                              stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSArray *stringsArray = [filtedContent componentsSeparatedByString:@","];
    
    NSMutableArray *emoticonsArrary = [NSMutableArray arrayWithCapacity:[stringsArray count]];
    for (int i=0; i<[stringsArray count]; i++) {
        Emoticon *emoticon = [Emoticon emoticonWithType:EmoticonTypeDefault
                                                  title:[stringsArray objectAtIndex:i]
                                                   code:[stringsArray objectAtIndex:i]
                                                  image:[UIImage imageNamed:@"emotion_placeholder.png"]];
        [emoticonsArrary addObject:emoticon];
    }
    
    return emoticonsArrary;
}


@end
