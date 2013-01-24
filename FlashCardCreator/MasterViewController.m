//
//  MasterViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "User.h"
#import "CardCell.h"
#import "CreateCardViewController.h"
#import "DataManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ZipFileDownloadHelper.h"
#import "ZipArchive.h"
#import "MBProgressHUD.h"
#import "Question.h"
#import "Answer.h"
#import "Pack.h"
#import "Card.h"
#import "PackListViewController.h"

#import "UIImageView+AFNetworking.h"
#import "CreatePackViewController.h"
#import "UINavigationController+DismissKeyboard.h"
#import "DataManager.h"
#import "FileOperationHelper.h"
#import "MoreInfoTableViewController.h"


@implementation MasterViewController

@synthesize currentPack = _currentPack;
@synthesize currentCard = _currentCard;
@synthesize indexCard = _indexCard;
@synthesize backgroundOfCreateCardView = _backgroundOfCreateCardView;

#pragma mark -
#pragma mark - Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //1. Setup notification

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPackAddedNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCardAddedNotification:) name:NEW_CARD_ADDED_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedPackNotification:) name:CURRENT_PACK_SELECTED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterDetailViewNotification:) name:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadPackNotification:) name:DOWNLOAD_PACK_NOTIFICATION object:nil];
        
        //2. Initialize
        _currentPack = [[Pack alloc] init];
        _currentCard = [[Card alloc] init];
        _indexCard = 0;
        _zipFileDownloadHelp =[[ZipFileDownloadHelper alloc] init];
        
        //3. others
        self.title = NSLocalizedString(@"Master-card list", @"Master");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
        }
     
    

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    _selectPackButton = [[UIBarButtonItem alloc] initWithTitle:PUBLIC_PACK_NAME style:UIBarButtonSystemItemBookmarks target:self action:@selector(selectAvailablePacks:)];
    
    UIBarButtonItem *newPackButton = [[UIBarButtonItem alloc] initWithTitle:@"Add Pack" style:UIBarButtonSystemItemBookmarks target:self action:@selector(createNewPack:)];
    self.navigationItem.leftBarButtonItems = @[_selectPackButton,newPackButton];
    
    if (isUserInterfaceIdiomPhone) {
        UIBarButtonItem *settingButton = [[UIBarButtonItem alloc] initWithTitle:@"More" style:UIBarButtonItemStylePlain target:self action:@selector(moreButtonClicked:)];

        self.navigationItem.rightBarButtonItems =
            @[settingButton];
    }
    
    self.navigationItem.leftBarButtonItem.title = @"Available Packs";
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //[self.tableView setEditing:YES animated:YES];
    self.title = @"";
    [self.tableView reloadData];

    
}

- (void)viewWillAppear:(BOOL)animated {
    
    if (_addCardButton == nil) {
        _addCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];    
    }
    
    if (isUserInterfaceIdiomPhone ) {
        _addCardButton.center = CGPointMake(100,320-40);
    } else {
        _addCardButton.center = CGPointMake(IPAD_UI_MASTER_WIDTH/2,IPAD_UI_HEIGHT -100);
    }
    [_addCardButton setImage:[UIImage imageNamed:@"red_plus_up.png"] forState:UIControlStateNormal];
    [_addCardButton setImage:[UIImage imageNamed:@"red_plus_up.png"] forState:UIControlEventTouchDown];
    [_addCardButton addTarget:self action:@selector(createNewCard:) forControlEvents:UIControlEventTouchUpInside];
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController.view insertSubview:_addCardButton atIndex:0];
        [self.navigationController.view bringSubviewToFront:_addCardButton];
    } else {
        [self.splitViewController.view insertSubview:_addCardButton atIndex:0];
        [self.splitViewController.view bringSubviewToFront:_addCardButton];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [_addCardButton removeFromSuperview];
}

#pragma mark -
#pragma mark - Create or select Pack

- (void) createNewPack:(id)sender {
    CreatePackViewController * createPackController = [[CreatePackViewController alloc] init];
	UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:createPackController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:navController animated:YES];

}

- (void)selectAvailablePacks:(id)sender
{
    PackListViewController *packListViewController = [[PackListViewController alloc] initWithNibName:@"PackListViewController" bundle:nil];
    
    if (isUserInterfaceIdiomPhone) {
        packListViewController.view.frame = CGRectMake(10, 10, 320, 131);
        [self.navigationController pushViewController:packListViewController animated:YES];
        
    } else {
        packListViewController.view.frame = CGRectMake(10, 10, 640, 262);
        packListViewController.view.clipsToBounds = YES;
        packListViewController.view.layer.cornerRadius = 0;
        packListViewController.view.backgroundColor =[UIColor clearColor];
        packListViewController.contentSizeForViewInPopover = CGSizeMake(660, 262);
        
        if (_packListPickerPopover == nil) {
            _packListPickerPopover = [[UIPopoverController alloc] initWithContentViewController:packListViewController];
        }
        [_packListPickerPopover presentPopoverFromRect:CGRectMake(0, 0, 50, 50) inView:self.navigationController.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}

#pragma mark -
#pragma mark Create new card

- (void)createNewCard:(id)sender
{
    //For iPhone, we don't need it
    if (!isUserInterfaceIdiomPhone) {
        if (_backgroundOfCreateCardView == nil) {
            _backgroundOfCreateCardView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
        }
        _backgroundOfCreateCardView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8];
        [_backgroundOfCreateCardView addTarget:self action:@selector(dismissCreateCardView:) forControlEvents:UIControlEventTouchDown];
        [self.navigationController.view addSubview:_backgroundOfCreateCardView];
    }
    
    
    CreateCardViewController *createCardViewController = [[CreateCardViewController alloc] init];
    createCardViewController.currentPack = _currentPack;
    if (isUserInterfaceIdiomPhone){
        createCardViewController.view.frame =CGRectMake(0,0,IPAD_UI_DETAIL_WIDTH,IPAD_UI_HEIGHT-IPAD_UI_NAVIGATION_BAR_HEIGHT);
        [self.navigationController pushViewController:createCardViewController animated:YES];
    } else {
        createCardViewController.view.frame =CGRectMake(0,0,480,320-44);
        [self.detailViewController.navigationController pushViewController:createCardViewController animated:YES];
    }
    
}

- (void) dismissCreateCardView:(id)sender {
    if ([sender isMemberOfClass:[UIButton class]]) {
        [(UIButton *)sender removeFromSuperview];
    }
    [self.detailViewController.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIBarButtonItem action

- (void)moreButtonClicked:(id) sender
{
    MoreInfoTableViewController *moreInfoViewController = [[MoreInfoTableViewController alloc] init];
    [self.navigationController pushViewController:moreInfoViewController animated:YES];
}


#pragma mark -
#pragma mark Notfication related

- (void) downloadPackNotification:(NSNotification *) notification {
    NSString *url = (NSString *)[notification object];
    [self downloadURLViaURLScheme:url];
}


- (void) selectedPackNotification:(NSNotification *) notification {
    int index = [(NSString *)[notification object] intValue];
    self.currentPack = [[User defaultUser] packs][index];
    self.navigationItem.leftBarButtonItem.title = _currentPack.packName;
    
    if (!isUserInterfaceIdiomPhone) {
        [_packListPickerPopover dismissPopoverAnimated:YES];
    }
    
    [self.tableView reloadData];
    
}


-(void)newCardAddedNotification:(NSNotification *)notification{
	[self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:([[_currentPack cards] count]-1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [_backgroundOfCreateCardView removeFromSuperview];
}

-(void)newPackAddedNotification:(NSNotification *)notification{
	//warning: need to be implemented.
}

#pragma mark -
#pragma mark - Update UI

- (void) updateMasterDetailViewNotification:(NSNotification *) notification {
    //Step1: update master view
    self.currentPack = (Pack *)[notification object];
    self.indexCard = [[_currentPack cards] count] -1;
    _selectPackButton.title = _currentPack.packName;
    [self.tableView reloadData];
    
    //Step2: update detail view
    self.detailViewController.detailItem = _currentCard.cardName;
    self.detailViewController.currentCard = _currentCard;
    self.detailViewController.currentPack = _currentPack;
    self.detailViewController.indexCard = _indexCard;
    
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:([[_currentPack cards] count] -1) inSection:0];
    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
    
}


#pragma mark -
#pragma mark UITableViewDataSource and UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([DataManager apiReachable] == FALSE) {
        return 0;
    }
    
    return ([[_currentPack cards] count]); //test purpose
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (isUserInterfaceIdiomPhone) {
        return 100;
    } else {
        return 200;    
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CardCell";
    
    CardCell *cell = (CardCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[CardCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UIImageView *backgroundView = [[UIImageView alloc] init];
        backgroundView.backgroundColor = [UIColor colorWithRed:0.23 green:0.50 blue:0.82 alpha:0.90];
        backgroundView.layer.cornerRadius =5;
        [backgroundView.layer setMasksToBounds:YES];
        cell.selectedBackgroundView = backgroundView;
	}
    
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    Card *card = [_currentPack cards][indexPath.row];
    cell.indexLabel.text = [NSString stringWithFormat:@"%d",indexPath.row+1];
    
    cell.cellImageView.image = [UIImage imageWithContentsOfFile:card.coverImageURL];
    
    if (_indexCard == indexPath.row) {
        [cell setSelected:YES animated:YES];
    }

    

    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentCard = [_currentPack cards][indexPath.row];
    _indexCard = indexPath.row;

    if (_currentPack.packID == PUBLIC_PACK_ID) {
        [Common alertViewCommon:@"will implement this function soon"];
        
    } else {
        if (isUserInterfaceIdiomPhone ) {
            if (!self.detailViewController) {
                self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil];
            }
            self.detailViewController.currentCard = _currentCard;
            self.detailViewController.currentPack = _currentPack;
            self.detailViewController.indexCard = _indexCard;
            
            //We need to avoid do pushViewController twice.
            NSArray *viewControllerArray =self.navigationController.viewControllers;
            if (![[viewControllerArray objectAtIndex:[viewControllerArray count]-1] isKindOfClass:[self.detailViewController class]]) {
                [self.navigationController pushViewController:self.detailViewController animated:YES];
            }
        } else {
            self.detailViewController.currentCard = _currentCard;
            self.detailViewController.currentPack = _currentPack;
            self.detailViewController.indexCard = _indexCard;
            [self.detailViewController showCurrentCardInScrollView];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Card *card =[_currentPack cards] [indexPath.row];
        [_currentPack removeCard:card];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil]
                              withRowAnimation:UITableViewRowAnimationFade];
	}
    
}

#pragma mark -
#pragma mark - ZipFileDownloadHelperDelegate

- (void)downloadProgressivePercent:(long long)current totalLength:(long long)total {
    _progressivePercent = (float) current/total;
    _HUD.progress = (float) current/total;
}

- (void)downloadSuccess:(BOOL)isSucess {
    if (isSucess == YES) {
        [_HUD hide:YES];
        [self unzipFileThenAssemblePack];
    }
}

- (void)downloadFail {
    [_HUD hide:YES];
}

#pragma mark -
#pragma mark - Download action

- (void) downloadURLViaURLScheme:(NSString *)urlStr{
    
    if ([DataManager apiReachable] == NO) {
        [Common alertViewCommon:@"Please check your network"];
        return;
    }
    
    [self showProgressIndicator];
    
    if ([urlStr rangeOfString:@".zip"].length == 0) {
        [Common alertViewCommon:@"Incorrect URL share linkage (must end with .zip"];
        return;
    }
    
    //The reson why to do it: https://www.dropbox.com/help/201/en
    NSString *temp = [urlStr stringByReplacingOccurrencesOfString:@"www" withString:@"dl"];
    NSString *downloadableFile = [temp stringByReplacingOccurrencesOfString:@"fcc" withString:@"http"];
    [_zipFileDownloadHelp downloadZipFile:downloadableFile];
    _zipFileDownloadHelp.delegate = self;
}

#pragma mark -
#pragma mark - Unzip and assemble pack/card

- (void) unzipFileThenAssemblePack {
    //Step1: unzip file
    ZipArchive* za = [[ZipArchive alloc] init];
    NSString *downloadedZipPackFileFixedPath = [FileOperationHelper downloadedZipPackFileFixedPath];
    if( [za UnzipOpenFile:downloadedZipPackFileFixedPath] )
    {
        BOOL ret = [za UnzipFileTo:[FileOperationHelper downloadedPackFileDirectory] overWrite:YES];
        if( NO==ret ) {
            // error handler here
        } else {
            NSLog(@"%s\nUnzip file successfully",__FUNCTION__);
        }
        [za UnzipCloseFile];
        
        [[NSFileManager defaultManager] removeItemAtPath:downloadedZipPackFileFixedPath error:nil];
    }
    
    //Step2: buid pack
    Pack *pack = [[Pack alloc] init];
    NSError *error = nil;
    NSString *downloadedPackInfoFilePath = [[FileOperationHelper downloadedPackFileDirectory] stringByAppendingPathComponent:@"packInformation.json"];
    NSData *packData = [NSData dataWithContentsOfFile:downloadedPackInfoFilePath];
    if (!packData) {
        [Common alertViewCommon:@"Error when parsing packInformation.json"];
        return;
    }
    id packJsonObject = [NSJSONSerialization JSONObjectWithData:packData options:
                           NSJSONReadingMutableContainers error:&error];
    if (packJsonObject != nil && error == nil) {
        if ([packJsonObject isKindOfClass:[NSDictionary class]]){
            
            NSDictionary *packDict = (NSDictionary *)packJsonObject;
            pack.packName = packDict[@"pack_name"];
            
            //We need to move cover image to imagesDirectory
            error = nil;
            NSString *currentcoverImageURL = [[FileOperationHelper downloadedPackFileDirectory ] stringByAppendingPathComponent:[packDict[@"cover_image"] lastPathComponent]];
            NSString *newCoverImageURL = [[FileOperationHelper imagesDirectory] stringByAppendingPathComponent:[packDict[@"cover_image"] lastPathComponent]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:newCoverImageURL]) {
                [[NSFileManager defaultManager] moveItemAtPath:currentcoverImageURL toPath:newCoverImageURL error:&error];
                if (error) {
                    NSLog(@"%s:Error when moving Pack's cover image",__FUNCTION__);
                    return;
                }
            }
            pack.coverImageURL = newCoverImageURL;
            
        }
    } else {
        NSLog(@"Unexpected packInformation.json format");
    }
    
    //Step3: Update user's pack and database
    pack.userID = [User defaultUser].userID;
    [[User defaultUser] addPack:pack];
    
    [[NSFileManager defaultManager] removeItemAtPath:downloadedPackInfoFilePath error:nil];
    
    //Step3: build cards by parsing zipped card
    error = nil;
    NSArray *fileListArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[FileOperationHelper downloadedPackFileDirectory] error:&error];
    if (error) {
        NSLog(@"%s:Error when using contentsOfDirectoryAtPath of NSFileManager",__FUNCTION__);
    }
    
    for (NSString *zippedCardFileName in fileListArray) {
        Card *assembledCard = [[Card alloc] init];
        if ([zippedCardFileName rangeOfString:@".zip"].length != 0) {
            NSString *zippedCardFullPath = [[FileOperationHelper downloadedPackFileDirectory] stringByAppendingPathComponent:zippedCardFileName];
            assembledCard = [self unzipFileThenAssembleCard:zippedCardFullPath];
            if (assembledCard)
                [pack addCard:assembledCard];
        }
    }
    
    //Step4: set successful flag
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isExamplePackDownloadedSuccessful"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    //Step5: send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:PARSE_DOWNLOADED_PACK_FINISH_NOTIFICATION object:pack];
    
    
}

- (Card *) unzipFileThenAssembleCard:(NSString *) zippedFilePath {
    
    //step1: unzip file
    ZipArchive* za = [[ZipArchive alloc] init];
    if( [za UnzipOpenFile:zippedFilePath] )
    {
        BOOL ret = [za UnzipFileTo:[FileOperationHelper imagesDirectory] overWrite:YES];
        if( NO==ret ) {
            // error handler here
        } else {
            NSLog(@"%s\nUnzip file successfully",__FUNCTION__);
        }
        [za UnzipCloseFile];
        
        [[NSFileManager defaultManager] removeItemAtPath:zippedFilePath error:nil];
    }
    
    //step2: Assemable question card
    Card *assembledCard = [[Card alloc] init];
    NSString *imagesDir = [[FileOperationHelper documentsDirectory] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    NSString *questionJsonPath = [imagesDir stringByAppendingPathComponent:@"questionTextContent.json"];
    NSData *questionData = [NSData dataWithContentsOfFile:questionJsonPath];
    if (!questionData) {
        [Common alertViewCommon:@"Error when parsing questionTextContent.json"];
        return nil;
    }
    id questionJsonObject = [NSJSONSerialization JSONObjectWithData:questionData options:NSJSONReadingMutableContainers error:&error];
    if (questionJsonObject != nil && error == nil) {
        
        if ([questionJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *questionDict = (NSDictionary *)questionJsonObject;
            [assembledCard question].questionID = -1; // -1 means new
            [assembledCard question].cardID = -1;
            [assembledCard question].title = questionDict[@"title"];
            [assembledCard question].content = questionDict[@"content"];
            [assembledCard question].logoFullPath = [imagesDir stringByAppendingPathComponent:questionDict[@"logo"]];
            [assembledCard question].imageFullPath = [imagesDir stringByAppendingPathComponent:questionDict[@"image"]];
            assembledCard.coverImageURL = [imagesDir stringByAppendingPathComponent:questionDict[@"cover_image"]];
            assembledCard.creator = questionDict[@"creator"];
        }
    } else {
        NSLog(@"Unexpected questionTextContent.json format");
    }
    [[NSFileManager defaultManager] removeItemAtPath:questionJsonPath error:nil];
    
    //step3: Assemable answer card
    error = nil;
    NSString *answerJsonPath = [imagesDir stringByAppendingPathComponent:@"answerTextContent.json"];
    NSData *answerData = [NSData dataWithContentsOfFile:answerJsonPath];
    if (!answerData) {
        [Common alertViewCommon:@"Error when parsing answerTextContent.json"];
        return nil;
    }
    id answerJsonObject = [NSJSONSerialization JSONObjectWithData:answerData options:
                           NSJSONReadingMutableContainers error:&error];
    if (answerJsonObject != nil && error == nil) {
        if ([answerJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *answerDict = (NSDictionary *)answerJsonObject;
            [assembledCard answer].answerID = -1;
            [assembledCard answer].cardID = -1;
            [assembledCard answer].title = answerDict[@"title"];
            [assembledCard answer].content = answerDict[@"content"];
            [assembledCard answer].imageFullPath = [imagesDir stringByAppendingPathComponent:answerDict[@"image"]];
            [assembledCard answer].logoFullPath = [imagesDir stringByAppendingPathComponent:answerDict[@"logo"]];
            
        }
    } else {
        NSLog(@"Unexpected questionTextContent.json format");
    }
    [[NSFileManager defaultManager] removeItemAtPath:answerJsonPath error:nil];
    
    return assembledCard;
    
}

#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)showProgressIndicator {
	
    _HUD = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
    _HUD.color = [UIColor colorWithRed:0.23 green:0.50 blue:0.82 alpha:0.90];
    //make sure to be in front and disable user interaction
    CGAffineTransform at = CGAffineTransformMakeRotation(-M_PI/2);
    [_HUD setTransform:at];
    
    // Set determinate mode
    _HUD.mode = MBProgressHUDModeDeterminate;
    
    _HUD.delegate = self;
    _HUD.labelText = @"Download pack...";
    
    // myProgressTask uses the HUD instance to update progress
    [_HUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
    
    [[[UIApplication sharedApplication] keyWindow] insertSubview:_HUD atIndex:0];
    [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:_HUD];
    
}



- (void)myProgressTask {
	while (_progressivePercent < 1.0f) {
		_HUD.progress = _progressivePercent;
		usleep(50000);
	}
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[_HUD removeFromSuperview];
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


@end
