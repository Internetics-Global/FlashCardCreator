//
//  PlayViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 2/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "PlayViewController.h"
#import "FlashCard.h"
#import "Pack.h"
#import "Card.h"
#import "NSArray+Randomised.h"
#import <CoreMotion/CoreMotion.h>

@interface PlayViewController ()

@end

@implementation PlayViewController

@synthesize currentCard = _currentCard;
@synthesize currentPack = _currentPack;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _scrollView = [[UIScrollView alloc] init];
        _flashCardViewArray = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(landscapeLeftRightOrientationChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc]init];
    }
    
    static BOOL enableSwitch = YES;
    
    _motionManager.deviceMotionUpdateInterval =0.01;
    if (_motionManager.isDeviceMotionAvailable) {
        [_motionManager startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            NSLog(@"The roll of gyroscope sensor is:%f",motion.attitude.roll);
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) {
                    if (motion.attitude.roll < -0.3) {
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
                    
                } else if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight) {
                    if (motion.attitude.roll > 0.3) {
                        if (enableSwitch == YES) {
                            [self switchQuestionAnswerView];
                            enableSwitch = NO;
                        }
                        
                    } else if (motion.attitude.roll < 0) {
                        if (enableSwitch == NO) {
                            enableSwitch = YES;
                        }
                        
                    } else {
                        //do nothing
                    }
                }
                
            });
            
        }];
    } else {
        NSLog(@"%s:The gyroscope sensor is not available",__FUNCTION__);;
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [_motionManager stopDeviceMotionUpdates];
    _motionManager = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
	[self layoutView];
}

- (void)layoutView {
    _closeButton.backgroundColor = [UIColor clearColor];
    [_closeButton setImage:[UIImage imageNamed:@"close_button.png"] forState:UIControlStateNormal];
    _closeButton.titleLabel.text = nil;
    _closeButton.showsTouchWhenHighlighted = YES;
    [_closeButton addTarget:self action:@selector(closePlayView) forControlEvents:UIControlEventTouchDown];
    
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.clipsToBounds = YES;
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.delegate = self;
    _scrollView.bounces = YES;
    _scrollView.backgroundColor =[UIColor clearColor];
    
    if (isUserInterfaceIdiomPhone){
        _closeButton.frame = CGRectMake(IPHONE_UI_WIDTH-40, 10, 30, 30);
        _scrollView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT);
    } else {
        _closeButton.frame = CGRectMake(IPAD_UI_WIDTH-40, 10, 30, 30);
        _scrollView.frame = CGRectMake(0, 0, IPAD_UI_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
    }
    
    [self.view addSubview:_scrollView];
    [self.view addSubview:_closeButton];
    
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
    
    _currentFlashCardView = (FlashCard *)_flashCardViewArray[0];
}

- (void)layoutScrollObjectsForiPad:(NSArray *)cardArray
{
    [_flashCardViewArray removeAllObjects];
    CGFloat curXLoc = (IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2;
    for (int index = 0; index < [cardArray count]; index++)
	{
		//flash card height = scroll height; flash card width < scroll width
        CGFloat flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_PlayMode_iPad)/2+IPAD_UI_NAVIGATION_BAR_HEIGHT; //Since it's horizontal movement, so this
        FlashCard *cardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad) defaultPack:_currentPack defaultCard:_currentCard];
        cardView.currentPack = _currentPack;
        cardView.currentCard = cardArray[index];
		CGRect rect = cardView.frame;
        rect.origin = CGPointMake(curXLoc, flashCardYPositionInScrollView);
        cardView.frame = rect;
        [cardView refreshAll];
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
    float flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-kFlashCardViewHeight_PlayMode_iPhone)/2+30; //Since it's horizontal movement, so this is a constant value
    for (int index = 0; index < [cardArray count]; index++)
	{
		//flash card height = scroll height; flash card width < scroll width
        FlashCard *cardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_Detail_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPhone,kFlashCardViewHeight_PlayMode_iPhone) defaultPack:_currentPack defaultCard:_currentCard];
        cardView.currentPack = _currentPack;
        cardView.currentCard = cardArray[index];
		CGRect rect = cardView.frame;
        rect.origin = CGPointMake(curXLoc, flashCardYPositionInScrollView);
        cardView.frame = rect;
        [cardView refreshAll];
        [cardView disableCardEdit];
        [cardView.segmentedControl setHidden:YES];
        //cardView.backgroundColor = [UIColor greenColor];
		[_scrollView addSubview:cardView];
        curXLoc += IPHONE_UI_WIDTH;
        [_flashCardViewArray addObject:cardView];
	}
	
	[_scrollView setContentSize:CGSizeMake(([[_currentPack cards] count] * IPHONE_UI_WIDTH), kFlashCardViewHeight_PlayMode_iPhone)];
    
}

- (void) closePlayView {
    [self dismissModalViewControllerAnimated:YES];
    
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    NSLog (@"current page is :%d", page);
    _currentFlashCardView = (FlashCard *)_flashCardViewArray[page];
}


- (void) landscapeLeftRightOrientationChanged:(NSNotification *)notification{
    
    //[self.view.superview bringSubviewToFront:self.view];
}

- (void) switchQuestionAnswerView {
    if (_currentFlashCardView) {
        if (_currentFlashCardView.segmentedControl.selectedSegmentIndex == 1) {
            [_currentFlashCardView.segmentedControl setSelectedSegmentIndex:0];
            [_currentFlashCardView refreshAll];
            [_currentFlashCardView disableCardEdit];
        } else {
            [_currentFlashCardView.segmentedControl setSelectedSegmentIndex:1];
            [_currentFlashCardView refreshAll];
            [_currentFlashCardView disableCardEdit];
        }        
        
    } else {
        NSLog(@"%s:current FlashCardView is empty",__FUNCTION__);
    }
}

#pragma mark -
#pragma mark Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotate {
    
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark -
#pragma mark - Memory Management
// will not be called in iOS 6
// will not be called when it's current view
- (void)viewDidUnload
{
    [super viewDidUnload];
    [self my_viewDidUnload];
}

// in iOS 6, view is no longer unloaded so do it manually
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && [self.view window] == nil) {
        self.view = nil;
        [self my_viewDidUnload];
    }
}

- (void)my_viewDidUnload
{
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}




@end
