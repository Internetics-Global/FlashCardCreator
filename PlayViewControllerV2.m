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

@interface PlayViewControllerV2 () <CycleScrollViewDatasource,CycleScrollViewDelegate> {
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
    
    UIView *_controlPanel;
    
    UIButton *_playButton;
    
}

@end

@implementation PlayViewControllerV2

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    FlashCard *currentCard = (FlashCard*)[_scrollView getCurrentView];
    _previousCard = currentCard;
    
    if (_isMute == FALSE) {
        if (currentCard) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"]) {
                double delayInSeconds = 0.5;
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
    
    
    NSString *recordSoundFile = currentCard.currentCard.question.recordedSoundFullPath;
    if (recordSoundFile.length == 0) {
        [_playButton setImage:[UIImage imageNamed:@"play25_dimmed"] forState:UIControlStateNormal];
    } else {
        [_playButton setImage:[UIImage imageNamed:@"play25_normal"] forState:UIControlStateNormal];
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
    
    UIButton *autoScrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
    autoScrollButton.frame = CGRectOffset(cyclePlayButton.frame, 20 + 20, 0);
    [autoScrollButton setImage:[UIImage imageNamed:@"auto_unselected"] forState:UIControlStateNormal];
    [autoScrollButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [autoScrollButton addTarget:self action:@selector(autoScrollButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //autoScrollButton.showsTouchWhenHighlighted =YES;
    [autoScrollButton setHitTestEdgeInsets:UIEdgeInsetsMake(-8, -8, -8, -8)];
    [_controlPanel addSubview:autoScrollButton];
    
    
    UILabel *autoPlayDelayLabel = [[UILabel alloc] initWithFrame:CGRectMake(90, 5, 90, 20)];
    autoPlayDelayLabel.textAlignment = NSTextAlignmentCenter;
    autoPlayDelayLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:10];
    autoPlayDelayLabel.text = @"Auto Play Speed";
    autoPlayDelayLabel.numberOfLines = 1;
    autoPlayDelayLabel.textColor = [UIColor whiteColor];
    autoPlayDelayLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:autoPlayDelayLabel];
    
    UISlider *autoPlayDelaySlider= [[UISlider alloc] initWithFrame:CGRectOffset(autoPlayDelayLabel.frame, 110, 0)];
    autoPlayDelaySlider.backgroundColor = [UIColor grayColor];
    [[UISlider appearance] setThumbImage:[UIImage imageNamed:@"slide_thumb"] forState:UIControlStateNormal];
    autoPlayDelaySlider.minimumValue = 3;
    autoPlayDelaySlider.maximumValue = 10.0;
    autoPlayDelaySlider.continuous = NO;
    autoPlayDelaySlider.value = k_Default_AutoPlayDelaySeconds;
    autoPlayDelaySlider.tintColor = [UIColor greenColor];
    [autoPlayDelaySlider addTarget:self action:@selector(autoPlayDelaySliderClicked:) forControlEvents:UIControlEventValueChanged];
    [autoPlayDelaySlider setBackgroundColor:[UIColor clearColor]];
    [_controlPanel addSubview: autoPlayDelaySlider];
    
    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(autoPlayDelaySlider.frame)- 20, 5, 20, 20)];
    minLabel.textAlignment = NSTextAlignmentRight;
    minLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    minLabel.text = @"4";
    minLabel.numberOfLines = 1;
    minLabel.textColor = [UIColor whiteColor];
    minLabel.backgroundColor = [UIColor clearColor];
    [_controlPanel addSubview:minLabel];
    
    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(autoPlayDelaySlider.frame), 5, 20, 20)];
    maxLabel.textAlignment = NSTextAlignmentLeft;
    maxLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    maxLabel.text = @"10";
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


- (FlashCard *)cardForiPad:(NSInteger)index
{
    [iConsole info:@"%s",__FUNCTION__];
    
    //2. Set current
    float flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_PlayMode_iPad)/2+IPAD_UI_NAVIGATION_BAR_HEIGHT/2; //Since it's horizontal movement, so this
    
    FlashCard *currentFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)
                                                 defaultPack:_currentPack defaultCard:_shuffledCardArray[index] isPlayingCard:YES];
    currentFlashCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    currentFlashCardView.calledViewController = self;//在iPad中，PlayViewControllerV2是通过modal方式出现的，这时如果点击logo image，通过rootViewController进行modal是不可行的，所以需要通过在calledViewController进行modal展示
    [currentFlashCardView refreshAll:[_isResizedArray[index] boolValue] withIndexPlaying:(int)index];
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
    //[self addGestureSupport]; :TODO:XXXX

    currentFlashCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    currentFlashCardView.calledViewController = self;//在iPad中，PlayViewControllerV2是通过modal方式出现的，这时如果点击logo image，通过rootViewController进行modal是不可行的，所以需要通过在calledViewController进行modal展示
    [currentFlashCardView refreshAll:[_isResizedArray[index] boolValue] withIndexPlaying:(int)index];
    [currentFlashCardView disableCardEdit];
    [currentFlashCardView.segmentedControl setHidden:YES];
    
    return currentFlashCardView;
    
}


- (void) dismiss {
    [iConsole info:@"%s",__FUNCTION__];
    
    [_scrollView clean];
    
    FlashCard *currentFlashCardView = (FlashCard *)[_scrollView getCurrentView];
    [currentFlashCardView stopTextToSpeechNow];
    
    _scrollView = nil;
    

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
    
    
    if (_isMute == FALSE) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"]) {
            [currentFlashCardView stopTextToSpeechNow];
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [currentFlashCardView textToSpeechAllContentNow];
            });;
        } else {
            [currentFlashCardView playAudio:NO];
        }
    }
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
    
    if (_isAutoScroll) {
        _isAutoScroll = NO;
        [button setImage:[UIImage imageNamed:@"auto_unselected"] forState:UIControlStateNormal];
    } else {
        _isAutoScroll = YES;
        [button setImage:[UIImage imageNamed:@"auto_selected"] forState:UIControlStateNormal];
    }
    
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:@"K_Not_Show_AutoScroll_Alert"];
    if (val) {
        
        if (_isAutoScroll) {
            _scrollView.userInteractionEnabled = NO;
            _scrollView.isAutoScroll = YES;
        } else {
            _scrollView.userInteractionEnabled = YES;
            _scrollView.isAutoScroll = NO;
        }
        
    } else {
        if (_isAutoScroll) {
            [UIAlertView showWithTitle:@"Autoplay enabled" message:@"You are in Auto Play mode, so you cannot manually operate the cards until you switch off Auto Play" cancelButtonTitle:@"OK" otherButtonTitles:@[@"Don't show me this again"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex == 0) {
                    
                } else {
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setBool:YES  forKey:@"K_Not_Show_AutoScroll_Alert"];
                    [defaults synchronize];
                }
                
                if (_isAutoScroll) {
                    _scrollView.userInteractionEnabled = NO;
                    _scrollView.isAutoScroll = YES;
                } else {
                    _scrollView.userInteractionEnabled = YES;
                    _scrollView.isAutoScroll = NO;
                }
                
            }];
        } else {
            if (_isAutoScroll) {
                _scrollView.userInteractionEnabled = NO;
                _scrollView.isAutoScroll = YES;
            } else {
                _scrollView.userInteractionEnabled = YES;
                _scrollView.isAutoScroll = NO;
            }
        }
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
        
        FlashCard *currentFlashCardView = (FlashCard *)[_scrollView getCurrentView];
        [currentFlashCardView stopAudio];
        
        
        
    }
    
}

- (void) autoPlayDelaySliderClicked:(UISlider *) slider {
    
    _scrollView.autoPlayDelaySeconds = slider.value;
    
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

- (void)didScrollToPage:(NSInteger)index {
     [iConsole info:@"%s",__FUNCTION__];
    FlashCard *currentCard = (FlashCard*)[_scrollView getCurrentView];
    if (_isMute == FALSE) {
        
        if (currentCard) {
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"]) {
                
                if (_previousCard) {
                    [_previousCard stopTextToSpeechNow];
                }
                
                double delayInSeconds = 0.5;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [currentCard textToSpeechAllContentNow];
                });;
            } else {
                [currentCard playAudio:NO];
            }
            
            
            NSString *recordSoundFile = currentCard.currentCard.question.recordedSoundFullPath;
            if (recordSoundFile.length == 0) {
                [_playButton setImage:[UIImage imageNamed:@"play25_dimmed"] forState:UIControlStateNormal];
            } else {
                [_playButton setImage:[UIImage imageNamed:@"play25_normal"] forState:UIControlStateNormal];
            }
            
            
        } else {
            [iConsole error:@"%s,currentCard should not be nil",__FUNCTION__];
        };
    }
    
    _previousCard = currentCard;
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
