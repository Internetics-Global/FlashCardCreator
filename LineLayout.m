
//
//  LineLayout.m
//  FFC
//
//  Created by Bourne Wang on 7/17/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "LineLayout.h"


#define ITEM_SIZE_WIDTH 250
#define ITEM_SIZE_Height 250

@interface LineLayout()

@property (nonatomic, strong) NSDictionary *shelfRects;

@end


@implementation LineLayout

#define ACTIVE_DISTANCE 250
#define ZOOM_FACTOR 0

-(id)init
{
    self = [super init];
    if (self) {
        self.itemSize = CGSizeMake(ITEM_SIZE_WIDTH, ITEM_SIZE_Height);
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.sectionInset = UIEdgeInsetsMake(10, 0, 30, 10.0); 
        self.minimumLineSpacing = 30.0;

    }
    return self;
}


@end
