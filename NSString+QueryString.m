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
            NSString *val = [[pair objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *key = [[pair objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if (val != nil && key != nil) {
                [ret setObject:val forKey:key];
            }
        }
    }
    
    return ret;
}

+ (NSString *)queryStringFromParams:(NSDictionary *)dict {
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[[dict allKeys] count]];
    for (NSString *key in [dict allKeys]) {
        NSString * encodedKey = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                    NULL,
                                                                                    (CFStringRef)key,
                                                                                    NULL,
                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                    kCFStringEncodingUTF8 );
        NSString *encodedParaVal = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                       NULL,
                                                                                       (CFStringRef)[dict objectForKey:key],
                                                                                       NULL,
                                                                                       (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                       kCFStringEncodingUTF8 );
        NSString *str = [[NSString alloc] initWithFormat:@"%@=%@",encodedKey,encodedParaVal];
        [ret addObject:str];
        CFRelease(encodedKey);
        CFRelease(encodedParaVal);
        [str release];
        
    }
    
    return [ret componentsJoinedByString:@"&"];
}


- (NSString*)stringForHttpRequest {
    NSString * encodedStr= (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                               NULL,
                                                                               (CFStringRef)self,
                                                                               NULL,
                                                                               (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                               kCFStringEncodingUTF8 );
    return [encodedStr autorelease];
}


@end

