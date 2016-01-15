//
//  ZipFileDownloadHelper.m
//  FFC
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

@implementation ZipFileDownloadHelper  {
    AFDownloadRequestOperation *_downloadOperation;
}

@synthesize delegate = _delegate;
@synthesize savedPath = _savedPath;

-(id)init{
	self = [super init];
	return self;
}

+(instancetype)sharedInstance{
    __weak __typeof(&*self)weakSelf = self;
    static id sharedInstance=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        sharedInstance=[[weakSelf alloc]init];
    });
    return sharedInstance;
}

/**
 *  历史原因，我们不得不用这种方法，在最新的SDK中，dropbox提供了更友好的方法： https://www.dropbox.com/developers-v1/core/start/ios#downloading
 */
- (NSString *) downloadZipFile:(NSString *)URLStr {
    
    URLStr = [URLStr stringByReplacingOccurrencesOfString:@"//www." withString:@"//dl."];
    
    [iConsole info:@"%s, download url = %@",__FUNCTION__,URLStr];
    self.downloadedURL = URLStr;
    __weak __typeof(&*self)weakSelf = self;
    
    //Every time before download, we need to clear it.
    [[NSFileManager defaultManager] removeItemAtPath:[FileOperationHelper downloadedPackFileDirectory] error:nil];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLStr]];
    NSString *path = [FileOperationHelper downloadedZipPackFileFixedPath];
    _downloadOperation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:YES];
    _downloadOperation.deleteTempFileOnCancel = YES;
    [_downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [iConsole info:@"%s\nSuccessfully downloaded file to %@",__FUNCTION__,path];
        [weakSelf.delegate downloadSuccess:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [iConsole error:@"Error download: %@", error];
        [weakSelf.delegate downloadFail];
        //[Common alertViewCommon:[error description]];
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_DOWNLOAD_LINK_ERROR",@"")];
    }];
    [_downloadOperation setProgressiveDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        [iConsole info:@"%s\nDownload percent is: %f, total byte is: %lld",__FUNCTION__, (float) totalBytesReadForFile/totalBytesExpectedToReadForFile,totalBytesExpectedToReadForFile];
        if (weakSelf.delegate != nil) {
            [weakSelf.delegate downloadProgressivePercent:totalBytesReadForFile totalLength:totalBytesExpectedToReadForFile];
        }
        
    }];
    
    
    if (_queue == nil) {
        _queue =[[NSOperationQueue alloc] init];
    }
    [_queue addOperation:_downloadOperation];
    
    return path;
}

- (void) cancelDownload {
    [_downloadOperation cancel];
    _downloadOperation = nil;
    if ([_queue isSuspended] == false) {
        [_queue setSuspended:YES];
    }
    _queue = nil;
    
    [self.delegate downloadFail];
    //[Common alertViewCommon:[error description]];
    [Common alertViewCommon:NSLocalizedString(@"DIALOG_DOWNLOAD_CANCELLED",@"")];
}


+ (NSString *) convertToDownloadableURL:(NSString *) urlStr{
    [iConsole info:@"%s",__FUNCTION__];
    NSString *downloadableURL = [urlStr stringByReplacingOccurrencesOfString:@"fcc://" withString:@"https://"];
    return downloadableURL;
}


@end
