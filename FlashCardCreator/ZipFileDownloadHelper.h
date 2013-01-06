//
//  ZipFileDownloadHelper.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 20/12/12.
//
//

#import <Foundation/Foundation.h>

@protocol ZipFileDownloadHelperDelegate

- (void) progressivePercent :(long long) current totalLength: (long long) total;

@end

@interface ZipFileDownloadHelper : NSObject {
    NSOperationQueue *_queue;
    id <ZipFileDownloadHelperDelegate> _delegate;
}

@property (nonatomic,assign) id <ZipFileDownloadHelperDelegate> delegate;


- (NSString *) downloadZipFile:(NSString *)URLStr;

@end
