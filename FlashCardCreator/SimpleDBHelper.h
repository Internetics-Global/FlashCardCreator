//
//  SimpleDBHelper.h
//  FFC
//
//  Created by Bourne Wang on 13-7-18.
//  Copyright (c) 2013年 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSSimpleDB/AWSSimpleDB.h>


@interface SimpleDBHelper : NSObject

+ (NSString *) defaultDomain;

+ (BOOL) insertOrUpdateItem: (NSDictionary *) dict withItemName: (NSString *) itemName withDomainName: (NSString *) domainName;
+ (NSMutableDictionary *) fetchAttributeValuesAtItem: (NSString *) itemName withDomainName: (NSString *) domainName;
+ (NSMutableArray *) fetchItemsWithDomain:(NSString *) domainName;;

@end
