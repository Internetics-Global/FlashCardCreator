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
#warning simuated function, since requirement is not clear.
    __block NSArray *jsonDictionary;
    NSURL *url = [NSURL URLWithString:@"https://s3-ap-southeast-2.amazonaws.com/flashcardcreator/public_pack.json"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:
                                         ^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
                                             jsonDictionary = (NSArray *) [JSON objectForKey:@"public_packs"];
                                             [_delegate performSelector:@selector(didReceiveJSONResponse:) withObject:jsonDictionary];
                                         }
                                                                                        failure:
                                         ^(NSURLRequest *req , NSURLResponse *response , NSError *error , id JSON) {
                                             NSLog(@"Failed: %@",[error localizedDescription]);
                                             [_delegate performSelector:@selector(didNotReceiveJSONResponse)];
                                         }
                                         ];
    [operation start];

    
}

@end
