//
//  PFLogInViewController+Landscape.h
//  FFC
//
//  Created by Internetics on 17/10/2015.
//  Copyright © 2015 Internetics. All rights reserved.
//

#import "PFLogInViewController.h"

@interface PFLogInViewController (Landscape)

/**
 *  区分来自于分享还是来自setting(MoreInfoTableViewController)
 */
@property (readwrite) BOOL fromSetting;

@end
