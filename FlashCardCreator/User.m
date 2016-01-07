//
//  User.m
//  FFC
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "User.h"
#import "SQLiteHelper.h"
#import "Pack.h"
#import "FileOperationHelper.h"

@implementation User

@synthesize userID = _userID;
@synthesize nickName = _nickName;

@synthesize packs = _packs;

#pragma mark -
#pragma mark Initialization

-(id)init{
	self = [super init];
    _userID = -1;
    _packs = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserPacks:) name:UPDATE_USER_PACKS_LIST_NOTIFICATION object:nil];
    
	return self;
}

//used to get _userID, _nickName and _packs
-(id)initWithDictionary:(NSDictionary *)dict{
	if (!(self = [self init])) return nil;
    
    if ([[dict allKeys] containsObject:@"user_id"]) {
        _userID = [[dict valueForKey:@"user_id"] intValue];
    } else {
        _userID = -1;
    }
	_nickName = [dict valueForKey:@"nick_name"];
	if ([[dict allKeys] containsObject:@"packs"]) {
		NSArray *packsDictArray = (NSArray *)[dict valueForKey:@"packs"];
		for (int i = 0; i < [packsDictArray count]; i++) {
			Pack *newPack = [[Pack alloc] initWithDictionary:packsDictArray[i]];
			[_packs addObject:newPack];
		}
	} else {
       //[iConsole info:@"%s:no pack under current user",__FUNCTION__];
    }
	
    return self;
}

#pragma mark -
#pragma mark Operation

+(User *)defaultUser {
	static User *defaultUser;
	@synchronized(self){
		if (defaultUser == nil) {
			NSString *query = [[NSString alloc] initWithFormat:@"SELECT * FROM Users_Tables WHERE user_id=\"%@\"", GLOBAL_USER_ID];
			sqlite3_stmt *queryStatement = [SQLiteHelper prepareStatementForQuery:query];
			while (sqlite3_step(queryStatement) == SQLITE_ROW) {
				NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
				[dataDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:0] forKey:@"user_id"];
				[dataDict setValue:[SQLiteHelper getStringFromQuery:queryStatement inColumn:1] forKey:@"nick_name"];
				[dataDict setValue:[Pack packsForUserID:[[dataDict valueForKey:@"user_id"] intValue]] forKey:@"packs"];
				defaultUser = [[User alloc] initWithDictionary:dataDict];
                break;
			}
			sqlite3_finalize(queryStatement);
		}
	}
	return defaultUser;
}


-(void)addPack:(Pack *)pack{
	BOOL exists = NO;
	for (int i = 0; i < [_packs count]; i++) {
		if ([_packs[i] packID] == pack.packID) {
			exists = YES;
            [iConsole info:@"%s:addPack failure because already existence",__FUNCTION__];
			break;
		}
	}
    
    pack.userID = self.userID; //build table linkage in database
    
	if (!exists) {
		[_packs addObject:pack];
		[pack save];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:PACK_ADDED_TO_USER_NOTIFICATION object:self];
}


/**
 *  @deprecated This method is deprecated
 *  不再推荐这种方法，因为这种方法的缺点是pack必须是_packs中的某个成员，否则会有问题。曾经出现的一个事故是：pack是刚new的赋予了packID的值，这时就会有问题
 */
-(void)removePack:(Pack *)pack
{
	[_packs removeObject:pack];
	[pack destroy];
}

-(void)removePackWithPackID:(long)pack_id{
    for (Pack *item in _packs) {
        if (item.packID == pack_id) {
            [self removePack:item];
            return;
        }
    }
}

// Sort self.packs
- (void) sortPacks:(SortTypeEnum) sortType {
    
    NSArray *shuffledArray= [NSArray arrayWithArray:self.packs];
    

    switch (sortType) {
        case SortTypeLastCreatedAscend:
            
            shuffledArray = [self.packs sortedArrayUsingComparator:^NSComparisonResult(Pack *a, Pack *b) {
                return (a.createDate >= b.createDate);
            }];
            self.packs = [NSMutableArray arrayWithArray:shuffledArray];
            
            break;
        case SortTypeLastCreatedDescend:
            
            shuffledArray = [self.packs sortedArrayUsingComparator:^NSComparisonResult(Pack *a, Pack *b) {
                return (a.createDate <= b.createDate);
            }];
            self.packs = [NSMutableArray arrayWithArray:shuffledArray];

            break;
        case SortTypeLastVisitedAscend:
            
            shuffledArray = [self.packs sortedArrayUsingComparator:^NSComparisonResult(Pack *a, Pack *b) {
                return (a.lastVisitDate >= b.lastVisitDate);
            }];
            self.packs = [NSMutableArray arrayWithArray:shuffledArray];

            break;
        case SortTypeLastVisitedDescend:
            
            shuffledArray = [self.packs sortedArrayUsingComparator:^NSComparisonResult(Pack *a, Pack *b) {
                return (a.lastVisitDate <= b.lastVisitDate);
            }];
            self.packs = [NSMutableArray arrayWithArray:shuffledArray];

            break;
        case SortTypeDefault:
            //do nothing
            break;
            
        default:
            break;
    }
    
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
