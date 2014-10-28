//
//  CSS.m
//  FlashCardCreator
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

@synthesize mainAlign = _mainAlign;
@synthesize mainAlignVertical = _mainAlignVertical;
@synthesize mainColor = _mainColor;
@synthesize mainSize = _mainSize;
@synthesize mainFont = _mainFont;

@synthesize subAlign = _subAlign;
@synthesize subAlignVertical = _subAlignVertical;
@synthesize subColor = _subColor;
@synthesize subSize = _subSize;
@synthesize subFont = _subFont;


#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _cssID = -1;
    
    _subheadingAlign = @"Center";
    _subheadingAlignVertical = @"";
    _subheadingColor = @"Black";
    _subheadingFont = @"";
    
    _mainAlign = @"Center";
    _mainAlignVertical = @"";
    _mainColor = @"Black";
    _mainFont = @"";
    
    _subAlign = @"Center";
    _subAlignVertical = @"";
    _subColor = @"Black";
    _subFont = @"";
    
    if (isUserInterfaceIdiomPhone) {
        _subheadingSize = 14;
        _mainSize = 12;
        _subSize = 12;
    } else {
        _subheadingSize = 32;
        _mainSize = 28;
        _subSize = 28;
    }
    
    
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dataDict{
	if (!(self = [self init])) return nil;
    
	_cssID = [[dataDict valueForKey:@"css_id"] intValue];
    
    _subheadingSize = [[dataDict valueForKey:@"subheading_size"] intValue];
    _subheadingAlign = [dataDict valueForKey:@"subheading_align"];
    _subheadingAlignVertical = [dataDict valueForKey:@"subheading_align_vertical"];
    _subheadingColor= [dataDict valueForKey:@"subheading_color"];
    _subheadingFont= [dataDict valueForKey:@"subheading_font"];
    if (IsEmpty(_subheadingFont)) {
        _subheadingFont = @"";
    }
    
    _mainSize = [[dataDict valueForKey:@"main_size"] intValue];
    _mainAlign = [dataDict valueForKey:@"main_align"];
    _mainAlignVertical = [dataDict valueForKey:@"main_align_vertical"];
    _mainColor= [dataDict valueForKey:@"main_color"];
    _mainFont= [dataDict valueForKey:@"main_font"];
    if (IsEmpty(_mainFont)) {
        _mainFont = @"";
    }
    
    _subSize = [[dataDict valueForKey:@"sub_size"] intValue];
    _subAlign = [dataDict valueForKey:@"sub_align"];
    _subAlignVertical = [dataDict valueForKey:@"sub_align_vertical"];
    _subColor= [dataDict valueForKey:@"sub_color"];
    _subFont= [dataDict valueForKey:@"sub_font"];
    if (IsEmpty(_subFont)) {
        _subFont = @"";
    }
    
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
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE CSS_Tables SET subheading_size=%d, subheading_align=\"%@\", subheading_color=\"%@\", main_size=%d, main_align=\"%@\", main_color=\"%@\",sub_size=%d, sub_align=\"%@\", sub_color=\"%@\" , subheading_font=\"%@\" , main_font=\"%@\" , sub_font=\"%@\", subheading_align_vertical=\"%@\", main_align_vertical=\"%@\", sub_align_vertical=\"%@\" WHERE css_id=%d", (int)_subheadingSize, _subheadingAlign, _subheadingColor, (int)_mainSize, _mainAlign, _mainColor, (int)_subSize, _subAlign, _subColor,_subheadingFont,_mainFont,_subFont, _subheadingAlignVertical,_mainAlignVertical,_subAlignVertical,_cssID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        DDLogError(@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query);
        
    }
}

-(void)insert{
	if (_cssID == -1) {
        _cssID = [[NSDate date] timeIntervalSince1970];
        
        while ([SQLiteHelper checkIntegerValueExists:_cssID forColumn:@"css_id" inTable:@"CSS_Tables"]) {
            DDLogError(@"%s:css has already existed, regenerate",__FUNCTION__);
            _cssID = [[NSDate date] timeIntervalSince1970] + 1;
            
        }
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO CSS_Tables(css_id, subheading_size, subheading_align, subheading_color, main_size, main_align, main_color, sub_size, sub_align, sub_color,subheading_font,main_font,sub_font,subheading_align_vertical,main_align_vertical,sub_align_vertical) VALUES (%d,%d, \"%@\", \"%@\", %d, \"%@\", \"%@\", %d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\")",_cssID, (int)_subheadingSize, _subheadingAlign, _subheadingColor, (int)_mainSize, _mainAlign, _mainColor, (int)_subSize, _subAlign, _subColor,_subheadingFont,_mainFont,_subFont,_subheadingAlignVertical,_mainAlignVertical,_subAlignVertical];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	int error = sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
    if ((error != SQLITE_OK)&&(error != SQLITE_DONE)) {
        DDLogError(@"%s:error (code = %d) to execute %@",__FUNCTION__,error,query);
        
    }
}

-(void)destroy{
	//Step1: delete from database
    NSString *query = [[NSString alloc] initWithFormat:@"DELETE FROM CSS_Tables WHERE css_id=%d", _cssID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);

}

+ (NSMutableDictionary *) cssForCSSID:(NSInteger)cssID {
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM CSS_Tables WHERE css_id=%d",cssID];
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
	}
	sqlite3_finalize(queryStatement);
	return cssDict;
}

@end
