//
//  MutipleTargetHelper.h
//  FlashCardCreator
//
//  Created by Internetics on 6/05/2016.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MutipleTargetHelper : NSObject

+ (BOOL) isFullVersion;
+ (void) showAlertToUpgradeToFullVersion;
+ (void) setFullVersionFlag:(BOOL) flag;

@end
