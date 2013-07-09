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
    [self initialzeCardViews];
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
    _scrollView.delegate = self;
    _scrollView.bounces = YES;
    _scrollView.backgroundColor =[UIColor clearColor];
    
    if (isUserInterfaceIdiomPhone){
        _closeButton.frame = CGRectMake(IPHONE_UI_WIDTH-40, 10, 30, 30);
        _scrollView.frame = CGRectMake(0, IPHONE_UI_NAVIGATION_BAR_HEIGHT, IPHONE_UI_WIDTH, IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT);
    } else {
        _closeButton.frame = CGRectMake(IPAD_UI_WIDTH-40, 10, 30, 30);
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
    
    [self showCurrentCardInScrollView:YES];
    
}

- (void)layoutScrollObjectsForiPad
{
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
    [_scrollView addSubview:_currentFlashCardView];
    
    [_currentFlashCardView refreshAll];
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
        [_scrollView addSubview:_previousFlashCardView];
        
        [_previousFlashCardView refreshAll];
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
        [_scrollView addSubview:_nextFlashCardView];
        
        [_nextFlashCardView refreshAll];
        [_nextFlashCardView disableCardEdit];
        [_nextFlashCardView.segmentedControl setHidden:YES];
    }
    
}


- (void)layoutScrollObjectsForiPhone
{
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
    [_scrollView addSubview:_currentFlashCardView];
    
    [_currentFlashCardView refreshAll];
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
        [_scrollView addSubview:_previousFlashCardView];
        
        [_previousFlashCardView refreshAll];
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
        [_scrollView addSubview:_nextFlashCardView];
        
        [_nextFlashCardView refreshAll];
        [_nextFlashCardView disableCardEdit];
        [_nextFlashCardView.segmentedControl setHidden:YES];
    }
    
}


- (void) closePlayView {
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void) initialzeCardViews {
    
    float flashCardYPositionInScrollView;
    
    if (isUserInterfaceIdiomPhone) {
        
        flashCardYPositionInScrollView = (IPHONE_UI_HEIGHT-IPHONE_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_PlayMode_iPhone)/2+IPHONE_UI_NAVIGATION_BAR_HEIGHT/2; //Since it's horizontal movement, so this is a constant value
        _currentFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPhone,kFlashCardViewHeight_PlayMode_iPhone) defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard]];
        _previousFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPhone,kFlashCardViewHeight_PlayMode_iPhone)
                                                defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard]];
        _nextFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPHONE_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPhone)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPhone,kFlashCardViewHeight_PlayMode_iPhone)
                                             defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard]];
        
    } else {
        
        flashCardYPositionInScrollView = (IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT-kFlashCardViewHeight_PlayMode_iPad)/2+IPAD_UI_NAVIGATION_BAR_HEIGHT/2; //Since it's horizontal movement, so this
        
        _currentFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)
                                                 defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard]];
        _previousFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)
                                                defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard]];
        _nextFlashCardView = [[FlashCard alloc] initWithFrame:CGRectMake((IPAD_UI_WIDTH-kFlashCardViewWidth_PlayMode_iPad)/2,flashCardYPositionInScrollView,kFlashCardViewWidth_PlayMode_iPad,kFlashCardViewHeight_PlayMode_iPad)
                                             defaultPack:_currentPack defaultCard:_shuffledCardArray[_indexCard]];
    }
    
    [[_currentFlashCardView layer] setShadowOffset:CGSizeMake(1, 1)];
    [[_currentFlashCardView layer] setShadowRadius:3];
    [[_currentFlashCardView layer] setShadowOpacity:0.5];
    [[_currentFlashCardView layer] setShadowColor:[UIColor whiteColor].CGColor];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    NSLog (@"current page is :%d", page);
    
    if ((page == _indexCard +1) || (page == _indexCard -1)) {
        _scrollView.userInteractionEnabled = FALSE; // avoid blank pages.
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
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
    }
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

- (void) addGestureSupport {
    UISwipeGestureRecognizer * recognizerUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureUpAction:)];
    [recognizerUp setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [_currentFlashCardView addGestureRecognizer:recognizerUp];
    
    UISwipeGestureRecognizer * recognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDownAction:)];
    [recognizerDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [_currentFlashCardView addGestureRecognizer:recognizerDown];
    
    
}

- (void)gestureUpAction:(UITapGestureRecognizer *)sender {
    if (_currentFlashCardView.segmentedControl.selectedSegmentIndex == 1) {
        [self switchQuestionAnswerView];
    }
}

- (void)gestureDownAction:(UITapGestureRecognizer *)sender {
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
