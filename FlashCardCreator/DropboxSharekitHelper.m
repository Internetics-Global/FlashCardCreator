//
//  DropboxSharekitHelper.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 1/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "DropboxSharekitHelper.h"
#import "Pack.h"
#import "FileOperationHelper.h"
#import "DataManager.h"
#import "SHKItem.h"
#import "SHK.h"

@implementation DropboxSharekitHelper

@synthesize currentCard = _currentCard;
@synthesize currentPack = _currentPack;
@synthesize baseViewController = _baseViewController;

- (id)initWithCurrentCard:(Card *)card currentPack:(Pack *) pack baseViewController:(UIViewController *) controller {
    
    if ((self = [super init])) {
        self.currentCard =card;
        self.currentPack = pack;
        self.baseViewController = controller;
    }
    
    return self;
}



#pragma mark -
#pragma mark - Dropbox and Share related

- (void)shareAction
{
    //Step1: check whether need to upload pack again
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
    if (!dict) {
        //do nothing
    } else {
        NSString *updateDate = [dict objectForKey:@"update_date"];
        NSString *shareDate = [dict objectForKey:@"share_date"];
        NSString *shareLink = [dict objectForKey:@"share_link"];
        if ((updateDate != nil) && (shareDate != nil) & (shareLink != nil)) {
            if ([[FileOperationHelper convertStringToNSDate:updateDate]
                 compare:
                 [FileOperationHelper convertStringToNSDate:shareDate]]
                == NSOrderedAscending) {
                NSLog(@"updateDate is earlier than shareDate");
                [self shareAction:shareLink];
                return;
            }
        }
    }
    
    //Step2: do upload and share if not meet
    if (![[DBSession sharedSession] isLinked]) {
		[[DBSession sharedSession] linkFromController:[[UIApplication sharedApplication] keyWindow].rootViewController];
    } else {
        [self exectueShareAfterDropboxLinked];
    }
    
}

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void) exectueShareAfterDropboxLinked {
    
    NSString *generatedZipFilePath = nil;
    //step1: create zip file
    if (_currentPack) {
        generatedZipFilePath = [FileOperationHelper zipPackForUpload:_currentPack];
    } else {
        [Common alertViewCommon:@"You need to select a pack first"];
        NSLog(@"%s:Pack to share is nil or public pack",__FUNCTION__);
        return;
    }
    
    //step2: upload to dropbox
    if ([DataManager apiReachable] == NO) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_CHECK_NETWORK_STATUS",@"")];
        return;
    }
    
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    }
    _restClient.delegate = self;
    
    //Create or replace current
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
    NSString *saveName;
    if ([dict objectForKey:@"share_filename"]) {
        saveName = [dict objectForKey:@"share_filename"];
    } else {
        saveName = [NSString stringWithFormat:@"Pack%d%d.zip", (int)[[NSDate date] timeIntervalSince1970], arc4random()];
        
    }
    
    //we use the deprecated method to replace: http://stackoverflow.com/questions/10682749/how-to-overwrite-file-with-parent-rev-using-dropbox-api-in-ios
    [_restClient uploadFile:saveName toPath:@"/FlashCardCreator"
                   fromPath:generatedZipFilePath];
    [self showProgressIndicator];
    
    //step3: create dropbox linkage which locate in uploadedFile:
    
}

- (void) shareAction:(NSString *)shareLinkage {
    
    NSString *urlSchemeLinkage = [shareLinkage stringByReplacingOccurrencesOfString:@"https://" withString:@"fcc://"];
    
    SHKItem *item = [SHKItem URL:[NSURL URLWithString:urlSchemeLinkage] title:@"example" contentType:SHKURLContentTypeUndefined];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self.baseViewController];
	[actionSheet showFromToolbar:self.baseViewController.navigationController.toolbar];
}

#pragma mark -
#pragma mark - DBRestClientDelegate related

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    
    _isCreatingShareLinkage = YES;
    
    //step3: create dropbox linkage
    [_restClient loadSharableLinkForFile:metadata.path shortUrl:NO];
    
    //step4: share via sharekit, which locate in loadedSharableLink:
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
    [_HUD hide:YES];
    [Common alertViewCommon:@"Failure to upload"];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath {
    _progressivePercent = progress;
    _HUD.progress = progress;
    
    if (progress == 1)
        _isCreatingShareLinkage = YES;
}

- (void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    NSLog(@"Share linkage create successfully with linkage - %@", link);
    [_HUD hide:YES];
    
    _isCreatingShareLinkage = NO;
    
    //share_date info
    NSString *sharedate = [FileOperationHelper getTodayString];
    NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
    [dict setObject:sharedate forKey:@"share_date"];
    [dict setObject:link forKey:@"share_link"];
    [dict setObject:[[path componentsSeparatedByString:@"/"]lastObject] forKey:@"share_filename"];  // similiar like like card1361507800.569792-1108896928.zip
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:_currentPack.packName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self shareAction:link];
    
}

- (void)restClient:(DBRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error {
    
    _HUD.labelText = @"Fail to create share linkage";
    _isCreatingShareLinkage = NO;
    NSLog(@"Share linkage create failed with error - %@", error);
}

#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)showProgressIndicator {
	
	_HUD = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
    //_HUD.color = [UIColor blackColor];
    CGAffineTransform at = CGAffineTransformMakeRotation(-M_PI/2);
    [_HUD setTransform:at];
    _HUD.mode = MBProgressHUDModeDeterminate;
    _HUD.delegate = self;
    _HUD.labelText = @"Uploading first...";
    _HUD.detailsLabelText = @"to Dropbox and create share linkage";
    _isCreatingShareLinkage = NO;
    [_HUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
    
    [[[UIApplication sharedApplication] keyWindow] insertSubview:_HUD atIndex:0];
    [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:_HUD];
    
}

- (void)myProgressTask {
	while (_progressivePercent < 1.0f) {
		_HUD.progress = _progressivePercent;
		usleep(50000);
	}
    _progressivePercent = 0;
    
    _HUD.mode = MBProgressHUDModeIndeterminate;
    _HUD.labelText = @"Then create share link...";
    
    while (_isCreatingShareLinkage == YES) {
        usleep(50000);
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
	[_HUD removeFromSuperview];
}

@end
