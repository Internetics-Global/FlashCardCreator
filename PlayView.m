//
//  PlayView.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 25/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "PlayView.h"
#import "FlashCardView.h"
#import "Pack.h"
#import "Card.h"

#define kFlashCardViewWidth_iPad     800
#define kFlashCardViewHeight_iPad    640     //Also is the scroll view's height

#define kFlashCardViewWidth_iPhone   ((IPHONE_UI_WIDTH) - 80)
#define kFlashCardViewHeight_iPhone    300     //Also is the scroll view's height

@implementation PlayView

@synthesize currentCard = _currentCard;
@synthesize currentPack = _currentPack;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _scrollView = [[UIScrollView alloc] init];
        _cardArray = [NSMutableArray array];
        _currentFlashCardView = [[FlashCardView alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(landscapeLeftRightOrientationChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeButton.backgroundColor = [UIColor clearColor];
    [_closeButton setImage:[UIImage imageNamed:@"close_button.png"] forState:UIControlStateNormal];
    _closeButton.titleLabel.text = nil;
    [_closeButton addTarget:self action:@selector(closePlayView) forControlEvents:UIControlEventTouchDown];
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.clipsToBounds = YES;
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.delegate = self;
    _scrollView.backgroundColor =[UIColor clearColor];
    
    if (isUserInterfaceIdiomPhone){
        _closeButton.frame = CGRectMake(IPHONE_UI_WIDTH-30, 10, 20, 20);
        _scrollView.frame = CGRectMake(0, 30, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT-2*30);
    } else {
        _closeButton.frame = CGRectMake(IPAD_UI_WIDTH-40, 10, 30, 30);
        _scrollView.frame = CGRectMake(0, (IPAD_UI_HEIGHT-kFlashCardViewHeight_iPad)/2, IPAD_UI_WIDTH, kFlashCardViewHeight_iPad);
    }
    
    [self addSubview:_closeButton];
    [self addSubview:_scrollView];
    
    if (isUserInterfaceIdiomPhone) {
        [self layoutScrollObjectsForiPhone];
    } else {
        [self layoutScrollObjectsForiPad];
    }
    
    //Set  _currentFlashCardView
    _currentFlashCardView = (FlashCardView *)_cardArray[0];
    
}

- (void)layoutScrollObjectsForiPad
{
    [_cardArray removeAllObjects];
    CGFloat curXLoc = (IPAD_UI_WIDTH-kFlashCardViewWidth_iPad)/2;
    for (int index = 0; index < [[_currentPack cards] count]; index++)
	{
		//flash card height = scroll height; flash card width < scroll width 
        FlashCardView *cardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_iPad)/2,0,kFlashCardViewWidth_iPad,kFlashCardViewHeight_iPad)];
        cardView.tag = index;	// tag our images for later use when we place them in serial fashion
        cardView.currentCard = [_currentPack cards][index];
		CGRect rect = cardView.frame;
        rect.origin = CGPointMake(curXLoc, 0);
        cardView.frame = rect;
        [cardView disableCardEdit];
        [cardView refreshQuestionAnserView];
		[_scrollView addSubview:cardView];
        curXLoc += IPAD_UI_WIDTH;
        [_cardArray addObject:cardView];
        
        
	}
	
	[_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPAD_UI_WIDTH), kFlashCardViewHeight_iPad)];
    
    
}

- (void)layoutScrollObjectsForiPhone
{
    [_cardArray removeAllObjects];
    CGFloat curXLoc = (IPHONE_UI_WIDTH-kFlashCardViewWidth_iPhone)/2;
    for (int index = 0; index < [[_currentPack cards] count]; index++)
	{
		//flash card height = scroll height; flash card width < scroll width
        FlashCardView *cardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_iPhone)/2,0,kFlashCardViewWidth_iPhone,kFlashCardViewHeight_iPhone)];
        cardView.tag = index;	// tag our images for later use when we place them in serial fashion
        cardView.currentCard = _currentCard;
		CGRect rect = cardView.frame;
        rect.origin = CGPointMake(curXLoc, 0);
        cardView.frame = rect;
        [cardView disableCardEdit];
        [cardView refreshQuestionAnserView];
		[_scrollView addSubview:cardView];
        curXLoc += IPHONE_UI_WIDTH;
        [_cardArray addObject:cardView];
        
        
	}
	
	[_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPHONE_UI_WIDTH), kFlashCardViewHeight_iPhone)];
    
    
}

- (void) closePlayView {
    [self removeFromSuperview];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    NSLog (@"current page is :%d", page);
    _currentFlashCardView = (FlashCardView *)_cardArray[page];
}


- (void) landscapeLeftRightOrientationChanged:(NSNotification *)notification{
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
        if (_currentFlashCardView) {
            if (_currentFlashCardView.segmentedControl.selectedSegmentIndex == 0) {
                [_currentFlashCardView.segmentedControl setSelectedSegmentIndex:1];
                [_currentFlashCardView segmentAction:_currentFlashCardView.segmentedControl];
            }
        } else {
            NSLog(@"%s:current FlashCardView is empty",__FUNCTION__);
        }
    }
    
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
        if (_currentFlashCardView) {
            if (_currentFlashCardView.segmentedControl.selectedSegmentIndex == 1) {
                [_currentFlashCardView.segmentedControl setSelectedSegmentIndex:0];
                [_currentFlashCardView segmentAction:_currentFlashCardView.segmentedControl];
            }
        } else {
            NSLog(@"%s:current FlashCardView is empty",__FUNCTION__);
        }
    }
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
