//
//  GoogleDriveMetadata.h
//  FlashCardCreator
//
//  Created by internetics on 12/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GoogleDriveMetadata : NSObject

@property (copy, nonatomic) NSString* uploadedFileID;


/**
 This is the whole path including file name and file path
 */
@property (copy, nonatomic) NSString* uploadedFileFullPath;

@end
