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
@synthesize content = _content;
@synthesize type = _type;
@synthesize imageName = _imageName;

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
    _content= [dataDict valueForKey:@"content"];
    _type= [dataDict valueForKey:@"type"];
    _imageName= [dataDict valueForKey:@"image"];
    
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
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Question_Tables SET question_id=%d, title=\"%@\", content=\"%@\", type=\"%@\", image=\"%@\" WHERE card_id=%d", _questionID, _title, _content, _type, _imageName, _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

-(void)insert{
	if (_questionID == -1) {
		_questionID = [SQLiteHelper getMaxValueForColumn:@"question_id" inTable:@"Question_Tables"] + 1;
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Question_Tables(question_id, card_id, title, content,  type, image) VALUES (%d, %d, \"%@\", \"%@\", \"%@\", \"%@\")", _questionID, _cardID, _title, _content, _type, _imageName];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}


+(NSMutableDictionary *) questionForCardID:(NSInteger)cardID{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Question_Tables WHERE card_id=%d", cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    NSMutableDictionary *questionDict = [[NSMutableDictionary alloc] init];
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		[questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"question_id"];
		[questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"card_id"];
		[questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"title"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"content"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"type"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:5] forKey:@"image"];
	}
	sqlite3_finalize(queryStatement);
	return questionDict;
}



@end
