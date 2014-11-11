//
//  AmazonClientManager.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 13-7-18.
//  Copyright (c) 2013年 Internetics. All rights reserved.
//

#import "AmazonClientManager.h"

#import <AWSSimpleDB/AWSSimpleDB.h>
#import <AWSRuntime/AWSRuntime.h>

static AmazonSimpleDBClient *sdb = nil;


@implementation AmazonClientManager

/**
 Build session
*/
+(AmazonSimpleDBClient *)sdb
{
    [iConsole info:@"%s",__FUNCTION__];
    [AmazonClientManager validateCredentials];
    return sdb;
}


+(void)validateCredentials
{
    [iConsole info:@"%s",__FUNCTION__];
    if (sdb == nil) {
        [AmazonClientManager clearCredentials];
        
        sdb = [[AmazonSimpleDBClient alloc] initWithAccessKey:SimpleDB_ACCESS_KEY_ID withSecretKey:SimpleDB_SECRET_KEY];
        sdb.endpoint = [AmazonEndpoints sdbEndpoint:US_EAST_1];
    }
}

+(void)clearCredentials
{
    [iConsole info:@"%s",__FUNCTION__];
    sdb = nil;
}

/**
 Default Database table(or domain) name special for this app: SimpleDB_DOMAIN_NAME_FOR_THIS_APP
 if no exist, will create one named SimpleDB_DOMAIN_NAME_FOR_THIS_APP
 */
+ (NSString *) defaultDomain{
    [iConsole info:@"%s",__FUNCTION__];
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
            SimpleDBCreateDomainRequest  *createDomainsRequest  = [[SimpleDBCreateDomainRequest alloc] initWithDomainName:SimpleDB_DOMAIN_NAME_FOR_THIS_APP];
            SimpleDBCreateDomainResponse *createDomainsResponse = [[AmazonClientManager sdb] createDomain:createDomainsRequest];
            if(createDomainsResponse.error != nil)
            {
                [iConsole error:@"SimpleDBCreateDomainRequest repsonse error: %@", createDomainsResponse.error];
            } else {
                defaultDomain = SimpleDB_DOMAIN_NAME_FOR_THIS_APP;
            }
		}
	}
	return defaultDomain;
}


/**
 Meaning of domain in Amazon SimpleDB is simliar with table in SQL
 */
+ (NSMutableArray *) fetchDomains {
    [iConsole info:@"%s",__FUNCTION__];
    NSMutableArray  *domains;
    
    SimpleDBListDomainsRequest  *listDomainsRequest  = [[SimpleDBListDomainsRequest alloc] init];
    SimpleDBListDomainsResponse *listDomainsResponse = [[AmazonClientManager sdb] listDomains:listDomainsRequest];
    if(listDomainsResponse.error != nil)
    {
        [iConsole error:@"SimpleDBListDomainsRequest repsonse error: %@", listDomainsResponse.error];
        return domains;
    }
    
    
    domains = [[NSMutableArray alloc] initWithCapacity:[listDomainsResponse.domainNames count]];
    
    for (NSString *name in listDomainsResponse.domainNames) {
        [domains addObject:name];
    }
    
    return domains;
}

/**
 Meaning of item in Amazon SimpleDB is simliar with row/record in SQL
 */
+  (NSMutableArray *) fetchItemsWithDomain:(NSString *) domainName {
    [iConsole info:@"%s",__FUNCTION__];
    NSMutableArray       *items;
    
    NSString *selectExpression = [NSString stringWithFormat:@"select itemName() from `%@`", domainName];
    
    SimpleDBSelectRequest  *selectRequest  = [[SimpleDBSelectRequest alloc] initWithSelectExpression:selectExpression];
    SimpleDBSelectResponse *selectResponse = [[AmazonClientManager sdb] select:selectRequest];
    if(selectResponse.error != nil)
    {
        [iConsole error:@"SimpleDBSelectRequest response error: %@", selectResponse.error];
    }
    
    items = [[NSMutableArray alloc] initWithCapacity:[selectResponse.items count]];
    
    for (SimpleDBItem *item in selectResponse.items) {
        [items addObject:item.name];
    }
    
    [items sortUsingSelector:@selector(compare:)];
    
    return items;
}

/**
 Attribute and value pairs
 */
+ (NSMutableDictionary *) fetchAttributeValuesAtItem: (NSString *) itemName withDomainName: (NSString *) domainName{
    [iConsole info:@"%s",__FUNCTION__];
    NSMutableDictionary       *data;
    
    SimpleDBGetAttributesRequest *gar = [[SimpleDBGetAttributesRequest alloc] initWithDomainName:domainName andItemName:itemName];
    SimpleDBGetAttributesResponse *response = [[AmazonClientManager sdb] getAttributes:gar];
    if(response.error != nil)
    {
        [iConsole error:@"SimpleDBGetAttributesRequest response error: %@", response.error];
    }
    
    data = [[NSMutableDictionary alloc] initWithCapacity:[response.attributes count]];
    
    for (SimpleDBAttribute *attr in response.attributes) {
        [data setObject:attr.value forKey:attr.name];
    }
    
    return data;
}


/**
  Update or add
 */
+ (BOOL) insertOrUpdateItem: (NSDictionary *) dict withItemName: (NSString *) itemName withDomainName: (NSString *) domainName {
    [iConsole info:@"%s",__FUNCTION__];
    BOOL result = TRUE;
    
    SimpleDBReplaceableAttribute *attribute;
    NSMutableArray *attributes = [[NSMutableArray alloc] initWithCapacity:dict.allKeys.count];
    
    int i = 0;
    for (NSString *key in [dict allKeys]) {
        attribute = [[SimpleDBReplaceableAttribute alloc] initWithName:[dict allKeys][i] andValue:[dict allValues][i] andReplace:YES];
        [attributes addObject:attribute];
        
        i++;
    }
    
    SimpleDBPutAttributesRequest *putAttributesRequest = [[SimpleDBPutAttributesRequest alloc] initWithDomainName:domainName andItemName:itemName andAttributes:attributes];
    
    SimpleDBPutAttributesResponse *putAttributesResponse = [[AmazonClientManager sdb] putAttributes:putAttributesRequest];
    
    if(putAttributesResponse.error != nil)
    {
        result  = false;
        [iConsole error:@"SimpleDBPutAttributesRequest repsonse error: %@", putAttributesResponse.error];
    }
    
    return result;
}


@end
