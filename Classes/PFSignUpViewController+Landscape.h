//
//  PFSignUpViewController+Landscape.h
//  FlashCardCreator
//
//  Created by Internetics on 17/10/2015.
//  Copyright © 2015 Internetics. All rights reserved.
//

#import "PFSignUpViewController.h"

@interface PFSignUpViewController (Landscape)

/**
 *  区分来自于分享还是来自setting(MoreInfoTableViewController)
 */
@property (readwrite) BOOL fromSetting;

@end
