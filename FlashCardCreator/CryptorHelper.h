//
//  CryptorHelper.h
//  FFC
//
//  Created by Bourne Wang on 4/06/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CryptorHelper : NSObject

+ (BOOL) decryptFileWithSameOutput:(NSString *) filePath;
+ (BOOL) encryptFileWithSameOutput:(NSString *) filePath;

@end
