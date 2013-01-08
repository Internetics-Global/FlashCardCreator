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

@implementation ZipFileDownloadHelper

@synthesize delegate = _delegate;
@synthesize savedPath = _savedPath;

-(id)init{
	self = [super init];
	return self;
}

- (NSString *) downloadZipFile:(NSString *)URLStr {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLStr]];
    NSString *path = [self downloadedZipFilePath];
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:YES];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%s\nSuccessfully downloaded file to %@",__FUNCTION__,path);
        [_delegate downloadSuccess:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error download: %@", error);
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
    [operation release];
    
    return path;
}

- (NSString *)downloadedZipFilePath {
    static NSString *completeDir;
        NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,    NSUserDomainMask ,YES );
        completeDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Complete"];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] fileExistsAtPath:completeDir]) {
            if(![[NSFileManager defaultManager] createDirectoryAtPath:completeDir withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create directory at %@", completeDir);
            }
        }
    
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    self.savedPath = [completeDir stringByAppendingPathComponent:[NSString stringWithFormat:@"temp%llu.zip",
                                                               [[NSNumber numberWithDouble:time] longLongValue]]];
    
    return _savedPath;
}


#pragma mark -
#pragma mark Memory Management

- (void)dealloc{
    FCC_RELEASE_SAFELY(_queue);
    FCC_RELEASE_SAFELY(_savedPath);
	[super dealloc];
}

@end
