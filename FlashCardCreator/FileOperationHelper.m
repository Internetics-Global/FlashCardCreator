//
//  FileOperationHelper.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "FileOperationHelper.h"

@implementation FileOperationHelper

+ (NSString *)documentsDirectory{
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentFolderPath = searchPaths[0];
	return documentFolderPath;
}

+ (NSString *)documentsPathForFileNamed:(NSString *)fileName{
	return [[FileOperationHelper documentsDirectory] stringByAppendingPathComponent:fileName];
}

+ (BOOL)fileExistsAtDocumentsPathWithName:(NSString *)fileName{
	return [[NSFileManager defaultManager] fileExistsAtPath:[FileOperationHelper documentsPathForFileNamed:fileName]];
}

+ (NSString *)temporaryDirectory{
	NSString *temporaryDirectory = NSTemporaryDirectory();
	return temporaryDirectory;
}

+ (NSString *)temporaryPathForFileNamed:(NSString *)fileName{
	return [[self temporaryDirectory] stringByAppendingPathComponent:fileName];
}

+ (NSString *) generateUniquePNGImageFilePath {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,    NSUserDomainMask ,YES );
    NSString *cardListDir = [paths[0] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:cardListDir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:cardListDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", cardListDir);
        }
    }
    
    
    NSString *uid = [NSString stringWithFormat:@"%f%d.png", [[NSDate date] timeIntervalSince1970], arc4random()];
    return ([cardListDir stringByAppendingPathComponent:uid]);
}


@end
