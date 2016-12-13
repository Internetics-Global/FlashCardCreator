//
//  GoogleDriveRestClient.h
//  FlashCardCreator
//
//  Created by internetics on 12/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GoogleDriveSession;
@class GoogleDriveMetadata;

@protocol GoogleDriveRestClientDelegate <NSObject>

@optional


- (void)restClient:(GoogleDriveSession*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
          metadata:(GoogleDriveMetadata*)metadata;

- (void)restClient:(GoogleDriveSession*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath;
- (void)restClient:(GoogleDriveSession*)client uploadFileFailedWithError:(NSError*)error;

- (void)restClient:(GoogleDriveSession*)restClient loadedSharableLink:(NSString*)link
           forFile:(NSString*)path;
- (void)restClient:(GoogleDriveSession*)restClient loadSharableLinkFailedWithError:(NSError*)error;

@end

@interface GoogleDriveRestClient : NSObject {
    GoogleDriveSession* _session;
}

@property (nonatomic, assign) id<GoogleDriveRestClientDelegate> delegate;

- (id)initWithSession:(GoogleDriveSession*)session;


- (void)cancelAllRequests;

- (void)uploadFile:(NSString*)filename toPath:(NSString*)path fromPath:(NSString *)sourcePath;


/**
 
 we try to keep the same API structure with Dropbox, except fileID

 @param fileID : Different with Dropbox, fileID is the only identifier
 @param createShortUrl : Not use
 */
- (void)loadSharableLinkForFile:(NSString *)fileID withPath:(NSString *) path shortUrl:(BOOL)createShortUrl;

@end
