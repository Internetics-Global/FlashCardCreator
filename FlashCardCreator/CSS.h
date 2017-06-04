//
//  CSS.h
//  FFC
//
//  Created by Wang Bourne on 8/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSS : NSObject {
    NSInteger _cssID;
    
    float _subheadingSize;
	NSString *_subheadingColor;
    NSString *_subheadingAlign;
    NSString *_subheadingAlignVertical;
    NSString *_subheadingFont;
    NSString *_subheadingText2SpeechSound;
    BOOL      _subheadingSemiTransparent;
    
    float _mainSize;
	NSString *_mainColor;
    NSString *_mainAlign;
    NSString *_mainAlignVertical;
    NSString *_mainFont;
    NSString *_mainText2SpeechSound;
    BOOL      _mainSemiTransparent;

    float _subSize;
	NSString *_subColor;
    NSString *_subAlign;
    NSString *_subAlignVertical;
    NSString *_subFont;
    NSString *_subText2SpeechSound;
    BOOL      _subSemiTransparent;
    
}

@property (nonatomic, assign) NSInteger cssID;

@property (nonatomic, assign) float subheadingSize;
@property (nonatomic, copy) NSString *subheadingColor;
@property (nonatomic, copy) NSString *subheadingAlign;
@property (nonatomic, copy) NSString *subheadingAlignVertical;
@property (nonatomic, copy) NSString *subheadingFont;
@property (nonatomic, copy) NSString *subheadingText2SpeechSound;
@property (nonatomic, assign) BOOL  subheadingSemiTransparent;

@property (nonatomic, assign) float mainSize;
@property (nonatomic, copy) NSString *mainColor;
@property (nonatomic, copy) NSString *mainAlign;
@property (nonatomic, copy) NSString *mainAlignVertical;
@property (nonatomic, copy) NSString *mainFont;
@property (nonatomic, copy) NSString *mainText2SpeechSound;
@property (nonatomic, assign) BOOL  mainSemiTransparent;

@property (nonatomic, assign) float subSize;
@property (nonatomic, copy) NSString *subColor;
@property (nonatomic, copy) NSString *subAlign;
@property (nonatomic, copy) NSString *subAlignVertical;
@property (nonatomic, copy) NSString *subFont;
@property (nonatomic, copy) NSString *subText2SpeechSound;
@property (nonatomic, assign) BOOL subSemiTransparent;


- (id)initWithDictionary:(NSDictionary *)dict;
- (void)save;
- (void)destroy;

+ (NSMutableDictionary *) cssForCSSID:(NSInteger)cssID;

- (id)copyWithZone:(NSZone *)zone;

@end
