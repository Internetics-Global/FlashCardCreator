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

typedef NS_ENUM(NSInteger, Enum_Status_Record) {
    Enum_Status_Record_Unknow      = -1,
    Enum_Status_Record_Recording       = 1,
    Enum_Status_Record_Normal   = 2,
    Enum_Status_Record_Stop    = 3,
};

@interface CreateSoundViewController () {
    AVAudioRecorder    *_recorder;
    AVAudioPlayer      *_player;
    
    Enum_Status_Record                _recordStatus;
}

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *startButton;
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
    
    self.title = @"Record card Sound";
    
    _recordStatus = Enum_Status_Record_Normal;
    
    self.playButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.playButton.layer.borderWidth = 1;
    
    self.saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveButton.layer.borderWidth = 1;
    
    _playButton.hidden = YES;
    _saveButton.hidden = YES;
    
    _startButton.layer.cornerRadius =45;
//    _startButton.layer.shadowColor = [[UIColor redColor] CGColor];
//    _startButton.layer.shadowOpacity = 1.0f;
    _startButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _startButton.layer.borderWidth = 1;
//    _startButton.layer.shadowRadius = 10.0f;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithCustomView:[FCCBarButton buttonWithImage:[UIImage imageNamed:@"close2_button"] target:self action:@selector(dismiss)]];
    
    [self setupRecord];
    

}

- (void) setupRecord {
    
    NSError *error;
    //这个为必须的，否则无法
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    _recorder = [[AVAudioRecorder alloc] initWithURL:[self tempRecordedFilePath] settings:recordSetting error:NULL];
    _recorder.delegate = self;
    _recorder.meteringEnabled = YES;
    [_recorder prepareToRecord];
    
    
    BOOL success = FALSE;
    success = [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    if (!success)  {
        NSLog(@"%s:AVAudioSession error overrideOutputAudioPort %@",__FUNCTION__,error);
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)startButtonClicked:(id)sender {
    
    switch (_recordStatus) {
        case Enum_Status_Record_Normal: {
            
            _recordStatus = Enum_Status_Record_Recording;
            
            [_startButton setTitle:@"Stop" forState:UIControlStateNormal];
            
            [_recorder record];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                _playButton.hidden = YES;
                _saveButton.hidden = YES;
                
                usleep(500000);
                
                NSDate*start =[NSDate date];
                while (_recordStatus == Enum_Status_Record_Recording) {
                    usleep(10000);
                    NSDate* methodFinish =[NSDate date];
                    NSTimeInterval executionTime =[methodFinish timeIntervalSinceDate:start];
                    if (executionTime > 10) {
                        NSLog(@"%s:finish recording a new customized sound",__FUNCTION__);
                        break;
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_alertLabel setText:[NSString stringWithFormat:@"Time left: %.2f",10.0 - executionTime]];
                    
                    });
                }
                
                usleep(200000);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_alertLabel setText:@"When you click “Record” you have a maximum of ten seconds to record your message. \n\nClick “Stop” when ready to stop recording.\n\nYou can then click “Play” to hear it, or “Save” to save it to the card."];
                    [_startButton setTitle:@"Record" forState:UIControlStateNormal];
                    
                    _playButton.hidden = NO;
                    _saveButton.hidden = NO;
                });
                
                
                [_recorder stop];
                
                
            });

        }
            break;
        
        case Enum_Status_Record_Recording: {
            _recordStatus = Enum_Status_Record_Stop;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_alertLabel setText:@"When you click “Record” you have a maximum of ten seconds to record your message. \n\nClick “Stop” when ready to stop recording.\n\nYou can then click “Play” to hear it, or “Save” to save it to the card."];
                [_startButton setTitle:@"Record" forState:UIControlStateNormal];
                
                _playButton.hidden = NO;
                _saveButton.hidden = NO;
            });
            
            usleep(200000);
            
            [_recorder stop];
            
            _recordStatus = Enum_Status_Record_Normal;
            
        }
            
        default:
            break;
    }
    
}


- (IBAction)playButtonClicked:(id)sender {
    
    NSError *error;
    //不能声明为局部变量，否则无法播放
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[self tempRecordedFilePath]
                                                                   error:&error];
    _player.delegate = self;
    _player.numberOfLoops = 0;
    [_player prepareToPlay];
    
    if (_player == nil)
		NSLog(@"%s:%@",__FUNCTION__,[error description]);
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
        NSLog(@"%s:%@",__FUNCTION__,[error localizedDescription]);
    }
    
    [_card save];
    [self dismiss];
    
    //update_date info
    NSString *updateDate = [FileOperationHelper getTodayString];
    NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_pack.packName];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
    [dict setObject:updateDate forKey:@"update_date"];
    
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:_pack.packName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
}

- (void) dismiss {

  [self dismissModalViewControllerAnimated:YES];
    
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
  NSLog(@"%s",__FUNCTION__);
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
  NSLog(@"%s",__FUNCTION__);
}

#pragma mark – AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"%s",__FUNCTION__);
    _player = nil;
    
    
}

- (void)dealloc {
    
    _player = nil;
    _recorder = nil;
    
}

@end
