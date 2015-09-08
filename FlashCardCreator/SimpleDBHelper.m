//
//  SimpleDBHelper.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 13-7-18.
//  Copyright (c) 2013年 Internetics. All rights reserved.
//

#import "SimpleDBHelper.h"
#import <AWSSimpleDB/AWSSimpleDB.h>
#import <Bolts/Bolts.h>


@implementation SimpleDBHelper


+ (NSString *) defaultDomain{
    [iConsole info:@"%s",__FUNCTION__];
    AWSSimpleDB *sdb = [AWSSimpleDB defaultSimpleDB];
    static NSString *defaultDomain;
    @synchronized(self){
        if (defaultDomain == nil) {
            NSMutableArray  *domains = [self fetchDomains];
            
            for (NSString *str in domains) {
                if ([str isEqualToString:SimpleDB_DOMAIN_NAME_FOR_THIS_APP]) {
                    defaultDomain = SimpleDB_DOMAIN_NAME_FOR_THIS_APP;
                    return defaultDomain;
                }
            }
            
            //if not exist, we will create one
            AWSSimpleDBCreateDomainRequest *createDomainRequest = [AWSSimpleDBCreateDomainRequest new];
            createDomainRequest.domainName = SimpleDB_DOMAIN_NAME_FOR_THIS_APP;
            [sdb createDomain:createDomainRequest];
            defaultDomain = SimpleDB_DOMAIN_NAME_FOR_THIS_APP;
        }
    }
    return defaultDomain;
}


/**
 Meaning of domain in Amazon SimpleDB is simliar with table in SQL
 */
+ (NSMutableArray *) fetchDomains {
    [iConsole info:@"%s",__FUNCTION__];
    AWSSimpleDB *sdb = [AWSSimpleDB defaultSimpleDB];
    
    AWSSimpleDBListDomainsRequest *listDomainsRequest = [AWSSimpleDBListDomainsRequest new];
    
    __block NSMutableArray  *domains;
    [[[sdb listDomains:listDomainsRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
             [iConsole info:@"%s:%@",__FUNCTION__,[task.error  description]];
        } else {
            if (task.result) {
                AWSSimpleDBListDomainsResult *listDomainsResult = task.result;
                domains = [[NSMutableArray alloc] initWithCapacity:[listDomainsResult.domainNames count]];
                
                for (NSString *name in listDomainsResult.domainNames) {
                    [domains addObject:name];
                }
                
            } else {
            }
        }
        
        return nil;
        
    }] waitUntilFinished];

    
    return domains;
}

/**
 Meaning of item in Amazon SimpleDB is simliar with row/record in SQL
 */
+  (NSMutableArray *) fetchItemsWithDomain:(NSString *) domainName {
    [iConsole info:@"%s",__FUNCTION__];
    AWSSimpleDB *sdb = [AWSSimpleDB defaultSimpleDB];
    
    NSString *selectExpression = [NSString stringWithFormat:@"select itemName() from `%@`", domainName];
    AWSSimpleDBSelectRequest *selectRequest = [AWSSimpleDBSelectRequest new];
    selectRequest.selectExpression = selectExpression;
    
    
    __block NSMutableArray       *items;
    [[[sdb select:selectRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            [iConsole info:@"%s:%@",__FUNCTION__,[task.error  description]];
            return nil;
        } else {
            if (task.result) {
                AWSSimpleDBSelectResult *selectResult = task.result;
                items = [[NSMutableArray alloc] initWithCapacity:[selectResult.items count]];
                
                for (AWSSimpleDBItem *item in selectResult.items) {
                    [items addObject:item.name];
                }
                [items sortUsingSelector:@selector(compare:)];
                
            } else {
            }
            
            
        }
        
        return nil;
        
        
    }] waitUntilFinished];
    
    return items;
}

/**
 Attribute and value pairs
 */
+ (NSMutableDictionary *) fetchAttributeValuesAtItem: (NSString *) itemName withDomainName: (NSString *) domainName{
    [iConsole info:@"%s",__FUNCTION__];
    AWSSimpleDB *sdb = [AWSSimpleDB defaultSimpleDB];
    
    AWSSimpleDBGetAttributesRequest *gar = [AWSSimpleDBGetAttributesRequest new];
    gar.domainName = domainName;
    gar.itemName = itemName;

    __block NSMutableDictionary       *dict;
    [[[sdb getAttributes:gar] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            [iConsole info:@"%s:%@",__FUNCTION__,[task.error  description]];
            return nil;
        } else {
            if (task.result) {
              AWSSimpleDBGetAttributesResult *selectResult = task.result;
              dict = [[NSMutableDictionary alloc] initWithCapacity:[selectResult.attributes count]];
              for (AWSSimpleDBAttribute *attr in selectResult.attributes) {
                [dict setObject:attr.value forKey:attr.name];
              }
                
                
            } else {
            }
        }
        
        return nil;
        
    }] waitUntilFinished ];
    
    return dict;
    
}


/**
  Update or add
 */
+ (BOOL) insertOrUpdateItem: (NSDictionary *) dict withItemName: (NSString *) itemName withDomainName: (NSString *) domainName {
    AWSSimpleDB *sdb = [AWSSimpleDB defaultSimpleDB];
    [iConsole info:@"%s",__FUNCTION__];
    
    AWSSimpleDBReplaceableAttribute *attribute;
    NSMutableArray *attributes = [[NSMutableArray alloc] initWithCapacity:dict.allKeys.count];
    
    for (int i= 0; i< [[dict allKeys] count]; i++) {
        attribute = [AWSSimpleDBReplaceableAttribute new];
        attribute.name = [dict allKeys][i];
        attribute.value = [dict allValues][i];
        attribute.replace = @YES;
        [attributes addObject:attribute];
    }
    
    AWSSimpleDBPutAttributesRequest *putAttributesRequest = [AWSSimpleDBPutAttributesRequest new];
    putAttributesRequest.domainName = domainName;
    putAttributesRequest.itemName = itemName;
    putAttributesRequest.attributes = attributes;
    
    __block BOOL result = true;
    [[[sdb putAttributes:putAttributesRequest]continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            [iConsole info:@"%s:%@",__FUNCTION__,[task.error  description]];
            result = false;
        } else {
        }
        
        return nil;
        
    }] waitUntilFinished];
    
    return result;
    
}


@end
