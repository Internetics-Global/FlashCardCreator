//
//  DropboxSharekitHelper.m
//  FFC
//
//  Created by Wang Bourne on 1/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "DropboxSharekitHelper.h"
#import "Pack.h"
#import "FileOperationHelper.h"
#import "DataManager.h"
#import "SimpleDBHelper.h"
#import "OpenUDID.h"
#import "AppDelegate.h"
#import "CryptorHelper.h"
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>

#import "FFCTextInputCompactAlertView.h"
#import "CallbackSLComposeViewController.h"
#import "CallbackMFMailComposeViewController.h"

#import <BlocksKit/UIAlertView+BlocksKit.h>

@interface DropboxSharekitHelper () <UIActionSheetDelegate,MFMailComposeViewControllerDelegate> {
    NSString *_finalPostMessage; //final share message
    
    NSString *_generatedZipFilePath;
    
    DBUploadTask *_uploadTask;
    
    DBRpcTask             *_getShareLinTask;
    DBRpcTask             *_createShareLinTask;
}

@end

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showShareActionSheetAgain) name:SHOW_SHARE_ACTIONSHEET_NOTIFICATION object:nil];
    
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
    [iConsole info:@"%s",__FUNCTION__];
    if ([Common isOwner:_currentPack]) {
        //Step1: check whether need to upload pack again
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
        if (!dict) {
            //do nothing
        } else {
            NSString *updateDate = [dict objectForKey:@"update_date"];
            NSString *shareDate = [dict objectForKey:@"share_date"];
            NSString *shareLink = self.currentPack.shareLink;
            if ((updateDate != nil) && (shareDate != nil) & (shareLink.length != 0)) {
                int update = [[FileOperationHelper convertStringToNSDate:updateDate] timeIntervalSince1970];
                int share = [[FileOperationHelper convertStringToNSDate:shareDate] timeIntervalSince1970];
                
                if (false) {
                    [iConsole info:@"updateDate is earlier than shareDate"];
                    [self shareAction:shareLink];
                    return;
                }
            }
        }
        
        [self showPasswordInputDialog]; //go through: password input, upload, create share link, etc
        
    } else {
        NSDictionary *downloadLinkageDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedDownloadLinkage"];
        NSString *linkage = [downloadLinkageDict objectForKey:[NSString stringWithFormat:@"%ld",(long)self.currentPack.packID]];
        
        NSString *finalLinkage = [linkage stringByReplacingOccurrencesOfString:@"https://dl" withString:@"fcc://www"];
        finalLinkage = [finalLinkage stringByReplacingOccurrencesOfString:@"https://" withString:@"fcc://"];
        
        if (finalLinkage.length > 0) {
            NSString *redirectedStr =[self redirectURL:finalLinkage];
            if ((redirectedStr == nil) || (redirectedStr.length == 0) || ([redirectedStr containsString:@"http://tinyurl.com/"] == false)) {
                [Common alertViewCommon:NSLocalizedString(@"DIALOG_REDIRECT_SERVICE_UNAVAILABLE",@"")];
                return;
            } else {
                if (self.currentPack.shareLink.length == 0) {
                    self.currentPack.shareLink = redirectedStr;
                    [self.currentPack savePackOnly];
                }
            }
            
            _finalPostMessage = [Common getShareMessage:redirectedStr];
            
            [self showShareActionSheet];
            
            
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"")
                                               message:@"Packs downloaded before current version of FlashCardCreator are no more supported to share"
                                              delegate:nil cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                     otherButtonTitles:nil];
            [alert show];
        }
        
    }
    
}

- (void) showPasswordInputDialog {
    [iConsole info:@"%s",__FUNCTION__];
    
    FFCTextInputCompactAlertView *alertView = [[FFCTextInputCompactAlertView alloc] init];
    [alertView showAlertViewWithMessage:NSLocalizedString(@"DIALOG_SET_PASSWORD",@"") buttonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Keyboard_Set",@""),NSLocalizedString(@"Keyboard_No_Needed",@""),NSLocalizedString(@"Keyboard_Cancel",@""), nil]];
    alertView.completion = ^(NSInteger buttonIndex,NSString *inputTextsString) {
        
        if (buttonIndex == 0) {
            [self uploadToDropbox:inputTextsString];
        } else if (buttonIndex == 1) {
            //Password not set
            [self uploadToDropbox:@""];
        }
        
    };
    
    APP_DELEGATE.isAllowToShowPackList = NO;
}


- (void) uploadToDropbox:(NSString *) password {
    [iConsole info:@"%s",__FUNCTION__];
    
    DropboxClient *client = [DropboxClientsManager authorizedClient];
    if (client == nil) {
        [iConsole info:@"%s: should not be here",__FUNCTION__];
        return;
    }
    
    if ([DataManager apiReachable] == NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_TITLE_NO_NETWORK",@"")
                                                        message:NSLocalizedString(@"DIALOG_PLEASE_CHECK_YOUR_NETWORK",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (_currentPack == nil) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_SELECT_PACK_BEFOREHAND",@"")];
        [iConsole info:@"%s:Pack to share is nil or public pack",__FUNCTION__];
        return;
    }
    
    
    __block int       errorCode = 0;
    __weak __typeof(&*self)weakSelf = self;
    
    
    [weakSelf showZipAndEncryptpIndicator];
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {

        
        //step1: create zip file
        _generatedZipFilePath = [FileOperationHelper zipPackForUpload:_currentPack withPassword:password];
        
        if (_generatedZipFilePath == nil) {
            errorCode = 1;
        } else {
            BOOL success = [CryptorHelper encryptFileWithSameOutput:_generatedZipFilePath];
            if (success == false) {
                errorCode = 2;
            }
        }
        
    });
    dispatch_group_notify(group,dispatch_get_main_queue(), ^ {
        
        if (errorCode == 1) {
            _HUD.hidden = YES;
            [_HUD removeFromSuperview]; //we need to clean up _HUD
            
            [Common alertViewCommon:NSLocalizedString(@"DIALOG_CREATE_ZIPPED_SHARE_FILE_FAILED",@"")];
            return;
            
        } else if (errorCode == 2) {
            _HUD.hidden = YES;
            [_HUD removeFromSuperview]; //we need to clean up _HUD
            
            [Common alertViewCommon:NSLocalizedString(@"DIALOG_ENCRPT_ZIPPED_SHARE_FILED_FAILED",@"")];
            return;
            
        } else if (errorCode == 0) {
            
            //step2: update local meta info
            if (weakSelf.currentPack.fileNameOnAWS.length == 0 || ([weakSelf.currentPack.fileNameOnAWS.lowercaseString rangeOfString:@"pack"].location == 0)) {
                weakSelf.currentPack.fileNameOnAWS = [FileOperationHelper generateUniqueFileNameOnCloud:weakSelf.currentPack];
                [weakSelf.currentPack savePackOnly];
            }
            
            //Step3: upload
            
            NSString *destPath = [@"/FlipFlashCardsPacks" stringByAppendingPathComponent:weakSelf.currentPack.fileNameOnAWS];
            NSData *fileData = [NSData dataWithContentsOfFile:_generatedZipFilePath];
            _uploadTask = [[[client.filesRoutes uploadData:destPath mode:[[DBFILESWriteMode alloc] initWithOverwrite] autorename:[NSNumber numberWithBool:false] clientModified:nil mute:[NSNumber numberWithBool:true] inputData:fileData]
             response:^(DBFILESFileMetadata *result, DBFILESUploadError *routeError, DBError * error) {
                 
                 if (routeError != nil || error != nil) {
                     [weakSelf uploadFileFailedWithError:error];
                 } else {
                     
                     [weakSelf uploadedFile:destPath from:_generatedZipFilePath metadata:result];
                 }
                 
                 
                
            }] progress:^(int64_t bytesUploaded, int64_t totalBytesUploaded, int64_t totalBytesExpectedToUploaded) {
                
                double percent = 1.0 * totalBytesUploaded/totalBytesExpectedToUploaded;
                
                [weakSelf uploadProgress:percent];
            }];
            
            
            
            [weakSelf showUploadingIndicator];
            
            //step3: create dropbox linkage which locate in uploadedFile:
            
        }
        
    });

    
}

- (void) shareAction:(NSString *)shareLinkage {
    [iConsole info:@"%s",__FUNCTION__];
    
    NSParameterAssert(shareLinkage != nil);
    
    if ([shareLinkage containsString:@"tinyurl"] == false) {
        NSString *urlSchemeLinkage = [shareLinkage stringByReplacingOccurrencesOfString:@"https://" withString:@"fcc://"];
        
        _finalShareLinkBeforeRedirect = [[NSString stringWithFormat:@"%@?from=%@",urlSchemeLinkage,_currentPack.creatorNickName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    } else {
        _finalShareLinkBeforeRedirect = shareLinkage;
    }
    
    
    FFCTextInputCompactAlertView *alertView = [[FFCTextInputCompactAlertView alloc] init];
    [alertView showAlertViewWithMessage:NSLocalizedString(@"DIALOG_SET_MAX_NUMBER_OF_DOWNLOADS",@"") buttonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Keyboard_Unlimited",@""),NSLocalizedString(@"DIALOG_OK",@""),NSLocalizedString(@"Keyboard_Cancel",@""), nil]];
    alertView.completion = ^(NSInteger buttonIndex,NSString *inputTextsString) {
        
        if (buttonIndex == 0 || buttonIndex == 1) {
            NSString *maxDownloadTimes;
            if (buttonIndex == 0) {
                maxDownloadTimes = @"9999999";
            } else {
                maxDownloadTimes = inputTextsString;
            }
            [self setMaxDownloadAlertViewClicked:maxDownloadTimes];
            
        } else if (buttonIndex == 2) {
            [self hideHud];
        }
        
        APP_DELEGATE.isAllowToShowPackList = YES;
        
        
    };
    
    APP_DELEGATE.isAllowToShowPackList = NO;
    
}

- (void)setMaxDownloadAlertViewClicked: (NSString *) maxNoString {
    if ([_finalShareLinkBeforeRedirect containsString:@"tinyurl"] == false) {
        _HUD.labelText = NSLocalizedString(@"Indicator_Share_Process_Processing",@"");
        [_HUD show:YES];
        
        double delayInSeconds = 0.4;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

            NSString *redirectedStr =[self redirectURL:_finalShareLinkBeforeRedirect];
            if ((redirectedStr == nil) || (redirectedStr.length == 0)) {
                _HUD.hidden = YES;
                [_HUD removeFromSuperview];//we need to clean up _HUD
                [Common alertViewCommon:NSLocalizedString(@"DIALOG_REDIRECT_SERVICE_UNAVAILABLE",@"")];
                return;
            }
            _HUD.hidden = YES;
            [_HUD removeFromSuperview]; //we need to clean up _HUD
            
            
            self.currentPack.shareLink = redirectedStr;
            [self.currentPack savePackOnly];
            
            //2. save meta info in background
            // insert this record in amazon singleDB for pack download limit control
            // shareLinkage is kind of "https://s3.amazonaws.com/internetics.flashcardcreator/internetics.flashcardcreator/Pack1432614117-1358153070.zip"
            // [shareLinkage lastPathComponent] is kind of "Pack1374148414-1884690931.zip"

            int maxNo = [maxNoString integerValue];
            NSRange range = [[_finalShareLinkBeforeRedirect lastPathComponent] rangeOfString:@".zip"];
            NSString *simpleDBItemName = [[_finalShareLinkBeforeRedirect lastPathComponent] substringToIndex:range.location];
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            __weak DropboxSharekitHelper *safeSelf = self;
            dispatch_async(queue, ^{
                [iConsole info:@"Amazon simpleDB item name:%@",simpleDBItemName];
                [safeSelf insertIntoAmazonSingleDB:simpleDBItemName withMaxNo:maxNo];
            });
            
            //3. 分享
            _finalPostMessage = [Common getShareMessage:redirectedStr];
            
            [self showShareActionSheet];
        });
    } else {
        if (self.currentPack.shareLink.length == 0) {
            self.currentPack.shareLink = _finalShareLinkBeforeRedirect;
            [self.currentPack savePackOnly];
        }
        
        _finalPostMessage = [Common getShareMessage:_finalShareLinkBeforeRedirect];
        
        [self showShareActionSheet];
    }
}

- (void) showShareActionSheetAgain {
    if (APP_DELEGATE.isToShowShareActinSheet_Dropbox){
        [self showShareActionSheet];
    }
}


- (void) showShareActionSheet {
    
    UIActionSheet *actionSheet;
    
    if (isUserInterfaceIdiomPhone) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"DIALOG_SHARE",@"") delegate:self cancelButtonTitle:@"Exit" destructiveButtonTitle:nil otherButtonTitles:
                 //      @"Facebook",
                       @"Twitter",
                       @"Email",
                       @"Copy",
                       nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"DIALOG_SHARE",@"") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:
      //   @"Facebook",
         @"Twitter",
         @"Email",
         @"Copy",
         @"Exit",
         nil];
    }
    
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
    
}


- (BOOL) insertIntoAmazonSingleDB: (NSString *) itemName withMaxNo: (int) maxNo {
    [iConsole info:@"%s",__FUNCTION__];
    BOOL result = false;
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",maxNo],@"0", nil] forKeys:[NSArray arrayWithObjects:@"maxNo",@"currentNo", nil]];
    NSString *defaultDomain = [SimpleDBHelper defaultDomain];
    result = [SimpleDBHelper insertOrUpdateItem:dict withItemName:itemName withDomainName:defaultDomain];
    return result;
}

#pragma mark -
#pragma mark - DBRestClientDelegate related


/**
 @param destPath an example: /FlipFlashCardsPacks/1111481524004-1771792289.zip
 @param srcPath an example: ../Documents/com.intenectics.fcc/Card Assemble Factory/1111481524003-663177798.zip
 */
- (void)uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBFILESFileMetadata*)metadata {
    
    __weak __typeof(&*self)weakSelf = self;
    
    [iConsole info:@"File uploaded successfully to path: %@", metadata.name];  //metadata.path example: /FlipFlashCardsPacks/1111481524004-1771792289.zip
    
    [FileOperationHelper removeAssembleFactoryDirectory];
    
    _isCreatingShareLinkage = YES;
    
    //step3: create dropbox linkage
    
    DropboxClient *client = [DropboxClientsManager authorizedClient];
    
    _getShareLinTask = [[client.sharingRoutes listSharedLinks:destPath cursor:nil directOnly:nil]
                          response:^(DBSHARINGListSharedLinksResult *metaData, DBSHARINGListSharedLinksError *shareError, DBError *error) {
                              if (shareError != nil || error != nil) {
                                  [weakSelf loadSharableLinkFailedWithError:error];
                              } else {
                                  NSArray *links = metaData.links;
                                  if ([links count] > 0) {
                                      DBSHARINGSharedLinkMetadata *firstObject = [links firstObject];
                                      [weakSelf loadedSharableLink:firstObject.url forFile:destPath];
                                  } else {
                                      [weakSelf createShareLink:destPath];
                                  }
                              }
        
    }];
    
    
    
    
    //step4: share via sharekit, which locate in loadedSharableLink:
}


- (void)createShareLink:(NSString*)destPath {
    DropboxClient *client = [DropboxClientsManager authorizedClient];
    
    __weak __typeof(&*self)weakSelf = self;
    
    _createShareLinTask = [[client.sharingRoutes createSharedLinkWithSettings:destPath]
                           response:^(DBSHARINGSharedLinkMetadata * metaData, DBSHARINGCreateSharedLinkWithSettingsError * shareError, DBError * error) {
                               if (shareError != nil || error != nil) {
                                   [weakSelf loadSharableLinkFailedWithError:error];
                               } else {
                                   [weakSelf loadedSharableLink:metaData.url forFile:destPath];
                               }
                           }];
}


- (void) uploadFileFailedWithError:(DBError*)error {
    [iConsole error:@"File upload failed with error - %@", error];
    
    [FileOperationHelper removeAssembleFactoryDirectory];
    [_HUD hide:YES];
    
    if ([error.statusCode integerValue] == 507 || [error.statusCode integerValue] == 409 ||
        (error.errorContent != nil && [error.errorContent containsString:@"insufficient_space"])) {  //dropbox quota is full
       [Common alertViewCommon:NSLocalizedString(@"DIALOG_ERROR_DROPBOX_QUOTA_FULL",@"")];
    } else {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_UPLOAD_FAILURE",@"")];
    }
    
}

- (void)uploadProgress:(CGFloat)progress{
    _progressivePercent = progress;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _HUD.progress = progress;
    });
    
    if (progress == 1)
        _isCreatingShareLinkage = YES;
}


/**
 @param link : an example https://www.dropbox.com/s/c6jajajeod9m5t4/1111481524004-1771792289.zip?dl=0
 @param path : an exammple /FlipFlashCardsPacks/1111481524004-1771792289.zip
 */
- (void)loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    [iConsole info:@"Share linkage create successfully with linkage - %@", link];
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

- (void)loadSharableLinkFailedWithError:(DBError*)error {
    [iConsole error:@"%s",__FUNCTION__];
    _HUD.labelText = NSLocalizedString(@"Indicator_Creating_Share_Linkage_Failure",@"");
    _isCreatingShareLinkage = NO;
    [iConsole error:@"Share linkage create failed with error - %@", error];
}

#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)showUploadingIndicator {
    
    if (_HUD) {
        [_HUD hide:YES];
        [_HUD removeFromSuperview];
        _HUD = nil;
    }
	
    _HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
    _HUD.mode = MBProgressHUDModeDeterminate;
    _HUD.delegate = self;
    _HUD.labelText = NSLocalizedString(@"Indicator_Upload",@"");
    
    _HUD.buttonTitle = @"    Cancel    ";
    _HUD.buttonTitleColor = [UIColor whiteColor];
;
    _isCreatingShareLinkage = NO;
    [_HUD showWhileExecuting:@selector(uploadProgressTask) onTarget:self withObject:nil animated:YES];
    
    [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
    [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
    
}

- (void)showZipAndEncryptpIndicator {
    
    if (_HUD) {
        [_HUD hide:YES];
        [_HUD removeFromSuperview];
        _HUD = nil;
    }
    
    _HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
    _HUD.mode = MBProgressHUDModeIndeterminate;
    _HUD.labelText = NSLocalizedString(@"Indicator_Share_Process_Processing",@"");
    [_HUD show:YES];
    
    [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
    [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
    
}

#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)hudTappedButton:(MBProgressHUD *)hud {
    
    if (_uploadTask) {
        [_uploadTask cancel];
    }
    
    if (_createShareLinTask) {
        [_createShareLinTask cancel];
    }
    
    if (_getShareLinTask) {
        [_getShareLinTask cancel];
    }
    
    [_HUD hide:YES];
    [_HUD removeFromSuperview];
}

- (void)uploadProgressTask {
    [iConsole info:@"%s",__FUNCTION__];
	while (_progressivePercent < 1.0f) {
		_HUD.progress = _progressivePercent;
		usleep(50000);
	}
    _progressivePercent = 0;
    
    _HUD.mode = MBProgressHUDModeIndeterminate;
    _HUD.labelText = NSLocalizedString(@"Indicator_Share_Process_Processing",@"");
    
    while (_isCreatingShareLinkage == YES) {
        usleep(50000);
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [iConsole info:@"%s",__FUNCTION__];
	[_HUD removeFromSuperview];
}

- (void) hideHud {
    if (_HUD) {
        [_HUD hide:YES];
        [_HUD removeFromSuperview];//we need to clean up _HUD
    }
}

- (NSString *) redirectURL:(NSString *)urlStr {
    [iConsole info:@"%s, url to be redirected:%@",__FUNCTION__,urlStr];
    NSString *returnURL;
    NSString *requestURL = [NSString stringWithFormat:@"%@%@",URL_REDIRECT_API,urlStr];
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5]; //the default timeout interval is 60 seconds.
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest
                                          returningResponse:&response
                                                      error:&error];
    
    if (error == nil)
    {
        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (([newStr rangeOfString:@"http://"].location != 0) || ([[newStr uppercaseString] rangeOfString:@"ERROR"].location != NSNotFound)) {
          [iConsole error:@"%s:%@",__FUNCTION__,newStr];
        } else {
            returnURL = newStr;
            [iConsole info:@"%s:redireced URL is %@",__FUNCTION__,newStr];
            
            //save redirected url
            NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
            if (rawDict) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
                [dict setObject:returnURL forKey:@"redirected_url"];
                [[NSUserDefaults standardUserDefaults] setObject:dict forKey:_currentPack.packName];
                [[NSUserDefaults standardUserDefaults] synchronize];
            } else {
                [iConsole error:@"%s, not exist in nsuerdefault for %@",__FUNCTION__,_currentPack.packName];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:SHARE_LINK_CREATED_NOTIFICATION object:returnURL userInfo:nil];
            
        }
        
    }
    
    [iConsole info:@"%s, redirected url:%@",__FUNCTION__,returnURL];
    
    return returnURL;
}

#pragma mark – UIActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    __weak __typeof(&*self)weakSelf = self;
    
    switch (buttonIndex + 1) {
        case 0: {
            
            APP_DELEGATE.isToShowShareActinSheet_Dropbox = true;
            
            if([CallbackSLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
                SLComposeViewController *controller = [CallbackSLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
                [controller setInitialText:_finalPostMessage];
                [_baseViewController presentViewController:controller animated:YES completion:Nil];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_NO_FACEBOOK",@"") message:NSLocalizedString(@"DIALOG_NO_FACEBOOK_DETAIL",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                [alertView show];
            }
            
        }
            break;
        case 1: {
            
            APP_DELEGATE.isToShowShareActinSheet_Dropbox = true;
            
            if ([CallbackSLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
            {
                SLComposeViewController *controller = [CallbackSLComposeViewController
                                                       composeViewControllerForServiceType:SLServiceTypeTwitter];
                [controller setInitialText:_finalPostMessage];
                [_baseViewController presentViewController:controller animated:YES completion:nil];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_NO_Twitter",@"") message:NSLocalizedString(@"DIALOG_NO_TWITTER_DETAIL",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                [alertView show];
            }
            
        }
            break;
        case 2: {
            
            APP_DELEGATE.isToShowShareActinSheet_Dropbox = true;
            
            if ([CallbackMFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *composeViewController = [[CallbackMFMailComposeViewController alloc] init];
                composeViewController.mailComposeDelegate = self;
                composeViewController.navigationBar.tintColor = [UIColor whiteColor];
                [composeViewController setSubject:@"Hi"];
                [composeViewController setMessageBody:_finalPostMessage isHTML:YES];
                [composeViewController setToRecipients:nil];
                
                [_baseViewController presentViewController:composeViewController animated:YES completion:nil];
            } else {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_WARN",@"") message:NSLocalizedString(@"DIALOG_CONFIG_MAIL_REQUIRED",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil] show];
            }

            
        }
            break;
        case 3: {
            
            APP_DELEGATE.isToShowShareActinSheet_Dropbox = true;
            
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            [pb setString:_finalPostMessage];
            
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_COPY_DONE",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil] show];
                
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_COPY_DONE",@"") cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_SHARE_ACTIONSHEET_NOTIFICATION object:nil userInfo:nil];
                }
                 ];
            });
            
            
        }
            break;
        default:
            APP_DELEGATE.isToShowShareActinSheet_Dropbox = false;
            break;
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    if (error) {
        NSLog(@"%@", error);
    }
    
    [_baseViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) dealloc {
    
    _uploadTask = nil;
    _createShareLinTask = nil;
    _getShareLinTask = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
