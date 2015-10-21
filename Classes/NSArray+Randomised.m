//
//  NSArray+Randomised.m
//  FFC
//
//  Created by Wang Bourne on 31/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "NSArray+Randomised.h"
#import "Card.h"

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

- (NSMutableArray *)cardSNOrdered;
{
    /*Bubble  Low effiency
    Card *t = nil;
    NSMutableArray *shuffledCardArray= [NSMutableArray arrayWithArray:self];
    int n = [shuffledCardArray count];
    for(int i=n-2;i>=0;i--) {
        for(int j=0;j<=i;j++) {
            if(((Card *)shuffledCardArray[j]).cardSN>((Card *)shuffledCardArray[j+1]).cardSN) {
                t=shuffledCardArray[j];
                shuffledCardArray[j]=shuffledCardArray[j+1];
                shuffledCardArray[j+1]=t;
            }
        }
    } */
    
    NSArray *shuffledCardArray= [NSArray arrayWithArray:self];
    shuffledCardArray = [self sortedArrayUsingComparator:^(Card *a, Card *b) {
        return [[NSString stringWithFormat:@"%d",[a cardSN]] compare:[NSString stringWithFormat:@"%d",[b cardSN]] options:NSNumericSearch];
    }];
    
    return [NSMutableArray arrayWithArray:shuffledCardArray];
}




@end
