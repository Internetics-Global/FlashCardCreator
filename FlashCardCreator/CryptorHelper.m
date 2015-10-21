//
//  CryptorHelper.m
//  FFC
//
//  Created by Bourne Wang on 4/06/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import "CryptorHelper.h"
#import <RNEncryptor.h>
#import <RNDecryptor.h>

#define K_Password  @"@$4245dfsfer42r4243sfds"

@implementation CryptorHelper


+ (BOOL) encryptFileWithSameOutput:(NSString *) filePath {

    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *error;
    NSData *cryptedData = [RNEncryptor encryptData:data
                                        withSettings:kRNCryptorAES256Settings
                                            password:K_Password
                                               error:&error];
    if (error) {
        NSLog(@"[Error] %@ (%@)", error, filePath);
        return false;
    }

    error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:filePath
                                                    error:&error])
    {
        NSLog(@"[Error] %@ (%@)", error, filePath);
        return false;
    }
    
    BOOL success = [cryptedData writeToFile:filePath atomically:YES];
    if (success == false) {
        return false;
    }
    
    return true;
}


+ (BOOL) decryptFileWithSameOutput:(NSString *) filePath{
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *error;
    NSData *cryptedData = [RNDecryptor decryptData:data
                                        withSettings:kRNCryptorAES256Settings
                                            password:K_Password
                                               error:&error];
    if (error) {
        NSLog(@"[Error] %@ (%@)", error, filePath);
        return false;
    }
    
    error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:filePath
                                                    error:&error])
    {
        NSLog(@"[Error] %@ (%@)", error, filePath);
        return false;
    }
    
    BOOL success = [cryptedData writeToFile:filePath atomically:YES];
    if (success == false) {
        return false;
    }
    
    return true;
    
}



@end
