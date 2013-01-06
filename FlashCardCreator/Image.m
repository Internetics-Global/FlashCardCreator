//
//  Image.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "Image.h"
#import "SQLiteHelper.h"

@implementation Image

@synthesize imageID = _imageID;
@synthesize imageFileName = _imageFileName;
@synthesize cardID = _cardID;
@synthesize isQuestionCard = _isQuestionCard;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _imageID = -1;
    _cardID = -1;
	return self;
}

#pragma mark -
#pragma mark Operation

+ (NSMutableArray *) imagesForCardID:(NSInteger)cardID {
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Image_Tables WHERE card_id=%d", cardID];
	sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
	NSMutableArray *returnArray = nil;
	while (sqlite3_step(queryStatement) == SQLITE_ROW) {
		if (returnArray == nil) {
			returnArray = [[NSMutableArray alloc] init];
		}
		NSMutableDictionary *imageDict = [[NSMutableDictionary alloc] init];
		[imageDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"image_id"];
		[imageDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"file_name"];
		[imageDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:2] forKey:@"card_id"];
        [imageDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:3] forKey:@"is_question_card"];
		[returnArray addObject:imageDict];
		[imageDict release];
	}
	sqlite3_finalize(queryStatement);
	return [returnArray autorelease];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    FCC_RELEASE_SAFELY(_imageFileName);
	[super dealloc];
}

@end



