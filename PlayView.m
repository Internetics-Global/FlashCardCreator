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
        _closeButton.frame = CGRectMake(IPHONE_UI_WIDTH-40, 10, 30, 30);
        _scrollView.frame = CGRectMake(0, 15, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT-2*15);
    } else {
        _closeButton.frame = CGRectMake(IPAD_UI_WIDTH-40, 10, 30, 30);
        _scrollView.frame = CGRectMake(0, (IPAD_UI_HEIGHT-kFlashCardViewHeight_PlayMode_iPad)/2, IPAD_UI_WIDTH, kFlashCardViewHeight_PlayMode_iPad);
    }
    
    [self addSubview:_scrollView];
    [self addSubview:_closeButton];
    
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
    CGFloat curXLoc = (IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2;
    for (int index = 0; index < [[_currentPack cards] count]; index++)
	{
		//flash card height = scroll height; flash card width < scroll width 
        FlashCardView *cardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,0,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)];
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
	
	[_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPAD_UI_WIDTH), kFlashCardViewHeight_PlayMode_iPad)];
    
    
}

- (void)layoutScrollObjectsForiPhone
{
    [_cardArray removeAllObjects];
    CGFloat curXLoc = (IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2;
    float flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-kFlashCardViewHeight_PlayMode_iPhone)/2; //Since it's horizontal movement, so this is a constant value
    for (int index = 0; index < [[_currentPack cards] count]; index++)
	{
		//flash card height = scroll height; flash card width < scroll width
        FlashCardView *cardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPhone,kFlashCardViewHeight_PlayMode_iPhone)];
        cardView.tag = index;	// tag our images for later use when we place them in serial fashion
        cardView.currentCard = _currentCard;
		CGRect rect = cardView.frame;
        rect.origin = CGPointMake(curXLoc, flashCardYPositionInScrollView);
        cardView.frame = rect;
        [cardView disableCardEdit];
        [cardView refreshQuestionAnserView];
		[_scrollView addSubview:cardView];
        curXLoc += IPHONE_UI_WIDTH;
        [_cardArray addObject:cardView];
        
        
	}
	
	[_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPHONE_UI_WIDTH), kFlashCardViewHeight_PlayMode_iPhone)];
    
    
}

- (void) closePlayView {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [UIView transitionWithView:keyWindow duration:0.5 options: UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [self removeFromSuperview];
    } completion:nil];
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
