//
//  DropboxSharekitHelper.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 1/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>
#import "MBProgressHUD.h"

@class Pack;
@class Card;

@interface DropboxSharekitHelper : NSObject <DBRestClientDelegate,MBProgressHUDDelegate, UIAlertViewDelegate> {
    Pack *_currentPack;
    Card *_currentCard;
    UIViewController *_baseViewController;
    
    DBRestClient *_restClient;
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
