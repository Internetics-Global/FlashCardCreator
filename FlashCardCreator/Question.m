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

#pragma mark -
#pragma mark Operation

+(NSMutableArray *) questionsForCardID:(NSInteger)cardID{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Question_Tables WHERE card_id=%d", cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	NSMutableArray *returnArray = nil;
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		if (returnArray == nil) {
			returnArray = [[NSMutableArray alloc] init];
		}
		NSMutableDictionary *questionDict = [[NSMutableDictionary alloc] init];
		[questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"question_id"];
		[questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"card_id"];
		[questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"title"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"content"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"type"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:5] forKey:@"image"];
		[returnArray addObject:questionDict];
		[questionDict release];
	}
	sqlite3_finalize(queryStatement);
	return [returnArray autorelease];
}

#pragma mark -
#pragma mark Memory Management

-(void)dealloc{
    FCC_RELEASE_SAFELY(_title);
    FCC_RELEASE_SAFELY(_type);
    FCC_RELEASE_SAFELY(_imageName);
	[super dealloc];
}

@end
