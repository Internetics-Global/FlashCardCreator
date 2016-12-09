//
//  GoogleDriveHelper.m
//  FlashCardCreator
//
//  Created by internetics on 9/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "GoogleDriveHelper.h"

#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import "GTLRDrive.h"
#import "GTMSessionFetcher.h"
#import "GTMSessionFetcherService.h"
#import "AppDelegate.h"


/*! @brief The OIDC issuer from which the configuration will be discovered.
 */
static NSString *const kIssuer = @"https://accounts.google.com";

/*! @brief The OAuth client ID.
 @discussion For Google, register your client at
 https://console.developers.google.com/apis/credentials?project=_
 The client should be registered with the "iOS" type.
 */
static NSString *const kClientID = @"1088270400357-c34d0lm948p1d9vkm5e89g8noum25n70.apps.googleusercontent.com";

/*! @brief The OAuth redirect URI for the client @c kClientID.
 @discussion With Google, the scheme of the redirect URI is the reverse DNS notation of the
 client ID. This scheme must be registered as a scheme in the project's Info
 property list ("CFBundleURLTypes" plist key). Any path component will work, we use
 'oauthredirect' here to help disambiguate from any other use of this scheme.
 */
static NSString *const kRedirectURI =
@"com.googleusercontent.apps.1088270400357-c34d0lm948p1d9vkm5e89g8noum25n70:/oauthredirect";

/*! @brief @c NSCoding key for the authState property.
 */
static NSString *const kExampleAuthorizerKey = @"authorization";


@interface GoogleDriveHelper () {
    NSString *_uploadedFileID;
    NSString *_accessToken;
    NSString *_downloadableLinkage;
}

/*! @brief The authorization state.
 */
@property(nonatomic, nullable) GTMAppAuthFetcherAuthorization *authorization;

@end



@implementation GoogleDriveHelper

+ (id)sharedHelper {
    static GoogleDriveHelper *sharedHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [[self alloc] init];
        [sharedHelper setup];
    });
    return sharedHelper;
}


- (void) setup {
    
    [self loadState];
}



- (BOOL)isLinked {
    
    if (_authorization) {
        return _authorization.canAuthorize;
    } else {
        return false;
    }
    
}
- (void)unlinkAll {
    
    [self setGtmAuthorization:nil];
}



/*
 * Auth process
 */
- (void)authWithSuccessCompletion:(nonnull AuthSuccessCompletion) authSuccessCompletion{
    NSURL *issuer = [NSURL URLWithString:kIssuer];
    NSURL *redirectURI = [NSURL URLWithString:kRedirectURI];
    
    // discovers endpoints
    [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuer
    completion:^(OIDServiceConfiguration *_Nullable configuration, NSError *_Nullable error) {
        
        if (!configuration) {
            
            [iConsole info:@"%s: Error retrieving discovery document: %@",__FUNCTION__,[error localizedDescription]];
            
            [self setGtmAuthorization:nil];
            return;
        }
        
        [iConsole info:@"%s: Got configuration: %@",__FUNCTION__,configuration];
        
        // builds authentication request
        NSArray<NSString *> *scopes = @[ kGTLRAuthScopeDrive, OIDScopeOpenID, OIDScopeEmail ];
        OIDAuthorizationRequest *request =
        [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:kClientID
                                                        scopes:scopes
                                                   redirectURL:redirectURI
                                                  responseType:OIDResponseTypeCode
                                          additionalParameters:nil];
        // performs authentication request
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [iConsole info:@"%s: Initiating authorization request with scope: %@",__FUNCTION__,request.scope];
        
        appDelegate.currentGoogleDriveAuthorizationFlow =
        [OIDAuthState authStateByPresentingAuthorizationRequest:request
                                       presentingViewController:[UIApplication sharedApplication].keyWindow.rootViewController
                                                       callback:^(OIDAuthState *_Nullable authState,NSError *_Nullable error) {
                                                           if (authState) {
                                                               GTMAppAuthFetcherAuthorization *authorization =
                                                               [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
                                                               
                                                               [self setGtmAuthorization:authorization];
                                                               
                                                               [iConsole info:@"%s: Got authorization tokens. Access token: %@",__FUNCTION__,authState.lastTokenResponse.accessToken];
                                                               
                                                               if (authSuccessCompletion != nil) {
                                                                   authSuccessCompletion();
                                                               }
                                                               
                                                           } else {
                                                               [self setGtmAuthorization:nil];
                                                               [iConsole info:@"%s: Authorization error: %@",__FUNCTION__,[error localizedDescription]];
                                                               
                                                               dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                                   
                                                                   UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_GOOGLE_DRIVE_AUTHE_FAILED",@"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                                                                   [alertView show];
                                                               });
                                                               
                                                           }
                                                       }];
    }];
}


- (void)setGtmAuthorization:(GTMAppAuthFetcherAuthorization*)authorization {
    if ([_authorization isEqual:authorization]) {
        return;
    }
    _authorization = authorization;
    self.driveService.authorizer = self.authorization;
    
    if (authorization != nil) {
        _accessToken = _authorization.authState.lastTokenResponse.accessToken;
    } else {
        _accessToken = @"";
        _downloadableLinkage = @"";
        _uploadedFileID = @"";
    }
    
    [self stateChanged];
}

- (void)stateChanged {
    [self saveState];
    [self updateUI];
}




- (void)updateUI {
}

/*! @brief Loads the @c GTMAppAuthFetcherAuthorization from @c NSUSerDefaults.
 */
- (void)loadState {
    GTMAppAuthFetcherAuthorization* authorization =
    [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kExampleAuthorizerKey];
    [self setGtmAuthorization:authorization];
}


/*! @brief Saves the @c GTMAppAuthFetcherAuthorization to @c NSUSerDefaults.
 */
- (void)saveState {
    if (_authorization.canAuthorize) {
        [GTMAppAuthFetcherAuthorization saveAuthorization:_authorization
                                        toKeychainForName:kExampleAuthorizerKey];
    } else {
        [GTMAppAuthFetcherAuthorization removeAuthorizationFromKeychainForName:kExampleAuthorizerKey];
    }
}

- (void)clearAuthState{
    [self setGtmAuthorization:nil];
}


- (GTLRDriveService *)driveService {
    static GTLRDriveService *service;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[GTLRDriveService alloc] init];
        
        // Turn on the library's shouldFetchNextPages feature to ensure that all items
        // are fetched.  This applies to queries which return an object derived from
        // GTLRCollectionObject.
        service.shouldFetchNextPages = YES;
        
        // Have the service object set tickets to retry temporary error conditions
        // automatically
        service.retryEnabled = YES;
    });
    return service;
}


@end
