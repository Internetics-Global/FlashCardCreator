//
//  FileOperationHelper.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileOperationHelper : NSObject

+ (NSString *)documentsDirectory;
+ (NSString *) documentsPathForFileNamed:(NSString *)fileName;
+ (BOOL) fileExistsAtDocumentsPathWithName:(NSString *)fileName;
+ (NSString *) temporaryDirectory;
+ (NSString *) temporaryPathForFileNamed:(NSString *)fileName;

@end
