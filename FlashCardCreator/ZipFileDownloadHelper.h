//
//  ZipFileDownloadHelper.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 20/12/12.
//
//

#import <Foundation/Foundation.h>

@protocol ZipFileDownloadHelperDelegate

- (void) downloadProgressivePercent :(long long) current totalLength: (long long) total;
- (void) downloadSuccess :(BOOL) isSucess;
- (void) downloadFail;

@end

@interface ZipFileDownloadHelper : NSObject {
    NSOperationQueue *_queue;
    id <ZipFileDownloadHelperDelegate> __weak _delegate;
    NSString *_savedPath;
}

@property (nonatomic,weak) id <ZipFileDownloadHelperDelegate> delegate;
@property (copy, nonatomic) NSString *savedPath;
@property (copy, nonatomic) NSString *downloadedURL;

+(instancetype)sharedInstance;
- (NSString *) downloadZipFile:(NSString *)URLStr;
+ (NSString *) convertToDropboxDownloadURL:(NSString *) urlStr;

@end
