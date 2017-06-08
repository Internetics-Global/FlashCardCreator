//
//  SQLiteHelper.m
//  FFC
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
    
    BOOL exist = FALSE;
    
    NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Users_Tables WHERE user_id=\"%@\"", GLOBAL_USER_ID];
    sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    while (sqlite3_step(queryStatement) == SQLITE_ROW) {
        exist = TRUE;
        break;
    }
    sqlite3_finalize(queryStatement);
    
    if (exist == FALSE) {
        //will execute following only when no GLOBAL_USER_ID table exists
        NSString *query2 = [[NSString alloc] initWithFormat:@"INSERT INTO Users_Tables(user_id, nick_name) VALUES (%d,\"%@\")", [GLOBAL_USER_ID intValue], @"vistor"];
        sqlite3_stmt *queryStatement2 = [SQLiteHelper prepareStatementForQuery:query2];
        sqlite3_step(queryStatement2);
        sqlite3_finalize(queryStatement2);
    }
    
    
}

/**
 *  只检查表是否存在，而不检查字段的一致性
 */
+ (void) verifyDatabase{
	if (![SQLiteHelper tableExists:@"Users_Tables"]) {
		sqlite3_stmt *createUsers = [SQLiteHelper prepareStatementForQuery:@"create table Users_Tables (user_id integer, nick_name text);"];
		sqlite3_step(createUsers);
		sqlite3_finalize(createUsers);
        
        sqlite3_stmt *createIndex = [SQLiteHelper prepareStatementForQuery:@"create index if not exists IA on Users_Tables (user_id);"];
		sqlite3_step(createIndex);
		sqlite3_finalize(createIndex);
        
        [iConsole info:@"%s:Create Users_Tables",__FUNCTION__];
        
	}
    
	if (![SQLiteHelper tableExists:@"Packs_Tables"]) {
		sqlite3_stmt *createItems = [SQLiteHelper prepareStatementForQuery:@"create table Packs_Tables (pack_id integer, pack_name text, sidebar_title text, user_id integer, language_name text, is_public text, cover_image text, creator text, creator_nick_name text,create_date integer,last_visit_date integer, job_title text, auto_play_speed integer,restore_password text,share_link text,file_name_on_aws text,platform text);"];
		sqlite3_step(createItems);
		sqlite3_finalize(createItems);
        
        sqlite3_stmt *createIndex = [SQLiteHelper prepareStatementForQuery:@"create index if not exists IA on Packs_Tables (pack_id);"];
		sqlite3_step(createIndex);
		sqlite3_finalize(createIndex);
        
        [iConsole info:@"%s:Create Packs_Tables",__FUNCTION__];
	}else {
        if (([Common currentInstalledSqliteVersion] <= 5) && ([Common newUpdatingSqliteVersion] == 6)) {
            [self AddFieldForPackFrom5To6];
        }
    }
    
	if (![SQLiteHelper tableExists:@"Cards_Tables"]) {
		sqlite3_stmt *createNotes = [SQLiteHelper prepareStatementForQuery:@"create table Cards_Tables (card_id integer, pack_id integer, card_name text, thumb_pic text, template_background text, creator text, card_sn integer);"];
		sqlite3_step(createNotes);
		sqlite3_finalize(createNotes);
        
        sqlite3_stmt *createIndex = [SQLiteHelper prepareStatementForQuery:@"create index if not exists IA on Cards_Tables (card_id);"];
		sqlite3_step(createIndex);
		sqlite3_finalize(createIndex);
        
        [iConsole info:@"%s:Create Cards_Tables",__FUNCTION__];
	}
    
    
	if (![SQLiteHelper tableExists:@"Question_Tables"]) {
		sqlite3_stmt *createNotes = [SQLiteHelper prepareStatementForQuery:@"create table Question_Tables (question_id integer, card_id integer, title text, main text, sub text, subheading text, image text, image2 text, logo text, logo_url text, css_id integer,template_id integer,line_number_subheading integer,line_number_main integer,line_number_sub integer, background_image text, movie text,movie2 text, audio text,autoresize_flag integer);"];
		sqlite3_step(createNotes);
		sqlite3_finalize(createNotes);
        
        sqlite3_stmt *createIndex = [SQLiteHelper prepareStatementForQuery:@"create index if not exists IA on Question_Tables (question_id);"];
		sqlite3_step(createIndex);
		sqlite3_finalize(createIndex);
        
        [iConsole info:@"%s:Create Question_Tables",__FUNCTION__];
        
	}
    
    
    if (![SQLiteHelper tableExists:@"Answer_Tables"]) {
		sqlite3_stmt *createNotes = [SQLiteHelper prepareStatementForQuery:@"create table Answer_Tables (answer_id integer, card_id integer, title text, main text, sub text, subheading text, image text,image2 text, logo text, css_id integer,template_id integer,line_number_subheading integer,line_number_main integer,line_number_sub integer, background_image text,movie text,movie2 text, audio text,autoresize_flag integer);"];
		sqlite3_step(createNotes);
		sqlite3_finalize(createNotes);
        
        sqlite3_stmt *createIndex = [SQLiteHelper prepareStatementForQuery:@"create index if not exists IA on Answer_Tables (answer_id);"];
		sqlite3_step(createIndex);
		sqlite3_finalize(createIndex);
        
        [iConsole info:@"%s:Create Answer_Tables",__FUNCTION__];
        
        
	}
    
    if (![SQLiteHelper tableExists:@"CSS_Tables"]) {
		sqlite3_stmt *createNotes = [SQLiteHelper prepareStatementForQuery:@"create table CSS_Tables (css_id integer,subheading_size integer, subheading_align text, subheading_color text, main_size integer, main_align text, main_color text, sub_size integer, sub_align text, sub_color text, subheading_font text, main_font text, sub_font text, subheading_align_vertical text,main_align_vertical text, sub_align_vertical text, subheading_semi_transparent integer,main_semi_transparent integer,sub_semi_transparent integer, subheading_text2speech text, main_text2speech text, sub_text2speech text);"];
		sqlite3_step(createNotes);
		sqlite3_finalize(createNotes);
        
        sqlite3_stmt *createIndex = [SQLiteHelper prepareStatementForQuery:@"create index if not exists IA on CSS_Tables (css_id);"];
		sqlite3_step(createIndex);
		sqlite3_finalize(createIndex);
        
        [iConsole info:@"%s:Create CSS_Tables",__FUNCTION__];
    } else {
        if (([Common currentInstalledSqliteVersion] <= 6) && ([Common newUpdatingSqliteVersion] == 7)) {
            [self AddFieldForPackFrom6To7];
        } else if (([Common currentInstalledSqliteVersion] <= 6) && ([Common newUpdatingSqliteVersion] == 8)) {
            [self AddFieldForPackFrom6To7];
            [self AddFieldForPackFrom7To8];
        } else if (([Common currentInstalledSqliteVersion] == 7) && ([Common newUpdatingSqliteVersion] == 8)) {
            [self AddFieldForPackFrom7To8];
        }
    }
    
    
    if ([Common currentInstalledSqliteVersion] != [Common newUpdatingSqliteVersion]) {
        [Common setCurrentInstalledSqliteVersion:[Common newUpdatingSqliteVersion]];
    }
    
    
}



+ (void) AddFieldForPackFrom5To6 {
    
    NSString *query = [[NSString alloc] initWithFormat:@"ALTER TABLE Packs_Tables ADD COLUMN auto_play_speed integer "];
    sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    sqlite3_step(queryStatement);
    sqlite3_finalize(queryStatement);
    
    [iConsole info:@"%s",__FUNCTION__];
    
    
}

+ (void) AddFieldForPackFrom6To7 {
    
    {
        NSString *query = [[NSString alloc] initWithFormat:@"ALTER TABLE CSS_Tables ADD COLUMN subheading_semi_transparent integer "];
        sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
        sqlite3_step(queryStatement);
        sqlite3_finalize(queryStatement);
    }
    
    {
        NSString *query = [[NSString alloc] initWithFormat:@"ALTER TABLE CSS_Tables ADD COLUMN main_semi_transparent integer "];
        sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
        sqlite3_step(queryStatement);
        sqlite3_finalize(queryStatement);
    }
    
    {
        NSString *query = [[NSString alloc] initWithFormat:@"ALTER TABLE CSS_Tables ADD COLUMN sub_semi_transparent integer "];
        sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
        sqlite3_step(queryStatement);
        sqlite3_finalize(queryStatement);
    }
    
    [iConsole info:@"%s",__FUNCTION__];
    
    
}

+ (void) AddFieldForPackFrom7To8 {
    
    {
        NSString *query = [[NSString alloc] initWithFormat:@"ALTER TABLE CSS_Tables ADD COLUMN subheading_text2speech integer "];
        sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
        sqlite3_step(queryStatement);
        sqlite3_finalize(queryStatement);
    }
    
    {
        NSString *query = [[NSString alloc] initWithFormat:@"ALTER TABLE CSS_Tables ADD COLUMN main_text2speech integer "];
        sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
        sqlite3_step(queryStatement);
        sqlite3_finalize(queryStatement);
    }
    
    {
        NSString *query = [[NSString alloc] initWithFormat:@"ALTER TABLE CSS_Tables ADD COLUMN sub_text2speech integer "];
        sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
        sqlite3_step(queryStatement);
        sqlite3_finalize(queryStatement);
    }
    
    [iConsole info:@"%s",__FUNCTION__];
    
    
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
        [iConsole warn:@"%s:%@",__FUNCTION__,@"can not find related value"];
		return @"";
	}
}

//should be used in "while (sqlite3_step(queryStatement) == SQLITE_ROW)"
+ (NSNumber *)getNumberFromQuery:(sqlite3_stmt *)statement inColumn:(NSInteger)colNum{
	return @(sqlite3_column_int(statement, colNum));
}

+ (BOOL)checkIntegerValueExists:(NSInteger)value forColumn:(NSString *)columnName inTable:(NSString *)table{
	NSString *queryString = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ WHERE %@=%ld", table, columnName, (long)value];
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
