//
//  Emoticon.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "Emoticon.h"

@implementation Emoticon
@synthesize type = _type;
@synthesize title = _title;
@synthesize code = _code;
@synthesize image = _image;

+ (Emoticon *)emoticonWithType:(EmoticonType)type title:(NSString *)title code:(NSString *)code image:(UIImage *)image{
    Emoticon *emoticon = [[Emoticon alloc] init];
    emoticon.type = type;
    emoticon.title = title;
    emoticon.code = code;
    emoticon.image = image;
    
    return emoticon;
}

@end
