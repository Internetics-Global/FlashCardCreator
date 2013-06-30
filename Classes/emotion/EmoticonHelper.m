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
    NSString *path = [[NSBundle mainBundle] pathForResource:@"emotion" ofType:@"plist"];
    NSDictionary *emoticonsDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    
    NSArray * allKeys = [NSArray arrayWithArray:[[emoticonsDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    NSMutableArray *emoticonsArrary = [NSMutableArray arrayWithCapacity:[allKeys count]];
    for (NSString *key in allKeys) {
        NSArray *valueArrary = (NSArray *)[emoticonsDictionary objectForKey:key];
        if ([valueArrary count] >= 2) {
            Emoticon *emoticon = [Emoticon emoticonWithType:EmoticonTypeDefault 
                                                          title:[valueArrary objectAtIndex:0] 
                                                           code:[valueArrary objectAtIndex:1]
                                                          image:[UIImage imageNamed:[NSString stringWithFormat:@"%@@2x",key]]];
            [emoticonsArrary addObject:emoticon];
        }
    }
    
    return emoticonsArrary;
}


@end
