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
#import "Common.h"

@implementation Question

@synthesize questionID = _questionID;
@synthesize cardID = _cardID;
@synthesize cssID = _cssID;
@synthesize title = _title;
@synthesize main = _main;
@synthesize sub = _sub;
@synthesize subheading = _subheading;

@synthesize imageFullPath = _imageFullPath;
@synthesize movieFullPath = _movieFullPath;

@synthesize logoFullPath = _logoFullPath;
@synthesize logoURLLinkage = _logoURLLinkage;
@synthesize css = _css;
@synthesize templateID = _templateID;

@synthesize backgroundImageFullPath = _backgroundImageFullPath;
@synthesize recordedSoundFullPath = _recordedSoundFullPath;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _questionID = -1;
    _cardID = -1;
    _cssID = -1;
    _css = [[CSS alloc] init];
    _logoURLLinkage = @"http://www.";
    _templateID = 0;
    
    _imageFullPath = @"";
    _movieFullPath = @"";
    _logoFullPath = @"";
    
    _backgroundImageFullPath = @"";
    
    _recordedSoundFullPath = @"";
    
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
    if (_imageFullPath.length == 0) {
        _imageFullPath = @"";
    }
    _movieFullPath= [dataDict valueForKey:@"movie"];
    if (_movieFullPath.length == 0) {
        _movieFullPath = @"";
    }
    _logoFullPath= [dataDict valueForKey:@"logo"];
    _logoURLLinkage = [dataDict valueForKey:@"logo_url"];
    _templateID = [[dataDict valueForKey:@"template_id"] intValue];
    
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
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Question_Tables SET question_id=%d, title=\"%@\", main=?, sub=?, subheading=?, image=\"%@\", logo=\"%@\", logo_url=\"%@\", css_id=%d, template_id=%d, line_number_subheading=%d, line_number_main=%d, line_number_sub=%d, background_image=\"%@\",movie=\"%@\",audio=\"%@\" WHERE card_id=%d", _questionID, _title, _imageFullPath, _logoFullPath, _logoURLLinkage, _cssID,_templateID, _lineNoSubheading,_lineNoMain, _lineNoSub,_backgroundImageFullPath,_movieFullPath,_recordedSoundFullPath, _cardID];
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
	if (_questionID == -1) {
		_questionID = [SQLiteHelper getMaxValueForColumn:@"question_id" inTable:@"Question_Tables"] + 1;
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Question_Tables(question_id, card_id, title, main, sub, subheading, image, logo, logo_url,css_id,template_id,line_number_subheading,line_number_main,line_number_sub,background_image,movie,audio) VALUES (%d, %d, \"%@\", ?, ?, ?, \"%@\", \"%@\", \"%@\", %d, %d, %d, %d, %d, \"%@\",\"%@\",\"%@\")", _questionID, _cardID, _title, _imageFullPath, _logoFullPath, _logoURLLinkage, _cssID, _templateID,_lineNoSubheading,_lineNoMain, _lineNoSub,_backgroundImageFullPath,_movieFullPath,_recordedSoundFullPath];
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

-(void)destroy {
	//Step1: delete from database
    NSString *query = [[NSString alloc] initWithFormat:@"DELETE FROM Question_Tables WHERE card_id=%d", _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    
    //Step2: delted image resources
    NSError *error = nil;
    
    BOOL isDir;
    //For history reason, we share logo image common under the same package. This could introduce into some waste of space, but temporarily, we have to do it like this.
    if (0) {
        //We never delete placeholder imae
        if (![[self.logoFullPath lastPathComponent] isEqualToString:@"question_placeholder_logo.jpg"]) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.logoFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
                [[NSFileManager defaultManager] removeItemAtPath:self.logoFullPath error:&error];
                if (error) {
                    [Common alertViewCommon:@"Error when removing file of question logoFullPath"];
                    DDLogInfo(@"%s:%@",__FUNCTION__,[error description]);
                }
            }
        }
    }
    
    error = nil;
    if (![[self.imageFullPath lastPathComponent] isEqualToString:@"question_placeholder_content.jpg"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.imageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question imageFullPath"];
                DDLogInfo(@"%s:%@",__FUNCTION__,[error description]);
            }
        }
    }
    
    error = nil;
    if (self.backgroundImageFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.backgroundImageFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.backgroundImageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question backgroundImageFullPath"];
                DDLogInfo(@"%s:%@",__FUNCTION__,[error description]);
            }
        }
    }
    
    error = nil;
    if (self.movieFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.movieFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.movieFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question movieFullPath"];
                DDLogInfo(@"%s:%@",__FUNCTION__,[error description]);
            }
        }
    }
    
    error = nil;
    if (self.recordedSoundFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.recordedSoundFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.recordedSoundFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question recordedSoundFullPath"];
                DDLogInfo(@"%s:%@",__FUNCTION__,[error description]);
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
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:10] forKey:@"template_id"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:11] forKey:@"line_number_subheading"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:12] forKey:@"line_number_main"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:13] forKey:@"line_number_sub"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:14] forKey:@"background_image"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:15] forKey:@"movie"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:16] forKey:@"audio"];

        
        
        [questionDict setValue:[CSS cssForCSSID:[[questionDict valueForKey:@"css_id"] intValue]] forKey:@"css"];
	}
	sqlite3_finalize(queryStatement);
	return questionDict;
}



@end
