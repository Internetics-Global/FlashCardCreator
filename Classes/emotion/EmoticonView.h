//
//  EmoticonView.h
//  FFC
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Emoticon.h"

@interface EmoticonView : UIView{
  Emoticon    *_emoticon;

  UIImageView *_emoticonView;
  UILabel     *_titleLabel;
}

/**
 *  在实际中，第一个page中有一个space bar需要特殊处理
 */
- (id)initWithEmoticon:(Emoticon *)emoticon atPage:(int) page;

@end
