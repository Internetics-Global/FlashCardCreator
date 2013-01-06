//
//  SQLiteHelper.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SQLiteHelper : NSObject

+ (sqlite3 *)defaultDatabase;
+ (void) verifyDatabase;
+ (void) checkUserExist;

+ (sqlite3_stmt *)prepareStatementForQuery:(NSString *)query;
+ (BOOL) tableExists:(NSString *)tableName;

+ (NSInteger) numRecordsInTable:(NSString *)tableName;

+ (BOOL) booleanForInt:(NSInteger)integer;

+ (NSString *) getStringFromQuery:(sqlite3_stmt *)statement inColumn:(NSInteger)colNum;
+ (NSNumber *) getNumberFromQuery:(sqlite3_stmt *)statement inColumn:(NSInteger)colNum;

+ (BOOL)checkIntegerValueExists:(NSInteger)value forColumn:(NSString *)columnName inTable:(NSString *)table;
+ (BOOL)checkStringValueExists:(NSString *)value forColumn:(NSString *)columnName inTable:(NSString *)table;
+ (NSInteger) getMaxValueForColumn:(NSString *)columnName inTable:(NSString *)tableName;

@end
