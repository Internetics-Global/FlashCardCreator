//
//  EmoticonSelectionViewController.h
//  FlashCardCreator
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EmoticonGridView.h"

@class ColorPageControl;
@class Emoticon;
@protocol EmoticonSelectionViewControllerDelegate;

@interface EmoticonSelectionViewController : UIViewController <UIScrollViewDelegate,EmoticonGridViewDelegate>{
    NSArray *_emoticons;

    NSInteger _emoticonRowCount;
    NSInteger _emoticonColumnCount;
    
    UIScrollView *_emoticonScrollView;
    ColorPageControl *_pageControl;
    
    NSMutableArray *_emoticonGridViews;
}

@property (nonatomic, assign) id<EmoticonSelectionViewControllerDelegate> delegate;

- (id)initWithEmoticons:(NSArray *)emoticons rowCount:(NSInteger)rowCount columnCount:(NSInteger)columnCount;

@end


@protocol EmoticonSelectionViewControllerDelegate <NSObject>

- (void)emoticonSelectionViewController:(EmoticonSelectionViewController *)emoticonSelectionViewController didSelectEmoticon:(Emoticon *)emoticon;

@end
