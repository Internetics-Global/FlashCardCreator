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
#import "FileOperationHelper.h"

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
@synthesize jobTitle = _jobTitle;

@synthesize restorePassword = _restorePassword;

@synthesize shareLink = _shareLink;
@synthesize fileNameOnAWS = _fileNameOnAWS;;

@synthesize isAllowShare = _isAllowShare;
@synthesize autoPlaySpeed = _autoPlaySpeed;

#pragma mark -
#pragma mark Initialization


- (NSString *)getCoverImageURL {
    if (_coverImageURL.length == 0 || [Common isDirectoryFormat:_coverImageURL] ) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_coverImageURL lastPathComponent]];
        return fullPath;
    }
}

- (void)setCoverImageURL:(NSString *)coverImageURL {
    if (coverImageURL.length == 0 || [Common isDirectoryFormat:coverImageURL] ) {
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[coverImageURL lastPathComponent]];
        _coverImageURL = fullPath;
    }
}

-(id)init{
	self = [super init];
    _packID = -1;
    _userID = -1;
    _cards = [[NSMutableArray alloc] init];
    
    _coverImageURL = @"";
    _jobTitle = @"";
    _restorePassword = @"";
    _shareLink = @"";
    _fileNameOnAWS = @"";
    
    _isAllowShare = YES;
    
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
     self.coverImageURL = [dict valueForKey:@"cover_image"];
    if ([[dict allKeys] containsObject:@"user_id"]) {
        _userID = [[dict valueForKey:@"user_id"] intValue];
    } else {
        _userID = -1;
    }
    _languageName = [dict valueForKey:@"language_name"];
    _creator = [dict valueForKey:@"creator"];
    _creatorNickName = [dict valueForKey:@"creator_nick_name"];
    _restorePassword = [dict valueForKey:@"restore_password"];
    _shareLink = [dict valueForKey:@"share_link"];
    _fileNameOnAWS = [dict valueForKey:@"file_name_on_aws"];
    _jobTitle = [dict valueForKey:@"job_title"];
    if (checkNullOrEmptyOrNullStr(_jobTitle)) {
        _jobTitle = @"";
    }
    
    if ([[dict allKeys] containsObject:@"create_date"]) {
        _createDate = [[dict valueForKey:@"create_date"] intValue];
    }
    if ([[dict allKeys] containsObject:@"last_visit_date"]) {;
        _lastVisitDate = [[dict valueForKey:@"last_visit_date"] intValue];
    }
    
    if ([[dict allKeys] containsObject:@"auto_play_speed"]) {;
        _autoPlaySpeed = [[dict valueForKey:@"auto_play_speed"] intValue];
    }
    
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
	[self savePackOnly];
    
	for (int i = 0; i < [_cards count]; i++) {
		[iConsole info:@"%s:saving cards...",__FUNCTION__];
		[_cards[i] save];
	}
}

- (void) savePackOnly {
    if (_packID == -1) {
		[self performSelector:@selector(insert)];
	}else {
		if ([SQLiteHelper checkIntegerValueExists:_packID forColumn:@"pack_id" inTable:@"Packs_Tables"]) {
			[self performSelector:@selector(update)];
		}else {
			[self performSelector:@selector(insert)];
		}
	}
}


-(void)update{
    
    //temporarily solution: TODO
    //when _jobTitle == creator, the result will be the value of "_creator", we still don't know why,
    if ([_jobTitle.lowercaseString isEqualToString:@"creator"]) {
        _jobTitle = @"Creator ";
    }
    
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Packs_Tables SET pack_name=\"%@\", language_name=\"%@\", is_public=%d, cover_image=\"%@\", creator=\"%@\", creator_nick_name=\"%@\",job_title=\"%@\", sidebar_title=\"%@\",create_date=%d,last_visit_date=%d,auto_play_speed=%d, restore_password=\"%@\", share_link=\"%@\", file_name_on_aws =\"%@\" WHERE pack_id=%d", _packName, _languageName,0, self.coverImageURL, _creator, _creatorNickName,_jobTitle, _sidebarTitle,_createDate,_lastVisitDate,_autoPlaySpeed,_restorePassword,_shareLink,_fileNameOnAWS,_packID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        [iConsole error:@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query];
        
    }
}

-(void)insert{
    
    //temporarily solution: TODO
    //when _jobTitle == creator, the result will be the value of "_creator", we still don't know why,
    if ([_jobTitle.lowercaseString isEqualToString:@"creator"]) {
        _jobTitle = @"Creator ";
    }
    
	if (_packID == -1) {
		_packID = [[NSString stringWithFormat:@"%f%d", [[NSDate date] timeIntervalSince1970], [[User defaultUser] userID]] intValue];
		//[[DataManager defaultManager] postEvent:self];
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Packs_Tables(pack_id, pack_name, user_id, language_name, is_public, cover_image, creator, creator_nick_name,job_title,sidebar_title,create_date,last_visit_date,auto_play_speed,restore_password,share_link,file_name_on_aws) VALUES (%d, \"%@\", %d, \"%@\",%d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %d, %d, %d, \"%@\", \"%@\",\"%@\")", _packID, _packName, [User defaultUser].userID, _languageName, 0, self.coverImageURL, _creator, _creatorNickName,_jobTitle, _sidebarTitle,_createDate,_lastVisitDate,_autoPlaySpeed,_restorePassword,_shareLink,_fileNameOnAWS];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        [iConsole error:@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query];
        
    }
	
}



- (void)destroy{
	//[[DataManager defaultManager] deleteEvent:self];
	NSString *query = [[NSString alloc] initWithFormat:@"DELETE FROM Packs_Tables WHERE pack_id=%d", self.packID];
	sqlite3_stmt *statement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(statement);
	sqlite3_finalize(statement);
    
    //Deleted image resources
    NSError *error = nil;
    //We never delete placeholder image
    BOOL isDir;
    if (![[self.coverImageURL lastPathComponent] isEqualToString:@"default_pack_cover_image"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.coverImageURL isDirectory:&isDir]  && (isDir  == FALSE)) {
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
		[iConsole info:@"%s:could not enter an empty card",__FUNCTION__];
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
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:9] forKey:@"create_date"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:10] forKey:@"last_visit_date"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:11] forKey:@"job_title"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:12] forKey:@"auto_play_speed"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:13] forKey:@"restore_password"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:14] forKey:@"share_link"];
        [packDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:15] forKey:@"file_name_on_aws"];
        [packDict setValue:[Card cardsForPackID:[[packDict valueForKey:@"pack_id"] intValue]] forKey:@"cards"];
		[returnArray addObject:packDict];
	}
	sqlite3_finalize(queryStatement);
    
	return returnArray;
}


@end
