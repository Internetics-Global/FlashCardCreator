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
#import "Common.h"

@implementation Answer

@synthesize answerID = _answerID;
@synthesize cardID = _cardID;
@synthesize cssID = _cssID;
@synthesize title = _title;
@synthesize main = _main;
@synthesize sub = _sub;
@synthesize subheading = _subheading;

@synthesize imageFullPath = _imageFullPath;
@synthesize movieFullPath = _movieFullPath;

@synthesize logoFullPath = _logoFullPath;
@synthesize css = _css;
@synthesize templateID = _templateID;

@synthesize autoresizeFlag = _autoresizeFlag;

@synthesize backgroundImageFullPath = _backgroundImageFullPath;
@synthesize recordedSoundFullPath = _recordedSoundFullPath;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _answerID = -1;
    _cardID = -1;
    _cssID = -1;
    _css = [[CSS alloc] init];
    _templateID = 0; //begin from 0
    
    _autoresizeFlag = 0;
    
    _imageFullPath = @"";
    _movieFullPath = @"";
    _logoFullPath = @"";
    
    _recordedSoundFullPath = @"";
    
    _backgroundImageFullPath = @"";
    
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
    if (_imageFullPath.length == 0) {
        _imageFullPath = @"";
    }
    _movieFullPath= [dataDict valueForKey:@"movie"];
    if (_movieFullPath.length == 0) {
        _movieFullPath = @"";
    }
    _logoFullPath= [dataDict valueForKey:@"logo"];
    _templateID = [[dataDict valueForKey:@"template_id"] intValue];
    
    _autoresizeFlag = [[dataDict valueForKey:@"autoresize_flag"] intValue];
    
    _lineNoSubheading = [[dataDict valueForKey:@"line_number_subheading"] intValue];
    _lineNoMain = [[dataDict valueForKey:@"line_number_main"] intValue];
    _lineNoSub = [[dataDict valueForKey:@"line_number_sub"] intValue];
    
    _backgroundImageFullPath= [dataDict valueForKey:@"background_image"];
    if (_backgroundImageFullPath.length == 0) {
        _backgroundImageFullPath = @"";
    }
    
    
    _recordedSoundFullPath= [dataDict valueForKey:@"audio"];
    if (_recordedSoundFullPath.length == 0) {
        _recordedSoundFullPath = @"";
    }
    
    
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
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Answer_Tables SET answer_id=%d, title=\"%@\", main=?, sub=?, subheading=?, image=\"%@\", logo=\"%@\", css_id=%d, template_id=%d,autoresize_flag=%d,line_number_subheading=%d, line_number_main=%d, line_number_sub=%d, background_image=\"%@\",movie=\"%@\",audio=\"%@\"  WHERE card_id=%d", _answerID, _title, _imageFullPath, _logoFullPath, _cssID, _templateID,_autoresizeFlag, _lineNoSubheading,_lineNoMain, _lineNoSub,_backgroundImageFullPath,_movieFullPath,_recordedSoundFullPath,_cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    sqlite3_bind_text(queryStatement, 1, [_main UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 2, [_sub UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 3, [_subheading UTF8String], -1, SQLITE_TRANSIENT);
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        DDLogInfo(@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query);
        
    }
}

-(void)insert{
	if (_answerID == -1) {
		_answerID = [SQLiteHelper getMaxValueForColumn:@"answer_id" inTable:@"Answer_Tables"] + 1;
	}

    NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Answer_Tables(answer_id, card_id, title, main, sub, subheading, image, logo, css_id, template_id,autoresize_flag,line_number_subheading,line_number_main,line_number_sub,background_image,movie,audio) VALUES (%d, %d, \"%@\", ?, ?, ?, \"%@\", \"%@\", %d, %d, %d,%d, %d, %d,\"%@\",\"%@\",\"%@\")", _answerID, _cardID, _title, _imageFullPath, _logoFullPath, _cssID, _templateID,_autoresizeFlag,_lineNoSubheading,_lineNoMain, _lineNoSub,_backgroundImageFullPath,_movieFullPath,_recordedSoundFullPath];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    sqlite3_bind_text(queryStatement, 1, [_main UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 2, [_sub UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 3, [_subheading UTF8String], -1, SQLITE_TRANSIENT);
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        DDLogInfo(@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query);
        
    }
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
    BOOL isDir;
    if (![[self.logoFullPath lastPathComponent] isEqualToString:@"answer_placeholder_logo.jpg"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.logoFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.logoFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer logoFullPath"];
                DDLogError(@"%s:%@",__FUNCTION__,[error description]);
            }
        }
    }
    error = nil;
    if (![[self.imageFullPath lastPathComponent] isEqualToString:@"answer_placeholder_content.jpg"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.imageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer imageFullPath"];
                DDLogError(@"%s:%@",__FUNCTION__,[error description]);
            }
        }
    }
    
    error = nil;
    if (self.backgroundImageFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.backgroundImageFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.backgroundImageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer backgroundImageFullPath"];
                DDLogError(@"%s:%@",__FUNCTION__,[error description]);
            }
        }
    }
    
    error = nil;
    if (self.movieFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.movieFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.movieFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer movieFullPath"];
                DDLogError(@"%s:%@",__FUNCTION__,[error description]);
            }
        }
    }
    
    error = nil;
    if (self.recordedSoundFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.recordedSoundFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.recordedSoundFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer recordedSoundFullPath"];
                DDLogError(@"%s:%@",__FUNCTION__,[error description]);
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
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:9] forKey:@"template_id"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:10] forKey:@"line_number_subheading"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:11] forKey:@"line_number_main"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:12] forKey:@"line_number_sub"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:13] forKey:@"background_image"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:14] forKey:@"movie"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:15] forKey:@"audio"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:16] forKey:@"autoresize_flag"];
        
        [answerDict setValue:[CSS cssForCSSID:[[answerDict valueForKey:@"css_id"] intValue]] forKey:@"css"];
	}
	sqlite3_finalize(queryStatement);
	return answerDict;
}

@end
