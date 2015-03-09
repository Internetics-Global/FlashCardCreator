//
//  EmoticonSelectionViewController.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 22/06/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "EmoticonSelectionViewController.h"
#import "ColorPageControl.h"

@implementation EmoticonSelectionViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIViewController

- (void)dealloc{
    
    [_emoticonGridViews makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    _emoticonScrollView.delegate = nil;
}


- (id)initWithEmoticons:(NSArray *)emoticons rowCount:(NSInteger)rowCount columnCount:(NSInteger)columnCount{
    if (self = [super initWithNibName:nil bundle:nil]) {
        //_emoticons = [emoticons retain];
        _emoticons = emoticons;
        _emoticonRowCount = rowCount;
        _emoticonColumnCount = columnCount;
        
        _emoticonGridViews = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)layoutEmotions{
    self.view.backgroundColor = [UIColor colorWithRed:213/255.0 green:215/255.0 blue:217/255.0 alpha:1];
    
    UIView *sepatator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 1)];
    sepatator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    sepatator.backgroundColor = [UIColor colorWithRed:175/255.0 green:179/255.0 blue:182/255.0 alpha:1];
    [self.view addSubview:sepatator];
    
    NSInteger emoticonsPerPage = _emoticonRowCount * _emoticonColumnCount;
    NSInteger pageCount = ceilf([_emoticons count]/(emoticonsPerPage*1.0));
    
    CGRect scrollViewFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    _emoticonScrollView = [[UIScrollView alloc] initWithFrame:scrollViewFrame];
    _emoticonScrollView.clipsToBounds = NO;
    _emoticonScrollView.showsHorizontalScrollIndicator = NO;
    _emoticonScrollView.showsVerticalScrollIndicator = NO;
    _emoticonScrollView.delegate = self;
    _emoticonScrollView.pagingEnabled = YES;
    //_emoticonScrollView.backgroundColor = [UIColor blueColor]
    _emoticonScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
    _emoticonScrollView.contentSize = CGSizeMake(self.view.bounds.size.width * pageCount, self.view.bounds.size.height);
    [self.view addSubview:_emoticonScrollView];
    
    _pageControl = [[ColorPageControl alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 20, self.view.bounds.size.width, 20)];
    _pageControl.numberOfPages = pageCount;
    _pageControl.normalPageColor = [UIColor colorWithRed:128/255.0 green:138/255.0 blue:151/255.0 alpha:1];
    _pageControl.currentPageColor = [UIColor whiteColor];
    _pageControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
    _pageControl.hidesForSinglePage = YES;
    _pageControl.width = 7;
    _pageControl.height = 7;
    _pageControl.gap = 10;
    
    [self.view addSubview:_pageControl];
    
    
    int screenWidth = [Common getScreenWidthInLandscape];

    NSRange subRange = NSMakeRange(0, emoticonsPerPage);
    for (int i = 0 ; i < pageCount ; i ++) {
        if (subRange.location + subRange.length > [_emoticons count]) {
            subRange.length = [_emoticons count] - subRange.location;
        }
        
        NSArray *subArray = [_emoticons subarrayWithRange:subRange];
        EmoticonGridView *emoticonGridView = [[EmoticonGridView alloc] initWithEmoticons:subArray atPage:i];
        emoticonGridView.delegate = self;
        //emoticonGridView.backgroundColor = [UIColor redColor];
        emoticonGridView.frame = CGRectOffset(_emoticonScrollView.bounds, i * screenWidth, 0) ;
        [_emoticonGridViews addObject:emoticonGridView];
        [_emoticonScrollView addSubview:emoticonGridView];
        
        subRange.location = subRange.location + subRange.length;
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [_emoticonGridViews removeAllObjects];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat pageWidth = sender.frame.size.width;
    int page = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _pageControl.currentPage = page;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark EmoticonGridViewDelegate
- (void)emoticonGridView:(EmoticonGridView *)emoticonGridView didSelectEmoticon:(Emoticon *)emoticon{
    if ([self.delegate respondsToSelector:@selector(emoticonSelectionViewController:didSelectEmoticon:)]) {
        [self.delegate emoticonSelectionViewController:self didSelectEmoticon:emoticon];
    }
}
@end
