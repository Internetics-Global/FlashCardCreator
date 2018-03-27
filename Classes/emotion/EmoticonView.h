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

- (id)initWithEmoticon:(Emoticon *)emoticon atPage:(int) page;

@end
