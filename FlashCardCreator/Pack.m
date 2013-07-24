//
//  Pack.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "Pack.h"
#import "SQLiteHelper.h"
#import "Card.h"
#import "User.h"
#import "Card.h"
#import "NSArray+Randomised.h"

@implementation Pack

@synthesize packID = _packID;
@synthesize packName = _packName;
@synthesize sidebarTitle = _sidebarTitle;
@synthesize coverImageURL = _coverImageURL;
@synthesize userID = _userID;
@synthesize languageName = _languageName;
@synthesize cards = _cards;
@synthesize creator = _creator;
@synthesize creatorNickName = _creatorNickName;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _packID = -1;
    _userID = -1;
    _cards = [[NSMutableArray alloc] init];
    
    _coverImageURL = @"";
    
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dict{
	if (!(self = [self init])) return nil;
    
    if ([[dict allKeys] containsObject:@"pack_id"]) {
        _packID = [[dict valueForKey:@"pack_id"] intValue];
    } else {
        _packID = -1;
    }
    _packName = [dict valueForKey:@"pack_name"];
    _sidebarTitle = [dict valueForKey:@"sidebar_title"];
     _coverImageURL = [dict valueForKey:@"cover_image"];
    if ([[dict allKeys] containsObject:@"user_id"]) {
        _userID = [[dict valueForKey:@"user_id"] intValue];
    } else {
        _userID = -1;
    }
    _languageName = [dict valueForKey:@"language_name"];
    _creator = [dict valueForKey:@"creator"];
    _creatorNickName = [dict valueForKey:@"creator_nick_name"];
    
	if ([[dict allKeys] containsObject:@"cards"]) {
		NSMutableArray *cardsArray = (NSMutableArray *)[dict valueForKey:@"cards"];
		for (int i = 0; i < [cardsArray count]; i++) {
			Card *card = [[Card alloc] initWithDictionary:cardsArray[i]];
			[_cards addObject:card];
		}
	}
    
    _cards = [_cards cardSNOrdered];

	return self;
}

- (NSMutableArray *)snOrderedCards {
    return [_cards cardSNOrdered];
}

#pragma mark -
#pragma mark Operation

-(void)save{
	if (_packID == -1) {
		[self performSelector:@selector(insert)];
	}else {
		if ([SQLiteHelper checkIntegerValueExists:_packID forColumn:@"pack_id" inTable:@"Packs_Tables"]) {
			[self performSelector:@selector(update)];
		}else {
			[self performSelector:@selector(insert)];
		}
	}
	for (int i = 0; i < [_cards count]; i++) {
		NSLog(@"%s:saving cards...",__FUNCTION__);
		[_cards[i] save];
	}
}


-(void)update{
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Packs_Tables SET pack_name=\"%@\", language_name=\"%@\", is_public=%d, cover_image=\"%@\", creator=\"%@\", creator_nick_name=\"%@\", sidebar_title=\"%@\" WHERE pack_id=%d", _packName, _languageName,0, _coverImageURL, _creator, _creatorNickName, _sidebarTitle, _packID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

-(void)insert{
	if (_packID == -1) {
		_packID = [[NSString stringWithFormat:@"%f%d", [[NSDate date] timeIntervalSince1970], [[User defaultUser] userID]] intValue];
		//[[DataManager defaultManager] postEvent:self];
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Packs_Tables(pack_id, pack_name, user_id, language_name, is_public, cover_image, creator, creator_nick_name,sidebar_title) VALUES (%d, \"%@\", %d, \"%@\",%d, \"%@\", \"%@\", \"%@\", \"%@\")", _packID, _packName, [User defaultUser].userID, _languageName, 0, _coverImageURL, _creator, _creatorNickName, _sidebarTitle];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
	
}



- (void)destroy{
	//[[DataManager defaultManager] deleteEvent:self];
	NSString *query = [[NSString alloc] initWithFormat:@"DELETE FROM Packs_Tables WHERE pack_id=%d", self.packID];
	sqlite3_stmt *statement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(statement);
	sqlite3_finalize(statement);
    
    //Deleted image resources
    NSError *error = nil;
    //We never delete placeholder imae
    if (![[self.coverImageURL lastPathComponent] isEqualToString:@"default_pack_cover_image.png"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.coverImageURL]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.coverImageURL error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of pack coverImageURL"];
            }
        }
    }
    
    sqlite3_exec([SQLiteHelper defaultDatabase], "BEGIN", 0, 0, 0);
    
    for (Card *card in _cards) {
        [card destroy];
    }
    
    sqlite3_exec([SQLiteHelper defaultDatabase], "COMMIT", 0, 0, 0);
}

- (void)addCard:(Card *)card{
	if (_cards == nil) {
		NSLog(@"%s:could not enter an empty card",__FUNCTION__);
	}
    
    card.packID = self.packID; //build table linkage in database
    
	[_cards addObject:card];
	[card save];
    
}

-(void)removeCard:(Card *)card{
	[_cards removeObject:card];
	[card destroy];
}

+(NSMutableArray *) packsForUserID:(NSInteger)userID{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Packs_Tables WHERE user_id=%d", userID];
    
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	NSMutableArray *returnArray = nil;
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		if (returnArray == nil) {
			returnArray = [[NSMutableArray alloc] init];
		}
		NSMutableDictionary *packDict = [[NSMutableDictionary alloc] init];
		[packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"pack_id"];
		[packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"pack_name"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"sidebar_title"];
		[packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"user_id"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"language_name"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:5] forKey:@"is_public"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:6] forKey:@"cover_image"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:7] forKey:@"creator"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:8] forKey:@"creator_nick_name"];
        [packDict setValue:[Card cardsForPackID:[[packDict valueForKey:@"pack_id"] intValue]] forKey:@"cards"];
		[returnArray addObject:packDict];
	}
	sqlite3_finalize(queryStatement);
    
	return returnArray;
}


@end
