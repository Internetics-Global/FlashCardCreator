//
//  FMMoveTableViewCell.h
//  FMFramework
//
//  Created by Florian Mielke.
//  Copyright 2012 Florian Mielke. All rights reserved.
//  

#import <SWTableViewCell.h>  //we changed this framework in order to both support swipe left/right and drage to sort

@interface FMMoveTableViewCell : SWTableViewCell

- (void)prepareForMove;

@end
