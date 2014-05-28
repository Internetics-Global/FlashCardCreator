//
//  Constant.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 5/23/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

extern int const ddLogLevel;

/**
 *  有时我们会因为种种原因（特别是数据库）会出现null的情况。这种情况下我们也是认为是null的
 */
static inline BOOL IsEmpty(id thing) {
    return thing == nil || [thing isEqual:[NSNull null]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0)
    || ([thing isKindOfClass:[NSString class]]
        && ([(NSString *)thing rangeOfString:@"null"].location != NSNotFound))
    || ([thing isKindOfClass:[NSString class]]
        && ([(NSString *)thing rangeOfString:@"nil"].location != NSNotFound));
}
