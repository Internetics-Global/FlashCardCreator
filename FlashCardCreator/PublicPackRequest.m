//
//  PublicPackRequest.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 18/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "PublicPackRequest.h"
#import "AFJSONRequestOperation.h"
#import "Pack.h"

@implementation PublicPackRequest

@synthesize delegate = _delegate;

- (void) requestPublicPack {
    __block NSArray *jsonDict;
    NSURL *url = [NSURL URLWithString:PUBLIC_PACK_JSON_FILE];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:
                                         ^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
                                             jsonDict = (NSArray *) JSON[@"public_packs"];
                                             [_delegate performSelector:@selector(didReceiveJSONResponse:) withObject:jsonDict];
                                         }
                                                                                        failure:
                                         ^(NSURLRequest *req , NSURLResponse *response , NSError *error , id JSON) {
                                             [iConsole error:@"Failed: %@",[error localizedDescription]];
                                             [_delegate performSelector:@selector(didNotReceiveJSONResponse)];
                                         }
                                         ];
    [operation start];

    
}

@end
