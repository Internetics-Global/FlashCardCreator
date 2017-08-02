//
//  GoogleDriveHelper.m
//  FlashCardCreator
//
//  Created by internetics on 9/12/16.
//  Copyright © 2016 Internetics. All rights reserved.
//

#import "GoogleDriveShareKitHelper.h"



#import "MBProgressHUD.h"
#import "Pack.h"
#import "FileOperationHelper.h"
#import "DataManager.h"
#import "SimpleDBHelper.h"
#import "OpenUDID.h"
#import "AppDelegate.h"
#import "CryptorHelper.h"
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>

#import "GoogleDriveRestClient.h"
#import "GoogleDriveSession.h"

#import "GoogleDriveMetadata.h"

#import "NSString+QueryString.h"

#import "FFCTextInputCompactAlertView.h"


@interface GoogleDriveShareKitHelper () <MBProgressHUDDelegate,UIActionSheetDelegate,MFMailComposeViewControllerDelegate,GoogleDriveRestClientDelegate>{
    
    NSString *_finalPostMessage; //final share message
    NSString *_generatedZipFilePath;
}


@end



@implementation GoogleDriveShareKitHelper


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
#pragma mark - Google Drive and Share related

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
                
                //                if (update < share) {  //之所以disable这个逻辑，因为这个会引起误解，不如用户没有改变任何的数据，但是想改变max downloaded和password。所以，这里索性无论何种情况，都重新来一次。
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
            [self uploadToGoogleDrive:inputTextsString];
        } else if (buttonIndex == 1) {
            //Password not set
            [self uploadToGoogleDrive:@""];
        }
        
    };
    
    APP_DELEGATE.isAllowToShowPackList = NO;
}


- (GoogleDriveRestClient *)restClient {
    [iConsole info:@"%s",__FUNCTION__];
    if (!_restClient) {
        _restClient =
        [[GoogleDriveRestClient alloc] initWithSession:[GoogleDriveSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void) uploadToGoogleDrive:(NSString *) password {
    [iConsole info:@"%s",__FUNCTION__];
    
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
            //同时为了处理老版本，所以有了额外逻辑（老版本都是类似：Pack1449621320-134252191.zip）
            if (weakSelf.currentPack.fileNameOnAWS.length == 0 || ([weakSelf.currentPack.fileNameOnAWS.lowercaseString rangeOfString:@"pack"].location == 0)) {
                weakSelf.currentPack.fileNameOnAWS = [FileOperationHelper generateUniqueFileNameOnCloud:weakSelf.currentPack];
                [weakSelf.currentPack savePackOnly];
            }
            
            //Step3: upload
            if (!_restClient) {
                _restClient = [[GoogleDriveRestClient alloc] initWithSession:[GoogleDriveSession sharedSession]];
            }
            _restClient.delegate = weakSelf;
            
            [_restClient uploadFile:weakSelf.currentPack.fileNameOnAWS toPath:@"/FlipFlashCardsPacks"
                           fromPath:_generatedZipFilePath];
            
            [weakSelf showUploadingIndicator];
            
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
        //已经是短链接，不需要再处理
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
            
            //1.生成short linkage
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
            
            NSString *simpleDBItemName;
            if (0) {
                //dropbox logic
                
                NSRange range = [[_finalShareLinkBeforeRedirect lastPathComponent] rangeOfString:@".zip"];
                simpleDBItemName = [[_finalShareLinkBeforeRedirect lastPathComponent] substringToIndex:range.location];
                
            } else {
                //Google drive logic, which is different with dropbox logic
                //_finalShareLinkBeforeRedirect example:   fcc://drive.google.com/uc?id=0ByMe_Cq4emVvbDg4WGF4WHllV1E&export=download?from=
                
                NSDictionary *dict = [NSString queryParamsFromString:_finalShareLinkBeforeRedirect];
                simpleDBItemName = [dict objectForKey:@"id"];
                
            }
            
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            __weak __typeof(&*self)safeSelf = self;
            dispatch_async(queue, ^{
                [iConsole info:@"Amazon simpleDB item name:%@",simpleDBItemName];
                [safeSelf insertIntoAmazonSingleDB:simpleDBItemName withMaxNo:maxNo];
            });
            
            //3. 分享
            _finalPostMessage = [Common getShareMessage:redirectedStr];
            
            [self showShareActionSheet];
        });
    } else {
        //已经是短链接了，可以直接处理
        
        //保证shareLink存在
        if (self.currentPack.shareLink.length == 0) {
            self.currentPack.shareLink = _finalShareLinkBeforeRedirect;
            [self.currentPack savePackOnly];
        }
        
        _finalPostMessage = [Common getShareMessage:_finalShareLinkBeforeRedirect];
        
        [self showShareActionSheet];
    }
}

- (void) showShareActionSheetAgain {
    if (APP_DELEGATE.isToShowShareActinSheet_Google_Drive){
        [self showShareActionSheet];
    }
}

- (void) showShareActionSheet {
    
    UIActionSheet *actionSheet;
    
    if (isUserInterfaceIdiomPhone) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"DIALOG_SHARE",@"") delegate:self cancelButtonTitle:@"Exit" destructiveButtonTitle:nil otherButtonTitles:
                       @"Facebook",
                       @"Twitter",
                       @"Email",
                       @"Copy",
                       nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"DIALOG_SHARE",@"") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:
                       @"Facebook",
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



- (void)restClient:(GoogleDriveRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(GoogleDriveMetadata*)metadata {
    
    NSString *uploadedFileFullPath = metadata.uploadedFileFullPath;
    [iConsole info:@"File uploaded successfully to path: %@", uploadedFileFullPath];
    
    [FileOperationHelper removeAssembleFactoryDirectory];
    
    _isCreatingShareLinkage = YES;
    
    //step3: create Google Drive share linkage
    [_restClient loadSharableLinkForFile:metadata.uploadedFileID withPath:uploadedFileFullPath shortUrl:false];
    
    //step4: share via sharekit, which locate in loadedSharableLink:
}


- (void)restClient:(GoogleDriveRestClient*)client uploadFileFailedWithError:(NSError*)error {
    
    //possible reason: Daily Limit for Unauthenticated Use Exceeded. Continued use requires signup.
    [iConsole error:@"File upload failed with error - %@", error];
    
    [FileOperationHelper removeAssembleFactoryDirectory];
    [_HUD hide:YES];
    
    if (error.code == 403) {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_ERROR_GOOGLE_DRIVE_QUOTA_FULL",@"")];
    } else {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_UPLOAD_FAILURE",@"")];
    }
    
}

- (void)restClient:(GoogleDriveRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath {
    _progressivePercent = progress;
    _HUD.progress = progress;
    
    if (progress == 1)
        _isCreatingShareLinkage = YES;
}

- (void)restClient:(GoogleDriveRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
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

- (void)restClient:(GoogleDriveRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error {
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
    
    //这时是有cancel button，之后的 create share link的indicator复用这个，也是有进度条的
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
    
    //这时是没有cancel button或进度条的
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
    [_restClient cancelAllRequests];  //including upload and create share link (但是不包括 shorted link，因为我们无法终止它）
    
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
    
    //一旦uploading完成后，就转成processing
    ///这时是有cancel button，create share link的indicator复用这个，也是有进度条的
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
    
    switch (buttonIndex) {
        case 0: {
            
            APP_DELEGATE.isToShowShareActinSheet_Google_Drive = true;
            
            if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
                SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
                [controller setInitialText:_finalPostMessage];
                //在iOS7下，如果是通过keywindow.rootviewcontroller会有问题
                [_baseViewController presentViewController:controller animated:YES completion:Nil];
            } else {
                //iOS6下，会自动提示，iOS7则需要手工加入
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_NO_FACEBOOK",@"") message:NSLocalizedString(@"DIALOG_NO_FACEBOOK_DETAIL",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                [alertView show];
            }
            
        }
            break;
        case 1: {
            
            APP_DELEGATE.isToShowShareActinSheet_Google_Drive = true;
            
            if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
            {
                SLComposeViewController *controller = [SLComposeViewController
                                                       composeViewControllerForServiceType:SLServiceTypeTwitter];
                [controller setInitialText:_finalPostMessage];
                //在iOS7下，如果是通过keywindow.rootviewcontroller会有问题
                [_baseViewController presentViewController:controller animated:YES completion:nil];
            } else {
                //iOS6下，会自动提示，iOS7则需要手工加入
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_NO_Twitter",@"") message:NSLocalizedString(@"DIALOG_NO_TWITTER_DETAIL",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
                [alertView show];
            }
            
        }
            break;
        case 2: {
            
            APP_DELEGATE.isToShowShareActinSheet_Google_Drive = true;
            
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] init];
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
            
            APP_DELEGATE.isToShowShareActinSheet_Google_Drive = true;
            
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            [pb setString:_finalPostMessage];
            
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"") message:NSLocalizedString(@"DIALOG_COPY_DONE",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil] show];
            });
            
            
        }
            break;
        default:
            APP_DELEGATE.isToShowShareActinSheet_Google_Drive = false;
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
    _restClient.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
