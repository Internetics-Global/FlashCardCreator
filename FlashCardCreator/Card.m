//
//  Card.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "Card.h"
#import "SQLiteHelper.h"
#import "Answer.h"
#import "Question.h"
#import "Image.h"
#import "SQLiteHelper.h"

@implementation Card

@synthesize cardID = _cardID;
@synthesize packID = _packID;
@synthesize cardName = _cardName;
@synthesize thumbPicURL = _thumbPicURL;
@synthesize onlineFileURLL = _onlineFileURL;
@synthesize isOnline = _isOnline;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _cardID = -1;
    _packID = -1;
    _isOnline = TRUE;
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dataDict{
	[self init];
	_cardID = [[dataDict valueForKey:@"card_id"] intValue];
    
    _cardName = [[dataDict valueForKey:@"card_name"] retain];
    
    _thumbPicURL = [[dataDict valueForKey:@"thumb_pic"] retain];
    
    _isOnline= [[dataDict valueForKey:@"is_online"] intValue] == 1;

	if ([[dataDict allKeys] containsObject:@"question"]) {
        //need to be updated
	}
    
    if ([[dataDict allKeys] containsObject:@"answer"]) {
        //need to be updated
	}
    
    if ([[dataDict allKeys] containsObject:@"image"]) {
        //need to be updated
	}
    
	return self;
}

#pragma mark -
#pragma mark Operation

- (void)save{
	if (_cardID == -1) {
		[self performSelector:@selector(insert)];
	}else {
		if ([SQLiteHelper checkIntegerValueExists:_cardID forColumn:@"card_id" inTable:@"Cards"]) {
			[self performSelector:@selector(update)];
		}else {
			[self performSelector:@selector(insert)];
		}
	}
}

-(void)update{
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Cards_Tables SET pack_id=%d, card_name=\"%@\", thumb_pic=\"%@\", is_online=%d WHERE card_id=%d", _packID, _cardName, _thumbPicURL, (_isOnline?1:0), _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
	[query release];
}

-(void)insert{
	if (_cardID == -1) {
		_cardID = [SQLiteHelper getMaxValueForColumn:@"card_id" inTable:@"Cards_Tables"] + 1;
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Cards_Tables(card_id, pack_id, card_name, thumb_pic,  is_online) VALUES (%d, %d, \"%@\", \"%@\", %d)", _cardID, _packID, _cardName, _thumbPicURL, (_isOnline?1:0)];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
	[query release];
}

-(void)destroy{
	NSString *query = [[NSString alloc] initWithFormat:@"DELETE FROM Cards_Tables WHERE card_id=%d", _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
	[query release];
	//[[DataManager defaultManager] deleteItem:self];
}

+(NSMutableArray *) cardsForPackID:(NSInteger)packID{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Cards_Tables WHERE pack_id=%d", packID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	NSMutableArray *returnArray = nil;
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		if (returnArray == nil) {
			returnArray = [[NSMutableArray alloc] init];
		}
		NSMutableDictionary *cardDict = [[NSMutableDictionary alloc] init];
		[cardDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"card_id"];
		[cardDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"pack_id"];
        [cardDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"card_name"];
		[cardDict setValue:[Question questionsForCardID:[[cardDict valueForKey:@"card_id"] intValue]] forKey:@"questions"];
        [cardDict setValue:[Answer answersForCardID:[[cardDict valueForKey:@"card_id"] intValue]] forKey:@"answers"];
#warning this is not finally completed
        [cardDict setValue:[Image imagesForCardID:[[cardDict valueForKey:@"card_id"] intValue]] forKey:@"images"];
		[returnArray addObject:cardDict];
		[cardDict release];
	}
	sqlite3_finalize(queryStatement);
	return [returnArray autorelease];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc{
	[super dealloc];
    FCC_RELEASE_SAFELY(_cardName);
    FCC_RELEASE_SAFELY(_thumbPicURL)
    FCC_RELEASE_SAFELY(_onlineFileURL);
}

@end
