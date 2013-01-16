//
//  Answer.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "Answer.h"
#import "SQLiteHelper.h"

@implementation Answer

@synthesize answerID = _answerID;
@synthesize cardID = _cardID;
@synthesize title = _title;
@synthesize content = _content;
@synthesize imageFullPath = _imageFullPath;
@synthesize logoFullPath = _logoFullPath;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _answerID = -1;
    _cardID = -1;
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dataDict{
	if (!(self = [self init])) return nil;
    
	_answerID = [[dataDict valueForKey:@"answer_id"] intValue];
    _cardID = [[dataDict valueForKey:@"card_id"] intValue];    
    _title = [dataDict valueForKey:@"title"];    
    _content= [dataDict valueForKey:@"content"];    
    _imageFullPath= [dataDict valueForKey:@"image"];
    _logoFullPath= [dataDict valueForKey:@"logo"];
	return self;
}

#pragma mark -
#pragma mark Operation

- (void)save{
	if (_answerID == -1) {
		[self performSelector:@selector(insert)];
	}else {
		if ([SQLiteHelper checkIntegerValueExists:_answerID forColumn:@"answer_id" inTable:@"Answer_Tables"]) {
			[self performSelector:@selector(update)];
		}else {
			[self performSelector:@selector(insert)];
		}
	}
}

-(void)update{
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Answer_Tables SET answer_id=%d, title=\"%@\", content=\"%@\", image=\"%@\", logo=\"%@\" WHERE card_id=%d", _answerID, _title, _content, _imageFullPath, _logoFullPath, _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

-(void)insert{
	if (_answerID == -1) {
		_answerID = [SQLiteHelper getMaxValueForColumn:@"question_id" inTable:@"Question_Tables"] + 1;
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Answer_Tables(answer_id, card_id, title, content, image, logo) VALUES (%d, %d, \"%@\", \"%@\", \"%@\", \"%@\")", _answerID, _cardID, _title, _content, _imageFullPath, _logoFullPath];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

+(NSMutableDictionary *) answerForCardID:(NSInteger)cardID{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Answer_Tables WHERE card_id=%d", cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	NSMutableDictionary *answerDict = [[NSMutableDictionary alloc] init];
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		[answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"answer_id"];
		[answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"card_id"];
		[answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"title"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"content"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"image"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:5] forKey:@"logo"];
	}
	sqlite3_finalize(queryStatement);
	return answerDict;
}

@end
