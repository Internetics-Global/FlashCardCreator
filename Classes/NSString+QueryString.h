//
//  NSString+QueryString.h
//  FFC
//
//  Created by Wang Bourne on 8/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (QueryString)

+ (NSDictionary *)queryParamsFromString:(NSString *)str;
@end
