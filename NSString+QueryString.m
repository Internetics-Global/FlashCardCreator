//
//  NSString+QueryString.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 8/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "NSString+QueryString.h"


@implementation NSString (QueryString)

+ (NSDictionary *)queryParamsFromString:(NSString *)str {
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSURL *url = [NSURL URLWithString:str];
    str = [url query];
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSArray *arr = [str componentsSeparatedByString:@"&"];
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    
    for (NSString *str in arr) {
        NSArray *pair = [str componentsSeparatedByString:@"="];
        if ([pair count] == 2) {
            NSString *val = [pair[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *key = [pair[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if (val != nil && key != nil) {
                ret[key] = val;
            }
        }
    }
    
    return ret;
}


@end

