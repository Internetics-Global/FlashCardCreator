//
//  SQLiteHelper.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "SQLiteHelper.h"
#import "FileOperationHelper.h"

@implementation SQLiteHelper

+ (sqlite3 *) defaultDatabase{
	static sqlite3 *db;
	@synchronized(self){
		if (db == nil) {
			sqlite3_open([[FileOperationHelper documentsPathForFileNamed:@"FlashCardCreator-Local.db"] UTF8String], &db);
		}
	}
	return db;
}

+ (sqlite3_stmt *)prepareStatementForQuery:(NSString *)query{
	sqlite3_stmt *preparedStatement;
	const char *utfStatement = [query UTF8String];
	sqlite3_prepare_v2([SQLiteHelper defaultDatabase], utfStatement, -1, &preparedStatement, NULL);
	return preparedStatement;
}

+ (BOOL) tableExists:(NSString *)tableName{
	int dbrc;
	sqlite3_stmt *existing = [SQLiteHelper prepareStatementForQuery:[NSString stringWithFormat:@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name='%@';", tableName]];
	NSNumber *value = nil;
	while ((dbrc = sqlite3_step(existing)) == SQLITE_ROW) {
		value = [[NSNumber alloc] initWithInt:sqlite3_column_int(existing, 0)];
	}
	if ([value intValue] == 0) {
		return NO;
	}else{
		return YES;
	}	
}

+ (NSInteger) numRecordsInTable:(NSString *)tableName{
	int dbrc;
	sqlite3_stmt *existing = [SQLiteHelper prepareStatementForQuery:[NSString stringWithFormat:@"SELECT count(*) FROM %@;", tableName]];
	NSNumber *value = nil;
	while ((dbrc = sqlite3_step(existing)) == SQLITE_ROW) {
		value = [[NSNumber alloc] initWithInt:sqlite3_column_int(existing, 0)];
	}
	return [value intValue];
}

+ (void) checkUserExist{
    
    NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Users_Tables WHERE user_id=\"%@\"", GLOBAL_USER_ID];
    sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    while (sqlite3_step(queryStatement) == SQLITE_ROW) {
        break;
    }
    sqlite3_finalize(queryStatement);
    
    //will execute following only when no GLOBAL_USER_ID table exists
    NSString *query2 = [[NSString alloc] initWithFormat:@"INSERT INTO Users_Tables(user_id, nick_name) VALUES (%d,\"%@\")", [GLOBAL_USER_ID intValue], @"vistor"];
	sqlite3_stmt *queryStatement2 = [SQLiteHelper prepareStatementForQuery:query2];
	sqlite3_step(queryStatement2);
	sqlite3_finalize(queryStatement2);
    
    
}

+ (void) verifyDatabase{
	if (![SQLiteHelper tableExists:@"Users_Tables"]) {
		sqlite3_stmt *createUsers = [SQLiteHelper prepareStatementForQuery:@"create table Users_Tables (user_id integer, nick_name text);"];
		sqlite3_step(createUsers);
		sqlite3_finalize(createUsers);
	}
    
	if (![SQLiteHelper tableExists:@"Packs_Tables"]) {
		sqlite3_stmt *createItems = [SQLiteHelper prepareStatementForQuery:@"create table Packs_Tables (pack_id integer, pack_name text, user_id integer, language_name text, is_public text, cover_image text);"];
		sqlite3_step(createItems);
		sqlite3_finalize(createItems);
	}
	if (![SQLiteHelper tableExists:@"Cards_Tables"]) {
		sqlite3_stmt *createNotes = [SQLiteHelper prepareStatementForQuery:@"create table Cards_Tables (card_id integer, pack_id integer, card_name text, thumb_pic text, creator text);"];
		sqlite3_step(createNotes);
		sqlite3_finalize(createNotes);
	}
	if (![SQLiteHelper tableExists:@"Question_Tables"]) {
		sqlite3_stmt *createNotes = [SQLiteHelper prepareStatementForQuery:@"create table Question_Tables (question_id integer, card_id integer, title text, content text, type text, image text, logo text);"];
		sqlite3_step(createNotes);
		sqlite3_finalize(createNotes);
	}
    if (![SQLiteHelper tableExists:@"Answer_Tables"]) {
		sqlite3_stmt *createNotes = [SQLiteHelper prepareStatementForQuery:@"create table Answer_Tables (answer_id integer, card_id integer, title text, content text, image text, logo text);"];
		sqlite3_step(createNotes);
		sqlite3_finalize(createNotes);
	}
    
    //type could be "true/false" or "multiple choice", 1,2,3,4, something like that
    if (![SQLiteHelper tableExists:@"Type_Tables"]) {
		sqlite3_stmt *createNotes = [SQLiteHelper prepareStatementForQuery:@"create table Votes (type text, content text);"];
		sqlite3_step(createNotes);
		sqlite3_finalize(createNotes);
	}
}

+ (BOOL)booleanForInt:(NSInteger)integer{
	if (integer > 0) {
		return YES;
	}else{
		return NO;
	}
}

//should be used in "while (sqlite3_step(queryStatement) == SQLITE_ROW)"
+ (NSString *)getStringFromQuery:(sqlite3_stmt *)statement inColumn:(NSInteger)colNum{
	const char *columnText = (const char *)sqlite3_column_text(statement, colNum);
	if (columnText != NULL) {
		return @(columnText);
	}else {
		return @"";
	}
}

//should be used in "while (sqlite3_step(queryStatement) == SQLITE_ROW)"
+ (NSNumber *)getNumberFromQuery:(sqlite3_stmt *)statement inColumn:(NSInteger)colNum{
	return @(sqlite3_column_int(statement, colNum));
}

+ (BOOL)checkIntegerValueExists:(NSInteger)value forColumn:(NSString *)columnName inTable:(NSString *)table{
	NSString *queryString = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ WHERE %@=%d", table, columnName, value];
	sqlite3_stmt *query = [SQLiteHelper prepareStatementForQuery:queryString];
	BOOL exists = NO;
	if (sqlite3_step(query) == SQLITE_ROW) {
		exists = YES;
	}
	sqlite3_finalize(query);
	return exists;
}

+ (BOOL)checkStringValueExists:(NSString *)value forColumn:(NSString *)columnName inTable:(NSString *)table{
	NSString *queryString = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ WHERE %@=\"%@\"", table, columnName, value];
	sqlite3_stmt *query = [SQLiteHelper prepareStatementForQuery:queryString];
	BOOL exists = NO;
	if (sqlite3_step(query) == SQLITE_ROW) {
		exists = YES;
	}
	sqlite3_finalize(query);
	return exists;
}

+ (NSInteger) getMaxValueForColumn:(NSString *)columnName inTable:(NSString *)tableName{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT max(%@) FROM %@", columnName, tableName];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	NSInteger number;
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		number = [[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] intValue];
	}
	sqlite3_finalize(queryStatement);
	return number;
}

@end
