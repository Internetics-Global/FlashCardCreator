//
//  Question.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "Question.h"
#import "SQLiteHelper.h"

@implementation Question

@synthesize questionID = _questionID;
@synthesize cardID = _cardID;
@synthesize title = _title;
@synthesize summary = _summary;
@synthesize detail = _detail;
@synthesize type = _type;
@synthesize imageFullPath = _imageFullPath;
@synthesize logoFullPath = _logoFullPath;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _questionID = -1;
    _cardID = -1;
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dataDict{
	if (!(self = [self init])) return nil;
    
	_questionID = [[dataDict valueForKey:@"question_id"] intValue];    
    _cardID = [[dataDict valueForKey:@"card_id"] intValue];
    _title = [dataDict valueForKey:@"title"];
    _summary= [dataDict valueForKey:@"summary"];
    _detail= [dataDict valueForKey:@"detail"];
    _type= [dataDict valueForKey:@"type"];
    _imageFullPath= [dataDict valueForKey:@"image"];
    _logoFullPath= [dataDict valueForKey:@"logo"];
    
	return self;
}



#pragma mark -
#pragma mark Operation

- (void)save{
	if (_questionID == -1) {
		[self performSelector:@selector(insert)];
	}else {
		if ([SQLiteHelper checkIntegerValueExists:_questionID forColumn:@"question_id" inTable:@"Question_Tables"]) {
			[self performSelector:@selector(update)];
		}else {
			[self performSelector:@selector(insert)];
		}
	}
}

-(void)update{
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Question_Tables SET question_id=%d, title=\"%@\", summary=\"%@\", detail=\"%@\", type=\"%@\", image=\"%@\", logo=\"%@\" WHERE card_id=%d", _questionID, _title, _summary, _detail, _type, _imageFullPath, _logoFullPath, _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

-(void)insert{
	if (_questionID == -1) {
		_questionID = [SQLiteHelper getMaxValueForColumn:@"question_id" inTable:@"Question_Tables"] + 1;
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Question_Tables(question_id, card_id, title, summary, detail, type, image, logo) VALUES (%d, %d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\")", _questionID, _cardID, _title, _summary, _detail, _type, _imageFullPath, _logoFullPath];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

-(void)destroy{
	//Step1: delete from database
    NSString *query = [[NSString alloc] initWithFormat:@"DELETE FROM Question_Tables WHERE card_id=%d", _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    
    //Step2: delted image resources
    NSError *error = nil;
    //We never delete placeholder imae
    if (![[self.logoFullPath lastPathComponent] isEqualToString:@"question_placeholder_logo.png"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.logoFullPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.logoFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question logoFullPath"];
            }
        }
    }
    error = nil;
    if (![[self.imageFullPath lastPathComponent] isEqualToString:@"question_placeholder_content"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageFullPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.imageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question imageFullPath"];
            }
        }
    }
}


+(NSMutableDictionary *) questionForCardID:(NSInteger)cardID{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Question_Tables WHERE card_id=%d", cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    NSMutableDictionary *questionDict = [[NSMutableDictionary alloc] init];
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		[questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"question_id"];
		[questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"card_id"];
		[questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"title"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"summary"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"detail"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:5] forKey:@"type"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:6] forKey:@"image"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:7] forKey:@"logo"];
	}
	sqlite3_finalize(queryStatement);
	return questionDict;
}



@end
