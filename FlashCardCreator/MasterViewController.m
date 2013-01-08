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
#import "PackCell.h"
#import "AddViewController.h"
#import "PackListTableViewController.h"
#import "DataManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ZipFileDownloadHelper.h"
#import "ZipArchive.h"
#import "MBProgressHUD.h"
#import "Question.h"
#import "Answer.h"


@implementation MasterViewController

@synthesize currentPack = _currentPack;
@synthesize publicPack = _publicPack;
@synthesize currentCard = _currentCard;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPackAddedNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCardsInSelectedPackNotification:) name:NEW_SELECTED_PACK_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDetailView:) name:DOWNLOAD_PARSE_CARD__FINISH_NOTIFICATION object:nil];
        
        self.title = NSLocalizedString(@"Master-card list", @"Master");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        }
        
        _currentPack = [[Pack alloc] init];
        _publicPack = [[Pack alloc] init];
        _zipFileDownloadHelp =[[ZipFileDownloadHelper alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *addButton = [[[UIBarButtonItem alloc]initWithTitle:@"Add card" style:UIBarButtonSystemItemAdd target:self action:@selector(insertNewCard:)] autorelease];
    self.navigationItem.rightBarButtonItem = addButton;
    UIBarButtonItem *selectPackButton = [[[UIBarButtonItem alloc] initWithTitle:@"Pack list" style:UIBarButtonSystemItemBookmarks target:self action:@selector(selectAvailablePacks:)] autorelease];
    self.navigationItem.leftBarButtonItem = selectPackButton;
    
    
#warning just for test,by default, we will load the public pack
    _isPublicPack = TRUE;
    
    PublicPackRequest *publicPackRequest = [[[PublicPackRequest alloc] init] autorelease];
    [publicPackRequest requestPublicPack];
    publicPackRequest.delegate = self;
    
}

-(void)newPackAddedNotification:(NSNotification *)notification{
	[self.tableView reloadData];
}


- (void)selectAvailablePacks:(id)sender
{
    PackListTableViewController *packListTableViewController = [[PackListTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    if (isUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:packListTableViewController animated:YES];
        
    } else {
        packListTableViewController.delegate = self;
        _packListPickerPopover = [[UIPopoverController alloc] initWithContentViewController:packListTableViewController];
        self.contentSizeForViewInPopover = CGSizeMake(500, 44*([[[User defaultUser] packs] count]+1));
        
        [_packListPickerPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    [packListTableViewController release];
}

- (void)insertNewCard:(id)sender
{
    AddViewController *addViewController = [[AddViewController alloc] initWithNibName:@"AddViewController" bundle:nil];
    [self.navigationController pushViewController:addViewController animated:YES];
    [addViewController release];
    
#warning need to be completed here.
    //[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (void) showCardsInSelectedPackNotification:(NSNotification *) notification {
    int index = [(NSString *)[notification object] intValue];
    if (index ==0) {
        _isPublicPack = TRUE;
#warning need to be completed here.
        self.currentPack = _publicPack;
    } else {
        _isPublicPack = FALSE;
        self.currentPack = [[[User defaultUser] packs] objectAtIndex:(index-1)];
    }
    
    [self.tableView reloadData];
    
}

- (void) updateDetailView:(NSNotification *) notification {
    
    if (isUserInterfaceIdiomPhone) {
	    if (!self.detailViewController) {
	        self.detailViewController = [[[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil] autorelease];
	    }
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    } else {
        
    }
    
    self.detailViewController.answerTitleLabel.text = _currentCard.answer.title;
    self.detailViewController.answerContentLabel.text = _currentCard.answer.content;
    self.detailViewController.questionTitleLabel.text = _currentCard.question.title;
    self.detailViewController.questionContentLabel.text = _currentCard.question.content;
    self.detailViewController.detailItem = _currentCard.cardName;
}

#pragma mark -
#pragma mark UITableViewDataSource and UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ([[_currentPack cards] count]); //test purpose
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CardCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    Card *card = [[[_currentPack cards] objectAtIndex:indexPath.row] retain];
    cell.textLabel.text = card.cardName;
    
    [cell.imageView setImageWithURL:[NSURL URLWithString:card.thumbPicURL]
                   placeholderImage:[UIImage imageNamed:@"placeholder.png"]];

	
    return cell;

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentCard = [[_currentPack cards] objectAtIndex:indexPath.row];
    

    if (_currentCard.isOnline) {
        _progressivePercent = 0;
        [self showProgressIndicator];
        
        //The reson why to do it: https://www.dropbox.com/help/201/en
        NSString *downloadableFile = [_currentCard.onlineFileURLL stringByReplacingOccurrencesOfString:@"www" withString:@"dl"];
        _saveZipFilePath = nil;
        _saveZipFilePath = [_zipFileDownloadHelp downloadZipFile:downloadableFile];
        _zipFileDownloadHelp.delegate = self;
        
    } else {
        [self updateDetailView:nil];
    }
}

#pragma mark -
#pragma mark PublicPackRequestDelegate

- (void)didReceiveJSONResponse:(NSArray*)JSONResponse {
    
    NSArray *keys = [NSArray arrayWithObjects:@"card_name",@"dropbox_zip_link",@"thumb_pic",@"card_id", nil];
    
    NSMutableArray *publicCardRawArray = [[[NSMutableArray alloc] init] autorelease];
    for (int i =0; i<[JSONResponse count]; i++) {
        [publicCardRawArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[JSONResponse[i] objectForKey:@"card_name"],[JSONResponse[i] objectForKey:@"dropbox_zip_link"],[JSONResponse[i] objectForKey:@"thumb_pic"],[JSONResponse[i] objectForKey:@"card_id"], nil] forKeys:keys]];
    }
    
    self.publicPack = [DataManager parseRemotePublicPack:publicCardRawArray];
    
}

- (void)didNotReceiveJSONResponse {
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error when getting public pack info from server" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[view show];
	[view release];
}

#pragma mark -
#pragma mark PackListDelegate

- (void)packListSelected:(int) index {
    [_packListPickerPopover dismissPopoverAnimated:YES];
    
    if (index ==0) {
        _isPublicPack = TRUE;
#warning need to be completed here.
        self.currentPack = _publicPack;
    } else {
        _isPublicPack = FALSE;
        self.currentPack = [[[User defaultUser] packs] objectAtIndex:(index-1)];
    }
    
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Rotate control
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (isUserInterfaceIdiomPhone)
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    else
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
    if (_saveZipFilePath) {
        ZipArchive* za = [[ZipArchive alloc] init];
        if( [za UnzipOpenFile:_saveZipFilePath] )
        {
            NSString *unzipFolder = [[_saveZipFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:_currentPack.packName];
            if (![[NSFileManager defaultManager] fileExistsAtPath:unzipFolder]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:unzipFolder withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            BOOL ret = [za UnzipFileTo:unzipFolder overWrite:YES];
            if( NO==ret ) {
                // error handler here
            } else {
                NSLog(@"%s\nUnzip file successfully",__FUNCTION__);
            }
            [za UnzipCloseFile];
            
            [[NSFileManager defaultManager] removeItemAtPath:_saveZipFilePath error:nil];
        }
        
        [za release];
    }
    
    //step2: assemable card
    NSError *error = nil;
    NSString *questionDir = [_saveZipFilePath stringByDeletingLastPathComponent];
    NSString *questionJsonPath = [questionDir stringByAppendingFormat:@"/%@/Question/questionTextContent.json",_currentPack.packName];
    NSData *questionData = [NSData dataWithContentsOfFile:questionJsonPath];
    id questionJsonObject = [NSJSONSerialization JSONObjectWithData:questionData options:NSJSONReadingMutableContainers error:&error];
    if (questionJsonObject != nil && error == nil) {
        
        if ([questionJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *questionDict = (NSDictionary *)questionJsonObject;
            [_currentCard question].questionID = [[questionDict objectForKey:@"question_id"] intValue];
            [_currentCard question].cardID = [[questionDict objectForKey:@"card_id"] intValue];
            [_currentCard question].title = [questionDict objectForKey:@"title"];
            [_currentCard question].content = [questionDict objectForKey:@"content"];
            [_currentCard question].type = [questionDict objectForKey:@"type"];
            [_currentCard question].imageName = [questionDict objectForKey:@"image"];
        }
    } else {
        NSLog(@"Unexpected questionTextContent.json format");
    }
    
    error = nil;
    NSString *answerDir = [_saveZipFilePath stringByDeletingLastPathComponent];
    NSString *answerJsonPath = [answerDir stringByAppendingFormat:@"/%@/Question/questionTextContent.json",_currentPack.packName];
    NSData *answerData = [NSData dataWithContentsOfFile:answerJsonPath];
    id answerJsonObject = [NSJSONSerialization JSONObjectWithData:answerData options:
        NSJSONReadingMutableContainers error:&error];
    if (answerJsonObject != nil && error == nil) {
        if ([answerJsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *answerDict = (NSDictionary *)answerJsonObject;
            [_currentCard answer].answerID = [[answerDict objectForKey:@"answer_id"] intValue];
            [_currentCard answer].cardID = [[answerDict objectForKey:@"card_id"] intValue];
            [_currentCard answer].title = [answerDict objectForKey:@"title"];
            [_currentCard answer].content = [answerDict objectForKey:@"content"];
            [_currentCard answer].imageName = [answerDict objectForKey:@"image"];
        }
    } else {
        NSLog(@"Unexpected questionTextContent.json format");
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOAD_PARSE_CARD__FINISH_NOTIFICATION object:nil];
    
}

#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)showProgressIndicator {
	
	_HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:_HUD];
	
	// Set determinate mode
	_HUD.mode = MBProgressHUDModeDeterminate;
	
	_HUD.delegate = self;
	_HUD.labelText = @"Loading...";
	
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
    [_detailViewController release];
    FCC_RELEASE_SAFELY(_currentPack);
    FCC_RELEASE_SAFELY(_currentCard);
    FCC_RELEASE_SAFELY(_packListPickerPopover);
    FCC_RELEASE_SAFELY(_saveZipFilePath);
    FCC_RELEASE_SAFELY(_HUD);
    FCC_RELEASE_SAFELY(_zipFileDownloadHelp);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}


@end
