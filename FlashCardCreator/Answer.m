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
@synthesize imageName = _imageName;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _answerID = -1;
    _cardID = -1;
	return self;
}

#pragma mark -
#pragma mark Operation

+(NSMutableArray *) answersForCardID:(NSInteger)cardID{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Answer_Tables WHERE card_id=%d", cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	NSMutableArray *returnArray = nil;
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		if (returnArray == nil) {
			returnArray = [[NSMutableArray alloc] init];
		}
		NSMutableDictionary *answerDict = [[NSMutableDictionary alloc] init];
		[answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"answer_id"];
		[answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"card_id"];
		[answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"title"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"content"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"image"];
		[returnArray addObject:answerDict];
		[answerDict release];
	}
	sqlite3_finalize(queryStatement);
	return [returnArray autorelease];
}

#pragma mark -
#pragma mark Memory Management

-(void)dealloc{
    FCC_RELEASE_SAFELY(_title);
    FCC_RELEASE_SAFELY(_content);
    FCC_RELEASE_SAFELY(_imageName);
	[super dealloc];
}

@end
