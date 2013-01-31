//
//  NSArray+Randomised.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 31/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "NSArray+Randomised.h"

@implementation NSArray (Randomised)

static inline int randomInt(int low, int high)
{
    return (arc4random() % (high-low+1)) + low;
}

- (NSArray *)randomised
{
    NSMutableArray *randomised = [NSMutableArray arrayWithCapacity:[self count]];
    
    for (id object in self) {
        NSUInteger index = randomInt(0, [randomised count]);
        [randomised insertObject:object atIndex:index];
    }
    return randomised;
}


@end
