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
#import "UIButton+Extensions.h"
#import "UIAlertView+Blocks.h"
#import "Question.h"
#import "Answer.h"
#import "Common.h"
#import "ASValueTrackingSlider.h"

#import "NSTimer+BlocksKit.h"
#import "OpenUDID.h"

#define K_AutoHideControlPanelDwellSeconds         5
#define K_IntervalBetweenCardSeconds_ForQAOnly     4

@interface PlayViewControllerV2 () <CycleScrollViewDatasource,CycleScrollViewDelegate,UIGestureRecognizerDelegate,ASValueTrackingSliderDataSource> {
    
    CycleScrollView              *_scrollView;
    UIButton                     *_closeButton;
    
    NSArray                      *_shuffledCardArray;
    
    NSMutableArray               *_isResizedArray; //用于判断是否已经被autoresize

    CMMotionManager              *_motionManager;
    
    NSDate                       *_startDate;
    
    
    /**
     *  实际中，auto scroll分两种
     *  1. 通过定时器控制的固定间隔的auto scroll
     *  2. 通过Text2Speech回调控制的smart delay的auto scroll
     */
    BOOL  _isAutoScroll;
    
    BOOL  _isCyclePlay;
    
    /**
     *  实际上不是真正的mute
     */
    BOOL  _isMute;
    
    BOOL  _isShuttingDown;
    
    FlashCard             *_previousCard;
    
    UIView                *_controlPanel;
    UIButton              *_playButton;
    UIButton              *_autoScrollButton;
    
    ASValueTrackingSlider *_pauseForAnswerSlider;
    UILabel               *_pauseForAnswerLabel;
    UILabel               *_minPauseForAnswerLabel;;
    UILabel               *_maxPauseForAnswerLabel;
    
    UIView                *_messageToastBaseView; //是否出现，逻辑同_countDownLabel完全一致
    
    /**
     *  _dwellTimeSlider.value + _pauseForAnswerSlider.value 为整个卡片（包括question和answer)的停留时间
     *  无论是question only，还是both question and answer,则question/answer上的停留时间都是_dwellTimeSlider.value
     *  取值范围
     *  1. 如果 == 最小值，则是[self isSmartDelay] = YES
     *  2. 否则其它情况，则为一般固定间隔
     *
     */
    ASValueTrackingSlider *_dwellTimeSlider;
    UILabel               *_minDwellTimeLabel;
    UILabel               *_maxDwellTimeLabel;
    
    
    UIButton              *_cyclePlayButton;
    
    /**
     * if _autoShowQuestionOnly = YES, to show question only
     */
    BOOL      _isAutoShowQuestionOnly;
    
    
    /**
     *  如果是SmartDelay，则忽略_autoSwitchQATimerForFixedDelay。而是通过text2SpeechFinished回调来自动切换
     */
    NSTimer  *_autoSwitchQATimerForFixedDelay;
    
    NSTimer  *_autoHideControlPanelTimer;
    
    NSTimer  *_firstTimeDelayTimer; //as soon as entering play mode, we set a delay before placing recording/text to speech
    
    NSTimer  *_firstPageDelay_FixedMode_Timer;
    NSTimer  *_firstPageDelay_AutoDelayMode_Timer;
    
    NSTimer  *_timerForDelayedText2Speech; //通过计算recording时间，用于recording结束后，进行自动text to speech
    
    /**
     *  当dwell on answer card expire后，自动触发，比如关闭正在播放的text to speech
     */
    NSTimer  * _timerForDwellOnAnswerExpire_FixedDelayModeOnly;
    
    UILabel  * _countDownLabel;
    NSTimer  * _countDownTimer;
    
    int       _currentPage;
    
    /**
     *  _isAutoShowQuestionOnly时，用于切换到下一个卡片的固定的delay（ K_IntervalBetweenCardSeconds_ForQAOnly）
     */
    NSTimer  *_timerAForText2SpeechFinished;
    
    /**
     *  _isAutoShowQuestionOnly ＝ false，且isQuestionShowing时，用于切换到answer的delay(_pauseForAnswerSlider.value)
     */
    NSTimer  *_timerBForText2SpeechFinished;
    
    /**
     *  _isAutoShowQuestionOnly ＝ false，且isQuestionShowing = false时,用于切换到下一个卡片的固定的delay（ K_IntervalBetweenCardSeconds_ForQAOnly）
     */
    NSTimer  *_timerCForText2SpeechFinished;
}

@end

@implementation PlayViewControllerV2

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _isAutoShowQuestionOnly = YES;
    
    _startDate =[NSDate date];
    
    
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
    
    
    //初始化_dwellTimeSlider值
    
    switch (self.oneOffPlayType) {
        case One_Off_Play_Type_Manually: {
            break;
        }
            
        case One_Off_Play_Type_Auto_Play:
            _dwellTimeSlider.value = kDefault_Auto_Play_Speed;
            break;
            
        case One_Off_Play_Type_Auto_Play_Loop:
            _dwellTimeSlider.value = kDefault_Auto_Play_Speed;
            break;
            
        default:
            break;
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _controlPanel.hidden = YES;
    _scrollView.userInteractionEnabled = NO;
    
    FlashCard *currentCard = [self getCurrrentCard];
    
    _firstTimeDelayTimer = [NSTimer scheduledTimerWithTimeInterval:(1) target:self selector:@selector(firstTimeDelayTimer) userInfo:nil repeats:NO];
    
    NSString *recordSoundFile = currentCard.currentCard.question.recordedSoundFullPath;
    if (recordSoundFile.length == 0) {
        [_playButton setImage:[UIImage imageNamed:@"play25_dimmed"] forState:UIControlStateNormal];
    } else {
        [_playButton setImage:[UIImage imageNamed:@"play25_normal"] forState:UIControlStateNormal];
    }
    
    _autoHideControlPanelTimer = [NSTimer scheduledTimerWithTimeInterval:K_AutoHideControlPanelDwellSeconds target:self selector:@selector(autoHideControlerPanel) userInfo:nil repeats:NO];
    
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
    
    //step2: CycleScrollView
    
    _scrollView = [[CycleScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.isCycle = NO;
    
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
        _controlPanel = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame) - 460)/2, CGRectGetHeight(self.view.frame) - 5 -30, 460, 30)];
    } else {
        _controlPanel = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame) - 460)/2, CGRectGetHeight(self.view.frame) - 25 -30, 460, 30)];
    }
    _controlPanel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    _controlPanel.layer.cornerRadius = 3;
    _controlPanel.backgroundColor = [UIColor colorWithRed:104.0/255 green:104.0/255 blue:104.0/255 alpha:1];
    _controlPanel.hidden = YES;
    [self.view addSubview:_controlPanel];
    
    _cyclePlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cyclePlayButton.frame = CGRectMake(10, 5, 20, 20);
    [_cyclePlayButton setImage:[UIImage imageNamed:@"repeat_unselected"] forState:UIControlStateNormal];
    [_cyclePlayButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_cyclePlayButton addTarget:self action:@selector(cyclePlayButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //cyclePlayButton.showsTouchWhenHighlighted =YES;
    [_cyclePlayButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
    [_controlPanel addSubview:_cyclePlayButton];
    
    _autoScrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _autoScrollButton.frame = CGRectOffset(_cyclePlayButton.frame, 10 + 20, 0);
    [_autoScrollButton setImage:[UIImage imageNamed:@"auto_unselected"] forState:UIControlStateNormal];
    [_autoScrollButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_autoScrollButton addTarget:self action:@selector(autoScrollButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //_autoScrollButton.showsTouchWhenHighlighted =YES;
    [_autoScrollButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
    [_controlPanel addSubview:_autoScrollButton];
    
    _dwellTimeSlider= [[ASValueTrackingSlider alloc] initWithFrame:CGRectMake(145, 5, 60, 20)];
    [_dwellTimeSlider setMaxFractionDigitsDisplayed:0];
    _dwellTimeSlider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:0.7];
    _dwellTimeSlider.font = [UIFont systemFontOfSize:12];
    _dwellTimeSlider.popUpViewWidthPaddingFactor = 2;
    _dwellTimeSlider.popUpViewCornerRadius = 3;
    _dwellTimeSlider.popUpViewHeightPaddingFactor = 1;
    _dwellTimeSlider.popUpViewArrowLength = 8;
    _dwellTimeSlider.popUpViewAnimatedColors = @[[UIColor orangeColor]];
    _dwellTimeSlider.textColor = [UIColor whiteColor];
    _dwellTimeSlider.backgroundColor = [UIColor grayColor];
    [[UISlider appearance] setThumbImage:[UIImage imageNamed:@"slide_thumb"] forState:UIControlStateNormal];
    _dwellTimeSlider.minimumValue = kMIN_Auto_Play_Speed;
    _dwellTimeSlider.maximumValue = kMAX_Auto_Play_Speed;
    _dwellTimeSlider.continuous = NO;
    if ((self.currentPack.autoPlaySpeed == 0)
        || (self.currentPack.autoPlaySpeed > kMAX_Auto_Play_Speed)
        || (self.currentPack.autoPlaySpeed < kMIN_Auto_Play_Speed)) {
      _dwellTimeSlider.value = kDefault_Auto_Play_Speed;
    } else {
        _dwellTimeSlider.value = self.currentPack.autoPlaySpeed;
    }
    
    _dwellTimeSlider.tintColor = [UIColor greenColor];
    [_dwellTimeSlider addTarget:self action:@selector(dwellTimeSliderClicked:) forControlEvents:UIControlEventValueChanged];
    [_dwellTimeSlider setBackgroundColor:[UIColor clearColor]];
    _dwellTimeSlider.dataSource = self;
    [_controlPanel addSubview: _dwellTimeSlider];
    
    _minDwellTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_dwellTimeSlider.frame)- 70, 5, 70, 20)];
    _minDwellTimeLabel.textAlignment = NSTextAlignmentRight;
    _minDwellTimeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    _minDwellTimeLabel.text = NSLocalizedString(@"Title_Reading_Timer",@"");
    _minDwellTimeLabel.numberOfLines = 1;
    _minDwellTimeLabel.textColor = [UIColor whiteColor];
    _minDwellTimeLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:_minDwellTimeLabel];
    
    _maxDwellTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_dwellTimeSlider.frame), 5, 20, 20)];
    _maxDwellTimeLabel.textAlignment = NSTextAlignmentLeft;
    _maxDwellTimeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    _maxDwellTimeLabel.text = [NSString stringWithFormat:@"%d",kMAX_Auto_Play_Speed];;
    _maxDwellTimeLabel.numberOfLines = 1;
    _maxDwellTimeLabel.textColor = [UIColor whiteColor];
    _maxDwellTimeLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:_maxDwellTimeLabel];
    
    
    _pauseForAnswerLabel = [[UILabel alloc] initWithFrame:CGRectMake(220, 5, 90, 20)];
    _pauseForAnswerLabel.textAlignment = NSTextAlignmentCenter;
    _pauseForAnswerLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:10];
    _pauseForAnswerLabel.text = NSLocalizedString(@"Title_Question_Pause",@"");
    _pauseForAnswerLabel.numberOfLines = 1;
    _pauseForAnswerLabel.textColor = [UIColor whiteColor];
    _pauseForAnswerLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:_pauseForAnswerLabel];
    
    _pauseForAnswerSlider= [[ASValueTrackingSlider alloc] initWithFrame:CGRectMake(315, 5, 60, 20)];
    [_pauseForAnswerSlider setMaxFractionDigitsDisplayed:0];
    _pauseForAnswerSlider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:0.7];
    _pauseForAnswerSlider.font = [UIFont systemFontOfSize:12];
    _pauseForAnswerSlider.popUpViewWidthPaddingFactor = 1.5;
    _pauseForAnswerSlider.popUpViewCornerRadius = 3;
    _pauseForAnswerSlider.popUpViewHeightPaddingFactor = 1;
    _pauseForAnswerSlider.popUpViewArrowLength = 8;
    _pauseForAnswerSlider.popUpViewAnimatedColors = @[[UIColor orangeColor]];
    _pauseForAnswerSlider.textColor = [UIColor whiteColor];
    _pauseForAnswerSlider.backgroundColor = [UIColor grayColor];
    [[UISlider appearance] setThumbImage:[UIImage imageNamed:@"slide_thumb"] forState:UIControlStateNormal];
    _pauseForAnswerSlider.minimumValue = kMIN_Pause_For_Answer;
    _pauseForAnswerSlider.maximumValue = kMAX_Pause_For_Answer;
    _pauseForAnswerSlider.continuous = NO;
    _pauseForAnswerSlider.value = kDefault_Pause_For_Answer;
    
    _pauseForAnswerSlider.tintColor = [UIColor greenColor];
    [_pauseForAnswerSlider addTarget:self action:@selector(pauseForAnswerSliderClicked:) forControlEvents:UIControlEventValueChanged];
    [_pauseForAnswerSlider setBackgroundColor:[UIColor clearColor]];
    [_controlPanel addSubview: _pauseForAnswerSlider];
    
    _minPauseForAnswerLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_pauseForAnswerSlider.frame)- 20, 5, 20, 20)];
    _minPauseForAnswerLabel.textAlignment = NSTextAlignmentRight;
    _minPauseForAnswerLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    _minPauseForAnswerLabel.text = [NSString stringWithFormat:@"%d",kMIN_Pause_For_Answer];
    _minPauseForAnswerLabel.numberOfLines = 1;
    _minPauseForAnswerLabel.textColor = [UIColor whiteColor];
    _minPauseForAnswerLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:_minPauseForAnswerLabel];
    
    _maxPauseForAnswerLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_pauseForAnswerSlider.frame), 5, 20, 20)];
    _maxPauseForAnswerLabel.textAlignment = NSTextAlignmentLeft;
    _maxPauseForAnswerLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    _maxPauseForAnswerLabel.text = [NSString stringWithFormat:@"%d",kMAX_Pause_For_Answer];;
    _maxPauseForAnswerLabel.numberOfLines = 1;
    _maxPauseForAnswerLabel.textColor = [UIColor whiteColor];
    _maxPauseForAnswerLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:_maxPauseForAnswerLabel];
    
    
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = CGRectMake(CGRectGetWidth(_controlPanel.frame)- 10 -20, 5, 20, 20);
    [_playButton setImage:[UIImage imageNamed:@"play25_normal"] forState:UIControlStateNormal];
    [_playButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(playButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //_playButton.showsTouchWhenHighlighted =YES;
    [_playButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
    [_controlPanel addSubview:_playButton];
    
    UIButton *muteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    muteButton.frame = CGRectOffset(_playButton.frame, -25, 0);
    [muteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [muteButton addTarget:self action:@selector(muteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //muteButton.showsTouchWhenHighlighted =YES;
    [muteButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
    [_controlPanel addSubview:muteButton];
    _isMute = [[NSUserDefaults standardUserDefaults] boolForKey:@"isMuteMode"];
    if (_isMute) {
       [muteButton setImage:[UIImage imageNamed:@"mute_selected"] forState:UIControlStateNormal];
    } else {
       [muteButton setImage:[UIImage imageNamed:@"mute_unselected"] forState:UIControlStateNormal];
    }
    
    [_dwellTimeSlider showPopUpViewAnimated:NO];
    [_pauseForAnswerSlider showPopUpViewAnimated:NO];
    
    
    if (isUserInterfaceIdiomPhone) {
        _countDownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 130, 130)];
        _countDownLabel.font = [UIFont boldSystemFontOfSize:84];
        _countDownLabel.layer.cornerRadius = 65;
    } else {
        _countDownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 230, 230)];
        _countDownLabel.font = [UIFont boldSystemFontOfSize:206];
        _countDownLabel.layer.cornerRadius = 115;
    
    }
    _countDownLabel.layer.masksToBounds = YES;
    _countDownLabel.center = self.view.center;
    _countDownLabel.textAlignment = NSTextAlignmentCenter;
    _countDownLabel.numberOfLines = 1;
    _countDownLabel.textColor = [UIColor whiteColor];
    _countDownLabel.alpha = 0.5;
    _countDownLabel.backgroundColor = [UIColor grayColor];
    
    
    if ((_currentPack.autoPlaySpeed != kDefault_Auto_Play_Speed)
            && ([Common isOwner:_currentPack] == false)){
        if (isUserInterfaceIdiomPhone) {
            _messageToastBaseView = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_controlPanel.frame) + 30, CGRectGetMinY(_controlPanel.frame) - 55, CGRectGetWidth(_controlPanel.frame) - 60, 50)];
        } else {
            _messageToastBaseView = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_controlPanel.frame) - 85, CGRectGetMinY(_controlPanel.frame) - 170, CGRectGetWidth(_controlPanel.frame) + 85 *2, 90)];
        }
        _messageToastBaseView.layer.cornerRadius = 15;
        _messageToastBaseView.layer.masksToBounds = YES;
        
        _messageToastBaseView.backgroundColor = [UIColor colorWithRed:183.0/255 green:183.0/255 blue:183.0/255 alpha:1];
        
        UILabel *messageToastLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, CGRectGetWidth(_messageToastBaseView.frame) - 10, CGRectGetHeight(_messageToastBaseView.frame) - 10)];
        messageToastLabel.text = [NSString stringWithFormat:@"PLEASE NOTE:THIS PACK CREATOR HAS SET THE READING TIME OF EACH CARD TO %d SECONDS. YOU CAN CHANGE THIS BY CLICKING BELOW THE CARD AND SELECTING ANOTHER LENGTH",_currentPack.autoPlaySpeed];
        messageToastLabel.numberOfLines = 3;
        messageToastLabel.textColor = [UIColor blackColor];
        messageToastLabel.textAlignment = NSTextAlignmentLeft;
        messageToastLabel.backgroundColor = [UIColor clearColor];
        if (isUserInterfaceIdiomPhone) {
            messageToastLabel.font = [UIFont boldSystemFontOfSize:10];
        } else {
            messageToastLabel.font = [UIFont boldSystemFontOfSize:17];
        }
        
        [_messageToastBaseView addSubview:messageToastLabel];
    }
    
    _scrollView.isFixedDelayAutoScroll = (![self isSmartDelay]);  //call this finally  since we need _dwellTimeSlider to be inintialized firstly
    
    
    
    

}

- (void) enablePauseForAnswerSlider {
    
    if ([self isPauseForAnswerSliderEnabled]) {
        return;
    }
    
    _pauseForAnswerSlider.enabled = YES;
    
    [_pauseForAnswerSlider showPopUpViewAnimated:NO];
    
    _pauseForAnswerLabel.enabled = YES;
    _minPauseForAnswerLabel.enabled = YES;
    _maxPauseForAnswerLabel.enabled = YES;
    
}

- (void) enableDwellTimeSlider {
    
    if ([self isDwellTimeSliderEnabled]) {
        return;
    }
    
    _dwellTimeSlider.enabled = YES;
    [_dwellTimeSlider showPopUpViewAnimated:YES];
    
    _minDwellTimeLabel.enabled = YES;
    _maxDwellTimeLabel.enabled = YES;
}

- (void) disablePauseForAnswerSlider {
    
    if ([self isPauseForAnswerSliderEnabled] == FALSE) {
        return;
    }
    
    _pauseForAnswerSlider.enabled = NO;
    
    [_pauseForAnswerSlider hidePopUpViewAnimated:NO];
    
    _pauseForAnswerLabel.enabled = NO;
    _minPauseForAnswerLabel.enabled = NO;
    _maxPauseForAnswerLabel.enabled = NO;
    
}

- (void) disableDwellTimeSlider {
    
    if ([self isDwellTimeSliderEnabled] == FALSE) {
        return;
    }
    
    _dwellTimeSlider.enabled = NO;
    [_dwellTimeSlider hidePopUpViewAnimated:NO];
    
    _minDwellTimeLabel.enabled = NO;
    _maxDwellTimeLabel.enabled = NO;
    
}

- (BOOL) isPauseForAnswerSliderEnabled {
    return _pauseForAnswerSlider.enabled;
}

- (BOOL) isDwellTimeSliderEnabled {
    return _dwellTimeSlider.enabled;
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

/*
 * position = -1, 前一张;position = 0, 当前; position =1, 后一张
 */
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
    
    _isShuttingDown = YES;
    
    if ([UIApplication sharedApplication].idleTimerDisabled == YES) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
    
    [_scrollView cleanupNSTimer];
    
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


/**
 *  由于是个延时调用，我们必须重新check
 */
- (void) switchQAFromTimerForFixedDelay {
    
    if (_isAutoScroll == FALSE) {
        return;
    }
    
    if (_isAutoShowQuestionOnly == YES) {
        return;
    }
    
    if (_isAutoScroll&& [self isSmartDelay]) {
        return;
    }
    
    [self switchQuestionAnswerViewWithHand:FALSE];
    
    if (_timerForDwellOnAnswerExpire_FixedDelayModeOnly) {
        [_timerForDwellOnAnswerExpire_FixedDelayModeOnly invalidate];
        _timerForDwellOnAnswerExpire_FixedDelayModeOnly = nil;
    }
    
    _timerForDwellOnAnswerExpire_FixedDelayModeOnly = [NSTimer scheduledTimerWithTimeInterval:(_dwellTimeSlider.value) target:self selector:@selector(didFinishDwellOnAnswerCard_FixedDelayModeOnly) userInfo:nil repeats:NO];
    
    
}


- (void) autoHideControlerPanel {
    _controlPanel.hidden = YES;
}



/**
 *  isManulally == YES: 来自CMMotionManager或tap或gesture action
 *  isManulally == NO: 来自NSTimer或text2SpeechFinished自动回调
 */
- (void) switchQuestionAnswerViewWithHand:(BOOL)isManually{
    
    if (_isAutoScroll && isManually) {
        return; //we don't allow to switch manually during auto play mode
    }
    
    
    [iConsole info:@"%s",__FUNCTION__];
    
    FlashCard *currentFlashCardView = [self getCurrrentCard];
    
    if (_isAutoScroll && ([currentFlashCardView isQuestionShowing] == FALSE)) {
        //we don't allow to automatically switch from answer to question again
        return;
    }
    
    
    //加入这段代码的原因是为了防止误操作 (进入play mode后，1秒内不准切换到answer)
    NSDate*methodFinish =[NSDate date];
    NSTimeInterval executionTime =[methodFinish timeIntervalSinceDate:_startDate];
    if (executionTime <1.0) {
        return;
    }
    
    if ([currentFlashCardView isQuestionShowing]) {
        [self disableDwellTimeSlider];
    }
    
    if (currentFlashCardView) {
        
        if (isManually) {
            [_autoSwitchQATimerForFixedDelay invalidate];
            _autoSwitchQATimerForFixedDelay = nil;
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
    
    [self resetAutoHideControlPanelTimer];
    
    //当移动到最后一个卡片时，这时如果点击cycle button，则会自动触发重新开始。在fixed delay模式下，由于定时器一直在工作，所以不用加额外逻辑，而在auto delay模式下，则需要模拟一个text2SpeechFinished事件
    if (_isAutoScroll && [self isSmartDelay] && (_currentPage == [[self.currentPack cards] count] -1)) {
        [self text2SpeechFinished:[NSNumber numberWithBool:NO]];
    }
    
    
}

/**
 *  同dwellTimeSliderClicked逻辑一样，简单化：先停止一切运行的，然后重启
 */
- (void) autoScrollButtonClicked:(UIButton *) button {
    
    FlashCard *currentCard = [self getCurrrentCard];
    [currentCard stopAudio];
    [currentCard stopTextToSpeechNow];
    
    [self invalidateAllTimers];
    [self resetAutoHideControlPanelTimer];
    
    if (_isAutoScroll == NO) {
        _isAutoScroll = YES;
        [self executeAutoPlay];
    } else {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        
        self.oneOffPlayType = One_Off_Play_Type_Unkown; //因为是one off的，所以一旦有新动作，需要重置
        
        [_dwellTimeSlider showPopUpViewAnimated:NO];
        [_pauseForAnswerSlider showPopUpViewAnimated:NO];
        
        _scrollView.userInteractionEnabled = YES;
        
        [_countDownLabel removeFromSuperview];
        [_messageToastBaseView removeFromSuperview];
        
        _isAutoScroll = NO;
        _scrollView.isAutoScroll = NO;
        [_autoScrollButton setImage:[UIImage imageNamed:@"auto_unselected"] forState:UIControlStateNormal];
        
        //_scrollView.userInteractionEnabled = YES;
        _scrollView.isFixedDelayAutoScroll = NO;
    }
}

/*
 * if both text to speech and recording exists, we play recording firstly then text to speech
 * execute textToSpeechAllContentNow or playAudio according to setting
*/
- (void) playbackOnCard:(FlashCard *) currentCard {
    
    if (currentCard) {
        if ([self isText2Speech] || [self isSmartDelay]) {
            
            if ([self isText2Speech] == FALSE) {
                currentCard.isMuteText2Speech = YES;  //这时我们进行mute播放
            } else {
                currentCard.isMuteText2Speech = NO;
            }
            
            if (_previousCard) {
                [_previousCard stopTextToSpeechNow];
                [_previousCard stopAudio];
            }
            if (_isShuttingDown == FALSE) {
                
                if (_isMute == false) {
                    
                    int durationForRecordedSound;
                    if ([currentCard isQuestionShowing]) {
                        durationForRecordedSound = [currentCard durationForQuestionRecordedSound];
                    } else {
                        durationForRecordedSound = [currentCard durationForAnswerRecordedSound];
                    }
                    if (durationForRecordedSound == 0) {
                        [currentCard textToSpeechAllContentNow];
                    } else {
                        [currentCard playAudioWithManualClick:NO withMute:_isMute];
                        double delayInSeconds = durationForRecordedSound + 1;  ////这里1秒是适当的，因为_pauseForAnswerSlider或K_IntervalBetweenCardSeconds_ForQAOnly都远大于这个数
                        
                        [_timerForDelayedText2Speech invalidate];
                        _timerForDelayedText2Speech = [NSTimer bk_scheduledTimerWithTimeInterval:delayInSeconds block:^(NSTimer *timer) {
                            if (_isShuttingDown == false) {
                                [currentCard textToSpeechAllContentNow];
                            }
                        } repeats:NO];
                        
                    }
                } else {
                    
                    [_timerForDelayedText2Speech invalidate];
                    [currentCard textToSpeechAllContentNow];
                    
                }
                
                
                
            }
        } else {
            
            [currentCard playAudioWithManualClick:NO withMute:_isMute];
        }
    } else {
        [iConsole error:@"%s,currentCard should not be nil",__FUNCTION__];
    };
}


- (FlashCard *) getCurrrentCard {
    FlashCard *currentCard = (FlashCard*)[_scrollView getCurrentView];
    return currentCard;
}


- (void) countDownTimer {
    
    int value = [_countDownLabel.text intValue];
    if (value == 1) {
        [_countDownLabel removeFromSuperview];
        [_messageToastBaseView removeFromSuperview];
        
        [_countDownTimer invalidate];
        _countDownTimer = nil;
    } else {
        _countDownLabel.text = [NSString stringWithFormat:@"%d",value - 1];
    }
    
}

- (void) firstTimeDelayTimer {
    
    [_firstTimeDelayTimer invalidate];
    _firstTimeDelayTimer = nil;
    
    _controlPanel.hidden = NO;
    _scrollView.userInteractionEnabled = YES;
    
    switch (self.oneOffPlayType) {
        case One_Off_Play_Type_Manually: {
            _isAutoScroll = NO;
            FlashCard *currentCard = [self  getCurrrentCard];
            if (currentCard) {
                [self playbackOnCard:currentCard];
            }
            
            break;
        }   
            
        case One_Off_Play_Type_Auto_Play:
            _isAutoScroll = YES;
            [self executeAutoPlay];
            break;
            
        case One_Off_Play_Type_Auto_Play_Loop:
            _isAutoScroll = YES;
            [self executeAutoPlay];
            [self cyclePlayButtonClicked:_cyclePlayButton];
            break;
            
        default:
            break;
    }

    
}

- (void) firstPageDelay_FixedMode_Timer {
    [self beginFixedDelayAutoScroll];
}

- (void) firstPageDelay_AutoDelayMode_Timer {
    FlashCard *currentCard = [self  getCurrrentCard];
    [self playbackOnCard:currentCard];
}


- (void) beginFixedDelayAutoScroll{
    
    if ([self isSmartDelay] || (_isAutoScroll == FALSE)) {
        return;
    }
    
    //_scrollView.userInteractionEnabled = NO;
    _scrollView.isFixedDelayAutoScroll = YES;
    
    if (_isAutoShowQuestionOnly) {
        _scrollView.dwellSecondsTotally = _dwellTimeSlider.value;
        _scrollView.dwellSecondsOnQuestion = _dwellTimeSlider.value;
    } else {
        _scrollView.dwellSecondsTotally = _dwellTimeSlider.value *2 + _pauseForAnswerSlider.value;
        _scrollView.dwellSecondsOnQuestion = _dwellTimeSlider.value;
    }
    
    if (_isAutoShowQuestionOnly) {
        _scrollView.intervalBetweenCardSeconds = _pauseForAnswerSlider.value;
    } else {
        _scrollView.intervalBetweenCardSeconds = K_IntervalBetweenCardSeconds_ForQAOnly;
    }
    
    FlashCard *currentCard = [self getCurrrentCard];
    _previousCard = currentCard;
    [self playbackOnCard:currentCard]; //这时，只是播放，而没有回调(自动切换到下一个page）的功能
    
    [self resetQASwitchTimer];
    
    
    
    
}

/**
 *  callback when click trumpet button
 */
- (void) playButtonClicked:(UIButton *) button {
    
    if (_isMute == FALSE) {
        FlashCard *currentCard = [self getCurrrentCard];
        if (currentCard) {
            [currentCard playAudioWithManualClick:YES withMute:_isMute];
        } else {
            [iConsole error:@"%s,currentCard should not be nil",__FUNCTION__];
        };
    }
    
    [self resetAutoHideControlPanelTimer];
}

- (void) muteButtonClicked:(UIButton *) button {
    
    FlashCard *currentFlashCardView = [self getCurrrentCard];
    
    if (_isMute) {
        _isMute = NO;
        [button setImage:[UIImage imageNamed:@"mute_unselected"] forState:UIControlStateNormal];
        [currentFlashCardView unMuteAudio];
    } else {
        _isMute = YES;
        [button setImage:[UIImage imageNamed:@"mute_selected"] forState:UIControlStateNormal];
        [currentFlashCardView muteAudio];
        
        
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:_isMute forKey:@"isMuteMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self resetAutoHideControlPanelTimer];
    
}


- (void) pauseForAnswerSliderClicked:(UISlider *) slider {

    if ([self isSmartDelay] == false) {
        //在smart delay中，我们并没有用到这个参数
        _scrollView.intervalBetweenCardSeconds = slider.value;
    }
    
    if (_isAutoShowQuestionOnly) {
        _scrollView.dwellSecondsTotally = (int)(_dwellTimeSlider.value);  
        _scrollView.dwellSecondsOnQuestion = (int)(_dwellTimeSlider.value);
    } else {
        _scrollView.dwellSecondsTotally = (int)(_dwellTimeSlider.value *2 + _pauseForAnswerSlider.value);
        _scrollView.dwellSecondsOnQuestion = (int)(_dwellTimeSlider.value);
    }
    
    
    [self resetAutoHideControlPanelTimer];
    
}


/**
 *  为避免复杂的逻辑，一刀切，简单化，执行如下操作
 *  1. 停止所有的声音播放
 *  2. 停止所有的count down逻辑 （包括显示和toast message）
 *  3. 停止所有的delay timer （包括auto hide)
 *  4. 重启
 */
- (void) dwellTimeSliderClicked:(ASValueTrackingSlider *) slider {
    
    //1.
    FlashCard *currentCard = [self getCurrrentCard];
    [currentCard stopAudio];
    [currentCard stopTextToSpeechNow];
    
    
    //2.
    [_countDownLabel removeFromSuperview];
    [_messageToastBaseView removeFromSuperview];
    
    //3.
    [self invalidateAllTimers];
    [self resetAutoHideControlPanelTimer];
    
    
    //4.
    int val = (int)slider.value;
    if (val == kMIN_Auto_Play_Speed) {
        _scrollView.isFixedDelayAutoScroll = NO;
    } else {
        _scrollView.isFixedDelayAutoScroll = YES;
        self.oneOffPlayType = One_Off_Play_Type_Unkown;  //因为是one off的，所以一旦有新动作，需要重置
    }
    
    if (_isAutoShowQuestionOnly) {
        _scrollView.dwellSecondsTotally = (int)(_dwellTimeSlider.value);
        _scrollView.dwellSecondsOnQuestion = (int)(_dwellTimeSlider.value);
    } else {
        _scrollView.dwellSecondsTotally = (int)(_dwellTimeSlider.value *2 + _pauseForAnswerSlider.value);
        _scrollView.dwellSecondsOnQuestion = (int)(_dwellTimeSlider.value);
    }
    
    _currentPack.autoPlaySpeed = slider.value;

    //if isSmartDelay = YES, we use Timer to trigger scrolling to next page
    //if isSmartDelay = NO, we use speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance
    if ([self isSmartDelay] == false) {
        if (_isAutoScroll) {
            [self beginFixedDelayAutoScroll];
        }
    } else
    {
        [self playbackOnCard:currentCard];
    }

    
}

/**
 *  在fixed delay模式中，在answer中，如果时间超过_dwellTimeSlider.value，则需要关闭text to speech
 */
- (void) didFinishDwellOnAnswerCard_FixedDelayModeOnly {
    
    if ([self isText2Speech] && ([self isSmartDelay] == FALSE)) { //需要限制条件
        FlashCard *currentCard = [self getCurrrentCard];
        [currentCard stopTextToSpeechNow];
    }
}

#pragma mark – CycleScrollViewDelegate

/**
 *  在fixed delay模式中，在question中，如果时间超过_dwellTimeSlider.value，则需要关闭text to speech
 */
- (void)didFinishDwellOnQuestionCard {
    if ([self isText2Speech] && ([self isSmartDelay] == FALSE)) { //需要限制条件
        FlashCard *currentCard = [self getCurrrentCard];
        [currentCard stopTextToSpeechNow];
    }
}

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
    
    if (_isAutoScroll) {
        [self enableDwellTimeSlider];
    }
    
    _currentPage = index;
    
    FlashCard *currentCard = [self getCurrrentCard];
    [self playbackOnCard:currentCard];
    _previousCard = currentCard;
    
    
    [self resetQASwitchTimer];
}

/**
 *  仅仅用于fixed delay mode
 */
- (void) resetQASwitchTimer {
    
    float seconds = (_dwellTimeSlider.value + _pauseForAnswerSlider.value);
    
    if (_autoSwitchQATimerForFixedDelay) {
        [_autoSwitchQATimerForFixedDelay invalidate];
        _autoSwitchQATimerForFixedDelay = nil;
    }
    if (_isAutoScroll && (_isAutoShowQuestionOnly == NO) && ([self isSmartDelay] == FALSE)) {
        [_autoSwitchQATimerForFixedDelay invalidate];
        _autoSwitchQATimerForFixedDelay = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(switchQAFromTimerForFixedDelay) userInfo:nil repeats:NO];
    }
    
}

- (void) switchControlPanelVisibility {
    [self resetAutoHideControlPanelTimer];
    [_controlPanel setHidden:!(_controlPanel.hidden)];
}


- (void) resetAutoHideControlPanelTimer {
    if (_autoHideControlPanelTimer) {
        [_autoHideControlPanelTimer invalidate];
        _autoHideControlPanelTimer = nil;
    }
    _autoHideControlPanelTimer = [NSTimer scheduledTimerWithTimeInterval:K_AutoHideControlPanelDwellSeconds target:self selector:@selector(autoHideControlerPanel) userInfo:nil repeats:NO];
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


-(void)executeAutoPlay {
    
    NSNumber *countDownNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"K_CountDown_Val"];
    int countDown;
    if (countDownNumber) {
        countDown = [countDownNumber integerValue];
    } else {
        countDown = kDEFAULT_CountDown_Slider_Value;
    }
    
    if (_countDownLabel || countDown == 0) {
        [_countDownLabel removeFromSuperview];
        [_messageToastBaseView removeFromSuperview];
    }
    _countDownLabel.text = [NSString stringWithFormat:@"%d",countDown];
    if (countDown > 0) {
        _countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDownTimer) userInfo:nil repeats:YES];
        [self.view addSubview:_countDownLabel];
        [self.view addSubview:_messageToastBaseView];
    }
    
    BOOL isShowQuestionOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"isShowQuestionOnly"];
    if (isShowQuestionOnly) {
        _isAutoShowQuestionOnly = YES;
        
    } else {
        _isAutoShowQuestionOnly = NO;
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    _scrollView.isAutoScroll = YES;
    
    [self enableDwellTimeSlider];
    if ([self isSmartDelay]) {
        [self enablePauseForAnswerSlider];
    } else {
        [self enablePauseForAnswerSlider];  //we don't use disablePauseForAnswerSlider any more
    }
    
    
    _scrollView.userInteractionEnabled = FALSE;
    [_autoScrollButton setImage:[UIImage imageNamed:@"auto_selected"] forState:UIControlStateNormal];
    
    

    if ([self isSmartDelay] == false) {
        [_firstPageDelay_FixedMode_Timer invalidate];
        _firstPageDelay_FixedMode_Timer = [NSTimer scheduledTimerWithTimeInterval:(countDown) target:self selector:@selector(firstPageDelay_FixedMode_Timer) userInfo:nil repeats:NO];
    } {
        [_firstPageDelay_AutoDelayMode_Timer invalidate];
        _firstPageDelay_AutoDelayMode_Timer = [NSTimer scheduledTimerWithTimeInterval:(countDown) target:self selector:@selector(firstPageDelay_AutoDelayMode_Timer) userInfo:nil repeats:NO];
    }
    
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


#pragma mark – Text to speech callback from FlashCard


/**
 *  This method is only called when setting SmartDelay = YES
 *  will delay to scroll after _pauseForAnswerSlider.value
 */
- (void) text2SpeechFinished:(NSNumber *) isQuestionShowing {
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (_isAutoScroll && (isQuestionShowing == FALSE)) {
        [self enableDwellTimeSlider];
    }
    
    if ([self isSmartDelay] && _isAutoScroll) {
        if (_isAutoShowQuestionOnly) {
            double delayInSeconds = _pauseForAnswerSlider.value;
            [_timerAForText2SpeechFinished invalidate];
            _timerAForText2SpeechFinished = [NSTimer bk_scheduledTimerWithTimeInterval:delayInSeconds block:^(NSTimer *timer) {
                //我们需要这些条件，因为这是一个延时操作
                if ((_isShuttingDown == FALSE) && _isAutoScroll && [self isSmartDelay]) {
                    [_scrollView scrollNow];
                }
            } repeats:NO];
            
        } else {
            if ([isQuestionShowing boolValue]) {
                double delayInSeconds = _pauseForAnswerSlider.value;
                [_timerBForText2SpeechFinished invalidate];
                _timerBForText2SpeechFinished = [NSTimer bk_scheduledTimerWithTimeInterval:delayInSeconds block:^(NSTimer *timer) {
                    //我们需要这些条件，因为这是一个延时操作
                    if ((_isShuttingDown == FALSE) && _isAutoScroll && [self isSmartDelay]) {
                        [weakSelf switchQuestionAnswerViewWithHand:NO];
                    }
                } repeats:NO];
                
            } else {
                double delayInSeconds = K_IntervalBetweenCardSeconds_ForQAOnly;
                [_timerCForText2SpeechFinished invalidate];
                _timerCForText2SpeechFinished = [NSTimer bk_scheduledTimerWithTimeInterval:delayInSeconds block:^(NSTimer *timer) {
                    //我们需要这些条件，因为这是一个延时操作
                    if ((_isShuttingDown == FALSE) && _isAutoScroll && [self isSmartDelay]) {
                        [_scrollView scrollNow];
                    }
                } repeats:NO];
            }
        }
    } else {
        //do nothing
    }
    
    
}

- (BOOL) isText2Speech {
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"];
    return b;
}

/**
 *  是Auto play中的其中一种（另外一种是fixed delay，就是用NSTimer进行固定时间间隔的切换卡片
 *  这是一种智能的方式，只有文本读完了，才切换到下一个卡片
 */
- (BOOL) isSmartDelay {
    //我们采用了一种非常特殊的方法，就是slider的值到了最小值时，isSmartDelay ＝ YES
    
    if (self.oneOffPlayType == One_Off_Play_Type_Auto_Play || self.oneOffPlayType == One_Off_Play_Type_Auto_Play_Loop) {
        return YES;
    } else {
        //我们不check else的状态
    }
    
    
    if ((int)_dwellTimeSlider.value == kMIN_Auto_Play_Speed) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark – ASValueTrackingSliderDataSource
/**
 *  仅能用来更新indicator string，而不能做其它逻辑。原因在于这个方法会在重画/或重布局时被调用，而不是只有值改变时才被调用
 */
- (NSString *)slider:(ASValueTrackingSlider *)slider stringForValue:(float)value;
{
    NSString *s;
    if (value == kMIN_Auto_Play_Speed) {
        s = NSLocalizedString(@"Title_Auto",@"");
    } else {
        s = [NSString stringWithFormat:@"%d",(int)value];
    }
    return s;
}

#pragma mark -
#pragma mark - Memory Management

- (void) invalidateAllTimers {
    [_timerForDwellOnAnswerExpire_FixedDelayModeOnly invalidate];
    _timerForDwellOnAnswerExpire_FixedDelayModeOnly = nil;
    
    [_autoSwitchQATimerForFixedDelay invalidate];
    _autoSwitchQATimerForFixedDelay = nil;
    
    [_firstPageDelay_FixedMode_Timer invalidate];
    _firstPageDelay_FixedMode_Timer = nil;
    
    [_firstPageDelay_AutoDelayMode_Timer invalidate];
    _firstPageDelay_AutoDelayMode_Timer = nil;
    
    [_firstTimeDelayTimer invalidate];
    _firstTimeDelayTimer = nil;
    
    [_countDownTimer invalidate];
    _countDownTimer = nil;
    
    [_timerAForText2SpeechFinished invalidate];
    _timerAForText2SpeechFinished = nil;
    
    [_timerBForText2SpeechFinished invalidate];
    _timerBForText2SpeechFinished = nil;
    
    [_timerCForText2SpeechFinished invalidate];
    _timerCForText2SpeechFinished = nil;
    
    [_timerForDelayedText2Speech invalidate];
    _timerForDelayedText2Speech = nil;
}


- (void)dealloc {
    
    [iConsole info:@"%s",__FUNCTION__];
    
    [self invalidateAllTimers];
    
    _scrollView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}



@end
