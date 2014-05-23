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
#import "AmazonClientManager.h"
#import "Common.h"
#import "OpenUDID.h"

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

/**
 *  when user clicks the "share the pack" button
 *  and will do next:
 *  1. set password and then upload
 *  2. set max download number
 *  3. share
 *  if the current pack does not belong to current use, step1 and step2 will be ignored.
 */
- (void)shareAction
{
    DDLogInfo(@"%s",__FUNCTION__);
    if ([self checkPackEditable]) {
        //Step1: check whether need to upload pack again
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
        if (!dict) {
            //do nothing
        } else {
            NSString *updateDate = [dict objectForKey:@"update_date"];
            NSString *shareDate = [dict objectForKey:@"share_date"];
            NSString *shareLink = [dict objectForKey:@"share_link"];
            if ((updateDate != nil) && (shareDate != nil) & (shareLink != nil)) {
                int update = [[FileOperationHelper convertStringToNSDate:updateDate] timeIntervalSince1970];
                int share = [[FileOperationHelper convertStringToNSDate:shareDate] timeIntervalSince1970];
                
                if (update < share) {
                    DDLogInfo(@"updateDate is earlier than shareDate");
                    [self shareAction:shareLink];
                    return;
                }
            }
        }
        
        //Step2: do upload and share if not meet
        if (![[DBSession sharedSession] isLinked]) {
            [[DBSession sharedSession] linkFromController:[[UIApplication sharedApplication] keyWindow].rootViewController];
        } else {
            [self setPassword];
        }
    } else {
        NSDictionary *downloadLinkageDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedDownloadLinkage"];
        NSString *linkage = [downloadLinkageDict objectForKey:[NSString stringWithFormat:@"%d",self.currentPack.packID]];
        
        NSString *finalLinkage = [linkage stringByReplacingOccurrencesOfString:@"https://dl" withString:@"fcc://www"];
        finalLinkage = [finalLinkage stringByReplacingOccurrencesOfString:@"https://" withString:@"fcc://"];
        
        if (finalLinkage.length > 0) {
            NSString *redirectedStr =[self redirectURL:finalLinkage];
            if ((redirectedStr == nil) || (redirectedStr.length == 0)) {
                [Common alertViewCommon:@"Redirect sevice is not available now, please try again"];
                return;
            }
            
            NSString *finalPostMessage = [NSString stringWithFormat:@"Share a pack of Flash Cards with the Flash Card Creator! ( %@ ) Check it out!",redirectedStr];
            //SHKItem *item = [SHKItem URL:[NSURL URLWithString:redirectedStr] title:@"example" contentType:SHKURLContentTypeUndefined];
            SHKItem *item = [SHKItem text:finalPostMessage];
            SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
            [SHK setRootViewController:self.baseViewController];
            [actionSheet showFromToolbar:self.baseViewController.navigationController.toolbar];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                               message:@"Packs downloaded before current version of FlashCardCreator are no more supported to share"
                                              delegate:nil cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                     otherButtonTitles:nil];
            [alert show];
        }
        
    }
    
}

- (void) setPassword {
    DDLogInfo(@"%s",__FUNCTION__);
    UIAlertView *alert;
    if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
        alert = [[UIAlertView alloc] initWithTitle:nil
                                   message:@"Set a password?"
                                  delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Set",@"")
                                 otherButtonTitles:NSLocalizedString(@"Keyboard_No_Needed",@""), nil];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                           message:@"Set a password?"
                                          delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Set",@"")
                                 otherButtonTitles:NSLocalizedString(@"Keyboard_No_Needed",@""), nil];
    }
    alert.tag = 1;
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert textFieldAtIndex:0].text = @"";
    alert.delegate = self;
    [alert show];
}

- (BOOL) checkPackEditable {
    DDLogInfo(@"%s",__FUNCTION__);
    BOOL result = NO;
    Card *firstCard = [[self.currentPack cards] objectAtIndex:0];
    if ([firstCard.creator isEqualToString:[OpenUDID value]]) {
        result = YES;
    } else {
        result = NO;
    }
    
    return result;
}


- (DBRestClient *)restClient {
    DDLogInfo(@"%s",__FUNCTION__);
    if (!_restClient) {
        _restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void) exectueShareAfterDropboxLinked:(NSString *) password {
    DDLogInfo(@"%s",__FUNCTION__);
    NSString *generatedZipFilePath = nil;
    //step1: create zip file
    if (_currentPack) {
        generatedZipFilePath = [FileOperationHelper zipPackForUpload:_currentPack withPassword:password];
        
        if (generatedZipFilePath == nil) {
            [Common alertViewCommon:@"Failure to create zipped share file."];
            return;
        }
        
    } else {
        [Common alertViewCommon:@"You need to select a pack first"];
        DDLogInfo(@"%s:Pack to share is nil or public pack",__FUNCTION__);
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
    DDLogInfo(@"%s",__FUNCTION__);
    NSString *urlSchemeLinkage = [shareLinkage stringByReplacingOccurrencesOfString:@"https://" withString:@"fcc://"];
    
    _finalShareLinkBeforeRedirect = [[NSString stringWithFormat:@"%@?from=%@",urlSchemeLinkage,_currentPack.creatorNickName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    
    UIAlertView *alert;
    if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
        alert = [[UIAlertView alloc] initWithTitle:nil
                                           message:@"Set max number of downloads"
                                          delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                 otherButtonTitles:NSLocalizedString(@"Keyboard_Unlimited",@""), nil];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                   message:@"Set max number of downloads"
                                  delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                         otherButtonTitles:NSLocalizedString(@"Keyboard_Unlimited",@""), nil];
    }
    alert.tag = 2;
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert textFieldAtIndex:0].text = @"9999";
    alert.delegate = self;
    [alert show];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    DDLogInfo(@"%s",__FUNCTION__);
    
    switch (alertView.tag) {
        case 1: {
            NSString *password = [alertView textFieldAtIndex:0].text;
            [self exectueShareAfterDropboxLinked:password];
            
        }
            
            break;
            
        case 2: {
            NSString *maxNoString = [alertView textFieldAtIndex:0].text;
            
            int maxNo;
            if (buttonIndex == 1) {
                //unlimited
                maxNo = 9999999;
            } else {
                maxNo = [maxNoString integerValue];
            }
            
            NSString *redirectedStr =[self redirectURL:_finalShareLinkBeforeRedirect];
            if ((redirectedStr == nil) || (redirectedStr.length == 0)) {
                [Common alertViewCommon:@"Redirect sevice is not available now, please try again"];
                return;
            }
            
            // insert this record in amazon singleDB for pack download limit control
            // shareLinkage is kind of "https://www.dropbox.com/s/xdkukqr6ezjntu7/Pack1374148414-1884690931.zip"
            // [shareLinkage lastPathComponent] is kind of "Pack1374148414-1884690931.zip"
            NSRange range = [[_finalShareLinkBeforeRedirect lastPathComponent] rangeOfString:@".zip"];
            NSString *simpleDBItemName = [[_finalShareLinkBeforeRedirect lastPathComponent] substringToIndex:range.location];
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            __weak DropboxSharekitHelper *safeSelf = self;
            dispatch_async(queue, ^{
                DDLogInfo(@"Amazon simpleDB item name:%@",simpleDBItemName);
                [safeSelf insertIntoAmazonSingleDB:simpleDBItemName withMaxNo:maxNo];
            });
            
            
            
            NSString *finalPostMessage = [NSString stringWithFormat:@"I've just created a pack of Flash Cards with the Flash Card Creator! ( %@ ) Check it out!",redirectedStr];
            //SHKItem *item = [SHKItem URL:[NSURL URLWithString:redirectedStr] title:@"example" contentType:SHKURLContentTypeUndefined];
            SHKItem *item = [SHKItem text:finalPostMessage];
            SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
            [SHK setRootViewController:self.baseViewController];
            [actionSheet showFromToolbar:self.baseViewController.navigationController.toolbar];
        }
            
            break;
            
        default:
            break;
    }
    
    
    
}


- (BOOL) insertIntoAmazonSingleDB: (NSString *) itemName withMaxNo: (int) maxNo {
    DDLogInfo(@"%s",__FUNCTION__);
    BOOL result = false;
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",maxNo],@"0", nil] forKeys:[NSArray arrayWithObjects:@"maxNo",@"currentNo", nil]];
    NSString *defaultDomain = [AmazonClientManager defaultDomain];
    result = [AmazonClientManager insertOrUpdateItem:dict withItemName:itemName withDomainName:defaultDomain];
    return result;
}

#pragma mark -
#pragma mark - DBRestClientDelegate related

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    DDLogInfo(@"File uploaded successfully to path: %@", metadata.path);
    
    _isCreatingShareLinkage = YES;
    
    //step3: create dropbox linkage
    [_restClient loadSharableLinkForFile:metadata.path shortUrl:NO];
    
    //step4: share via sharekit, which locate in loadedSharableLink:
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    DDLogInfo(@"File upload failed with error - %@", error);
    [_HUD hide:YES];
    [Common alertViewCommon:@"Failure to upload, please try again"];
    DDLogInfo(@"failure to upload: %@", [error description]);
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath {
    _progressivePercent = progress;
    _HUD.progress = progress;
    
    if (progress == 1)
        _isCreatingShareLinkage = YES;
}

- (void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    DDLogInfo(@"Share linkage create successfully with linkage - %@", link);
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
    DDLogInfo(@"%s",__FUNCTION__);
    _HUD.labelText = @"Fail to create share linkage";
    _isCreatingShareLinkage = NO;
    DDLogInfo(@"Share linkage create failed with error - %@", error);
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
    _HUD.labelText = NSLocalizedString(@"Indicator_Upload",@"")
;
    _isCreatingShareLinkage = NO;
    [_HUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
    
    [[[UIApplication sharedApplication] keyWindow] insertSubview:_HUD atIndex:0];
    [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:_HUD];
    
}

- (void)myProgressTask {
    DDLogInfo(@"%s",__FUNCTION__);
	while (_progressivePercent < 1.0f) {
		_HUD.progress = _progressivePercent;
		usleep(50000);
	}
    _progressivePercent = 0;
    
    _HUD.mode = MBProgressHUDModeIndeterminate;
    _HUD.labelText = NSLocalizedString(@"Indicator_Create_Share_Link",@"")
;
    
    while (_isCreatingShareLinkage == YES) {
        usleep(50000);
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    DDLogInfo(@"%s",__FUNCTION__);
	[_HUD removeFromSuperview];
}

- (NSString *) redirectURL:(NSString *)urlStr {
    DDLogInfo(@"%s",__FUNCTION__);
    NSString *returnURL;
    NSString *requestURL = [NSString stringWithFormat:@"%@%@",URL_REDIRECT_API,urlStr];
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURL]];
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest
                                          returningResponse:&response
                                                      error:&error];
    
    if (error == nil)
    {
        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (([newStr rangeOfString:@"http://"].location != 0) || ([[newStr uppercaseString] rangeOfString:@"Error"].location != NSNotFound)) {
        } else {
            returnURL = newStr;
        }
    } 
    
    return returnURL;
}

@end
