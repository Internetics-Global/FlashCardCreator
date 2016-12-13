//
//  GoogleDriveHelper.h
//  FlashCardCreator
//
//  Created by internetics on 9/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@class Pack;
@class Card;
@class GoogleDriveRestClient;

@interface GoogleDriveShareKitHelper : NSObject {
    Pack *_currentPack;
    Card *_currentCard;
    UIViewController *_baseViewController;
    
    GoogleDriveRestClient *_restClient;
    MBProgressHUD *_HUD;
    
    float _progressivePercent;
    BOOL _isCreatingShareLinkage;
    
    NSString *_finalShareLinkBeforeRedirect;
}

@property (nonatomic, strong) Pack *currentPack;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, strong) UIViewController *baseViewController;

- (id)initWithCurrentCard:(Card *)card currentPack:(Pack *) pack baseViewController:(UIViewController *) controlle;
- (void)shareAction;


@end
