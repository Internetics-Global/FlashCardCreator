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

/*!
 @param type 表情类型
 @param title 表情的标题,用于指明表情的含义
 @param code 表情的代号,比如系统表情的发送和解析并不是以图片的方式进行的,而是通过代号替换的
 @param image 表情对应的图片
 */
+ (Emoticon *)emoticonWithType:(EmoticonType)type title:(NSString *)title code:(NSString *)code image:(UIImage *)image;

@end
