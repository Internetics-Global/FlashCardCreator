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

@end

@interface ZipFileDownloadHelper : NSObject {
    NSOperationQueue *_queue;
    id <ZipFileDownloadHelperDelegate> _delegate;
    NSString *_savedPath;
}

@property (nonatomic,assign) id <ZipFileDownloadHelperDelegate> delegate;
@property (copy, nonatomic) NSString *savedPath;


- (NSString *) downloadZipFile:(NSString *)URLStr;

@end
