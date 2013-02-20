//
//  FileOperationHelper.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Card;
@class Pack;

@interface FileOperationHelper : NSObject

+ (NSString *) cachesDirectory;
+ (NSString *) imagesDirectory;
+ (NSString *) assembleFactoryDirectory;

+ (NSString *) documentsPathForFileNamed:(NSString *)fileName;

+ (NSString *) temporaryDirectory;
+ (NSString *) temporaryPathForFileNamed:(NSString *)fileName;

+ (NSString *) generateUniquePNGImageFilePath;
+ (NSString *) zipPackForUpload:(Pack *) pack;

+ (NSString *)downloadedPackFileDirectory;
+ (NSString *)downloadedZipPackFileFixedPath;

@end
