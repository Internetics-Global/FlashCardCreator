//
//  ZipFileDownloadHelper.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 20/12/12.
//
//

#import "ZipFileDownloadHelper.h"
#import "AFDownloadRequestOperation.h"
#import "ZipArchive.h"
#import "Pack.h"
#import "Card.h"
#import "FileOperationHelper.h"

@implementation ZipFileDownloadHelper

@synthesize delegate = _delegate;
@synthesize savedPath = _savedPath;

-(id)init{
	self = [super init];
	return self;
}

- (NSString *) downloadZipFile:(NSString *)URLStr {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLStr]];
    NSString *path = [self.class downloadedZipFilePath];
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:YES];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%s\nSuccessfully downloaded file to %@",__FUNCTION__,path);
        [_delegate downloadSuccess:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error download: %@", error);
        [Common alertViewCommon:[error description]];
    }];
    [operation setProgressiveDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        NSLog(@"%s\nDownload percent is: %f, total byte is: %lld",__FUNCTION__, (float) totalBytesReadForFile/totalBytesExpectedToReadForFile,totalBytesExpectedToReadForFile);
        if (_delegate != nil) {
            [_delegate downloadProgressivePercent:totalBytesReadForFile totalLength:totalBytesExpectedToReadForFile];
        }
        
    }];
    
    if (_queue == nil) {
        _queue =[[NSOperationQueue alloc] init];
    }
    [_queue addOperation:operation];
    
    return path;
    
    
}

//we put downloaded zip file under Document/Images 
+ (NSString *)downloadedZipFilePath {
    NSString *completeDir = [[FileOperationHelper documentsDirectory] stringByAppendingPathComponent:@"Images"];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] fileExistsAtPath:completeDir]) {
            if(![[NSFileManager defaultManager] createDirectoryAtPath:completeDir withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create directory at %@", completeDir);
            }
        }

    NSString *path = [completeDir stringByAppendingPathComponent:@"downloadedZipFilePath"];
    
    return path;
}


@end
