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
@synthesize subheadingColor = _subheadingColor;
@synthesize subheadingSize = _subheadingSize;

@synthesize mainAlign = _mainAlign;
@synthesize mainColor = _mainColor;
@synthesize mainSize = _mainSize;

@synthesize subAlign = _subAlign;
@synthesize subColor = _subColor;
@synthesize subSize = _subSize;


#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _cssID = -1;
    
    _subheadingAlign = @"Center";
    _subheadingColor = @"Black";
    
    _mainAlign = @"Center";
    _mainColor = @"Black";
    
    _subAlign = @"Center";
    _subColor = @"Black";
    
    if (isUserInterfaceIdiomPhone) {
        _subheadingSize = 14;
        _mainSize = 12;
        _subSize = 12;
    } else {
        _subheadingSize = 34;
        _mainSize = 30;
        _subSize = 30;
    }
    
    
	return self;
}

-(id)initWithDictionary:(NSDictionary *)dataDict{
	if (!(self = [self init])) return nil;
    
	_cssID = [[dataDict valueForKey:@"css_id"] intValue];
    
    _subheadingSize = [[dataDict valueForKey:@"subheading_size"] intValue];
    _subheadingAlign = [dataDict valueForKey:@"subheading_align"];
    _subheadingColor= [dataDict valueForKey:@"subheading_color"];
    
    _mainSize = [[dataDict valueForKey:@"main_size"] intValue];
    _mainAlign = [dataDict valueForKey:@"main_align"];
    _mainColor= [dataDict valueForKey:@"main_color"];
    
    _subSize = [[dataDict valueForKey:@"sub_size"] intValue];
    _subAlign = [dataDict valueForKey:@"sub_align"];
    _subColor= [dataDict valueForKey:@"sub_color"];
    
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
	NSString *query = [[NSString alloc] initWithFormat:@"UPDATE CSS_Tables SET subheading_size=%d, subheading_align=\"%@\", subheading_color=\"%@\", main_size=%d, main_align=\"%@\", main_color=\"%@\",sub_size=%d, sub_align=\"%@\", sub_color=\"%@\" WHERE css_id=%d", _subheadingSize, _subheadingAlign, _subheadingColor, _mainSize, _mainAlign, _mainColor, _subSize, _subAlign, _subColor, _cssID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
}

-(void)insert{
	if (_cssID == -1) {
		_cssID = [SQLiteHelper getMaxValueForColumn:@"css_id" inTable:@"CSS_Tables"] + 1;
	}
	NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO CSS_Tables(css_id, subheading_size, subheading_align, subheading_color, main_size, main_align, main_color, sub_size, sub_align, sub_color) VALUES (%d,%d, \"%@\", \"%@\", %d, \"%@\", \"%@\", %d, \"%@\", \"%@\")",_cssID, _subheadingSize, _subheadingAlign, _subheadingColor, _mainSize, _mainAlign, _mainColor, _subSize, _subAlign, _subColor];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	sqlite3_step(queryStatement);
	sqlite3_finalize(queryStatement);
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
	}
	sqlite3_finalize(queryStatement);
	return cssDict;
}

@end
