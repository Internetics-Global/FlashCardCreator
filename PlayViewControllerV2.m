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
#import "UIButton+Extensions.h"
#import "UIAlertView+Blocks.h"
#import "Question.h"
#import "Answer.h"
#import "Common.h"
#import "PopoverView.h"
#import "ASValueTrackingSlider.h"

@interface PlayViewControllerV2 () <CycleScrollViewDatasource,CycleScrollViewDelegate,PopoverViewDelegate,UIGestureRecognizerDelegate> {
    CycleScrollView *_scrollView;
    UIButton        *_closeButton;
    
    NSArray        *_shuffledCardArray;
    
    NSMutableArray *_isResizedArray; //用于判断是否已经被autoresize

    CMMotionManager *_motionManager;
    
    NSDate                      *_startDate;
    SharkfoodMuteSwitchDetector *_silenceDetector;
    
    BOOL  _isAutoScroll;
    BOOL  _isCyclePlay;
    BOOL  _isMute;
    
    FlashCard *_previousCard;
    
    UIView    *_controlPanel;
    
    UIButton              *_playButton;
    ASValueTrackingSlider *_autoPlayDelaySlider;
    UIButton              *_autoScrollButton;
    
    NSTimer  *_autoSwitchQATimer; //auto switch question/answer card timer
    BOOL      _isAutoShowQuestionOnly;  //used together with _autoSwitchQATimer, if _autoShowQuestionOnly = YES, to show question only
    
    NSTimer *_autoHideControlPanelTimer;
    
    NSTimer  *_firstPageDelayTimer;  //used in auto mode. pause for seconds on the first page before auto play
    NSTimer  *_countDownTick;
    UILabel *_countDownLabel;
    
}

@end

@implementation PlayViewControllerV2

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _isAutoShowQuestionOnly = YES;
    
    _startDate =[NSDate date];
    
    //check silence mode
    //There's a problem for SharkfoodMuteSwitchDetector, which could make noise intermittly. so we have disable it.
//    _silenceDetector = [SharkfoodMuteSwitchDetector shared];
//    __weak __typeof(&*self)weakSelf = self;
//    _silenceDetector.silentNotify = ^(BOOL silent){
//        BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"];
//        if (silent && b && (weakSelf != nil)) {
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Silent Mode is On. You may possibly could not hear text speech" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            [alertView show];
//            
//        }
//    };
    
    
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
    
    UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchControlPanelVisibility)];
    oneTap.numberOfTapsRequired = 1;
    oneTap.delegate = self;
    [self.view addGestureRecognizer:oneTap];
    
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
                            [safeSelf switchQuestionAnswerViewWithHand:TRUE];
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
                            [safeSelf switchQuestionAnswerViewWithHand:TRUE];
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

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    FlashCard *currentCard = [self getCurrrentCard];
    _previousCard = currentCard;
    [self playbackOnCard:currentCard];
    
    NSString *recordSoundFile = currentCard.currentCard.question.recordedSoundFullPath;
    if (recordSoundFile.length == 0) {
        [_playButton setImage:[UIImage imageNamed:@"play25_dimmed"] forState:UIControlStateNormal];
    } else {
        [_playButton setImage:[UIImage imageNamed:@"play25_normal"] forState:UIControlStateNormal];
    }
    
    _autoHideControlPanelTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(autoHideControlerPanel) userInfo:nil repeats:NO];
    
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
    [_closeButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
    
    //step2: uiscroll view
    
    _scrollView = [[CycleScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.isCycle = NO;
    _scrollView.isAutoScroll = NO;
    
    if (isUserInterfaceIdiomPhone){
        _closeButton.frame = CGRectMake(IPHONE_UI_WIDTH-30, 0, 30, 30);
        _scrollView.frame = CGRectMake(0, 0, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT); //全屏
    } else {
        _closeButton.frame = CGRectMake(IPAD_UI_WIDTH-50, 20, 30, 30);
        _scrollView.frame = CGRectMake(0, IPAD_UI_NAVIGATION_BAR_HEIGHT, IPAD_UI_WIDTH, IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
    }
    
    [self.view addSubview:_scrollView];
    [self.view addSubview:_closeButton];
    
    _scrollView.delegate = self;
    _scrollView.datasource = self;
    _scrollView.backgroundColor =[UIColor clearColor];
    
    //step4: control panel
    if (isUserInterfaceIdiomPhone) {
        _controlPanel = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame) - 400)/2, CGRectGetHeight(self.view.frame) - 5 -30, 400, 30)];
    } else {
        _controlPanel = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame) - 400)/2, CGRectGetHeight(self.view.frame) - 25 -30, 400, 30)];
    }
    _controlPanel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    _controlPanel.layer.cornerRadius = 3;
    _controlPanel.backgroundColor = [UIColor colorWithRed:104.0/255 green:104.0/255 blue:104.0/255 alpha:1];
    [self.view addSubview:_controlPanel];
    
    UIButton *cyclePlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cyclePlayButton.frame = CGRectMake(10, 5, 20, 20);
    [cyclePlayButton setImage:[UIImage imageNamed:@"repeat_unselected"] forState:UIControlStateNormal];
    [cyclePlayButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cyclePlayButton addTarget:self action:@selector(cyclePlayButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //cyclePlayButton.showsTouchWhenHighlighted =YES;
    [cyclePlayButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
    [_controlPanel addSubview:cyclePlayButton];
    
    _autoScrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _autoScrollButton.frame = CGRectOffset(cyclePlayButton.frame, 20 + 20, 0);
    [_autoScrollButton setImage:[UIImage imageNamed:@"auto_unselected"] forState:UIControlStateNormal];
    [_autoScrollButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_autoScrollButton addTarget:self action:@selector(autoScrollButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //_autoScrollButton.showsTouchWhenHighlighted =YES;
    [_autoScrollButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
    [_controlPanel addSubview:_autoScrollButton];
    
    
    UILabel *autoPlayDelayLabel = [[UILabel alloc] initWithFrame:CGRectMake(90, 5, 90, 20)];
    autoPlayDelayLabel.textAlignment = NSTextAlignmentCenter;
    autoPlayDelayLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:10];
    autoPlayDelayLabel.text = @"Auto Play Speed";
    autoPlayDelayLabel.numberOfLines = 1;
    autoPlayDelayLabel.textColor = [UIColor whiteColor];
    autoPlayDelayLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:autoPlayDelayLabel];
    
    _autoPlayDelaySlider= [[ASValueTrackingSlider alloc] initWithFrame:CGRectOffset(autoPlayDelayLabel.frame, 110, 0)];
    [_autoPlayDelaySlider setMaxFractionDigitsDisplayed:0];
    _autoPlayDelaySlider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:0.7];
    _autoPlayDelaySlider.font = [UIFont systemFontOfSize:12];
    _autoPlayDelaySlider.popUpViewWidthPaddingFactor = 1.5;
    _autoPlayDelaySlider.popUpViewCornerRadius = 3;
    _autoPlayDelaySlider.popUpViewHeightPaddingFactor = 1;
    _autoPlayDelaySlider.popUpViewArrowLength = 8;
    _autoPlayDelaySlider.popUpViewAnimatedColors = @[[UIColor orangeColor]];
    _autoPlayDelaySlider.textColor = [UIColor whiteColor];
    _autoPlayDelaySlider.backgroundColor = [UIColor grayColor];
    [[UISlider appearance] setThumbImage:[UIImage imageNamed:@"slide_thumb"] forState:UIControlStateNormal];
    _autoPlayDelaySlider.minimumValue = 4;
    _autoPlayDelaySlider.maximumValue = 60.0;
    _autoPlayDelaySlider.continuous = NO;
    if ((self.currentPack.autoPlaySpeed == 0)
        || (self.currentPack.autoPlaySpeed > kMAX_Auto_Play_Speed)
        || (self.currentPack.autoPlaySpeed < kMIN_Auto_Play_Speed)) {
      _autoPlayDelaySlider.value = kDefault_Auto_Play_Speed;
    } else {
        _autoPlayDelaySlider.value = self.currentPack.autoPlaySpeed;
    }
    
    _autoPlayDelaySlider.tintColor = [UIColor greenColor];
    [_autoPlayDelaySlider addTarget:self action:@selector(autoPlayDelaySliderClicked:) forControlEvents:UIControlEventValueChanged];
    [_autoPlayDelaySlider setBackgroundColor:[UIColor clearColor]];
    [_controlPanel addSubview: _autoPlayDelaySlider];
    
    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_autoPlayDelaySlider.frame)- 20, 5, 20, 20)];
    minLabel.textAlignment = NSTextAlignmentRight;
    minLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    minLabel.text = [NSString stringWithFormat:@"%d",kMIN_Auto_Play_Speed];
    minLabel.numberOfLines = 1;
    minLabel.textColor = [UIColor whiteColor];
    minLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:minLabel];
    
    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_autoPlayDelaySlider.frame), 5, 20, 20)];
    maxLabel.textAlignment = NSTextAlignmentLeft;
    maxLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    maxLabel.text = [NSString stringWithFormat:@"%d",kMAX_Auto_Play_Speed];;
    maxLabel.numberOfLines = 1;
    maxLabel.textColor = [UIColor whiteColor];
    maxLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:maxLabel];
    
    
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = CGRectMake(CGRectGetWidth(_controlPanel.frame)- 20 -20, 5, 20, 20);
    [_playButton setImage:[UIImage imageNamed:@"play25_normal"] forState:UIControlStateNormal];
    [_playButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(playButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //_playButton.showsTouchWhenHighlighted =YES;
    [_playButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
    [_controlPanel addSubview:_playButton];
    
    UIButton *muteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    muteButton.frame = CGRectOffset(_playButton.frame, -30, 0);
    [muteButton setImage:[UIImage imageNamed:@"mute_unselected"] forState:UIControlStateNormal];
    [muteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [muteButton addTarget:self action:@selector(muteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //muteButton.showsTouchWhenHighlighted =YES;
    [muteButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
    [_controlPanel addSubview:muteButton];
    

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


- (FlashCard *)cardForiPad:(NSInteger)index withPosition:(int)position
{
    [iConsole info:@"%s",__FUNCTION__];
    
    //2. Set current
    float flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_PlayMode_iPad)/2+IPAD_UI_NAVIGATION_BAR_HEIGHT/2; //Since it's horizontal movement, so this
    
    FlashCard *currentFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)
                                                 defaultPack:_currentPack defaultCard:_shuffledCardArray[index] isPlayingCard:YES];
    
    if (position == -1) {
        currentFlashCardView.tag = PREVIOUS_FLASHCARDVIEW_TAG;
    } else if (position == 1) {
        currentFlashCardView.tag = NEXT_FLASHCARDVIEW_TAG;
    } else {
        currentFlashCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    }
    
    
    currentFlashCardView.calledViewController = self;//在iPad中，PlayViewControllerV2是通过modal方式出现的，这时如果点击logo image，通过rootViewController进行modal是不可行的，所以需要通过在calledViewController进行modal展示
    [currentFlashCardView refreshAll:[_isResizedArray[index] boolValue] withIndexPlaying:(int)index];
    [currentFlashCardView disableCardEdit];
    [currentFlashCardView.segmentedControl setHidden:YES];
    
    return currentFlashCardView;
    
}


- (FlashCard *)cardForiPhone:(NSInteger)index withPosition:(int)position
{
    [iConsole info:@"%s",__FUNCTION__];
    
    CGRect rect = CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2,
                             (IPHONE_UI_HEIGHT-kFlashCardViewHeight_PlayMode_iPhone)/2,
                             kFlashCardViewWidth_PlayMode_iPhone,
                             kFlashCardViewHeight_PlayMode_iPhone);
    FlashCard *currentFlashCardView = [[FlashCard alloc] initWithFrame:rect defaultPack:_currentPack defaultCard:_shuffledCardArray[index] isPlayingCard:YES];
    //[self addGestureSupport]; :TODO:XXXX

    if (position == -1) {
        currentFlashCardView.tag = PREVIOUS_FLASHCARDVIEW_TAG;
    } else if (position == 1) {
        currentFlashCardView.tag = NEXT_FLASHCARDVIEW_TAG;
    } else {
        currentFlashCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    }
    
    currentFlashCardView.calledViewController = self;//在iPad中，PlayViewControllerV2是通过modal方式出现的，这时如果点击logo image，通过rootViewController进行modal是不可行的，所以需要通过在calledViewController进行modal展示
    [currentFlashCardView refreshAll:[_isResizedArray[index] boolValue] withIndexPlaying:(int)index];
    [currentFlashCardView disableCardEdit];
    [currentFlashCardView.segmentedControl setHidden:YES];
    
    return currentFlashCardView;
    
}


- (void) dismiss {
    [iConsole info:@"%s",__FUNCTION__];
    
    if ([UIApplication sharedApplication].idleTimerDisabled == YES) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
    
    [_scrollView cleanup];
    
    FlashCard *currentFlashCardView = [self getCurrrentCard];
    [currentFlashCardView stopTextToSpeechNow];
    [currentFlashCardView stopAudio];
    
    _scrollView = nil;
    
    [_currentPack savePackOnly];
    

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

- (UIView *)pageAtIndex:(NSInteger)index withPosition:(int)position
{
    
    FlashCard *card;
    
    if (isUserInterfaceIdiomPhone) {
        card = [self cardForiPhone:index withPosition:position];
    } else {
        card = [self cardForiPad:index withPosition:position];
    }
    

    
    return card;
    
}

- (void) switchQAFromTimer {
    [self switchQuestionAnswerViewWithHand:FALSE];
}


- (void) autoHideControlerPanel {
    _controlPanel.hidden = YES;
}



- (void) switchQuestionAnswerViewWithHand:(BOOL)isManually{
    [iConsole info:@"%s",__FUNCTION__];
    
    FlashCard *currentFlashCardView = [self getCurrrentCard];
    
    //加入这段代码的原因是为了防止误操作
    NSDate*methodFinish =[NSDate date];
    NSTimeInterval executionTime =[methodFinish timeIntervalSinceDate:_startDate];
    if (executionTime <1.5) {
        return;
    }
    
    if (currentFlashCardView) {
        
        if (isManually) {
            [_autoSwitchQATimer invalidate];
            _autoSwitchQATimer = nil;
        }
        
        if (currentFlashCardView.segmentedControl.selectedSegmentIndex == 1) {
            [currentFlashCardView.segmentedControl setSelectedSegmentIndex:0];
            [currentFlashCardView refreshAll];
            [currentFlashCardView disableCardEdit];
            
            
            NSString *recordSoundFile = currentFlashCardView.currentCard.question.recordedSoundFullPath;
            if (recordSoundFile.length == 0) {
                [_playButton setImage:[UIImage imageNamed:@"play25_dimmed"] forState:UIControlStateNormal];
            } else {
                [_playButton setImage:[UIImage imageNamed:@"play25_normal"] forState:UIControlStateNormal];
            }
            
        } else {
            [currentFlashCardView.segmentedControl setSelectedSegmentIndex:1];
            [currentFlashCardView refreshAll];
            [currentFlashCardView disableCardEdit];
            
            NSString *recordSoundFile = currentFlashCardView.currentCard.answer.recordedSoundFullPath;
            if (recordSoundFile.length == 0) {
                [_playButton setImage:[UIImage imageNamed:@"play25_dimmed"] forState:UIControlStateNormal];
            } else {
                [_playButton setImage:[UIImage imageNamed:@"play25_normal"] forState:UIControlStateNormal];
            }
        }
        
        
    } else {
        [iConsole info:@"%s:current FlashCardView is empty",__FUNCTION__];
    }
    
    
    [self playbackOnCard:currentFlashCardView];
    
}


- (void) cyclePlayButtonClicked:(UIButton *) button {
    
    if (_isCyclePlay) {
        _isCyclePlay = NO;
        [button setImage:[UIImage imageNamed:@"repeat_unselected"] forState:UIControlStateNormal];
    } else {
         _isCyclePlay = YES;
        [button setImage:[UIImage imageNamed:@"repeat_selected"] forState:UIControlStateNormal];
    }
    
    if (_isCyclePlay) {
        _scrollView.isCycle = YES;
        
    } else {
        _scrollView.isCycle = NO;
    }
    
}

- (void) autoScrollButtonClicked:(UIButton *) button {
    
    if (_isAutoScroll == FALSE) {
        [PopoverView showPopoverAtPoint:_autoScrollButton.center
                                 inView:_controlPanel
                              withTitle:@"Option"
                        withStringArray:[NSArray arrayWithObjects:@"Show question only",@"Both question and answer", nil]
                               delegate:self];
        
    } else {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        _autoPlayDelaySlider.enabled = TRUE;
        
        _scrollView.userInteractionEnabled = YES;
        
        [_countDownLabel removeFromSuperview];
        _countDownLabel = nil;
        
        [_countDownTick invalidate];
        _countDownTick = nil;
        
        [_firstPageDelayTimer invalidate];
        _firstPageDelayTimer = nil;
        
        _isAutoScroll = NO;
        [_autoScrollButton setImage:[UIImage imageNamed:@"auto_unselected"] forState:UIControlStateNormal];
        
        //_scrollView.userInteractionEnabled = YES;
        _scrollView.isAutoScroll = NO;
        
        [_autoSwitchQATimer invalidate];
        _autoSwitchQATimer = nil;
    }
}

/*
 * execute textToSpeechAllContentNow or playAudio according to setting
*/
- (void) playbackOnCard:(FlashCard *) currentCard {
    
    if (_isMute == FALSE) {
        if (currentCard) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"]) {
                if (_previousCard) {
                    [_previousCard stopTextToSpeechNow];
                }
                double delayInSeconds = 0.3;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [currentCard textToSpeechAllContentNow];
                });;
            } else {
                [currentCard playAudio:NO];
            }
        } else {
            [iConsole error:@"%s,currentCard should not be nil",__FUNCTION__];
        };
    }
}

- (FlashCard *) getCurrrentCard {
    FlashCard *currentCard = (FlashCard*)[_scrollView getCurrentView];
    return currentCard;
}


- (void) beginAutoScroll{
    
    //_scrollView.userInteractionEnabled = NO;
    _scrollView.isAutoScroll = YES;
    _scrollView.autoPlayDelaySeconds = _autoPlayDelaySlider.value;
    
    FlashCard *currentCard = [self getCurrrentCard];
    _previousCard = currentCard;
    [self playbackOnCard:currentCard];
    
    if (_autoSwitchQATimer) {
        [_autoSwitchQATimer invalidate];
        _autoSwitchQATimer = nil;
    }
    if (_isAutoShowQuestionOnly == NO) {
        _autoSwitchQATimer = [NSTimer scheduledTimerWithTimeInterval:(_autoPlayDelaySlider.value/2-0.5) target:self selector:@selector(switchQAFromTimer) userInfo:nil repeats:NO];
    }
    
    
}

- (void) playButtonClicked:(UIButton *) button {
    
    if (_isMute == FALSE) {
        FlashCard *currentCard = (FlashCard*)[_scrollView getCurrentView];
        if (currentCard) {
            [currentCard playAudio:YES];
        } else {
            [iConsole error:@"%s,currentCard should not be nil",__FUNCTION__];
        };
    }
}

- (void) muteButtonClicked:(UIButton *) button {
    
    if (_isMute) {
        _isMute = NO;
        [button setImage:[UIImage imageNamed:@"mute_unselected"] forState:UIControlStateNormal];
    } else {
        _isMute = YES;
        [button setImage:[UIImage imageNamed:@"mute_selected"] forState:UIControlStateNormal];
        
        FlashCard *currentFlashCardView = [self getCurrrentCard];
        [currentFlashCardView stopAudio];
        
        
        
    }
    
}

- (void) autoPlayDelaySliderClicked:(UISlider *) slider {
    
    _scrollView.autoPlayDelaySeconds = slider.value;
    _currentPack.autoPlaySpeed = slider.value;
    
}



#pragma mark – CycleScrollViewDelegate

- (void)tapDownAction:(CycleScrollView *)csView atPageIndex:(NSInteger)index {
    [iConsole info:@"%s",__FUNCTION__];
    [self switchQuestionAnswerViewWithHand:TRUE];
}

- (void)gestureUpAction:(CycleScrollView *)csView atPageIndex:(NSInteger)index {
    [iConsole info:@"%s",__FUNCTION__];
    FlashCard *currentFlashCardView = [self getCurrrentCard];
    if ((currentFlashCardView != nil) && (currentFlashCardView.segmentedControl.selectedSegmentIndex == 1)) {
        [self switchQuestionAnswerViewWithHand:TRUE];
    }
}

- (void)gestureDownAction:(CycleScrollView *)csView atPageIndex:(NSInteger)index {
    [iConsole info:@"%s",__FUNCTION__];
    FlashCard *currentFlashCardView = [self getCurrrentCard];
    if ((currentFlashCardView != nil) && (currentFlashCardView.segmentedControl.selectedSegmentIndex == 0)) {
        [self switchQuestionAnswerViewWithHand:TRUE];
    }
}

- (void)didScrollToPage:(NSInteger)index {
     [iConsole info:@"%s",__FUNCTION__];
    
    FlashCard *currentCard = [self getCurrrentCard];
    [self playbackOnCard:currentCard];
    _previousCard = currentCard;
    
    
    if (_autoSwitchQATimer) {
        [_autoSwitchQATimer invalidate];
        _autoSwitchQATimer = nil;
    }
    if (_isAutoScroll && (_isAutoShowQuestionOnly == NO)) {
        _autoSwitchQATimer = [NSTimer scheduledTimerWithTimeInterval:(_autoPlayDelaySlider.value/2-0.5) target:self selector:@selector(switchQAFromTimer) userInfo:nil repeats:NO];
    }
}

- (void) switchControlPanelVisibility {
    if (_autoHideControlPanelTimer) {
        [_autoHideControlPanelTimer invalidate];
        _autoHideControlPanelTimer = nil;
    }
    _autoHideControlPanelTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(autoHideControlerPanel) userInfo:nil repeats:NO];
    [_controlPanel setHidden:!(_controlPanel.hidden)];
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


#pragma mark – PopoverViewDelegate

-(void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index {
    
    [popoverView dismiss];
    
    if (index ==0) {
        _isAutoShowQuestionOnly = YES;
        
    } else {
        _isAutoShowQuestionOnly = NO;
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    _isAutoScroll = YES;
    _autoPlayDelaySlider.enabled = FALSE;
    _scrollView.userInteractionEnabled = FALSE;
    [_autoScrollButton setImage:[UIImage imageNamed:@"auto_selected"] forState:UIControlStateNormal];
    
    //client's special requirement to request a pause after entry into play mode
    FlashCard *currentCard = (FlashCard*)[_scrollView getCurrentView];
    [currentCard stopAudio];
    [currentCard stopTextToSpeechNow];
    [_firstPageDelayTimer invalidate];
    _firstPageDelayTimer = [NSTimer scheduledTimerWithTimeInterval:(_autoPlayDelaySlider.value) target:self selector:@selector(beginAutoScroll) userInfo:nil repeats:NO];
    
    if (_countDownLabel) {
       [_countDownLabel removeFromSuperview];
    }
    if (isUserInterfaceIdiomPhone) {
        _countDownLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetHeight(self.view.frame)- 30, 30, 20)];
        _countDownLabel.font = [UIFont systemFontOfSize:24];
    } else {
        _countDownLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetHeight(self.view.frame)- 60, 80, 50)];
        _countDownLabel.font = [UIFont systemFontOfSize:56];
    }
    _countDownLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
    _countDownLabel.textAlignment = NSTextAlignmentCenter;
    _countDownLabel.numberOfLines = 1;
    _countDownLabel.textColor = [UIColor whiteColor];
    _countDownLabel.backgroundColor = [UIColor clearColor];
    _countDownLabel.text = [NSString stringWithFormat:@"%d",(int)_autoPlayDelaySlider.value];
    [self.view addSubview:_countDownLabel];
    _countDownTick = [NSTimer scheduledTimerWithTimeInterval:(1) target:self selector:@selector(countDownTick) userInfo:nil repeats:YES];
    
    [self playbackOnCard:currentCard];
}

//avoid _controlpanel and its subview touch event is intercepted by gesture
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view == _controlPanel) {
        return FALSE;
    }  else {
        
        for (UIView *myView in [_controlPanel subviews]) {
            if (touch.view == myView) {
                return FALSE;
            }
        }
        
        return TRUE;
    }
}

- (void) countDownTick {
    int value = [_countDownLabel.text intValue];
    if (value == 0) {
        [_countDownLabel removeFromSuperview];
        _countDownLabel = nil;
        [_countDownTick invalidate];
        _countDownTick = nil;
    } else {
        _countDownLabel.text = [NSString stringWithFormat:@"%d",value - 1];
    }
}

#pragma mark -
#pragma mark - Memory Management


- (void)dealloc {
    
    [iConsole info:@"%s",__FUNCTION__];
    
    [_autoSwitchQATimer invalidate];
    _autoSwitchQATimer = nil;
    
    [_firstPageDelayTimer invalidate];
    _firstPageDelayTimer = nil;
    
    [_countDownTick invalidate];
    _countDownTick = nil;
    
    _silenceDetector.silentNotify = nil;
    _silenceDetector = nil;
    _scrollView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}



@end
