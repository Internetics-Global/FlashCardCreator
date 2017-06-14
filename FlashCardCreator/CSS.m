//
//  CSS.m
//  FFC
//
//  Created by Wang Bourne on 8/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "CSS.h"
#import "SQLiteHelper.h"

@implementation CSS

@synthesize cssID = _cssID;

@synthesize subheadingAlign = _subheadingAlign;
@synthesize subheadingAlignVertical = _subheadingAlignVertical;
@synthesize subheadingColor = _subheadingColor;
@synthesize subheadingSize = _subheadingSize;
@synthesize subheadingFont = _subheadingFont;
@synthesize subheadingSemiTransparent = _subheadingSemiTransparent;
@synthesize subheadingText2SpeechSound = _subheadingText2SpeechSound;


@synthesize mainAlign = _mainAlign;
@synthesize mainAlignVertical = _mainAlignVertical;
@synthesize mainColor = _mainColor;
@synthesize mainSize = _mainSize;
@synthesize mainFont = _mainFont;
@synthesize mainSemiTransparent = _mainSemiTransparent;
@synthesize mainText2SpeechSound = _mainText2SpeechSound;

@synthesize subAlign = _subAlign;
@synthesize subAlignVertical = _subAlignVertical;
@synthesize subColor = _subColor;
@synthesize subSize = _subSize;
@synthesize subFont = _subFont;
@synthesize subSemiTransparent = _subSemiTransparent;
@synthesize subText2SpeechSound = _subText2SpeechSound;


#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _cssID = -1;
    
    _subheadingAlign = @"Center";
    _subheadingAlignVertical = @"";
    _subheadingColor = @"Black";
    _subheadingFont = @"";
    _subText2SpeechSound = @"";
    _subheadingSemiTransparent = false;
    
    _mainAlign = @"Center";
    _mainAlignVertical = @"";
    _mainColor = @"Black";
    _mainFont = @"";
    _mainText2SpeechSound = @"";
    _mainSemiTransparent = false;
    
    _subAlign = @"Center";
    _subAlignVertical = @"";
    _subColor = @"Black";
    _subFont = @"";
    _subText2SpeechSound = @"";
    _subSemiTransparent = false;
    
    if (isUserInterfaceIdiomPhone) {
        _subheadingSize = 14;
        _mainSize = 12;
        _subSize = 12;
    } else {
        _subheadingSize = 32;
        _mainSize = 28;
        _subSize = 28;
    }
    
    _subheadingText2SpeechSound = @"";
    _mainText2SpeechSound= @"";
    _subText2SpeechSound = @"";
    
    
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dataDict{
	if (!(self = [self init])) return nil;
    
	_cssID = [[dataDict valueForKey:@"css_id"] intValue];
    
    _subheadingSize = [[dataDict valueForKey:@"subheading_size"] intValue];
    _subheadingAlign = [dataDict valueForKey:@"subheading_align"];
    _subheadingAlignVertical = [dataDict valueForKey:@"subheading_align_vertical"];
    _subheadingColor= [dataDict valueForKey:@"subheading_color"];
    _subheadingText2SpeechSound= [dataDict valueForKey:@"subheading_text2speech"];
    _subheadingFont= [dataDict valueForKey:@"subheading_font"];
    if (IsEmpty(_subheadingFont)) {
        _subheadingFont = @"";
    }
    _subheadingSemiTransparent = [[dataDict valueForKey:@"subheading_semi_transparent"] integerValue] == 1;
    
    _mainSize = [[dataDict valueForKey:@"main_size"] intValue];
    _mainAlign = [dataDict valueForKey:@"main_align"];
    _mainAlignVertical = [dataDict valueForKey:@"main_align_vertical"];
    _mainColor= [dataDict valueForKey:@"main_color"];
    _mainFont= [dataDict valueForKey:@"main_font"];
    _mainText2SpeechSound= [dataDict valueForKey:@"main_text2speech"];
    if (IsEmpty(_mainFont)) {
        _mainFont = @"";
    }
    _mainSemiTransparent = [[dataDict valueForKey:@"main_semi_transparent"] integerValue] == 1;
    
    _subSize = [[dataDict valueForKey:@"sub_size"] intValue];
    _subAlign = [dataDict valueForKey:@"sub_align"];
    _subAlignVertical = [dataDict valueForKey:@"sub_align_vertical"];
    _subColor= [dataDict valueForKey:@"sub_color"];
    _subFont= [dataDict valueForKey:@"sub_font"];
    _subText2SpeechSound = [dataDict valueForKey:@"sub_text2speech"];
    if (IsEmpty(_subFont)) {
        _subFont = @"";
    }
    _subSemiTransparent = [[dataDict valueForKey:@"sub_semi_transparent"] integerValue] == 1;
    
	return self;
}

#pragma mark -
#pragma mark Operation

- (void)save{
	if (_cssID == -1) {
		[self performSelector:@selector(insert)];
	}else {
		if ([SQLiteHelper checkIntegerValueExists:_cssID forColumn:@"css_id" inTable:@"CSS_Tables"]) {
			[self performSelector:@selector(update)];
		}else {
			[self performSelector:@selector(insert)];
		}
	}
}

-(void)update{
    NSString *query = [[NSString alloc] initWithFormat:@"UPDATE CSS_Tables SET subheading_size=%d, subheading_align=\"%@\", subheading_color=\"%@\", main_size=%d, main_align=\"%@\", main_color=\"%@\",sub_size=%d, sub_align=\"%@\", sub_color=\"%@\" , subheading_font=\"%@\" , main_font=\"%@\" , sub_font=\"%@\", subheading_align_vertical=\"%@\", main_align_vertical=\"%@\", sub_align_vertical=\"%@\", subheading_semi_transparent=%d, main_semi_transparent=%d, sub_semi_transparent=%d, subheading_text2speech=\"%@\", main_text2speech=\"%@\", sub_text2speech=\"%@\" WHERE css_id=%ld", (int)_subheadingSize, _subheadingAlign, _subheadingColor, (int)_mainSize, _mainAlign, _mainColor, (int)_subSize, _subAlign, _subColor,_subheadingFont,_mainFont,_subFont, _subheadingAlignVertical,_mainAlignVertical,_subAlignVertical,_subheadingSemiTransparent?1:0,_mainSemiTransparent?1:0,_subSemiTransparent?1:0, _subheadingText2SpeechSound,_mainText2SpeechSound,_subText2SpeechSound,(long)_cssID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        [iConsole error:@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query];
        
    }
}

-(void)insert{
    if (_cssID == -1) {
        _cssID = [[NSDate date] timeIntervalSince1970];
        while ([SQLiteHelper checkIntegerValueExists:_cssID forColumn:@"css_id" inTable:@"CSS_Tables"]) {
            [iConsole error:@"%s:css has already existed, regenerate",__FUNCTION__];
            _cssID = [[NSDate date] timeIntervalSince1970] + arc4random()%1000;
            
        }
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO CSS_Tables(css_id, subheading_size, subheading_align, subheading_color, main_size, main_align, main_color, sub_size, sub_align, sub_color,subheading_font,main_font,sub_font,subheading_align_vertical,main_align_vertical,sub_align_vertical,subheading_semi_transparent,main_semi_transparent,sub_semi_transparent,subheading_text2speech,main_text2speech,sub_text2speech) VALUES (%ld,%d, \"%@\", \"%@\", %d, \"%@\", \"%@\", %d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %d, %d, %d, \"%@\", \"%@\", \"%@\")",(long)_cssID, (int)_subheadingSize, _subheadingAlign, _subheadingColor, (int)_mainSize, _mainAlign, _mainColor, (int)_subSize, _subAlign, _subColor,_subheadingFont,_mainFont,_subFont,_subheadingAlignVertical,_mainAlignVertical,_subAlignVertical,_subheadingSemiTransparent?1:0,_mainSemiTransparent?1:0,_subSemiTransparent?1:0,_subheadingText2SpeechSound,_mainText2SpeechSound,_subText2SpeechSound];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        [iConsole error:@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query];
        
    }
}

-(void)destroy{
	//Step1: delete from database
    NSString *query = [[NSString alloc] initWithFormat:@"DELETE FROM CSS_Tables WHERE css_id=%ld", (long)_cssID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);

}

+ (NSMutableDictionary *) cssForCSSID:(NSInteger)cssID {
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM CSS_Tables WHERE css_id=%ld",(long)cssID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	NSMutableDictionary *cssDict = [[NSMutableDictionary alloc] init];
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		[cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"css_id"];
		[cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"subheading_size"];
		[cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"subheading_align"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"subheading_color"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:4] forKey:@"main_size"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:5] forKey:@"main_align"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:6] forKey:@"main_color"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:7] forKey:@"sub_size"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:8] forKey:@"sub_align"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:9] forKey:@"sub_color"];
        
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:10] forKey:@"subheading_font"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:11] forKey:@"main_font"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:12] forKey:@"sub_font"];
        
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:13] forKey:@"subheading_align_vertical"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:14] forKey:@"main_align_vertical"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:15] forKey:@"sub_align_vertical"];
        
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:16] forKey:@"subheading_semi_transparent"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:17] forKey:@"main_semi_transparent"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:18] forKey:@"sub_semi_transparent"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:19] forKey:@"subheading_text2speech"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:20] forKey:@"main_text2speech"];
        [cssDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:21] forKey:@"sub_text2speech"];
	}
	sqlite3_finalize(queryStatement);
	return cssDict;
}


- (id)copyWithZone:(NSZone *)zone
{
    CSS *copy=[[[self class] allocWithZone:zone] init];
    
    copy.cssID = _cssID;
    
    copy.subheadingSize = _subheadingSize;
    copy.subheadingColor = _subheadingColor;
    copy.subheadingAlign = _subheadingAlign;
    copy.subheadingAlignVertical = _subheadingAlignVertical;
    copy.subheadingFont = _subheadingFont;
    copy.subheadingSemiTransparent = _subheadingSemiTransparent;
    copy.subheadingText2SpeechSound = _subheadingText2SpeechSound;
    
    copy.mainSize = _mainSize;
    copy.mainColor = _mainColor;
    copy.mainAlign = _mainAlign;
    copy.mainAlignVertical = _mainAlignVertical;
    copy.mainFont = _mainFont;
    copy.mainSemiTransparent = _mainSemiTransparent;
    copy.mainText2SpeechSound = _mainText2SpeechSound;
    
    copy.subSize = _subSize;
    copy.subColor = _subColor;
    copy.subAlign = _subAlign;
    copy.subAlignVertical = _subAlignVertical;
    copy.subFont = _subFont;
    copy.subSemiTransparent = _subSemiTransparent;
    copy.subText2SpeechSound = _subText2SpeechSound;
    
    return copy;
}

@end
