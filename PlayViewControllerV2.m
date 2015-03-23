//
//  PlayViewControllerV2.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 23/03/2015.
//  Copyright (c) 2015 Internetics. All rights reserved.
//

#import "PlayViewControllerV2.h"
#import "CycleScrollView.h"
#import "NSArray+Randomised.h"
#import "FlashCard.h"
#import "Card.h"
#import <CoreMotion/CoreMotion.h>
#import "SharkfoodMuteSwitchDetector.h"

@interface PlayViewControllerV2 () <CycleScrollViewDatasource,CycleScrollViewDelegate> {
    CycleScrollView *_scrollView;
    UIButton        *_closeButton;
    
    NSArray        *_shuffledCardArray;
    
    NSMutableArray *_isResizedArray; //用于判断是否已经被autoresize

    CMMotionManager *_motionManager;
    
    NSDate                      *_startDate;
    SharkfoodMuteSwitchDetector *_silenceDetector;
    
}

@end

@implementation PlayViewControllerV2

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _startDate =[NSDate date];
    
    //check silence mode
    _silenceDetector = [SharkfoodMuteSwitchDetector shared];
    __weak __typeof(&*self)weakSelf = self;
    _silenceDetector.silentNotify = ^(BOOL silent){
        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"];
        if (silent && b && (weakSelf != nil)) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Silent Mode is On. You may possibly could not hear text speech" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            
        }
    };
    
    
    if isUserInterfaceIdiomPhone {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"w1136"]];
    } else {
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0)) {
            // Retina display
            self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"w2048"]];
        } else {
            // non-Retina display
            self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"w1024"]];
        }
    }
    
    [self prepareData];
    [self setupViews];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(landscapeLeftRightOrientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [iConsole info:@"%s",__FUNCTION__];
    [super viewWillAppear:animated];
    
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc]init];
    }
    
    static BOOL enableSwitch = YES;
    
    _motionManager.deviceMotionUpdateInterval =0.01;
    __weak PlayViewControllerV2 *safeSelf = self;
    if (_motionManager.isDeviceMotionAvailable) {
        [_motionManager startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            //[iConsole info:@"The roll of gyroscope sensor is:%f",motion.attitude.roll];
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) {
                    if (motion.attitude.roll < -0.3) {
                        if (enableSwitch == YES) {
                            [safeSelf switchQuestionAnswerView];
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
                            [safeSelf switchQuestionAnswerView];
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
        [iConsole info:@"%s:The gyroscope sensor is not available",__FUNCTION__];
    }
}


- (void) setupViews {
    
    //step1: close button
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeButton.backgroundColor = [UIColor clearColor];
    if (isUserInterfaceIdiomPhone) {
        [_closeButton setImage:[UIImage imageNamed:@"close_button.png"] forState:UIControlStateNormal];
    } else {
        [_closeButton setImage:[UIImage imageNamed:@"close_buttonBig.png"] forState:UIControlStateNormal];
    }
    
    _closeButton.titleLabel.text = nil;
    _closeButton.showsTouchWhenHighlighted = YES;
    [_closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    
    //step2: uiscroll view
    
    _scrollView = [[CycleScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.delegate = self;
    _scrollView.datasource = self;
    _scrollView.backgroundColor =[UIColor clearColor];
    
    if (isUserInterfaceIdiomPhone){
        _closeButton.frame = CGRectMake(IPHONE_UI_WIDTH-30, 0, 30, 30);
        _scrollView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT); //全屏
    } else {
        _closeButton.frame = CGRectMake(IPAD_UI_WIDTH-50, 20, 30, 30);
        _scrollView.frame = CGRectMake(0, IPAD_UI_NAVIGATION_BAR_HEIGHT, IPAD_UI_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
    }
    
    [self.view addSubview:_scrollView];
    [self.view addSubview:_closeButton];
    

}

- (void) prepareData {
    BOOL isRandomPlayMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRandomPlayMode"];
    if (isRandomPlayMode == YES) {
        _shuffledCardArray = [[_currentPack cards] randomised];
    } else {
        //Bubble Sorting
        _shuffledCardArray = [[_currentPack cards] cardSNOrdered];
    }
    _isResizedArray = [NSMutableArray array];
    for (int i = 0;i<[_shuffledCardArray count];i++) {
        _isResizedArray[i]= @"NO";
    }
}


- (FlashCard *)cardForiPad:(NSInteger)index
{
    [iConsole info:@"%s",__FUNCTION__];
    
    //2. Set current
    float flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_PlayMode_iPad)/2+IPAD_UI_NAVIGATION_BAR_HEIGHT/2; //Since it's horizontal movement, so this
    
    FlashCard *currentFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)
                                                 defaultPack:_currentPack defaultCard:_shuffledCardArray[index] isPlayingCard:YES];
    currentFlashCardView.calledViewController = self;
    currentFlashCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    
    [currentFlashCardView refreshAll:[_isResizedArray[index] boolValue] withIndexPlaying:index];
    [currentFlashCardView disableCardEdit];
    [currentFlashCardView.segmentedControl setHidden:YES];
    
    return currentFlashCardView;
    
}


- (FlashCard *)cardForiPhone:(NSInteger)index
{
    [iConsole info:@"%s",__FUNCTION__];
    
    CGRect rect = CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2,
                             (IPHONE_UI_HEIGHT-kFlashCardViewHeight_PlayMode_iPhone)/2,
                             kFlashCardViewWidth_PlayMode_iPhone,
                             kFlashCardViewHeight_PlayMode_iPhone);
    FlashCard *currentFlashCardView = [[FlashCard alloc] initWithFrame:rect defaultPack:_currentPack defaultCard:_shuffledCardArray[index] isPlayingCard:YES];
    currentFlashCardView.calledViewController = self;
    //[self addGestureSupport]; :TODO:XXXX

    currentFlashCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    
    [currentFlashCardView refreshAll:[_isResizedArray[index] boolValue] withIndexPlaying:index];
    [currentFlashCardView disableCardEdit];
    [currentFlashCardView.segmentedControl setHidden:YES];
    
    return currentFlashCardView;
    
}


- (void) dismiss {
    [iConsole info:@"%s",__FUNCTION__];
    
    //[_currentFlashCardView stopTextToSpeechNow]; TODO:XXX

    [self dismissViewControllerAnimated:YES completion:nil];
    
}


#pragma mark – UIDeviceOrientationDidChangeNotification

- (void) landscapeLeftRightOrientationChanged:(NSNotification *)notification{
    
    //[self.view.superview bringSubviewToFront:self.view];
}


#pragma mark – CycleScrollViewDatasource

- (NSInteger)numberOfPages
{
    return [_shuffledCardArray count];
}

- (UIView *)pageAtIndex:(NSInteger)index
{
    
    FlashCard *card;
    
    if (isUserInterfaceIdiomPhone) {
        card = [self cardForiPhone:index];
    } else {
        card = [self cardForiPad:index];
    }
    
    return card;
    
}



- (void) switchQuestionAnswerView{
    [iConsole info:@"%s",__FUNCTION__];
    
    FlashCard *currentFlashCardView = (FlashCard *)[_scrollView getCurrentView];
    
    //加入这段代码的原因是为了防止误操作
    NSDate*methodFinish =[NSDate date];
    NSTimeInterval executionTime =[methodFinish timeIntervalSinceDate:_startDate];
    if (executionTime <1.5) {
        return;
    }
    
    if (currentFlashCardView) {
        
        
        if (currentFlashCardView.segmentedControl.selectedSegmentIndex == 1) {
            [currentFlashCardView.segmentedControl setSelectedSegmentIndex:0];
            [currentFlashCardView refreshAll];
            [currentFlashCardView disableCardEdit];
        } else {
            [currentFlashCardView.segmentedControl setSelectedSegmentIndex:1];
            [currentFlashCardView refreshAll];
            [currentFlashCardView disableCardEdit];
        }
        
    } else {
        [iConsole info:@"%s:current FlashCardView is empty",__FUNCTION__];
    }
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"]) {
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [currentFlashCardView textToSpeechAllContentNow];
        });;
    } else {
        [currentFlashCardView playAudio];
    }
}


#pragma mark – CycleScrollViewDelegate

- (void)tapDownAction:(CycleScrollView *)csView atPageIndex:(NSInteger)index {
    [iConsole info:@"%s",__FUNCTION__];
    [self switchQuestionAnswerView];
}

- (void)gestureUpAction:(CycleScrollView *)csView atPageIndex:(NSInteger)index {
    [iConsole info:@"%s",__FUNCTION__];
    FlashCard *currentFlashCardView = (FlashCard *)[_scrollView getCurrentView];
    if ((currentFlashCardView != nil) && (currentFlashCardView.segmentedControl.selectedSegmentIndex == 1)) {
        [self switchQuestionAnswerView];
    }
}

- (void)gestureDownAction:(CycleScrollView *)csView atPageIndex:(NSInteger)index {
    [iConsole info:@"%s",__FUNCTION__];
    FlashCard *currentFlashCardView = (FlashCard *)[_scrollView getCurrentView];
    if ((currentFlashCardView != nil) && (currentFlashCardView.segmentedControl.selectedSegmentIndex == 0)) {
        [self switchQuestionAnswerView];
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

- (void)dealloc {
    
    [iConsole info:@"%s",__FUNCTION__];
    
    _silenceDetector.silentNotify = nil;
    _silenceDetector = nil;
    _scrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}



@end
