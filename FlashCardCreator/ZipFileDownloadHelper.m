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

@implementation ZipFileDownloadHelper

@synthesize delegate = _delegate;

-(id)init{
	self = [super init];
	return self;
}


- (NSString *) downloadZipFile:(NSString *)URLStr {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLStr]];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[self tempFileName]];
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:YES];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully downloaded file to %@", path);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error download: %@", error);
    }];
    [operation setProgressiveDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        NSLog(@"Operation%i: bytesRead: %d", 1, bytesRead);
        NSLog(@"Operation%i: totalBytesRead: %lld", 1, totalBytesRead);
        NSLog(@"Operation%i: totalBytesExpected: %lld", 1, totalBytesExpected);
        NSLog(@"Operation%i: totalBytesReadForFile: %lld", 1, totalBytesReadForFile);
        NSLog(@"Operation%i: totalBytesExpectedToReadForFile: %lld", 1, totalBytesExpectedToReadForFile);
        if (_delegate != nil) {
            [_delegate progressivePercent:totalBytesReadForFile totalLength:totalBytesExpectedToReadForFile];
        }
        
    }];
    
    if (_queue == nil) {
        _queue =[[NSOperationQueue alloc] init];
    }
    [_queue addOperation:operation];
    [operation release];
    
    return path;
}

- (NSString *) tempFileName {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSString *curTime = [NSString stringWithFormat:@"temp%llu.zip",
                         [[NSNumber numberWithDouble:time] longLongValue]];
    return curTime;
}


#pragma mark -
#pragma mark Memory Management

- (void)dealloc{
    FCC_RELEASE_SAFELY(_queue);
	[super dealloc];
}

@end
