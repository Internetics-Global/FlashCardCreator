//
//  AWSS3UploadHelper.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 1/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "AWSS3UploadHelper.h"
#import "Pack.h"
#import "FileOperationHelper.h"
#import "DataManager.h"
#import "SimpleDBHelper.h"
#import "OpenUDID.h"
#import "AppDelegate.h"
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>

#import <AWSS3/AWSS3.h>
#import "AWS_Constants.h"
#import <Bolts/Bolts.h>

#import "CryptorHelper.h"

#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>

#import "AWS_Constants.h"

typedef NS_ENUM(NSUInteger, Type_ActionSheet) {
    Type_ActionSheet_Share      = -1,
};

@interface AWSS3UploadHelper () <UIActionSheetDelegate,MFMailComposeViewControllerDelegate> {
    NSString *_finalPostMessage; //final share message
    
    NSString *_generatedZipFilePath;
}

@end

@implementation AWSS3UploadHelper

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
#pragma mark - Upload and Share related

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
                
                if (update < share) {
                    [iConsole info:@"updateDate is earlier than shareDate"];
                    [self shareAction:shareLink];
                    return;
                }
            }
        }
        
        //Step2:
        [self showPasswordInputDialog];
        
    } else {
        NSDictionary *downloadLinkageDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedDownloadLinkage"];
        NSString *linkage = [downloadLinkageDict objectForKey:[NSString stringWithFormat:@"%d",self.currentPack.packID]];
        
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
            
            _finalPostMessage = [NSString stringWithFormat:@"Share a pack of Flash Cards with Flip Flash Cards app! ( %@ ) Check it out! Get the Flip Flash Cards app http://www.apple.com",redirectedStr];
            
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"DIALOG_SHARE",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") destructiveButtonTitle:nil otherButtonTitles:
                                          @"Facebook",
                                          @"Twitter",
                                          @"Email",
                                          @"Copy",
                                          nil];
            actionSheet.tag = Type_ActionSheet_Share;
            [actionSheet showInView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
            
            
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
    UIAlertView *alert;
    if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
        alert = [[UIAlertView alloc] initWithTitle:nil
                                   message:NSLocalizedString(@"DIALOG_SET_PASSWORD",@"")
                                  delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Set",@"")
                                 otherButtonTitles:NSLocalizedString(@"Keyboard_No_Needed",@""), nil];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"")
                                           message:NSLocalizedString(@"DIALOG_SET_PASSWORD",@"")
                                          delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Set",@"")
                                 otherButtonTitles:NSLocalizedString(@"Keyboard_No_Needed",@""), nil];
    }
    alert.tag = 1;
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert textFieldAtIndex:0].text = @"";
    alert.delegate = self;
    [alert show];
    
    APP_DELEGATE.isAllowToShowPackList = NO;
}


- (void) uploadToAWSS3:(NSString *) password {
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
    
    //step1: create zip file
    if (_currentPack) {
        _generatedZipFilePath = [FileOperationHelper zipPackForUpload:_currentPack withPassword:password];
        
        if (_generatedZipFilePath == nil) {
            [Common alertViewCommon:NSLocalizedString(@"DIALOG_CREATE_ZIPPED_SHARE_FILE_FAILED",@"")];
            return;
        }
        
        BOOL success = [CryptorHelper encryptFileWithSameOutput:_generatedZipFilePath];
        if (success == false) {
            [Common alertViewCommon:NSLocalizedString(@"DIALOG_ENCRPT_ZIPPED_SHARE_FILED_FAILED",@"")];
            return;
        }
        
    } else {
        [Common alertViewCommon:NSLocalizedString(@"DIALOG_SELECT_PACK_BEFOREHAND",@"")];
        [iConsole info:@"%s:Pack to share is nil or public pack",__FUNCTION__];
        return;
    }
    
    
    //step2: update local meta info
    if (self.currentPack.fileNameOnAWS.length == 0) {
        self.currentPack.fileNameOnAWS = [NSString stringWithFormat:@"Pack%d%d.zip", (int)[[NSDate date] timeIntervalSince1970], arc4random()];
        
        [self.currentPack savePackOnly];
    }
    
    
    //step3: upload to S3
    __weak __typeof(&*self)weakSelf = self;
    [self showUploadingIndicator];
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf upload:_generatedZipFilePath withFileName:weakSelf.currentPack.fileNameOnAWS];
    });
    
}


- (void)upload:(NSString *)generatedZipFilePath withFileName:(NSString *)saveName {
    
    NSAssert([PFUser currentUser].username.length > 0, @"PFUser currentUser].username should exist");

    NSString *expectedBucketName = [[PFUser currentUser].username lowercaseString]; //aws要求bucket必须是小写的
    
    [iConsole info:@"%s:expectedBucketName= %@",__FUNCTION__,expectedBucketName];
    
    expectedBucketName = [NSString stringWithFormat:@"%@-%@",expectedBucketName,BucketPostfixAfterUserName];
    
    AWSS3 *s3 = [AWSS3 defaultS3];
    
    __block BOOL existing = NO;
    [[[s3 listBuckets:nil] continueWithBlock:^id(AWSTask *task) {
        
        AWSS3ListBucketsOutput *listBucketOutput = task.result;
        
        NSArray *buckets = listBucketOutput.buckets;
        for (AWSS3Bucket *item in buckets) {
            if ([item.name isEqualToString:expectedBucketName]) {
                existing = YES;
            }
        }
        
        
        return nil;
    }] waitUntilFinished];
    
    if (existing == NO) {
        
        
        AWSS3CreateBucketRequest *createBucketReq = [AWSS3CreateBucketRequest new];
        createBucketReq.bucket = expectedBucketName;
        __block BOOL success = NO;
        [[[s3 createBucket:createBucketReq] continueWithBlock:^id(AWSTask *task) {
            if (task.error) {
                 [iConsole error:@"%s:%@",__FUNCTION__,[task.error description]];
                success = NO;
            } else {
                [iConsole info:@"%s:succesfully create a new bucket with name = %@",__FUNCTION__,expectedBucketName];
                success = YES;
            }
            return nil;
        }] waitUntilFinished];
        
        if (success == NO) {
            
            [self hideHud];
            
            //有可能到这里，因为：The bucket namespace is shared by all users of the system. Please select a different name and try again.
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ERROR",@"") message:NSLocalizedString(@"DIALOG_FAILURE_TO_CREATE_BUCKET",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"DIALOG_OK",@"") otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
        
        
//        AWSS3Grantee *granteeOne = [AWSS3Grantee new];
//        granteeOne.URI = @"http://acs.amazonaws.com/groups/global/AllUsers";
//        granteeOne.types = AWSS3TypesGroup;
//        
//        AWSS3Grant *grantOne = [AWSS3Grant new];
//        grantOne.permission = AWSS3PermissionFullControl;
//        grantOne.grantee = granteeOne;
//        
//        NSArray *grantsList = [NSArray arrayWithObjects:grantOne, nil];
//        
//        AWSS3Owner *s3Owner = [AWSS3Owner new];
//        s3Owner.displayName = @"jackyccaa";
//        s3Owner.identifier = @"255052dd94bf53e48d6c71d003b1b25cd95bd411c96683275cd43a0efde8cfc1";
//        
//        
//        AWSS3AccessControlPolicy *accessControlPolicy = [AWSS3AccessControlPolicy new];
//        accessControlPolicy.grants = grantsList;
//        accessControlPolicy.owner = s3Owner;
//        
//        AWSS3PutBucketAclRequest *putBucketAclReq = [AWSS3PutBucketAclRequest new];
//        putBucketAclReq.bucket = expectedBucketName;
//        putBucketAclReq.accessControlPolicy = accessControlPolicy;
//        success = NO;
//        [[[s3 putBucketAcl:putBucketAclReq] continueWithBlock:^id(AWSTask *task) {
//            
//            if (task.error) {
//                success = NO;
//            } else {
//                success = YES;
//            }
//            
//            return nil;
//            
//        }] waitUntilFinished];
        
        
    }
    
    
    
    //1. setup
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.body = [NSURL fileURLWithPath:generatedZipFilePath];
    uploadRequest.key = saveName;
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    uploadRequest.bucket = expectedBucketName;
    

    //3. 执行upload
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    [[transferManager upload:uploadRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            [iConsole error:@"%s:%@",__FUNCTION__,[task.error  description]];
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                switch (task.error.code) {
                    case AWSS3TransferManagerErrorCancelled:
                    case AWSS3TransferManagerErrorPaused:
                        break;
                    default:
                        NSLog(@"Upload failed: [%@]", task.error);
                        break;
                }
            } else {
                NSLog(@"Upload failed: [%@]", task.error);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [iConsole error:@"File upload failed with error - %@", task.error];
                [self hideHud];
                [Common alertViewCommon:NSLocalizedString(@"DIALOG_UPLOAD_FAILURE",@"")];
            });
            
        } else {
            
        }
        
        //5. 执行完毕后，进行操作
        __weak __typeof(&*self)weakSelf = self;
        if (task.result) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [_HUD hide:YES];
                [iConsole info:@"Upload complete"];
                
                
                //save local meta info
                NSString *link = [NSString stringWithFormat:@"%@/%@/%@",S3BaseURL,expectedBucketName,saveName];
                NSString *sharedate = [FileOperationHelper getTodayString];
                NSDictionary * rawDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_currentPack.packName];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rawDict];
                [dict setObject:sharedate forKey:@"share_date"];
                [[NSUserDefaults standardUserDefaults] setObject:dict forKey:_currentPack.packName];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                //share action
                [weakSelf shareAction:link];
                
            });
            
        }
        
        return nil;
    }];
    
    
    //4.在uploadProgress中自动更新进度
    switch (uploadRequest.state) {
        case AWSS3TransferManagerRequestStateRunning: {
            
            uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (totalBytesExpectedToSend > 0) {
                        float progress = (float)((double) totalBytesSent / totalBytesExpectedToSend);
                        
                        _progressivePercent = progress;
                        _HUD.progress = progress;
                        
                    }
                    
                    
                });
            };
            break;
        }
            
        default:
        {
            [_HUD hide:YES];
            [iConsole info:@"go to default here"];
            break;
        }
    }
    
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
    
    
    UIAlertView *alert;
    if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
        alert = [[UIAlertView alloc] initWithTitle:nil
                                           message:NSLocalizedString(@"DIALOG_SET_MAX_NUMBER_OF_DOWNLOADS",@"")
                                          delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                                 otherButtonTitles:NSLocalizedString(@"Keyboard_Unlimited",@""), nil];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DIALOG_ALERT",@"")
                                   message:NSLocalizedString(@"DIALOG_SET_MAX_NUMBER_OF_DOWNLOADS",@"")
                                  delegate:self cancelButtonTitle:NSLocalizedString(@"Keyboard_Done",@"")
                         otherButtonTitles:NSLocalizedString(@"Keyboard_Unlimited",@""), nil];
    }
    alert.tag = 2;
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert textFieldAtIndex:0].text = @"9999";
    alert.delegate = self;
    [alert show];
    
    APP_DELEGATE.isAllowToShowPackList = NO;
    
}

- (BOOL) insertIntoAmazonSingleDB: (NSString *) itemName withMaxNo: (int) maxNo {
    [iConsole info:@"%s",__FUNCTION__];
    BOOL result = false;
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",maxNo],@"0", nil] forKeys:[NSArray arrayWithObjects:@"maxNo",@"currentNo", nil]];
    NSString *defaultDomain = [SimpleDBHelper defaultDomain];
    result = [SimpleDBHelper insertOrUpdateItem:dict withItemName:itemName withDomainName:defaultDomain];
    
    return result;
}

#pragma mark – UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [iConsole info:@"%s",__FUNCTION__];
    
    switch (alertView.tag) {
        case 1: {
            [[alertView textFieldAtIndex:0] resignFirstResponder];
            NSString *password = [alertView textFieldAtIndex:0].text;
            [self uploadToAWSS3:password];
            
        }
            
            break;
            
        case 2: {
            [[alertView textFieldAtIndex:0] resignFirstResponder];
            
            if ([_finalShareLinkBeforeRedirect containsString:@"tinyurl"] == false) {
                _HUD.labelText = NSLocalizedString(@"Indicator_Creating_Short_Linkage",@"");
                [_HUD show:YES];
                
                __weak __typeof(&*self)weakSelf = self;
                double delayInSeconds = 0.4;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    
                    //1.生成short linkage
                    NSString *redirectedStr =[self redirectURL:_finalShareLinkBeforeRedirect];
                    if ((redirectedStr == nil) || (redirectedStr.length == 0)) {
                        [weakSelf hideHud];
                        [Common alertViewCommon:NSLocalizedString(@"DIALOG_REDIRECT_SERVICE_UNAVAILABLE",@"")];
                        return;
                    }
                    [weakSelf hideHud];
                    
                    
                    weakSelf.currentPack.shareLink = redirectedStr;
                    [weakSelf.currentPack savePackOnly];
                    
                    //2. save meta info in background
                    // insert this record in amazon singleDB for pack download limit control
                    // shareLinkage is kind of "https://s3.amazonaws.com/internetics.flashcardcreator/internetics.flashcardcreator/Pack1432614117-1358153070.zip"
                    // [shareLinkage lastPathComponent] is kind of "Pack1374148414-1884690931.zip"
                    NSString *maxNoString = [alertView textFieldAtIndex:0].text;
                    int maxNo;
                    if (buttonIndex == 1) {
                        //unlimited
                        maxNo = 9999999;
                    } else {
                        maxNo = [maxNoString integerValue];
                    }
                    NSRange range = [[_finalShareLinkBeforeRedirect lastPathComponent] rangeOfString:@".zip"];
                    NSString *simpleDBItemName = [[_finalShareLinkBeforeRedirect lastPathComponent] substringToIndex:range.location];
                    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    dispatch_async(queue, ^{
                        [iConsole info:@"Amazon simpleDB item name:%@",simpleDBItemName];
                        BOOL succeeded = [weakSelf insertIntoAmazonSingleDB:simpleDBItemName withMaxNo:maxNo];
                        if (succeeded == false) {
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Error to insertIntoAmazonSingleDB" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            [alertView show];
                            return;
                        }
                    });
                    
                    //3. 分享
                    _finalPostMessage = [NSString stringWithFormat:@"I've just created a pack of Flash Cards with Flip Flash Cards app! ( %@ ) Check it out! Get the Flip Flash Cards app http://www.apple.com",redirectedStr];
                    
                    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"DIALOG_SHARE",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") destructiveButtonTitle:nil otherButtonTitles:
                                                  @"Facebook",
                                                  @"Twitter",
                                                  @"Email",
                                                  @"Copy",
                                                  nil];
                    actionSheet.tag = Type_ActionSheet_Share;
                    [actionSheet showInView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
                });
            } else {
                //已经是短链接了，可以直接处理
                
                //保证shareLink存在
                if (self.currentPack.shareLink.length == 0) {
                    self.currentPack.shareLink = _finalShareLinkBeforeRedirect;
                    [self.currentPack savePackOnly];
                }
                
                _finalPostMessage = [NSString stringWithFormat:@"I've just created a pack of Flash Cards with Flip Flash Cards app! ( %@ ) Check it out! Get the Flip Flash Cards app http://www.apple.com",_finalShareLinkBeforeRedirect];
                
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"DIALOG_SHARE",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"DIALOG_CANCEL",@"") destructiveButtonTitle:nil otherButtonTitles:
                                              @"Facebook",
                                              @"Twitter",
                                              @"Email",
                                              NSLocalizedString(@"Title_Copy_To_Clipboard",@""),
                                              nil];
                actionSheet.tag = Type_ActionSheet_Share;
                [actionSheet showInView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
            }
            
        }
            
            break;
            
        default:
            break;
    }
    
    APP_DELEGATE.isAllowToShowPackList = YES;
    
    
    
}



#pragma mark -
#pragma mark - MBProgressHUDDelegate and related

- (void)showUploadingIndicator {
	
	_HUD = [[MBProgressHUD alloc] initWithView:APP_DELEGATE.progressHUDHolderView];
    _HUD.mode = MBProgressHUDModeDeterminate;
    _HUD.delegate = self;
    _HUD.labelText = NSLocalizedString(@"Indicator_Upload",@"")
;
    [_HUD showWhileExecuting:@selector(uploadProgressTask) onTarget:self withObject:nil animated:YES];
    
    [APP_DELEGATE.progressHUDHolderView insertSubview:_HUD atIndex:0];
    [APP_DELEGATE.progressHUDHolderView bringSubviewToFront:_HUD];
    
}

- (void)uploadProgressTask {
    [iConsole info:@"%s",__FUNCTION__];
	while (_progressivePercent < 1.0f) {
		_HUD.progress = _progressivePercent;
		usleep(50000);
	}
    _progressivePercent = 0;
    
    _HUD.mode = MBProgressHUDModeIndeterminate;
;
    
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [iConsole info:@"%s",__FUNCTION__];
	//[_HUD removeFromSuperview];  //我们需要多次的hide/show，所以需要comment out这段默认的逻辑
}

- (void) hideHud {
    if (_HUD) {
        [_HUD hide:YES];
        [_HUD removeFromSuperview];//we need to clean up _HUD
    }
}


/**
 *  生成短连接，通过tinyurl.com
 */
- (NSString *) redirectURL:(NSString *)urlStr {
    [iConsole info:@"%s, url to be redirected:%@",__FUNCTION__,urlStr];
    NSString *returnURL;
    NSString *requestURL = [NSString stringWithFormat:@"%@%@",URL_REDIRECT_API,urlStr];
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10]; //the default timeout interval is 60 seconds.
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
            
        }
    }
    
    [iConsole info:@"%s, redirected url:%@",__FUNCTION__,returnURL];
    
    return returnURL;
}

#pragma mark – UIActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.tag == Type_ActionSheet_Share) {
        
        switch (buttonIndex) {
            case 0: {
                
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
                break;
        }
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
    _generatedZipFilePath = nil;
}


@end
