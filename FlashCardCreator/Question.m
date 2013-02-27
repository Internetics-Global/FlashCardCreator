//
//  Question.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "Question.h"
#import "SQLiteHelper.h"
#import "CSS.h"

@implementation Question

@synthesize questionID = _questionID;
@synthesize cardID = _cardID;
@synthesize cssID = _cssID;
@synthesize title = _title;
@synthesize main = _main;
@synthesize sub = _sub;
@synthesize subheading = _subheading;
@synthesize imageFullPath = _imageFullPath;
@synthesize logoFullPath = _logoFullPath;
@synthesize logoURLLinkage = _logoURLLinkage;
@synthesize css = _css;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _questionID = -1;
    _cardID = -1;
    _cssID = -1;
    _css = [[CSS alloc] init];
    _logoURLLinkage = @"http://www.";
    
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dataDict{
	if (!(self = [self init])) return nil;
    
	_questionID = [[dataDict valueForKey:@"question_id"] intValue];    
    _cardID = [[dataDict valueForKey:@"card_id"] intValue];
    _cssID = [[dataDict valueForKey:@"css_id"] intValue];
    _title = [dataDict valueForKey:@"title"];
    _main= [dataDict valueForKey:@"main"];
    _sub= [dataDict valueForKey:@"sub"];
    _subheading= [dataDict valueForKey:@"subheading"];
    _imageFullPath= [dataDict valueForKey:@"image"];
    _logoFullPath= [dataDict valueForKey:@"logo"];
    _logoURLLinkage = [dataDict valueForKey:@"logo_url"];
    
    if ([[dataDict allKeys] containsObject:@"css"]) {
        NSDictionary *cssArray = (NSDictionary *)[dataDict valueForKey:@"css"];
        self.css = [[CSS alloc] initWithDictionary:cssArray];
	}
    
	return self;
}



#pragma mark -
#pragma mark Operation

- (void)save{
    
    // css save first, since we need cssID for Question
    [_css save];
    self.cssID = _css.cssID;
    
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
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Question_Tables SET question_id=%d, title=\"%@\", main=\"%@\", sub=\"%@\", subheading=\"%@\", image=\"%@\", logo=\"%@\", logo_url=\"%@\", css_id=%d WHERE card_id=%d", _questionID, _title, _main, _sub, _subheading, _imageFullPath, _logoFullPath, _logoURLLinkage, _cssID, _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

-(void)insert{
	if (_questionID == -1) {
		_questionID = [SQLiteHelper getMaxValueForColumn:@"question_id" inTable:@"Question_Tables"] + 1;
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Question_Tables(question_id, card_id, title, main, sub, subheading, image, logo, logo_url,css_id) VALUES (%d, %d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %d)", _questionID, _cardID, _title, _main, _sub, _subheading, _imageFullPath, _logoFullPath, _logoURLLinkage, _cssID];
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
    if (![[self.logoFullPath lastPathComponent] isEqualToString:@"question_placeholder_logo.jpg"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.logoFullPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.logoFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question logoFullPath"];
                NSLog(@"%s:%@",__FUNCTION__,[error description]);
            }
        }
    }
    error = nil;
    if (![[self.imageFullPath lastPathComponent] isEqualToString:@"question_placeholder_content.png"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageFullPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.imageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question imageFullPath"];
                NSLog(@"%s:%@",__FUNCTION__,[error description]);
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
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"main"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"sub"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:5] forKey:@"subheading"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:6] forKey:@"image"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:7] forKey:@"logo"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:8] forKey:@"logo_url"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:9] forKey:@"css_id"];
        [questionDict setValue:[CSS cssForCSSID:[[questionDict valueForKey:@"css_id"] intValue]] forKey:@"css"];
	}
	sqlite3_finalize(queryStatement);
	return questionDict;
}



@end
