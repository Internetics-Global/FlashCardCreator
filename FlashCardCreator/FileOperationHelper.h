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
+ (NSString *) documentDirectory;
+ (NSString *) dataDocumentDirectory;
+ (NSString *) imagesDirectory;
+ (NSString *) temporaryImagesDirectory;
+ (NSString *) assembleFactoryDirectory;

+ (NSString *) documentsPathForFileNamed:(NSString *)fileName;

+ (NSString *) temporaryDirectory;
+ (NSString *) temporaryPathForFileNamed:(NSString *)fileName;

+ (NSString *)unzippedPackInfoJsonFilePath;

+ (NSString *) generateUniqueJPEGImageFilePathUnderImagesFolder;
+ (NSString *) generateUniqueMovFilePathUnderImagesFolder;
+ (NSString *) zipPackForUpload:(Pack *)pack withPassword: (NSString *) password;

+ (NSString *)downloadedPackFileDirectory;
+ (NSString *)downloadedZipPackFileFixedPath;

+ (NSString *)getTodayString;

+ (NSDate *)convertStringToNSDate:(NSString *) str;

+ (BOOL) isPackListOpenedBefore;

+ (BOOL)addSkipBackupAttributeToFileAtPath:(NSString *)aFilePath;

+ (NSArray *)listFilesAtPath:(NSString *)path;

+ (NSString *)cachesPathForFileNamed:(NSString *)fileName;

@end
