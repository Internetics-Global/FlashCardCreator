//
//  EmoticonGridView.h
//  FFC
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Emoticon;
@class EmoticonPreviewView;
@protocol EmoticonGridViewDelegate;
@interface EmoticonGridView : UIView{
  NSInteger              _rowCount;
  NSInteger              _columnCount;

  CGSize                 _emoticonThumbSize;

  NSArray                *_emoticons;
  UIView                 *_gridContainerView;
  NSMutableArray         *_emoticonViews;

  UITapGestureRecognizer *_tapGestureRecognizer;
}

@property (nonatomic,assign ) int                      currentPage;
@property (nonatomic,assign ) CGSize                   emoticonThumbSize;
@property (nonatomic, assign) id<EmoticonGridViewDelegate> delegate;

- (id)initWithEmoticons:(NSArray *)emoticons width:(int)width atPage:(int) page;

@end

@protocol EmoticonGridViewDelegate <NSObject>

- (void)emoticonGridView:(EmoticonGridView *)emoticonGridView didSelectEmoticon:(Emoticon *)emoticon;

@end
