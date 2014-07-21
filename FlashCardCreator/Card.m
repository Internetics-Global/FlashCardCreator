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
#import "SQLiteHelper.h"
#import "Common.h"

@implementation Card

@synthesize cardID = _cardID;
@synthesize packID = _packID;
@synthesize cardSN = _cardSN;
@synthesize cardName = _cardName;
@synthesize coverImageURL = _coverImageURL;
@synthesize templateBackgroundName = _templateBackgroundName;
@synthesize creator = _creator;
@synthesize answer = _answer;
@synthesize question = _question;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    
    _cardID = -1;
    _packID = -1;
    _cardSN = -1;
    _templateBackgroundName = @"card_background_blue.png";
    _question = [[Question alloc] init];
    _answer = [[Answer alloc] init];
    
    _coverImageURL = @"";
    
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dataDict{
	if (!(self = [self init])) return nil;
    
	_cardID = [[dataDict valueForKey:@"card_id"] intValue];
    _packID = [[dataDict valueForKey:@"pack_id"] intValue];
    _cardSN = [[dataDict valueForKey:@"card_sn"] intValue];
    _cardName = [dataDict valueForKey:@"card_name"];    
    _coverImageURL = [dataDict valueForKey:@"thumb_pic"];
    _templateBackgroundName = [dataDict valueForKey:@"template_background"];
    _creator = [dataDict valueForKey:@"creator"];

	if ([[dataDict allKeys] containsObject:@"question"]) {
        NSDictionary *questionArray = (NSDictionary *)[dataDict valueForKey:@"question"];
        self.question = [[Question alloc] initWithDictionary:questionArray];
	}    
    if ([[dataDict allKeys] containsObject:@"answer"]) {
        NSDictionary *answerArray = (NSDictionary *)[dataDict valueForKey:@"answer"];
        self.answer = [[Answer alloc] initWithDictionary:answerArray];
	}
    
	return self;
}

#pragma mark -
#pragma mark Operation

- (void)save{
	if (_cardID == -1) {
		[self performSelector:@selector(insert)];
	}else {
		if ([SQLiteHelper checkIntegerValueExists:_cardID forColumn:@"card_id" inTable:@"Cards_Tables"]) {
			[self performSelector:@selector(update)];
		}else {
			[self performSelector:@selector(insert)];
		}
	}
    
    _question.cardID = _cardID; //build table linkage in database
    _answer.cardID = _cardID; //build table linkage in database
    [_question save];
    [_answer save];
}

-(void)update{
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Cards_Tables SET pack_id=%d, card_name=\"%@\", thumb_pic=\"%@\", template_background=\"%@\", creator=\"%@\", card_sn=%d WHERE card_id=%d", _packID, _cardName, _coverImageURL, _templateBackgroundName, _creator, _cardSN, _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        DDLogError(@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query);
        
    }
}

-(void)insert{
	if (_cardID == -1) {
		_cardID = [[NSDate date] timeIntervalSince1970];
        BOOL isExist = [SQLiteHelper checkIntegerValueExists:_cardID forColumn:@"card_id" inTable:@"Cards_Tables"];
        if (isExist) {
            DDLogError(@"%s:_cardID has already existed",__FUNCTION__);
        }
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Cards_Tables(card_id, pack_id, card_name, thumb_pic, template_background, creator, card_sn) VALUES (%d, %d, \"%@\", \"%@\", \"%@\", \"%@\", %d)", _cardID, _packID, _cardName, _coverImageURL, _templateBackgroundName, _creator, _cardSN];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        DDLogError(@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query);
        
    }
}

-(void)destroy{
	//Step1: delete from database
    NSString *query = [[NSString alloc] initWithFormat:@"DELETE FROM Cards_Tables WHERE card_id=%d", _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
	
    //Step2: delted image resources
    NSError *error = nil;
    //We never delete placeholder imae
    BOOL isDir;
    if (![[self.coverImageURL lastPathComponent] isEqualToString:@"card_cover_image_placeholder.png"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.coverImageURL isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.coverImageURL error:&error];
            if (error) {
                DDLogError(@"%s:Error when removing file of card coverImageURL",__FUNCTION__);
                [Common alertViewCommon:@"Error when removing file of card coverImageURL"];
            }
        }
    }
    
    //Step3: We need to destroy all the data related in persistence
    [self.question destroy];
    [self.answer destroy];
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
        [cardDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"thumb_pic"];
        [cardDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"template_background"];
        [cardDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:5] forKey:@"creator"];
        [cardDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:6] forKey:@"card_sn"];
        [cardDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:7] forKey:@"template_id"];
		[cardDict setValue:[Question questionForCardID:[[cardDict valueForKey:@"card_id"] intValue]] forKey:@"question"];
        [cardDict setValue:[Answer answerForCardID:[[cardDict valueForKey:@"card_id"] intValue]] forKey:@"answer"];
		[returnArray addObject:cardDict];
	}
	sqlite3_finalize(queryStatement);
	return returnArray;
}

@end
