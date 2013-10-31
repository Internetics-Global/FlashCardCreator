//
//  AppDelegate.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h> 

@class MasterViewController;
@class DetailViewController;
@class Pack;
@class Card;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    Pack *_lastCreatedPack;
    int _indexLastCreatedPack;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) MGSplitViewController *splitViewController;
@property (strong, nonatomic) MasterViewController *masterViewController;
@property (strong, nonatomic) DetailViewController *detailViewController;

@property (assign, nonatomic) int packIDForMasterViewPack;

@end
