//
//  Answer.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "Answer.h"
#import "SQLiteHelper.h"
#import "CSS.h"

@implementation Answer

@synthesize answerID = _answerID;
@synthesize cardID = _cardID;
@synthesize cssID = _cssID;
@synthesize title = _title;
@synthesize main = _main;
@synthesize sub = _sub;
@synthesize subheading = _subheading;
@synthesize imageFullPath = _imageFullPath;
@synthesize logoFullPath = _logoFullPath;
@synthesize css = _css;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _answerID = -1;
    _cardID = -1;
    _cssID = -1;
    _css = [[CSS alloc] init];
    
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dataDict{
	if (!(self = [self init])) return nil;
    
	_answerID = [[dataDict valueForKey:@"answer_id"] intValue];
    _cardID = [[dataDict valueForKey:@"card_id"] intValue];
    _cssID = [[dataDict valueForKey:@"css_id"] intValue];
    _title = [dataDict valueForKey:@"title"];
    _subheading= [dataDict valueForKey:@"subheading"];
    _main= [dataDict valueForKey:@"main"];
    _sub= [dataDict valueForKey:@"sub"];
    _imageFullPath= [dataDict valueForKey:@"image"];
    _logoFullPath= [dataDict valueForKey:@"logo"];
    
    if ([[dataDict allKeys] containsObject:@"css"]) {
        NSDictionary *cssArray = (NSDictionary *)[dataDict valueForKey:@"css"];
        self.css = [[CSS alloc] initWithDictionary:cssArray];
	}
    
	return self;
}

#pragma mark -
#pragma mark Operation

- (void)save{
    
    // css save first, since we need cssID for Answer
    [_css save];
    self.cssID = _css.cssID;
    
    
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
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Answer_Tables SET answer_id=%d, title=\"%@\", main=\"%@\", sub=\"%@\", subheading=\"%@\", image=\"%@\", logo=\"%@\", css_id=%d WHERE card_id=%d", _answerID, _title, _main, _sub, _subheading, _imageFullPath, _logoFullPath, _cssID, _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

-(void)insert{
	if (_answerID == -1) {
		_answerID = [SQLiteHelper getMaxValueForColumn:@"question_id" inTable:@"Answer_Tables"] + 1;
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Answer_Tables(answer_id, card_id, title, main, sub, subheading, image, logo, css_id) VALUES (%d, %d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %d)", _answerID, _cardID, _title, _main, _sub, _subheading, _imageFullPath, _logoFullPath, _cssID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

-(void)destroy{
	//Step1: delete from database
    NSString *query = [[NSString alloc] initWithFormat:@"DELETE FROM Answer_Tables WHERE card_id=%d", _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    
    //Step2: delted image resources
    NSError *error = nil;
    //We never delete placeholder imae
    if (![[self.logoFullPath lastPathComponent] isEqualToString:@"answer_placeholder_logo.png"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.logoFullPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.logoFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer logoFullPath"];
            }
        }
    }
    error = nil;
    if (![[self.imageFullPath lastPathComponent] isEqualToString:@"answer_placeholder_content"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageFullPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.imageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer imageFullPath"];
            }
        }
    }
}

+(NSMutableDictionary *) answerForCardID:(NSInteger)cardID{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Answer_Tables WHERE card_id=%d", cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	NSMutableDictionary *answerDict = [[NSMutableDictionary alloc] init];
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		[answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"answer_id"];
		[answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"card_id"];
		[answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"title"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"main"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"sub"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:5] forKey:@"subheading"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:6] forKey:@"image"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:7] forKey:@"logo"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:8] forKey:@"css_id"];
        [answerDict setValue:[CSS cssForCSSID:[[answerDict valueForKey:@"css_id"] intValue]] forKey:@"css"];
	}
	sqlite3_finalize(queryStatement);
	return answerDict;
}

@end
