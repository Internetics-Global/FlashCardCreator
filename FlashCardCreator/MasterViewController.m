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
#import "AddViewController.h"
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


@implementation MasterViewController

@synthesize currentPack = _currentPack;
@synthesize publicPack = _publicPack;
@synthesize currentCard = _currentCard;
@synthesize indexCard = _indexCard;
@synthesize isCurrentPackPublic = _isCurrentPackPublic;
@synthesize backgroundOfCreateCardView = _backgroundOfCreateCardView;

@synthesize dropboxShareLinkURL = _dropboxShareLinkURL;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //1. Setup notification

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPackAddedNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCardAddedNotification:) name:NEW_CARD_ADDED_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedPackNotification:) name:CURRENT_PACK_SELECTED_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterDetailView:) name:DOWNLOAD_PARSE_CARD__FINISH_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMasterViewOnPublicStartup:) name:DOWNLOAD_PUBLIC_PACK_FINISH_NOTIFICATION object:nil];
        
        //2. Initialize
        _currentPack = [[Pack alloc] init];
        _currentCard = [[Card alloc] init];
        _publicPack = [[Pack alloc] init];
        _indexCard = 0;
        _zipFileDownloadHelp =[[ZipFileDownloadHelper alloc] init];
        _dropboxShareLinkURL = nil;
        
        
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

    
    UIBarButtonItem *selectPackButton = [[UIBarButtonItem alloc] initWithTitle:PUBLIC_PACK_NAME style:UIBarButtonSystemItemBookmarks target:self action:@selector(selectAvailablePacks:)];
    
    UIBarButtonItem *newPackButton = [[UIBarButtonItem alloc] initWithTitle:@"Add Pack" style:UIBarButtonSystemItemBookmarks target:self action:@selector(createNewPack:)];
    self.navigationItem.leftBarButtonItems = @[selectPackButton,newPackButton];
    
    if (!_isCurrentPackPublic) {
        self.navigationItem.leftBarButtonItem.title = self.currentPack.packName;
        [self.tableView reloadData];
    } else {
        self.navigationItem.leftBarButtonItem.title = PUBLIC_PACK_NAME;
    }
    
    UIButton *addCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    
    if (isUserInterfaceIdiomPhone ) {
        addCardButton.center = CGPointMake(100,320-40);
    } else {
        addCardButton.center = CGPointMake(IPAD_UI_MASTER_WIDTH/2,IPAD_UI_HEIGHT -50);
    }
    [addCardButton setImage:[UIImage imageNamed:@"red_plus_up.png"] forState:UIControlStateNormal];
    [addCardButton setImage:[UIImage imageNamed:@"red_plus_up.png"] forState:UIControlEventTouchDown];
    [addCardButton addTarget:self action:@selector(createNewCard:) forControlEvents:UIControlEventTouchUpInside];
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController.view insertSubview:addCardButton atIndex:0];
        [self.navigationController.view bringSubviewToFront:addCardButton];
    } else {
        [self.splitViewController.view insertSubview:addCardButton atIndex:0];
        [self.splitViewController.view bringSubviewToFront:addCardButton];
    }
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.title = @"";
    
}

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
#pragma mark Insert new card

- (void)insertNewCard:(id)sender
{
    AddViewController *addViewController = [[AddViewController alloc] initWithNibName:@"AddViewController" bundle:nil];
    [self.navigationController pushViewController:addViewController animated:YES];
}

- (void)createNewCard:(id)sender
{
    if (_isCurrentPackPublic) {
        [Common alertViewCommon:@"Can not add card under online example pack"];
        return;
    }
    
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
#pragma mark Notfication related

/*
 There are two sources:
 1. just select packs
 2. called from outside via URL scheme then have to deal with logic of download
 */
- (void) selectedPackNotification:(NSNotification *) notification {
    int index = [(NSString *)[notification object] intValue];
    if (index ==0) {
        _isCurrentPackPublic = TRUE;
        self.currentPack = _publicPack;
        self.navigationItem.leftBarButtonItem.title = PUBLIC_PACK_NAME;
    } else {
        _isCurrentPackPublic = FALSE;
        self.currentPack = [[User defaultUser] packs][(index-1)];
        self.navigationItem.leftBarButtonItem.title = _currentPack.packName;
        
        //Only when it's an online card
        if (_dropboxShareLinkURL) {
            [self downloadURLViaURLScheme];
        }
    }
    
    if (!isUserInterfaceIdiomPhone) {
        [_packListPickerPopover dismissPopoverAnimated:YES];
    }
    
    
    [self.tableView reloadData];
    
}

/*
 There are two sources:
 1. just select packs
 2. called from outside via URL scheme then have to deal with logic of download
 */
-(void)newPackAddedNotification:(NSNotification *)notification{
    if (_dropboxShareLinkURL) { //we are planning to download online card
        self.currentPack = (Pack *)[notification object];
        [self downloadURLViaURLScheme];
        
    }
    
}

-(void)newCardAddedNotification:(NSNotification *)notification{
	[self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:([[_currentPack cards] count]-1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [_backgroundOfCreateCardView removeFromSuperview];
}


- (void) downloadURLViaURLScheme{
    if (!_dropboxShareLinkURL) {
        NSLog(@"%s:need to set _dropboxShareLinkURL before use",__FUNCTION__);
        return;
    }
    
    if ([DataManager apiReachable] == NO) {
        [Common alertViewCommon:@"Please check your network"];
        return;
    }
    
    [self showProgressIndicator];
    
    if ([_dropboxShareLinkURL rangeOfString:@".zip"].length == 0) {
        [Common alertViewCommon:@"Incorrect URL share linkage (must end with .zip"];
        return;
    }
    
    //The reson why to do it: https://www.dropbox.com/help/201/en
    NSString *temp = [_dropboxShareLinkURL stringByReplacingOccurrencesOfString:@"www" withString:@"dl"];
    NSString *downloadableFile = [temp stringByReplacingOccurrencesOfString:@"fcc" withString:@"http"];
    _dropboxShareLinkURL = nil; //we need to set this
    [_zipFileDownloadHelp downloadZipFile:downloadableFile];
    _zipFileDownloadHelp.delegate = self;
}


- (void) updateMasterViewOnPublicStartup:(NSNotification *) notification {
    [self.tableView reloadData];
    self.navigationItem.leftBarButtonItem.title = _currentPack.packName;
}

- (void) updateMasterDetailView:(NSNotification *) notification {
    
    //Step1: update master view
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
    if (([DataManager apiReachable] == FALSE) && (_isCurrentPackPublic)) {
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
        UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SelectedCellBackground.png"]];
        backgroundView.layer.cornerRadius =5;
        [backgroundView.layer setMasksToBounds:YES];
        cell.selectedBackgroundView = backgroundView;
	}
    
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    Card *card = [_currentPack cards][indexPath.row];
    cell.indexLabel.text = [NSString stringWithFormat:@"%d",indexPath.row+1];
    
    
    if (_isCurrentPackPublic) {
        
        [cell.cellImageView setImageWithURL:[NSURL URLWithString:card.coverImageURL]
                           placeholderImage:[UIImage imageNamed:@"card_list_placeholder.png"]];
    } else {
        cell.cellImageView.image = [UIImage imageWithContentsOfFile:card.coverImageURL];
    }
    
    
    if (_indexCard == indexPath.row) {
        [cell setSelected:YES animated:YES];
    }

    

    return cell;

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentCard = [_currentPack cards][indexPath.row];
    _indexCard = indexPath.row;

    if (_currentPack.packID == PUBLIC_PACK_ID) {
        _dropboxShareLinkURL = _currentCard.onlineFileURLL;
        CreatePackViewController * createPackController = [[CreatePackViewController alloc] init];
        createPackController.isIncludePackListView = YES;
        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:createPackController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:navController animated:YES];
        
    } else {
        if (isUserInterfaceIdiomPhone ) {
            if (!self.detailViewController) {
                self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil];
            }
            self.detailViewController.currentCard = _currentCard;
            self.detailViewController.currentPack = _currentPack;
            self.detailViewController.indexCard = _indexCard;
            [self.navigationController pushViewController:self.detailViewController animated:YES];
        } else {
            self.detailViewController.currentCard = _currentCard;
            self.detailViewController.currentPack = _currentPack;
            self.detailViewController.indexCard = _indexCard;
            [self.detailViewController showCurrentCardInScrollView];
        }
    }
}

#pragma mark -
#pragma mark PublicPackRequestDelegate

- (void)didReceiveJSONResponse:(NSArray*)JSONResponse {
    
    NSArray *keys = @[@"card_name",@"dropbox_zip_link",@"thumb_pic",@"card_id"];
    
    NSMutableArray *publicCardRawArray = [[NSMutableArray alloc] init];
    for (int i =0; i<[JSONResponse count]; i++) {
        [publicCardRawArray addObject:[NSDictionary dictionaryWithObjects:@[(JSONResponse[i])[@"card_name"],(JSONResponse[i])[@"dropbox_zip_link"],(JSONResponse[i])[@"thumb_pic"],(JSONResponse[i])[@"card_id"]] forKeys:keys]];
    }
    
    self.publicPack = [DataManager parseRemotePublicPack:publicCardRawArray];

    if (_isCurrentPackPublic) {
        self.currentPack = self.publicPack;
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOAD_PUBLIC_PACK_FINISH_NOTIFICATION object:nil];
    }
    
}

- (void)didNotReceiveJSONResponse {
    NSLog(@"%s:Error to receive example pack json response",__FUNCTION__);
}


#pragma mark -
#pragma mark Rotate control

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


#pragma mark -
#pragma mark - ZipFileDownloadHelperDelegate, Unzip and assemble card

- (void)downloadProgressivePercent:(long long)current totalLength:(long long)total {
    _progressivePercent = (float) current/total;
}

- (void)downloadSuccess:(BOOL)isSucess {
    if (isSucess == YES) {
        [self unzipFileThenAssembleCard];
    }
}


- (void) unzipFileThenAssembleCard {
    
    //step1: unzip file
    ZipArchive* za = [[ZipArchive alloc] init];
    NSString *downloadedZipFilePath = [ZipFileDownloadHelper downloadedZipFilePath];
    if( [za UnzipOpenFile:downloadedZipFilePath] )
    {        
        BOOL ret = [za UnzipFileTo:[downloadedZipFilePath stringByDeletingLastPathComponent] overWrite:YES];
        if( NO==ret ) {
            // error handler here
        } else {
            NSLog(@"%s\nUnzip file successfully",__FUNCTION__);
        }
        [za UnzipCloseFile];
        
        [[NSFileManager defaultManager] removeItemAtPath:downloadedZipFilePath error:nil];
    }
    
    NSString *imagesDir = [[FileOperationHelper documentsDirectory] stringByAppendingPathComponent:@"Images"];
    
    //step2: Assemable question card
    NSError *error = nil;
    NSString *questionJsonPath = [imagesDir stringByAppendingPathComponent:@"questionTextContent.json"];
    NSData *questionData = [NSData dataWithContentsOfFile:questionJsonPath];
    if (!questionData) {
        [Common alertViewCommon:@"Error when parsing questionTextContent.json"];
        return;
    }
    id questionJsonObject = [NSJSONSerialization JSONObjectWithData:questionData options:NSJSONReadingMutableContainers error:&error];
    if (questionJsonObject != nil && error == nil) {
        
        if ([questionJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *questionDict = (NSDictionary *)questionJsonObject;
            [_currentCard question].questionID = [questionDict[@"question_id"] intValue];
            [_currentCard question].cardID = [questionDict[@"card_id"] intValue];
            [_currentCard question].title = questionDict[@"title"];
            [_currentCard question].content = questionDict[@"content"];
            [_currentCard question].type = questionDict[@"type"];
            [_currentCard question].logoFullPath = [imagesDir stringByAppendingPathComponent:questionDict[@"logo"]];
            [_currentCard question].imageFullPath = [imagesDir stringByAppendingPathComponent:questionDict[@"image"]];
            _currentCard.coverImageURL = [imagesDir stringByAppendingPathComponent:questionDict[@"cover_image"]];
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
        return;
    }
    id answerJsonObject = [NSJSONSerialization JSONObjectWithData:answerData options:
        NSJSONReadingMutableContainers error:&error];
    if (answerJsonObject != nil && error == nil) {
        if ([answerJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *answerDict = (NSDictionary *)answerJsonObject;
            [_currentCard answer].answerID = [answerDict[@"answer_id"] intValue];
            [_currentCard answer].cardID = [answerDict[@"card_id"] intValue];
            [_currentCard answer].title = answerDict[@"title"];
            [_currentCard answer].content = answerDict[@"content"];
            [_currentCard answer].imageFullPath = [imagesDir stringByAppendingPathComponent:answerDict[@"image"]];
            [_currentCard answer].logoFullPath = [imagesDir stringByAppendingPathComponent:answerDict[@"logo"]];
            
        }
    } else {
        NSLog(@"Unexpected questionTextContent.json format");
    }
    [[NSFileManager defaultManager] removeItemAtPath:answerJsonPath error:nil];
    
    //Step4: save new downloaded card to current pack
    [_currentPack addCard:_currentCard];
    
    _isCurrentPackPublic = FALSE;
    
    //Step5: notification to update UI
    [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOAD_PARSE_CARD__FINISH_NOTIFICATION object:_currentCard];
    
}

#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)showProgressIndicator {
	
	if (_HUD == nil) {
      _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    }

    //make sure to be in front and disable user interaction
    CGAffineTransform at = CGAffineTransformMakeRotation(-M_PI/2);
    [_HUD setTransform:at];
    
    [[[UIApplication sharedApplication] keyWindow] insertSubview:_HUD atIndex:0];
    [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:_HUD];
	
	// Set determinate mode
	_HUD.mode = MBProgressHUDModeDeterminate;
	
	_HUD.delegate = self;
	_HUD.labelText = @"Download card...";
    _progressivePercent = 0;
	
	// myProgressTask uses the HUD instance to update progress
	[_HUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
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


@end
