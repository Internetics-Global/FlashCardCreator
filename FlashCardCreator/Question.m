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
#import "FileOperationHelper.h"

@implementation Question

@synthesize questionID = _questionID;
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
@synthesize logoURLLinkage = _logoURLLinkage;
@synthesize css = _css;
@synthesize templateID = _templateID;

/**
 *  0：允许进行autoresize,否则不允许。默认可以的
 */
@synthesize autoresizeFlag = _autoresizeFlag;

@synthesize backgroundImageFullPath = _backgroundImageFullPath;
@synthesize recordedSoundFullPath = _recordedSoundFullPath;

#pragma mark -
#pragma mark Initialization

- (NSString *)getBackgroundImageFullPath {
    if (_backgroundImageFullPath.length == 0 || [Common isDirectoryFormat:_backgroundImageFullPath] ) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_backgroundImageFullPath lastPathComponent]];
        return fullPath;
    }
}

- (NSString *)getRecordedSoundFullPath {
    if (_recordedSoundFullPath.length == 0 || [Common isDirectoryFormat:_recordedSoundFullPath] ) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_recordedSoundFullPath lastPathComponent]];
        return fullPath;
    }
}


- (void)setBackgroundImageFullPath:(NSString *)backgroundImageFullPath {
    if (backgroundImageFullPath.length == 0 || [Common isDirectoryFormat:backgroundImageFullPath] ) {
        _backgroundImageFullPath = nil;
        //[iConsole error:@"%backgroundImageFullPath could not be nil or empty or directory",__FUNCTION__];
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[backgroundImageFullPath lastPathComponent]];
        _backgroundImageFullPath = fullPath;
    }
}

- (void)setRecordedSoundFullPath:(NSString *)recordedSoundFullPath {
    
    if (recordedSoundFullPath.length == 0 || [Common isDirectoryFormat:recordedSoundFullPath] ) {
        _recordedSoundFullPath = nil;
         //[iConsole error:@"%s:recordedSoundFullPath could not be nil or empty or directory",__FUNCTION__];
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[recordedSoundFullPath lastPathComponent]];
        _recordedSoundFullPath = fullPath;
    }
    
}

- (NSString *)getImageFullPath {
    if (_imageFullPath.length == 0 || [Common isDirectoryFormat:_imageFullPath] ) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_imageFullPath lastPathComponent]];
        return fullPath;
    }
}

- (NSString *)getImageFullPath2 {
    if (_imageFullPath2.length == 0 || [Common isDirectoryFormat:_imageFullPath2] ) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_imageFullPath2 lastPathComponent]];
        return fullPath;
    }
}

- (NSString *)getLogoFullPath {
    if (_logoFullPath.length == 0 || [Common isDirectoryFormat:_logoFullPath] ) {
        return nil;
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_logoFullPath lastPathComponent]];
        return fullPath;
    }
}

- (NSString *)getMovieFullPath {
    if (_movieFullPath.length == 0 || [Common isDirectoryFormat:_movieFullPath] ) {
        return nil;
    } else {
        if ([_movieFullPath rangeOfString:@"http"].location == NSNotFound) {
            NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_movieFullPath lastPathComponent]];
            return fullPath;
        } else {
            return _movieFullPath;
        }
        
    }
}

- (NSString *)getMovieFullPath2 {
    if (_movieFullPath2.length == 0 || [Common isDirectoryFormat:_movieFullPath2] ) {
        return nil;
    } else {
        if ([_movieFullPath2 rangeOfString:@"http"].location == NSNotFound) {
            NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[_movieFullPath2 lastPathComponent]];
            return fullPath;
        } else {
            return _movieFullPath2;
        }
        
    }
}

- (void)setImageFullPath:(NSString *)imageFullPath {
    if (imageFullPath.length == 0 || [Common isDirectoryFormat:imageFullPath] ) {
        [iConsole error:@"%s: imageFullPath could not be nil or empty or diectory",__FUNCTION__];
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[imageFullPath lastPathComponent]];
        _imageFullPath = fullPath;
    }
}

- (void)setImageFullPath2:(NSString *)imageFullPath2 {
    if (imageFullPath2.length == 0 || [Common isDirectoryFormat:imageFullPath2] ) {
        [iConsole error:@"%s: imageFullPath2 could not be nil or empty or directory",__FUNCTION__];
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[imageFullPath2 lastPathComponent]];
        _imageFullPath2 = fullPath;
    }
    
}

- (void)setLogoFullPath:(NSString *)logoFullPath {
    if (logoFullPath.length == 0 || [Common isDirectoryFormat:logoFullPath] ) {
        [iConsole error:@"%s: logoFullPath could not be nil or empty or directory",__FUNCTION__];
    } else {
        NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[logoFullPath lastPathComponent]];
        _logoFullPath = fullPath;
    }
}

- (void)setMovieFullPath:(NSString *)movieFullPath {
    if (movieFullPath.length == 0 || [Common isDirectoryFormat:movieFullPath] ) {
        [iConsole error:@"%s: movieFullPath could not be nil or empty or directory",__FUNCTION__];
    } else {
        //we don't do conversion when its an http/https url
        if ([movieFullPath rangeOfString:@"http"].location == NSNotFound) {
            NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[movieFullPath lastPathComponent]];
            _movieFullPath = fullPath;
        } else {
            _movieFullPath = movieFullPath;
        }
        
    }
}

- (void)setMovieFullPath2:(NSString *)movieFullPath2 {
    if (movieFullPath2.length == 0 || [Common isDirectoryFormat:movieFullPath2]) {
        [iConsole error:@"%s: movieFullPath2 could not be nil or empty or directory",__FUNCTION__];
    } else {
        if ([movieFullPath2 rangeOfString:@"http"].location == NSNotFound) {
            NSString *fullPath = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[movieFullPath2 lastPathComponent]];
            _movieFullPath2 = fullPath;
        } else {
            _movieFullPath2 = movieFullPath2;
        }
        
    }
}

-(id)init{
	self = [super init];
    _questionID = -1;
    _cardID = -1;
    _cssID = -1;
    _css = [[CSS alloc] init];
    _logoURLLinkage = @"http://www.";
    _templateID = 0;
    
    _autoresizeFlag = 1; //表示允许
    
    _imageFullPath = @"";
    _imageFullPath2 = @"";
    _movieFullPath = @"";
    _movieFullPath2 = @"";
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
    _logoURLLinkage = [dataDict valueForKey:@"logo_url"];
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
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Question_Tables SET question_id=%d, title=\"%@\", main=?, sub=?, subheading=?, image=\"%@\", image2=\"%@\", logo=\"%@\", logo_url=\"%@\", css_id=%d, template_id=%d, autoresize_flag=%d, line_number_subheading=%d, line_number_main=%d, line_number_sub=%d, background_image=\"%@\",movie=\"%@\",movie2=\"%@\",audio=\"%@\" WHERE card_id=%d", _questionID, _title, _imageFullPath, _imageFullPath2, _logoFullPath, _logoURLLinkage, _cssID,_templateID,_autoresizeFlag, _lineNoSubheading,_lineNoMain, _lineNoSub,_backgroundImageFullPath,_movieFullPath,_movieFullPath2,_recordedSoundFullPath, _cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    sqlite3_bind_text(queryStatement, 1, [_main UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 2, [_sub UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 3, [_subheading UTF8String], -1, SQLITE_TRANSIENT);
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        [iConsole error:@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query];

    }
}

-(void)insert{
	if (_questionID == -1) {
		_questionID = [[NSDate date] timeIntervalSince1970];
        
        while ([SQLiteHelper checkIntegerValueExists:_questionID forColumn:@"question_id" inTable:@"Question_Tables"]) {
            [iConsole error:@"%s:_questionID has already existed, regenerate",__FUNCTION__];
            _questionID = [[NSDate date] timeIntervalSince1970]+ arc4random()%1000;
            
        }
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Question_Tables(question_id, card_id, title, main, sub, subheading, image, image2, logo, logo_url,css_id,template_id,autoresize_flag,line_number_subheading,line_number_main,line_number_sub,background_image,movie,movie2,audio) VALUES (%d, %d, \"%@\", ?, ?, ?, \"%@\", \"%@\", \"%@\", \"%@\", %d, %d, %d, %d, %d, %d, \"%@\",\"%@\",\"%@\",\"%@\")", _questionID, _cardID, _title, _imageFullPath,_imageFullPath2, _logoFullPath, _logoURLLinkage, _cssID, _templateID,_autoresizeFlag,_lineNoSubheading,_lineNoMain, _lineNoSub,_backgroundImageFullPath,_movieFullPath,_movieFullPath2,_recordedSoundFullPath];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
    sqlite3_bind_text(queryStatement, 1, [_main UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 2, [_sub UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(queryStatement, 3, [_subheading UTF8String], -1, SQLITE_TRANSIENT);
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        [iConsole error:@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query];
        
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
        //We never delete placeholder image
        if ([Common isPlaceholderFilePathOrDirectory:self.logoFullPath] == FALSE) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.logoFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
                [[NSFileManager defaultManager] removeItemAtPath:self.logoFullPath error:&error];
                if (error) {
                    [Common alertViewCommon:@"Error when removing file of question logoFullPath"];
                    [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
                }
            }
        }
    }
    
    error = nil;
    if ([Common isPlaceholderFilePathOrDirectory:self.imageFullPath] == FALSE) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.imageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question imageFullPath"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if ([Common isPlaceholderFilePathOrDirectory:self.imageFullPath2] == FALSE) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageFullPath2 isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.imageFullPath2 error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question imageFullPath2"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if (self.backgroundImageFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.backgroundImageFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.backgroundImageFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question backgroundImageFullPath"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if (self.movieFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.movieFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.movieFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question movieFullPath"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if (self.movieFullPath2.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.movieFullPath2 isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.movieFullPath2 error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question movieFullPath2"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    error = nil;
    if (self.recordedSoundFullPath.length >0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.recordedSoundFullPath isDirectory:&isDir]  && (isDir  == FALSE)) {
            [[NSFileManager defaultManager] removeItemAtPath:self.recordedSoundFullPath error:&error];
            if (error) {
                [Common alertViewCommon:@"Error when removing file of question recordedSoundFullPath"];
                [iConsole error:@"%s:%@",__FUNCTION__,[error description]];
            }
        }
    }
    
    [self.css destroy];
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
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:7] forKey:@"image2"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:8] forKey:@"logo"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:9] forKey:@"logo_url"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:10] forKey:@"css_id"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:11] forKey:@"template_id"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:12] forKey:@"line_number_subheading"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:13] forKey:@"line_number_main"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:14] forKey:@"line_number_sub"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:15] forKey:@"background_image"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:16] forKey:@"movie"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:17] forKey:@"movie2"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:18] forKey:@"audio"];
        [questionDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:19] forKey:@"autoresize_flag"];

        
        
        [questionDict setValue:[CSS cssForCSSID:[[questionDict valueForKey:@"css_id"] intValue]] forKey:@"css"];
	}
	sqlite3_finalize(queryStatement);
	return questionDict;
}



@end
