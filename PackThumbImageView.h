//
//  PackThumbImageView.h
//  PackList
//
//  Created by Wang Bourne on 5/01/13.
//  Copyright (c) 2013 temp. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PackThumbImageViewDelegate
@optional
- (void)ClickBegin:(NSInteger)imageTag;

@end

@interface PackThumbImageView : UIImageView {
    id<PackThumbImageViewDelegate> __weak _delegate;
}

@property (weak, nonatomic) id<PackThumbImageViewDelegate> delegate;

@end
