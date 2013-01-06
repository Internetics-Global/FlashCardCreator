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


@implementation MasterViewController

@synthesize currentPack = _currentPack;
@synthesize publicPack = _publicPack;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Master-card list", @"Master");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        }
        
        _currentPack = [[Pack alloc] init];
        _publicPack = [[Pack alloc] init];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPackAddedNotification:) name:NEW_PACK_ADDED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCardsInSelectedPackNotification:) name:NEW_SELECTED_PACK_NOTIFICATION object:nil];
    
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
    Card *card = [[_currentPack cards] objectAtIndex:indexPath.row];
    

    if (card.isOnline) {
        #warning this is not finally completed
        //step1: download zip file;
        //step2: unzip it, including json file;
        //step3: show download progress percent;
        //step4: fill content of card
        //step5: show card content (question/answer)
        
    }
    
    if (isUserInterfaceIdiomPhone) {
	    if (!self.detailViewController) {
	        self.detailViewController = [[[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil] autorelease];
	    }
	    self.detailViewController.detailItem = card.cardName;
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    } else {
        self.detailViewController.detailItem = card.cardName;
    }
}

#pragma mark -
#pragma mark PublicPackRequestDelegate

- (void)didReceiveJSONResponse:(NSArray*)JSONResponse {
#warning since the requirement is not clear, so i just simuate data here.
    
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
    FCC_RELEASE_SAFELY(_packListPickerPopover);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEW_PACK_ADDED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEW_SELECTED_PACK_NOTIFICATION object:nil];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Rotate control
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (isUserInterfaceIdiomPhone)
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    else
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
