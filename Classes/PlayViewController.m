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
#import "CSS.h"
#import "Question.h"
#import "Answer.h"
#import "Common.h"
#import "OpenUDID.h"
#import "SharkfoodMuteSwitchDetector.h"

@interface PlayViewController () {
    SharkfoodMuteSwitchDetector * _silenceDetector;
}



@end

@implementation PlayViewController

@synthesize currentPack = _currentPack;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _scrollView = [[UIScrollView alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(landscapeLeftRightOrientationChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(previousCardNotification:)
                                                     name:@"PREVIOUS_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(nextCardNotification:)
                                                     name:@"NEXT_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION"
                                                   object:nil];
        
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [iConsole info:@"%s",__FUNCTION__];
    [super viewWillAppear:animated];
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc]init];
    }
    
    static BOOL enableSwitch = YES;
    
    _motionManager.deviceMotionUpdateInterval =0.01;
    __weak PlayViewController *safeSelf = self;
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


- (void)viewWillDisappear:(BOOL)animated {
    [_motionManager stopDeviceMotionUpdates];
    _motionManager = nil;
}

- (void)viewDidLoad
{
    [iConsole info:@"%s",__FUNCTION__];
    
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
    
    
    _startDate =[NSDate date];
    
    [super viewDidLoad];
    
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
    
    [self initialzeCardViews];
	[self layoutView];
}



- (void)layoutView {
    _closeButton.backgroundColor = [UIColor clearColor];
    if (isUserInterfaceIdiomPhone) {
      [_closeButton setImage:[UIImage imageNamed:@"close_button.png"] forState:UIControlStateNormal];
    } else {
        [_closeButton setImage:[UIImage imageNamed:@"close_buttonBig.png"] forState:UIControlStateNormal];
    }
    
    _closeButton.titleLabel.text = nil;
    _closeButton.showsTouchWhenHighlighted = YES;
    [_closeButton addTarget:self action:@selector(closePlayView) forControlEvents:UIControlEventTouchDown];
    
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.clipsToBounds = YES;
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;

    _scrollView.bounces = YES;
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
    
    BOOL isRandomPlayMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRandomPlayMode"];
    if (isRandomPlayMode == YES) {
        _shuffledCardArray = [[_currentPack cards] randomised];
    } else {
        //Bubble sorting
        _shuffledCardArray = [[_currentPack cards] cardSNOrdered];
    }
    _isResizedArray = [NSMutableArray array];
    for (int i = 0;i<[_shuffledCardArray count];i++) {
        _isResizedArray[i]= @"NO";
    }
    
    [self showCurrentCardInScrollView:YES];
    
}

- (void)layoutScrollObjectsForiPad
{
    [iConsole info:@"%s",__FUNCTION__];
    CGRect rect;
    
    for (FlashCard *cardView in [_scrollView subviews]) {
        [cardView removeFromSuperview];
    }
    
    if (_shuffledCardArray.count == 0) {
        return;
    }
    
    //1. Content size
    [_scrollView setContentSize:CGSizeMake(([_shuffledCardArray count] * IPAD_UI_WIDTH), IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT)];
    
    //2. Set current
    
    _currentFlashCardView.currentCard = _shuffledCardArray[_indexCard];
    _currentFlashCardView.currentPack = _currentPack;
    _currentFlashCardView.calledViewController = self;
    [self addGestureSupport];
    
    rect = _currentFlashCardView.frame;
    CGFloat curXLoc = (IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2;
    curXLoc += IPAD_UI_WIDTH *_indexCard;
    rect.origin.x = curXLoc;
    _currentFlashCardView.frame = rect;
    _currentFlashCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    [_scrollView addSubview:_currentFlashCardView];
    
    [_currentFlashCardView refreshAll:[_isResizedArray[_indexCard] boolValue] withIndexPlaying:_indexCard];
    [_currentFlashCardView disableCardEdit];
    [_currentFlashCardView.segmentedControl setHidden:YES];
    
    //3. Set previous
    if (_indexCard == 0) {
        //_previousCardView = nil;
    } else {
        _previousFlashCardView.currentCard = _shuffledCardArray[_indexCard-1];
        _previousFlashCardView.currentPack = _currentPack;
        _previousFlashCardView.calledViewController = nil;
        rect.origin.x = curXLoc -IPAD_UI_WIDTH;
        _previousFlashCardView.frame = rect;
        _previousFlashCardView.tag = PREVIOUS_FLASHCARDVIEW_TAG;
        [_scrollView addSubview:_previousFlashCardView];
        
        [_previousFlashCardView refreshAll:[_isResizedArray[_indexCard -1] boolValue] withIndexPlaying:_indexCard -1 ];
        [_previousFlashCardView disableCardEdit];
        [_previousFlashCardView.segmentedControl setHidden:YES];
    }
    
    //5. Set next
    if (([_shuffledCardArray count]-1) == _indexCard) {
        //_nextCardView = nil;
    } else {
        _nextFlashCardView.currentCard = _shuffledCardArray[_indexCard+1];
        _nextFlashCardView.currentPack = _currentPack;
        _nextFlashCardView.calledViewController = nil;
        rect.origin.x = curXLoc +IPAD_UI_WIDTH;
        _nextFlashCardView.frame = rect;
        _nextFlashCardView.tag = NEXT_FLASHCARDVIEW_TAG;
        [_scrollView addSubview:_nextFlashCardView];
        
        [_nextFlashCardView refreshAll:[_isResizedArray[_indexCard+1] boolValue] withIndexPlaying:_indexCard+1];
        [_nextFlashCardView disableCardEdit];
        [_nextFlashCardView.segmentedControl setHidden:YES];
    }
    
}


- (void)layoutScrollObjectsForiPhone
{
    [iConsole info:@"%s",__FUNCTION__];
    
    CGRect rect;
    
    for (FlashCard *cardView in [_scrollView subviews]) {
        [cardView removeFromSuperview];
    }
    
    if (_shuffledCardArray.count == 0) {
        return;
    }
    
    //1. Content size
    [_scrollView setContentSize:CGSizeMake(([_shuffledCardArray count] * IPHONE_UI_WIDTH), IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT)];
    
    //2. Set current
    _currentFlashCardView.currentCard = _shuffledCardArray[_indexCard];
    _currentFlashCardView.currentPack = _currentPack;
    _currentFlashCardView.calledViewController = self;
    [self addGestureSupport];
    
    rect = _currentFlashCardView.frame;
    CGFloat curXLoc = (IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2;
    curXLoc += IPHONE_UI_WIDTH *_indexCard;
    rect.origin.x = curXLoc;
    _currentFlashCardView.frame = rect;
    _currentFlashCardView.tag = CURRENT_FLASHCARDVIEW_TAG;
    [_scrollView addSubview:_currentFlashCardView];
    
    [_currentFlashCardView refreshAll:[_isResizedArray[_indexCard] boolValue] withIndexPlaying:_indexCard];
    [_currentFlashCardView disableCardEdit];
    [_currentFlashCardView.segmentedControl setHidden:YES];
    
    //3. Set previous
    if (_indexCard == 0) {
        //_previousCardView = nil;
    } else {
        _previousFlashCardView.currentCard = _shuffledCardArray[_indexCard-1];
        _previousFlashCardView.currentPack = _currentPack;
        _previousFlashCardView.calledViewController = nil;
        rect.origin.x = curXLoc -IPHONE_UI_WIDTH;
        _previousFlashCardView.frame = rect;
        _previousFlashCardView.tag = PREVIOUS_FLASHCARDVIEW_TAG;
        [_scrollView addSubview:_previousFlashCardView];
        
        [_previousFlashCardView refreshAll:[_isResizedArray[_indexCard-1] boolValue] withIndexPlaying:_indexCard-1];
        [_previousFlashCardView disableCardEdit];
        [_previousFlashCardView.segmentedControl setHidden:YES];
    }
    
    //5. Set next
    if (([_shuffledCardArray count]-1) == _indexCard) {
        //_nextCardView = nil;
    } else {
        _nextFlashCardView.currentCard = _shuffledCardArray[_indexCard+1];
        _nextFlashCardView.currentPack = _currentPack;
        _nextFlashCardView.calledViewController = nil;
        rect.origin.x = curXLoc +IPHONE_UI_WIDTH;
        _nextFlashCardView.frame = rect;
        _nextFlashCardView.tag = NEXT_FLASHCARDVIEW_TAG;
        [_scrollView addSubview:_nextFlashCardView];
        
        [_nextFlashCardView refreshAll:[_isResizedArray[_indexCard+1] boolValue] withIndexPlaying:_indexCard+1];
        [_nextFlashCardView disableCardEdit];
        [_nextFlashCardView.segmentedControl setHidden:YES];
    }
    
}


- (void) closePlayView {
    [iConsole info:@"%s",__FUNCTION__];
    
    [_currentFlashCardView stopTextToSpeechNow];
    
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void) initialzeCardViews {
    [iConsole info:@"%s",__FUNCTION__];
    float flashCardYPositionInScrollView;
    
    if (isUserInterfaceIdiomPhone) {
        
        CGRect rect = CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2,
                                 (IPHONE_UI_HEIGHT-kFlashCardViewHeight_PlayMode_iPhone)/2,
                                 kFlashCardViewWidth_PlayMode_iPhone,
                                 kFlashCardViewHeight_PlayMode_iPhone);
        _currentFlashCardView = [[FlashCard alloc] initWithFrame:rect defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard] isPlayingCard:YES];
//        _currentFlashCardView.backgroundColor = [UIColor redColor];
        _previousFlashCardView = [[FlashCard alloc] initWithFrame:rect
                                                defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard] isPlayingCard:YES];
        _nextFlashCardView = [[FlashCard alloc] initWithFrame:rect
                                             defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard] isPlayingCard:YES];
        
    } else {
        
        flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_PlayMode_iPad)/2+IPAD_UI_NAVIGATION_BAR_HEIGHT/2; //Since it's horizontal movement, so this
        
        _currentFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)
                                                 defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard] isPlayingCard:YES];
        _previousFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)
                                                defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard] isPlayingCard:YES];
        _nextFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)
                                             defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard] isPlayingCard:YES];
    }
    
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [iConsole info:@"%s",__FUNCTION__];
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    //NSLog (@"current page is :%d", page);
    
    if ((page == _indexCard +1) || (page == _indexCard -1)) {
        _scrollView.userInteractionEnabled = FALSE; // avoid blank pages.
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [iConsole info:@"%s",__FUNCTION__];
    //Step1: calculate page(index)
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if ((page == _indexCard +1) || (page == _indexCard -1)) {
        _indexCard = page;
        [self showCurrentCardInScrollView:YES];
    }
    _scrollView.userInteractionEnabled = YES;
    
}

- (void) showCurrentCardInScrollView:(BOOL) shouldResetSegment {
    
    [iConsole info:@"%s",__FUNCTION__];
    
    
    
    if (isUserInterfaceIdiomPhone) {
        [self layoutScrollObjectsForiPhone];
        [_scrollView setContentOffset:CGPointMake(_indexCard*(IPHONE_UI_WIDTH),0) animated:NO];
    } else {
        [self layoutScrollObjectsForiPad];
        [_scrollView setContentOffset:CGPointMake(_indexCard*(IPAD_UI_WIDTH),0) animated:NO];
    }
    
    if ((shouldResetSegment == YES) && (_currentFlashCardView.segmentedControl.selectedSegmentIndex == 1)) {
        _currentFlashCardView.segmentedControl.selectedSegmentIndex = 0;
        [_currentFlashCardView segmentAction:nil];
        [_currentFlashCardView disableCardEdit];
    }
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"]) {
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [_currentFlashCardView textToSpeechAllContentNow];
        });;
    } else {
        [_currentFlashCardView playAudio];
    }
    
}


- (void) landscapeLeftRightOrientationChanged:(NSNotification *)notification{
    
    //[self.view.superview bringSubviewToFront:self.view];
}

- (void) switchQuestionAnswerView {
    [iConsole info:@"%s",__FUNCTION__];
    //加入这段代码的原因是为了防止误操作
    NSDate*methodFinish =[NSDate date];
    NSTimeInterval executionTime =[methodFinish timeIntervalSinceDate:_startDate];
    if (executionTime <2.5) {
        return;
    }
    
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
        [iConsole info:@"%s:current FlashCardView is empty",__FUNCTION__];
    }

    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isTextToSpeech"]) {
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [_currentFlashCardView textToSpeechAllContentNow];
        });;
    } else {
        [_currentFlashCardView playAudio];
    }
}

- (void) addGestureSupport {
    [iConsole info:@"%s",__FUNCTION__];
    UISwipeGestureRecognizer * recognizerUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureUpAction:)];
    [recognizerUp setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [_currentFlashCardView addGestureRecognizer:recognizerUp];
    
    UISwipeGestureRecognizer * recognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDownAction:)];
    [recognizerDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [_currentFlashCardView addGestureRecognizer:recognizerDown];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDownAction:)];
    [_currentFlashCardView addGestureRecognizer:tapGestureRecognizer];
    
    
}

- (void)tapDownAction:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    [self switchQuestionAnswerView];
}

- (void)gestureUpAction:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    if (_currentFlashCardView.segmentedControl.selectedSegmentIndex == 1) {
        [self switchQuestionAnswerView];
    }
}

- (void)gestureDownAction:(UITapGestureRecognizer *)sender {
    [iConsole info:@"%s",__FUNCTION__];
    if (_currentFlashCardView.segmentedControl.selectedSegmentIndex == 0) {
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


#pragma mark –  PREVIOUS_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION and NEXT_CARD_UPDATE_IN_PLAYMODE_NOTIFICATION

/**
 *  DetailViewController也有非常类似的逻辑
 *  previousCardNotification和nextCardNotification方法体逻辑基本一样，
 *  分开写虽然逻辑有些啰嗦，但是思路更清晰，
 */
-(void) previousCardNotification:(NSNotification *)notification {
    [iConsole info:@"%s",__FUNCTION__];
    if ([_currentPack.creator isEqualToString:[OpenUDID value]]) {
        return;
    }


    NSArray *myArray = [notification object];
    
    if (_indexCard >0) {
        
        if ([_isResizedArray[_indexCard - 1] boolValue] == YES) {
            return;
        }
        
        Card *card = _shuffledCardArray[_indexCard - 1];
        if (isUserInterfaceIdiomPhone) {
            //仅适用iPhone
            card.question.css.subheadingSize = [myArray[0] floatValue]/kFlashCardViewProporation_iPhone ;
            card.question.css.mainSize = [myArray[1] floatValue]/kFlashCardViewProporation_iPhone ;
            card.question.css.subSize = [myArray[2] floatValue]/kFlashCardViewProporation_iPhone;
        } else {
            card.question.css.subheadingSize = [myArray[0] floatValue] ;
            card.question.css.mainSize = [myArray[1] floatValue] ;
            card.question.css.subSize = [myArray[2] floatValue];
        }
        
        [iConsole info:@"%s:css.subheadingSize = %f, css.mainSize = %f and css.subSize = %f",__FUNCTION__,
              card.question.css.subheadingSize,card.question.css.mainSize,card.question.css.subSize];
        
        _isResizedArray[_indexCard - 1] = @YES;
        
    }
    
    
}

/**
 *  DetailViewController也有非常类似的逻辑
 *  previousCardNotification和nextCardNotification方法体逻辑基本一样，
 *  分开写虽然逻辑有些啰嗦，但是思路更清晰，
 */
-(void) nextCardNotification:(NSNotification *)notification {
    [iConsole info:@"%s",__FUNCTION__];
    if ([_currentPack.creator isEqualToString:[OpenUDID value]]) {
        return;
    }
    
    NSArray *myArray = [notification object];
    
    if (_indexCard < [_shuffledCardArray count] - 1) {
        
        if ([_isResizedArray[_indexCard + 1] boolValue] == YES) {
            return;
        }
        
        Card *card = _shuffledCardArray[_indexCard + 1];
        if (isUserInterfaceIdiomPhone) {
            card.question.css.subheadingSize = [myArray[0] floatValue]/kFlashCardViewProporation_iPhone;
            card.question.css.mainSize = [myArray[1] floatValue]/kFlashCardViewProporation_iPhone ;
            card.question.css.subSize = [myArray[2] floatValue]/kFlashCardViewProporation_iPhone ;
        } else {
            card.question.css.subheadingSize = [myArray[0] floatValue];
            card.question.css.mainSize = [myArray[1] floatValue] ;
            card.question.css.subSize = [myArray[2] floatValue] ;
        }
        
        [iConsole info:@"%s:css.subheadingSize = %f, css.mainSize = %f and css.subSize = %f",__FUNCTION__,
              card.question.css.subheadingSize,card.question.css.mainSize,card.question.css.subSize];
        
        _isResizedArray[_indexCard + 1] = @YES;
    }
    
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
    _silenceDetector = nil;
    _scrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [iConsole info:@"%s",__FUNCTION__];
}




@end
