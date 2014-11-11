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
#import "FileOperationHelper.h"

@implementation Answer

@synthesize answerID = _answerID;
@synthesize cardID = _cardID;
@synthesize cssID = _cssID;
@synthesize title = _title;
@synthesize main = _main;
@synthesize sub = _sub;
@synthesize subheading = _subheading;

@synthesize imageFullPath = _imageFullPath;
@synthesize imageFullPath2 = _imageFullPath2;
@synthesize movieFullPath = _movieFullPath;
@synthesize movieFullPath2 = _movieFullPath2;

@synthesize logoFullPath = _logoFullPath;
@synthesize css = _css;
@synthesize templateID = _templateID;

@synthesize autoresizeFlag = _autoresizeFlag;

@synthesize backgroundImageFullPath = _backgroundImageFullPath;
@synthesize recordedSoundFullPath = _recordedSoundFullPath;

#pragma mark -
#pragma mark Initialization

- (NSString *)getImageFullPath {
    if (_imageFullPath.length == 0) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_imageFullPath lastPathComponent]];
        return fullPath;
    }
}

- (NSString *)getImageFullPath2 {
    if (_imageFullPath2.length == 0) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_imageFullPath2 lastPathComponent]];
        return fullPath;
    }
}

- (NSString *)getLogoFullPath {
    if (_logoFullPath.length == 0) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_logoFullPath lastPathComponent]];
        return fullPath;
    }
}

- (NSString *)getMovieFullPath {
    if (_movieFullPath.length == 0) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_movieFullPath lastPathComponent]];
        return fullPath;
    }
}

- (NSString *)getMovieFullPath2 {
    if (_movieFullPath2.length == 0) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_movieFullPath2 lastPathComponent]];
        return fullPath;
    }
}

- (void)setImageFullPath:(NSString *)imageFullPath {
    if (imageFullPath.length == 0) {
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[imageFullPath lastPathComponent]];
        _imageFullPath = fullPath;
    }
}

- (void)setImageFullPath2:(NSString *)imageFullPath2 {
    if (imageFullPath2.length == 0) {
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[imageFullPath2 lastPathComponent]];
        _imageFullPath2 = fullPath;
    }
    
}

- (void)setLogoFullPath:(NSString *)logoFullPath {
    if (logoFullPath.length == 0) {
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[logoFullPath lastPathComponent]];
        _logoFullPath = fullPath;
    }
}

- (void)setMovieFullPath:(NSString *)movieFullPath {
    if (movieFullPath.length == 0) {
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[movieFullPath lastPathComponent]];
        _movieFullPath = fullPath;
    }
}

- (void)setMovieFullPath2:(NSString *)movieFullPath2 {
    if (movieFullPath2.length == 0) {
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[movieFullPath2 lastPathComponent]];
        _movieFullPath2 = fullPath;
    }
}

-(id)init{
	self = [super init];
    _answerID = -1;
    _cardID = -1;
    _cssID = -1;
    _css = [[CSS alloc] init];
    _templateID = 0; //begin from 0
    
    _autoresizeFlag = 1; //表示允许
    
    _imageFullPath = @"";
    _imageFullPath2 = @"";
    _movieFullPath = @"";
    _movieFullPath2 = @"";
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
    self.imageFullPath= [dataDict valueForKey:@"image"];
    if (self.imageFullPath.length == 0) {
        self.imageFullPath = @"";
    }
    self.imageFullPath2= [dataDict valueForKey:@"image2"];
    if (self.imageFullPath2.length == 0) {
        self.imageFullPath2 = @"";
    }
    self.movieFullPath= [dataDict valueForKey:@"movie"];
    if (self.movieFullPath.length == 0) {
        self.movieFullPath = @"";
    }
    
    self.movieFullPath2= [dataDict valueForKey:@"movie2"];
    if (self.movieFullPath2.length == 0) {
        self.movieFullPath2 = @"";
    }
    
    self.logoFullPath= [dataDict valueForKey:@"logo"];
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
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Answer_Tables SET answer_id=%d, title=\"%@\", main=?, sub=?, subheading=?, image=\"%@\", image2=\"%@\", logo=\"%@\", css_id=%d, template_id=%d,autoresize_flag=%d,line_number_subheading=%d, line_number_main=%d, line_number_sub=%d, background_image=\"%@\",movie=\"%@\",movie2=\"%@\",audio=\"%@\"  WHERE card_id=%d", _answerID, _title, _imageFullPath, _imageFullPath2, _logoFullPath, _cssID, _templateID,_autoresizeFlag, _lineNoSubheading,_lineNoMain, _lineNoSub,_backgroundImageFullPath,_movieFullPath,_movieFullPath2,_recordedSoundFullPath,_cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    sqlite3_bind_text(queryStatement, 1, [_main UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 2, [_sub UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 3, [_subheading UTF8String], -1, SQLITE_TRANSIENT);
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        [iConsole info:@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query];
        
    }
}

-(void)insert{
	if (_answerID == -1) {
        _answerID = [[NSDate date] timeIntervalSince1970];
        
        while ([SQLiteHelper checkIntegerValueExists:_answerID forColumn:@"answer_id" inTable:@"Answer_Tables"]) {
            [iConsole error:@"%s:_answerID has already existed, regenerate",__FUNCTION__];
            _answerID = [[NSDate date] timeIntervalSince1970] + arc4random()%1000;
            
        }
	}

    NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Answer_Tables(answer_id, card_id, title, main, sub, subheading, image,image2, logo, css_id, template_id,autoresize_flag,line_number_subheading,line_number_main,line_number_sub,background_image,movie,movie2,audio) VALUES (%d, %d, \"%@\", ?, ?, ?, \"%@\",\"%@\", \"%@\", %d, %d, %d,%d, %d, %d,\"%@\",\"%@\",\"%@\",\"%@\")", _answerID, _cardID, _title, _imageFullPath, _imageFullPath2, _logoFullPath, _cssID, _templateID,_autoresizeFlag,_lineNoSubheading,_lineNoMain, _lineNoSub,_backgroundImageFullPath,_movieFullPath,_movieFullPath2,_recordedSoundFullPath];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    sqlite3_bind_text(queryStatement, 1, [_main UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 2, [_sub UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 3, [_subheading UTF8String], -1, SQLITE_TRANSIENT);
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        [iConsole info:@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query];
        
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
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    error = nil;
    if (![[self.imageFullPath lastPathComponent] isEqualToString:@"answer_placeholder_content.jpg"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.imageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer imageFullPath"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if (![[self.imageFullPath2 lastPathComponent] isEqualToString:@"answer_placeholder_content.jpg"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageFullPath2 isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.imageFullPath2 error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer imageFullPath2"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if (self.backgroundImageFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.backgroundImageFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.backgroundImageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer backgroundImageFullPath"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if (self.movieFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.movieFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.movieFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer movieFullPath"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if (self.movieFullPath2.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.movieFullPath2 isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.movieFullPath2 error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer movieFullPath2"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if (self.recordedSoundFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.recordedSoundFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.recordedSoundFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of answer recordedSoundFullPath"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    [self.css destroy];
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
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:7] forKey:@"image2"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:8] forKey:@"logo"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:9] forKey:@"css_id"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:10] forKey:@"template_id"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:11] forKey:@"line_number_subheading"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:12] forKey:@"line_number_main"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:13] forKey:@"line_number_sub"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:14] forKey:@"background_image"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:15] forKey:@"movie"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:16] forKey:@"movie2"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:17] forKey:@"audio"];
        [answerDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:18] forKey:@"autoresize_flag"];
        
        [answerDict setValue:[CSS cssForCSSID:[[answerDict valueForKey:@"css_id"] intValue]] forKey:@"css"];
	}
	sqlite3_finalize(queryStatement);
	return answerDict;
}

@end
