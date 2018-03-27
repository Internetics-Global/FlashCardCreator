//
//  Emoticon.h
//  FFC
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    EmoticonTypeDefault,
    EmoticonTypeTaogongzai,
    EmoticonTypeCustom
}EmoticonType;

@interface Emoticon : NSObject{
    EmoticonType _type;
    NSString *_title;
    NSString *_code;
    UIImage *_image;
}

@property (nonatomic, assign) EmoticonType type;
@property (nonatomic, copy  ) NSString     *title;
@property (nonatomic, copy  ) NSString     *code;
@property (nonatomic, strong) UIImage      *image;

+ (Emoticon *)emoticonWithType:(EmoticonType)type title:(NSString *)title code:(NSString *)code image:(UIImage *)image;

@end
