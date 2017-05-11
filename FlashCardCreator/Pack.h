//
//  Pack.h
//  FFC
//
//  Created by Wang Bourne on 14/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

@interface Pack : NSObject {
    NSInteger _packID;
	NSString *_packName;
    NSString *_sidebarTitle;
    NSString *_coverImageURL;
	NSInteger _userID;
    NSString *_languageName;
    NSString *_creator; //we use OpenUDID to generate
    NSString *_creatorNickName; //User input this during creating pack
    NSString *_jobTitle;
    int       _lastVisitDate;
    int       _createDate;
    int       _autoPlaySpeed;  //in second
    NSMutableArray *_cards;
    
    NSString *_restorePassword; //used to re-clain the ownership
    
    NSString *_shareLink;
    NSString *_fileNameOnAWS;  //AWS or Dropbox
    
    NSString *_platform;
    
    /**
     *  当下载后，会判断是否允许share（false if maxDownloadCount = 1，且不是本人创建）
     */
    BOOL     _isAllowShare;
}

@property (nonatomic, assign                      ) NSInteger                      packID;
@property (nonatomic, copy                        ) NSString                       *packName;
@property (nonatomic, copy                        ) NSString                       *sidebarTitle;

/**
 *  完整path,而不是只是一个文件名
 */
@property (nonatomic, copy,getter=getCoverImageURL) NSString                       *coverImageURL;

@property (nonatomic, assign                      ) NSInteger                      userID;
@property (nonatomic, copy                        ) NSString                       *languageName;
@property (nonatomic, assign                      ) BOOL                           isPublic;
@property (nonatomic, strong                      ) NSMutableArray                 *cards;
@property (nonatomic, copy                        ) NSString                       *creator;
@property (nonatomic, copy                        ) NSString                       *creatorNickName;
@property (nonatomic, copy                        ) NSString                       *jobTitle;
@property (assign, nonatomic                      ) int                            createDate;
@property (assign, nonatomic                      ) int                            lastVisitDate;
@property (assign, nonatomic                      ) int                            autoPlaySpeed;

@property (nonatomic, copy                        ) NSString                       *restorePassword;

@property (nonatomic, copy                        ) NSString                       *shareLink;
@property (nonatomic, copy                        ) NSString                       *fileNameOnAWS;

@property (nonatomic, assign                      ) BOOL                           isAllowShare;

@property (nonatomic, copy                        ) NSString                       *platform;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)addCard:(Card *)card;
- (void)removeCard:(Card *)card;
- (void)save;
- (void)savePackOnly;
- (void)destroy;

- (NSMutableArray *)snOrderedCards;

+ (NSMutableArray *) packsForUserID:(NSInteger)userID;

- (void)insertCard:(Card *)card afterCardID:(int)cardID;

@end

