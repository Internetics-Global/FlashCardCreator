//
//  CSS.h
//  FlashCardCreator
//
//  Created by Wang Bourne on 8/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSS : NSObject {
    NSInteger _cssID;
    
    NSInteger _subheadingSize;
	NSString *_subheadingColor;
    NSString *_subheadingAlign;
    
    NSInteger _mainSize;
	NSString *_mainColor;
    NSString *_mainAlign;

    NSInteger _subSize;
	NSString *_subColor;
    NSString *_subAlign;
    
}

@property (nonatomic, assign) NSInteger cssID;

@property (nonatomic, assign) NSInteger subheadingSize;
@property (nonatomic, copy) NSString *subheadingColor;
@property (nonatomic, copy) NSString *subheadingAlign;

@property (nonatomic, assign) NSInteger mainSize;
@property (nonatomic, copy) NSString *mainColor;
@property (nonatomic, copy) NSString *mainAlign;

@property (nonatomic, assign) NSInteger subSize;
@property (nonatomic, copy) NSString *subColor;
@property (nonatomic, copy) NSString *subAlign;


- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableDictionary *) cssForCSSID:(NSInteger)cssID;

@end
