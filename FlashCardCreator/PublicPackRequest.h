//
//  PublicPackRequest.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 18/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>


@protocol PublicPackRequestDelegate <NSObject>

@required
- (void)didReceiveJSONResponse:(NSArray*)JSONResponse;
- (void)didNotReceiveJSONResponse;

@end

@interface PublicPackRequest : NSObject {
    
    id <PublicPackRequestDelegate> _delegate;
}

@property (assign, nonatomic) id <PublicPackRequestDelegate> delegate;

- (void) requestPublicPack;

@end
