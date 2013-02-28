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
#import "NSArray+Randomised.h"
#import <CoreMotion/CoreMotion.h>

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
        _flashCardViewArray = [NSMutableArray array];
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
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.clipsToBounds = YES;
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.delegate = self;
    _scrollView.bounces = YES;
    _scrollView.backgroundColor =[UIColor clearColor];
    
    if (isUserInterfaceIdiomPhone){
        _closeButton.frame = CGRectMake(IPHONE_UI_WIDTH-30, 10, 20, 20);
        _scrollView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT);
    } else {
        _closeButton.frame = CGRectMake(IPAD_UI_WIDTH-40, 10, 30, 30);
        _scrollView.frame = CGRectMake(0, 0, IPAD_UI_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
    }
    
    [self addSubview:_scrollView];
    [self addSubview:_closeButton];
    
    NSArray *shuffledCardArray = nil;
    BOOL isRandomPlayMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRandomPlayMode"];
    if (isRandomPlayMode == YES) {
        shuffledCardArray = [[_currentPack cards] randomised];
    } else {
        //Bubble sorting
        shuffledCardArray = [[_currentPack cards] cardSNOrdered];
    }
    
    if (isUserInterfaceIdiomPhone) {
        [self layoutScrollObjectsForiPhone:shuffledCardArray];
    } else {
        [self layoutScrollObjectsForiPad:shuffledCardArray];
    }
    
    //Set  _currentFlashCardView
    _currentFlashCardView = (FlashCardView *)_flashCardViewArray[0];
    
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc]init];    
    }
    
    static BOOL enableSwitch = YES;
    
    _motionManager.deviceMotionUpdateInterval =1.0/60;
    if (_motionManager.isDeviceMotionAvailable) {
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            //NSLog(@"The roll of gyro sensor is:%f",motion.attitude.roll);
            if (motion.attitude.roll < -0.30) {
                if (enableSwitch == YES) {
                    [self switchQuestionAnswerView];
                    enableSwitch = NO;
                }
                
            } else if (motion.attitude.roll > 0) {
                if (enableSwitch == NO) {
                    enableSwitch = YES;
                }
                
            } else {
                //do nothing
            }
            
        }];
    } else {
        NSLog(@"%s:the gyro sensor is not available",__FUNCTION__);
    }
}

- (void)layoutScrollObjectsForiPad:(NSArray *)cardArray
{
    [_flashCardViewArray removeAllObjects];
    CGFloat curXLoc = (IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2;
    for (int index = 0; index < [cardArray count]; index++)
	{
		//flash card height = scroll height; flash card width < scroll width
        CGFloat flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_PlayMode_iPad)/2+IPAD_UI_NAVIGATION_BAR_HEIGHT; //Since it's horizontal movement, so this
        FlashCardView *cardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)];
        cardView.currentPack = _currentPack;
        cardView.currentCard = cardArray[index];
		CGRect rect = cardView.frame;
        rect.origin = CGPointMake(curXLoc, flashCardYPositionInScrollView);
        cardView.frame = rect;
        [cardView refreshQuestionAnserView];
        [cardView disableCardEdit];
        [cardView.segmentedControl setHidden:YES];
		[_scrollView addSubview:cardView];
        curXLoc += IPAD_UI_WIDTH;
        [_flashCardViewArray addObject:cardView];
	}
	
	[_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPAD_UI_WIDTH), kFlashCardViewHeight_PlayMode_iPad)];
}

- (void)layoutScrollObjectsForiPhone:(NSArray *)cardArray
{
    [_flashCardViewArray removeAllObjects];
    CGFloat curXLoc = (IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2;
    float flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-kFlashCardViewHeight_PlayMode_iPhone)/2; //Since it's horizontal movement, so this is a constant value
    for (int index = 0; index < [cardArray count]; index++)
	{
		//flash card height = scroll height; flash card width < scroll width
        FlashCardView *cardView = [[FlashCardView alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPhone,kFlashCardViewHeight_PlayMode_iPhone)];;
        cardView.currentPack = _currentPack;
        cardView.currentCard = cardArray[index];
		CGRect rect = cardView.frame;
        rect.origin = CGPointMake(curXLoc, flashCardYPositionInScrollView);
        cardView.frame = rect;
        [cardView refreshQuestionAnserView];
        [cardView disableCardEdit];
        [cardView.segmentedControl setHidden:YES];
		[_scrollView addSubview:cardView];
        curXLoc += IPHONE_UI_WIDTH;
        [_flashCardViewArray addObject:cardView];
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
    _currentFlashCardView = (FlashCardView *)_flashCardViewArray[page];
}


- (void) landscapeLeftRightOrientationChanged:(NSNotification *)notification{
        
    [self.superview bringSubviewToFront:self];
}

- (void) switchQuestionAnswerView {
    if (_currentFlashCardView) {
        if (_currentFlashCardView.segmentedControl.selectedSegmentIndex == 1) {
            [_currentFlashCardView.segmentedControl setSelectedSegmentIndex:0];
            [_currentFlashCardView segmentAction:_currentFlashCardView.segmentedControl];
        } else {
            [_currentFlashCardView.segmentedControl setSelectedSegmentIndex:1];
            [_currentFlashCardView segmentAction:_currentFlashCardView.segmentedControl];
        }
    } else {
        NSLog(@"%s:current FlashCardView is empty",__FUNCTION__);
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

                            

@end
