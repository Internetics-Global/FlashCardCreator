//
//  GoogleDriveRestClient.m
//  FlashCardCreator
//
//  Created by internetics on 12/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "GoogleDriveRestClient.h"
#import "GoogleDriveSession.h"

#import "GTLRDrive.h"
#import "GTMSessionFetcher.h"
#import "GTMSessionFetcherService.h"
#import "GoogleDriveMetadata.h"

#import "iConsole.h"

@interface GoogleDriveRestClient () {
    NSString *_downloadableLinkage;
    
    GTLRServiceTicket *_uploadTicket;
}

@end

@implementation GoogleDriveRestClient

- (id)initWithSession:(GoogleDriveSession*)session {
    
    self = [super init];
    if (self) {
        _session = session;
        
        
    }
    
    return self;
    
}



- (void)createFolderOfFlipFlashCardsPacks:(void (^)(NSError *error, NSString *folderID))handler {
    GTLRDriveService *service = _session.driveService;
    
    GTLRDrive_File *folder = [GTLRDrive_File object];
    folder.name = @"FlipFlashCardsPacks";
    folder.mimeType = @"application/vnd.google-apps.folder";
    
    GTLRDriveQuery_FilesCreate *query =
    [GTLRDriveQuery_FilesCreate queryWithObject:folder
                               uploadParameters:nil];
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRDrive_File *folderItem,
                            NSError *callbackError) {
            // Callback
            if (callbackError == nil) {
                if (handler) {
                    handler(nil,[folderItem.JSON objectForKey:@"id"]);
                    return;
                }
            } else {
                if (handler) {
                    handler(callbackError,nil);
                    return;
                }
            }
        }];
}


- (void)checkFolderOfFlipFlashCardsPacksExist:(void (^)(BOOL isExist,NSError *error, NSString *folderID))handler{
    
    __weak __typeof(&*self)weakSelf = self;
    
    GTLRDrive_FileList *_fileList;
    NSError *_fileListFetchError;
    
    _fileList = nil;
    _fileListFetchError = nil;
    
    GTLRDriveService *service = _session.driveService;
    
    GTLRDriveQuery_FilesList *query = [GTLRDriveQuery_FilesList query];
    query.q = @"mimeType = 'application/vnd.google-apps.folder' and name = 'FlipFlashCardsPacks' and trashed = false";
    
    // Because GTLRDrive_FileList is derived from GTLCollectionObject and the service
    // property shouldFetchNextPages is enabled, this may do multiple fetches to
    // retrieve all items in the file list.
    
    // Google APIs typically allow the fields returned to be limited by the "fields" property.
    // The Drive API uses the "fields" property differently by not sending most of the requested
    // resource's fields unless they are explicitly specified.
    query.fields = @"kind,files(mimeType,id,name)";
    
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRDrive_FileList *fileList,
                            NSError *callbackError) {
            
            if (callbackError == nil) {
                
                BOOL isExist = false;
                GTLRDrive_File *firstFile = [fileList.files firstObject];
                if (firstFile) {
                    NSString *fileID = [firstFile.JSON objectForKey:@"id"];
                    isExist = true;
                    NSLog(@"Founded, the fileID is %@", fileID);
                    if (handler) {
                        handler(true,nil,fileID);
                        return;
                    }
                }
                
                if (isExist == false) {
                    if (handler) {
                        handler(false,nil,nil);
                    }
                }
                
            } else {
                handler(false,callbackError,nil);
            }
            
            
            
        }];
    
}



- (void)uploadFile:(NSString*)filename toPath:(NSString*)destPath fromPath:(NSString *)sourcePath {
    
    [self checkFolderOfFlipFlashCardsPacksExist:^(BOOL isExist, NSError *error,NSString *folderID) {
        if (error == nil) {
            if (isExist) {
                [self uploadFile:filename toPath:destPath fromPath:sourcePath parentFolderID:folderID];
            } else {
                [self createFolderOfFlipFlashCardsPacks:^(NSError *error, NSString *folderID) {
                    if (error == nil) {
                        [self uploadFile:filename toPath:destPath fromPath:sourcePath parentFolderID:folderID];
                    } else {
                        if (self.delegate) {
                            [self.delegate restClient:_session uploadFileFailedWithError:error];
                        }
                    }
                }];
            }
        } else {
            if (self.delegate) {
                [self.delegate restClient:_session uploadFileFailedWithError:error];
            }
        }
    }];
    
}


/**
  private method
 */
- (void)uploadFile:(NSString*)filename toPath:(NSString*)destPath fromPath:(NSString *)sourcePath parentFolderID:(NSString *)parentFolderID {
    
    __weak __typeof(&*self)weakSelf = self;
    
    NSURL *fileToUploadURL = [NSURL fileURLWithPath:sourcePath];
    
    GTLRDriveService *service = _session.driveService;
    
    GTLRUploadParameters *uploadParameters =
    [GTLRUploadParameters uploadParametersWithFileURL:fileToUploadURL
                                             MIMEType:@"application/zip"];
    
    GTLRDrive_File *newFile = [GTLRDrive_File object];
    newFile.name = fileToUploadURL.lastPathComponent;
    newFile.parents = [NSArray arrayWithObject:parentFolderID];
    
    GTLRDriveQuery_FilesCreate *query =
    [GTLRDriveQuery_FilesCreate queryWithObject:newFile
                               uploadParameters:uploadParameters];
    
    
    query.executionParameters.uploadProgressBlock =
    ^(GTLRServiceTicket *ticket,
      unsigned long long numberOfBytesRead,
      unsigned long long dataLength) {
        
        if (weakSelf.delegate && dataLength > 0) {
            [weakSelf.delegate restClient:_session uploadProgress:numberOfBytesRead/dataLength forFile:destPath from:sourcePath];
        }
        
    };
    
    _uploadTicket =
    [service executeQuery:query
        completionHandler:^(GTLRServiceTicket *callbackTicket,
                            GTLRDrive_File *uploadedFile,
                            NSError *callbackError) {
            if (callbackError == nil) {
                
                NSLog(@"uploaded file id = %@",uploadedFile.identifier);
                
                if (weakSelf.delegate) {
                    GoogleDriveMetadata *metaData = [[GoogleDriveMetadata alloc] init];
                    metaData.uploadedFileID = uploadedFile.identifier;
                    
                    metaData.uploadedFileFullPath = [destPath stringByAppendingPathComponent:filename];
                    [weakSelf.delegate restClient:_session uploadedFile:destPath from:sourcePath metadata:metaData];
                }
            } else {
                if (weakSelf.delegate) {
                    [weakSelf.delegate restClient:_session uploadFileFailedWithError:callbackError];
                }
            }
        }];
    
    
    
    
    
    
}

- (void)cancelAllRequests {
    
    if (_uploadTicket) {
        [_uploadTicket cancelTicket];
    }
    
}

/**
 create Google Drive share linkage
 */
- (void)loadSharableLinkForFile:(NSString *)fileID withPath:(NSString *) path shortUrl:(BOOL)createShortUrl {
    
    //first to set permision, so we can get shareable link
    [self makeItPublic:fileID withPath:path];
    
    
    
    
    
}

- (void)makeItPublic:(NSString *)fileID withPath:(NSString *) path {
    
    __weak __typeof(&*self)weakSelf = self;
    
    NSString *urlStr = [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@/permissions",fileID];
    
    // 1
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setHTTPAdditionalHeaders:@{@"Authorization":[NSString stringWithFormat:@"Bearer %@",_session.accessToken],
                                       @"Content-Type": @"application/json"}];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    // 2
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    
    // 3.Create a JSON representation of the dictionary you will post to the web service.
    NSDictionary *dictionary = @{@"role": @"reader",@"type": @"anyone"};
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions error:&error];
    [request setHTTPBody:data];
    
    // 3
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            // convert the NSData response to a dictionary
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            
            if (error) {
                
                [weakSelf.delegate restClient:_session loadSharableLinkFailedWithError:error];
                
            } else {
                
                [weakSelf getShareLink:fileID withPath:(NSString *) path];
            }
            
        } else {
            
            [weakSelf.delegate restClient:_session loadSharableLinkFailedWithError:error];
            
        }
        
        
    }];
    
    [postDataTask resume];
    
    
}


- (void)getShareLink:(NSString *)fileID withPath:(NSString *) path {
    
    __weak __typeof(&*self)weakSelf = self;
    
    NSString *urlStr = [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@?fields=webContentLink",fileID];
    
    // 1
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setHTTPAdditionalHeaders:@{@"Authorization":[NSString stringWithFormat:@"Bearer %@",_session.accessToken],
                                       @"Content-Type": @"application/json"}];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    
    
    // 2
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    
    // 3
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            // convert the NSData response to a dictionary
            
            NSError *serializationError = nil;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (serializationError) {
                    
                    if (weakSelf.delegate) {
                        [weakSelf.delegate restClient:_session loadSharableLinkFailedWithError:error];
                    }
                    
                } else {
                    
                    NSString *downloadableLinkage = [dictionary objectForKey:@"webContentLink"];
                    
                    if (downloadableLinkage) {
                        if (weakSelf.delegate) {
                            [weakSelf.delegate restClient:_session loadedSharableLink:downloadableLinkage forFile:path];
                        }
                    } else {
                        
                        if (weakSelf.delegate) {
                            NSMutableDictionary* details = [NSMutableDictionary dictionary];
                            [details setValue:@"downloadableLinkage is nil, check log" forKey:NSLocalizedDescriptionKey];
                            NSError *myError = [NSError errorWithDomain:@"com.ccaa" code:200 userInfo:details];
                            [weakSelf.delegate restClient:_session loadSharableLinkFailedWithError:myError];
                        }
                        
                        [iConsole info:@"%s:%@",__FUNCTION__,dictionary];
                    }
                    
                    
                }
            });
            
        } else {
            
            if (weakSelf.delegate) {
                [weakSelf.delegate restClient:_session loadSharableLinkFailedWithError:error];
            }
            
        }
        
        
    }];
    
    [postDataTask resume];
    
    
}


- (void)dealloc {
    
    _uploadTicket = nil;
}

@end
