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

+(instancetype)sharedInstance{
    __weak __typeof(&*self)weakSelf = self;
    static id sharedInstance=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        sharedInstance=[[weakSelf alloc]init];
    });
    return sharedInstance;
}

- (NSString *) downloadZipFile:(NSString *)URLStr {
    [iConsole info:@"%s, download url = %@",__FUNCTION__,URLStr];
    self.downloadedURL = URLStr;
    __weak __typeof(&*self)weakSelf = self;
    
    //Every time before download, we need to clear it.
    [[NSFileManager defaultManager] removeItemAtPath:[FileOperationHelper downloadedPackFileDirectory] error:nil];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLStr]];
    NSString *path = [FileOperationHelper downloadedZipPackFileFixedPath];
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:YES];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [iConsole info:@"%s\nSuccessfully downloaded file to %@",__FUNCTION__,path];
        [weakSelf.delegate downloadSuccess:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [iConsole error:@"Error download: %@", error];
        [weakSelf.delegate downloadFail];
        //[Common alertViewCommon:[error description]];
        [Common alertViewCommon:@"Check your download linkage or Dropbox sever is temporarily unavailable"];
    }];
    [operation setProgressiveDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        [iConsole info:@"%s\nDownload percent is: %f, total byte is: %lld",__FUNCTION__, (float) totalBytesReadForFile/totalBytesExpectedToReadForFile,totalBytesExpectedToReadForFile];
        if (weakSelf.delegate != nil) {
            [weakSelf.delegate downloadProgressivePercent:totalBytesReadForFile totalLength:totalBytesExpectedToReadForFile];
        }
        
    }];
    
    if (_queue == nil) {
        _queue =[[NSOperationQueue alloc] init];
    }
    [_queue addOperation:operation];
    
    return path;
}

//The reson why to do it: https://www.dropbox.com/help/201/en
+ (NSString *) convertToDropboxDownloadURL:(NSString *) urlStr{
    [iConsole info:@"%s",__FUNCTION__];
    NSString *temp = [urlStr stringByReplacingOccurrencesOfString:@"fcc://dropbox.com" withString:@"fcc://www.dropbox.com"];
    NSString *downloadableURL = [temp stringByReplacingOccurrencesOfString:@"fcc://www" withString:@"https://dl"];
    downloadableURL = [downloadableURL stringByReplacingOccurrencesOfString:@"https://www" withString:@"https://dl"];
    downloadableURL = [downloadableURL stringByReplacingOccurrencesOfString:@"http://www" withString:@"https://dl"];
    return downloadableURL;
}

@end
