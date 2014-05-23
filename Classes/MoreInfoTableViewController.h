//
//  MoreInfoTableViewController.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 18/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface MoreInfoTableViewController : UITableViewController <MFMailComposeViewControllerDelegate> {
    UISwitch *_dropboxSwitch;
    UISwitch *_playModeSwitch;
}

@end
