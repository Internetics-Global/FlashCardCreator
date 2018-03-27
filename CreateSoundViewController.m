//
//  CreateSoundViewController.m
//  NoiseMeter
//
//  Created by Bourne Wang on 14-2-13.
//  Copyright (c) 2014年 Internetics Pty Ltd. All rights reserved.
//

#import "CreateSoundViewController.h"
#import "FileOperationHelper.h"
#import "Card.h"
#import "FCCBarButton.h"
#import "DKCircleButton.h"
#import "AppDelegate.h"

#define k_Max_Record_Second   30


@interface CreateSoundViewController () {
    AVAudioPlayer      *_player;
    
}

@property (strong, nonatomic) IBOutlet DKCircleButton *startButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *playButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *saveButton;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *alertLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *dismissButton;

@end

@implementation CreateSoundViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = NSLocalizedString(@"Title_Record_Card_Sound",@"");
    
    if (isUserInterfaceIdiomPhone) {
      self.startButton = [[DKCircleButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2 - 45, 25,90,90)];
    } else {
        self.startButton = [[DKCircleButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2 - 45, 200,90,90)];
    }
    
    self.startButton.titleLabel.font = [UIFont systemFontOfSize:18];
    self.startButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin;
    
    [self.startButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateSelected];
    [self.startButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateHighlighted];
    
    [self.startButton setTitle:NSLocalizedString(@"Title_Record_Start",@"") forState:UIControlStateNormal];
    [self.startButton setTitle:NSLocalizedString(@"Title_Record_Start",@"") forState:UIControlStateSelected];
    [self.startButton setTitle:NSLocalizedString(@"Title_Record_Start",@"") forState:UIControlStateHighlighted];

    
    [self.startButton addTarget:self action:@selector(startButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];
    
    self.playButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.playButton.layer.borderWidth = 1;
    self.playButton.showsTouchWhenHighlighted = YES;
    
    self.saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveButton.layer.borderWidth = 1;
    self.saveButton.showsTouchWhenHighlighted = YES;
    
    _playButton.hidden = YES;
    _saveButton.hidden = YES;
    
    _startButton.layer.cornerRadius =45;
//    _startButton.layer.shadowColor = [[UIColor redColor] CGColor];
//    _startButton.layer.shadowOpacity = 1.0f;
    _startButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _startButton.layer.borderWidth = 1;
//    _startButton.layer.shadowRadius = 10.0f;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"close2_button"] target:self action:@selector(dismiss)]];
    
    
    APP_DELEGATE.recorder.delegate = self;
    
    if (APP_DELEGATE.isRecordFinished) {
        
        [APP_DELEGATE.recorder stop];
        
        self.playButton.hidden = NO;
        self.saveButton.hidden = NO;
        
        [self.alertLabel setText:NSLocalizedString(@"Record_Introduction_Text2",@"")];
        

        [APP_DELEGATE setupAudioWithoutRecord];
        
    } else {
        self.playButton.hidden = YES;
        self.saveButton.hidden = YES;

        [self.alertLabel setText:NSLocalizedString(@"Record_Introduction_Text",@"")];
        
        [APP_DELEGATE setupAudioWithRecord];


    }
    

}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    BOOL isExistRecordedSound;
    if (self.isOnQuestion) {
        if (_card.question.recordedSoundFullPath.length > 0) {
            isExistRecordedSound = YES;
        } else {
            isExistRecordedSound = NO;
        }
    } else {
        if (_card.answer.recordedSoundFullPath.length > 0 ) {
            isExistRecordedSound = YES;
        } else {
            isExistRecordedSound = NO;
        }
    }
    
    if (isExistRecordedSound) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"delete_button"] target:self action:@selector(delete)]];
    }
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)startButtonClicked:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [APP_DELEGATE setupAudioWithRecord];
    
    APP_DELEGATE.isRecordFinished = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"K_CreateSoundViewController_Dimissed_Notification" object:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"is_to_recording"] userInfo:nil];
    
}


- (IBAction)playButtonClicked:(id)sender {
    
    NSError *error;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[self tempRecordedFilePath]
                                                                   error:&error];
    _player.delegate = self;
    _player.numberOfLoops = 0;
    [_player prepareToPlay];
    
    if (_player == nil)
		[iConsole error:@"%s:%@",__FUNCTION__,[error description]];
	else
		[_player play];
    
}

- (IBAction)closeButtonClicked:(id)sender {
    [self dismiss];
}

- (IBAction)saveButtonClicked:(id)sender {
    
    if ([_player isPlaying]) {
        [_player stop];
    }
    
    NSString *saveTo = [FileOperationHelper generateUniqueAudioAACFilePathUnderImagesFolder];;
    if (_isOnQuestion) {
        if (_card.question.recordedSoundFullPath.length == 0) {
            _card.question.recordedSoundFullPath = saveTo;
        }  else {
            saveTo = _card.question.recordedSoundFullPath;
        }
    } else {
        if (_card.answer.recordedSoundFullPath.length == 0) {
            _card.answer.recordedSoundFullPath = saveTo;
        } else {
            saveTo = _card.answer.recordedSoundFullPath;
        }
    }
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:saveTo error:&error];
    [[NSFileManager defaultManager] moveItemAtPath:[self tempRecordedPathString]
                                            toPath:saveTo
                                             error:&error];
    if (error) {
        [iConsole error:@"%s:%@",__FUNCTION__,[error localizedDescription]];
    }
    
    if (self.isFromNewCreatedCard) {
        //we don't save here
        //and we assign value to _card.answer/question.recordedSoundFullPath
    } else {
      [_card save];    
    }
    
    
    [self dismiss];
    
    {
        //update_date info
        NSString *updateDate = [FileOperationHelper getTodayString];
        NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_pack.packName];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
        [dict setObject:updateDate forKey:@"update_date"];
        
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:_pack.packName];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        if (_isOnQuestion) {
            [dict setObject:saveTo forKey:@"question"];
        } else {
            [dict setObject:saveTo forKey:@"answer"];
        }
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SOUND_RECORDING_SAVED_NOTIFICATION object:nil userInfo:dict];
    }
    
    
}

- (void) delete {
    NSError *error;
    if (self.isOnQuestion) {
        if (_card.question.recordedSoundFullPath.length > 0) {
            [[NSFileManager defaultManager] removeItemAtPath:_card.question.recordedSoundFullPath error:&error];
        }
        _card.question.recordedSoundFullPath = @"";
    } else {
       _card.answer.recordedSoundFullPath = @"";
        if (_card.answer.recordedSoundFullPath.length > 0) {
            [[NSFileManager defaultManager] removeItemAtPath:_card.answer.recordedSoundFullPath error:&error];
        }
    }
    
    if (error) {
      [iConsole info:@"%s:%@",__FUNCTION__,[error description]];
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_RECORDED_SOUND_REMOVED",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
    [alertView show];
    
    self.navigationItem.leftBarButtonItem = nil;
    
    if (self.isFromNewCreatedCard) {
        //we don't save here
    } else {
        [_card save];
    }
}

/*
 * Diff with start recording and dismiss, it's simply used to dimiss recording view and exit whole recording process
 */
- (void) dismiss {
    
  APP_DELEGATE.isRecordFinished = NO; //back to normal
  [[NSNotificationCenter defaultCenter] postNotificationName:@"K_CreateSoundViewController_Dimissed_Notification" object:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"is_to_recording"] userInfo:nil];
    
  [self dismissViewControllerAnimated:YES completion:nil];
    
  [APP_DELEGATE setupAudioWithoutRecord];
    
}

- (NSURL *) tempRecordedFilePath {
    NSURL *url = [NSURL fileURLWithPath:[self tempRecordedPathString]];
    return url;
}

- (NSString *) tempRecordedPathString {
    NSString *url = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.aac"];
    return url;
}

#pragma mark – AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
  [iConsole info:@"%s",__FUNCTION__];
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
  [iConsole info:@"%s",__FUNCTION__];
}

#pragma mark – AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [iConsole info:@"%s",__FUNCTION__];
    _player = nil;
    
    
}

- (void)dealloc {
    APP_DELEGATE.recorder.delegate = nil;
    _player = nil;
    
}

@end
