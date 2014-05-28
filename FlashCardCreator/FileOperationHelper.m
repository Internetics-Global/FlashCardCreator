//
//  FileOperationHelper.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "FileOperationHelper.h"
#import "ZipArchive.h"
#import "Pack.h"
#import "Card.h"
#import "Question.h"
#import "Answer.h"
#import "CSS.h"
#import <sys/xattr.h>
#import "Common.h"
#import "OpenUDID.h"

@implementation FileOperationHelper

#pragma mark -
#pragma mark - Basic utilies

+ (NSString *)cachesDirectory{
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cacheFolderPath = searchPaths[0];
	return cacheFolderPath;
}


+ (NSString *)documentDirectory{
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentFolderPath = searchPaths[0];
	return documentFolderPath;
}

/**
 *  !!!!!!Used to save all app data except .db file
 */
+ (NSString *)dataDocumentDirectory{
    NSError *error = nil;
	NSString *path = [self documentsPathForFileNamed:@"com.intenectics.fcc"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", path);
        }
    }
	return path;
}

+ (NSString *)documentsPathForFileNamed:(NSString *)fileName{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentFolderPath = searchPaths[0];
	return [documentFolderPath stringByAppendingPathComponent:fileName];
}

+ (NSString *)cachesPathForFileNamed:(NSString *)fileName{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cachesFolderPath = searchPaths[0];
	return [cachesFolderPath stringByAppendingPathComponent:fileName];
}


+ (NSString *)temporaryDirectory{
	NSString *temporaryDirectory = NSTemporaryDirectory();
	return temporaryDirectory;
}

+ (NSString *)temporaryPathForFileNamed:(NSString *)fileName{
	return [[self temporaryDirectory] stringByAppendingPathComponent:fileName];
}

#pragma mark -
#pragma mark - FlashCardCreator's directory structure

+ (NSString *)imagesDirectory{
    NSString *returnPath = [[self dataDocumentDirectory] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:returnPath]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:returnPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", returnPath);
        }
    }
	return returnPath;
}

/**
 *	which is used to hold unzipped images, and will finally removed to imagesDirectory
 *
 *	@return	<#return value description#>
 */
+ (NSString *)temporaryImagesDirectory{
    NSString *returnPath = [[self dataDocumentDirectory] stringByAppendingPathComponent:@"Temporary_Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:returnPath]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:returnPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", returnPath);
        }
    }
	return returnPath;
}

+ (NSString *)assembleFactoryDirectory{
    NSString *returnPath = [[self dataDocumentDirectory] stringByAppendingPathComponent:@"Card Assemble Factory"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:returnPath]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:returnPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", returnPath);
        }
    }
	return returnPath;
}

+ (NSString *)downloadedZipPackFileFixedPath {
    NSString *dir = [FileOperationHelper downloadedPackFileDirectory ];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", dir);
        }
    }
    
    NSString *path = [dir stringByAppendingPathComponent:@"downloadedZipFile314159.zip"];
    
    return path;
}

+ (NSString *)downloadedPackFileDirectory {
    NSString *dir = [[FileOperationHelper dataDocumentDirectory] stringByAppendingPathComponent:@"Downloaded Pack"];
    NSError *error = nil;
    if(![[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error]) {
        DDLogError(@"Failed to create directory at %@", dir);
    }
    
    return dir;
}

+ (NSString *)unzippedPackInfoJsonFilePath {
    NSString *dir = [FileOperationHelper downloadedPackFileDirectory];
    NSString *path = [dir stringByAppendingPathComponent:@"packInformation.json"];
    return path;
}

/**
 *  Get only the first log file (full path)
 *
 *  @return <#return value description#>
 */
+(NSString*)logFile {
    
    NSArray *array = [self listFileAtPath:[self logDirectory]];
    if ([array count]>0) {
        return [[self logDirectory] stringByAppendingPathComponent:array[0]];
    } else {
        return nil;
    }
}


+ (NSString *)logDirectory {
    NSString *dir = [[FileOperationHelper cachesDirectory] stringByAppendingPathComponent:@"Logs"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", dir);
        }
    }
    
    return dir;
}


+ (NSArray *)listFileAtPath:(NSString *)path
{
    int count;
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++)
    {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    return directoryContent;
}




#pragma mark -
#pragma mark - Generate unique file name

/**
 *  Must be .aac format。
 */
+ (NSString *) generateUniqueAudioAACFilePathUnderImagesFolder {
    NSString *path = [[self dataDocumentDirectory] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", path);
        }
    }
    
    NSString *uid = [NSString stringWithFormat:@"%d%d.aac", (int)[[NSDate date] timeIntervalSince1970], arc4random()];
    return ([path stringByAppendingPathComponent:uid]);
}

/**
 *  Must be .3GP format。
 */
+ (NSString *) generateUniqueAudio3GPFilePathUnderImagesFolder {
    NSString *path = [[self dataDocumentDirectory] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", path);
        }
    }
    
    NSString *uid = [NSString stringWithFormat:@"%d%d.3gp", (int)[[NSDate date] timeIntervalSince1970], arc4random()];
    return ([path stringByAppendingPathComponent:uid]);
}

/**
 *	an unique name will be generated and will be under directory of "Images"
 *
 */
+ (NSString *) generateUniqueJPEGImageFilePathUnderImagesFolder {
    NSString *path = [[self dataDocumentDirectory] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", path);
        }
    }
    
    
    NSString *uid = [NSString stringWithFormat:@"%d%d.jpg", (int)[[NSDate date] timeIntervalSince1970], arc4random()];
    return ([path stringByAppendingPathComponent:uid]);
}


/**
 *	must be .3gp format
 *
 */
+ (NSString *) generateUniqueMovFilePathUnderImagesFolder {
    NSString *path = [[self dataDocumentDirectory] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", path);
        }
    }
    
    
    NSString *uid = [NSString stringWithFormat:@"%d%d.3gp", (int)[[NSDate date] timeIntervalSince1970], arc4random()];
    return ([path stringByAppendingPathComponent:uid]);
}

#pragma mark -
#pragma mark - Zip action

+ (NSString *) zipPackForUpload:(Pack *)pack withPassword: (NSString *) password  {
    DDLogInfo(@"%s",__FUNCTION__);
    //Step1: exception 
    if (pack == nil) {
        [Common alertViewCommon:@"Selected pack is empty"];
        return nil;
    }
    
    //Step2: Directory to exectue zip operaton
    NSString *cardAssembleDir = [FileOperationHelper assembleFactoryDirectory];
    
    //step 3: build packInformation.json
    NSError *error = nil;
    NSString *platformStr;
    if (isUserInterfaceIdiomPhone) {
        platformStr = @"iPhone";
    } else {
        platformStr = @"iPad";
    }
    
    if (pack.creator.length == 0) {
        pack.creator = [OpenUDID value];
    }
    
    NSDictionary *packDict = [NSDictionary dictionaryWithObjectsAndKeys:pack.packName,@"pack_name",pack.sidebarTitle,@"sidebar_title",[pack.coverImageURL lastPathComponent],@"cover_image", pack.creator,@"creator", pack.creatorNickName,@"creator_nick_name", pack.jobTitle,@"job_title",platformStr,@"platform",nil];
    NSData *jsonPackData = [NSJSONSerialization dataWithJSONObject:packDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *packInfoJsonFilePath = [cardAssembleDir stringByAppendingPathComponent:@"packInformation.json"];
    if (([jsonPackData length] >0) && (error == nil)) {
        [jsonPackData writeToFile:packInfoJsonFilePath atomically:YES];
    } else {
        DDLogError(@"Error to generate %@",packInfoJsonFilePath);
    }
    
    //Step3: zip them
    ZipArchive* zipFile = [[ZipArchive alloc] init];
    NSString *generatePackZipFilePath = [cardAssembleDir stringByAppendingPathComponent:
                                     [NSString stringWithFormat:@"Pack%d%d.zip", (int)[[NSDate date] timeIntervalSince1970], arc4random()]];
    if ([password isEqualToString:@""]) {
        [zipFile CreateZipFile2:generatePackZipFilePath];    
    } else {
        [zipFile CreateZipFile2:generatePackZipFilePath Password:password];    
    }
    

    NSString *generateCardZipFilePath = nil;
    
    for (Card *card in [pack cards]) {
        generateCardZipFilePath = [self zipCardForUpload:card];
        [zipFile addFileToZip:generateCardZipFilePath newname:[generateCardZipFilePath lastPathComponent]];
        [[NSFileManager defaultManager] removeItemAtPath:generateCardZipFilePath error:nil];
    }
    
    [zipFile addFileToZip:packInfoJsonFilePath newname:[packInfoJsonFilePath lastPathComponent]];
    
    if ([pack.coverImageURL lastPathComponent].length > 0) {
        [zipFile addFileToZip:pack.coverImageURL newname:[pack.coverImageURL lastPathComponent]];
    }
    
    if( ![zipFile CloseZipFile2] )
    {
        DDLogError(@"Failure to execute pack zip operation");
        return nil;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:packInfoJsonFilePath error:nil];
    
    return generatePackZipFilePath;
}

/**
 *	We put all the necessary files for uploading under Documents/Card Assemble Factory
 *  build card, assemble card, assemblecard
 */
+ (NSString *) zipCardForUpload:(Card *) card {
    DDLogInfo(@"%s",__FUNCTION__);
    if (card == nil) {
        return nil;
    }
    
    //step 1: build and verify directory structure
    NSString *cardAssembleDir = [FileOperationHelper assembleFactoryDirectory];
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cardAssembleDir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:cardAssembleDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            DDLogError(@"Failed to create directory at %@", cardAssembleDir);
        }
    }
    
    //step : build questionTextContent.json
    if (checkNullOrEmptyOrNullStr(card.question.backgroundImageFullPath)) {
        card.question.backgroundImageFullPath = @"";
    }
    
    if (checkNullOrEmptyOrNullStr(card.question.movieFullPath)) {
        card.question.movieFullPath = @"";
    }
    
    if (checkNullOrEmptyOrNullStr(card.question.recordedSoundFullPath)) {
        card.question.recordedSoundFullPath = @"";
    }
    
    //两种情况，普通youtube，另外一种，本地创建
    NSString *movieFinalPathQuestion;
    if ([Common isValidYoutubeLinkage:card.question.movieFullPath]){
        //it's youtube link
        movieFinalPathQuestion = card.question.movieFullPath;
        
    } else {
        movieFinalPathQuestion = [card.question.movieFullPath lastPathComponent];
    }
    
    NSDictionary *questionDict = [NSDictionary dictionaryWithObjectsAndKeys:card.question.title,@"title",card.question.main,@"main",card.question.sub,@"sub",card.question.subheading,@"subheading",[card.question.imageFullPath lastPathComponent],@"image",[card.question.logoFullPath lastPathComponent],@"logo", card.question.logoURLLinkage,@"logo_url",card.creator,@"creator",[card.coverImageURL lastPathComponent],@"cover_image",card.templateBackgroundName,@"template_background",[NSString stringWithFormat:@"%d",card.cardSN],@"cardSN",[NSString stringWithFormat:@"%d",card.question.templateID],@"template_id",card.question.css.subheadingAlign,@"subheading_align",card.question.css.subheadingColor,@"subheading_color",[NSString stringWithFormat:@"%d",(int)card.question.css.subheadingSize],@"subheading_size",card.question.css.mainAlign,@"main_align",card.question.css.mainColor,@"main_color",[NSString stringWithFormat:@"%d",(int)card.question.css.mainSize],@"main_size",card.question.css.subAlign,@"sub_align",card.question.css.subColor,@"sub_color",[NSString stringWithFormat:@"%d",(int)card.question.css.subSize],@"sub_size",
        [NSString stringWithFormat:@"%d",card.question.lineNoSubheading],@"line_number_subheading",
                [NSString stringWithFormat:@"%d",card.question.lineNoMain],@"line_number_main",
                        [NSString stringWithFormat:@"%d",card.question.lineNoSub],@"line_number_sub",[card.question.backgroundImageFullPath lastPathComponent],@"background_image",
                                  movieFinalPathQuestion,@"movie",
                                      [card.question.recordedSoundFullPath lastPathComponent],@"audio",
                                        card.question.css.subheadingFont,@"subheading_font",
                                        card.question.css.mainFont,@"main_font",
                                        card.question.css.subFont,@"sub_font",nil];
    
    NSData *jsonQuestionData = [NSJSONSerialization dataWithJSONObject:questionDict options:NSJSONWritingPrettyPrinted error:&error];
    if (([jsonQuestionData length] >0) && (error == nil)) {
        [jsonQuestionData writeToFile:[cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] atomically:YES];
    } else {
        DDLogError(@"Error to generate questionTextContent.json");
    }
    
    //step 3: build answerTextContent.json
    if (checkNullOrEmptyOrNullStr(card.answer.backgroundImageFullPath)) {
        card.answer.backgroundImageFullPath = @"";
    }
    
    if (checkNullOrEmptyOrNullStr(card.answer.movieFullPath)) {
        card.answer.movieFullPath = @"";
    }
    
    if (checkNullOrEmptyOrNullStr(card.answer.recordedSoundFullPath)) {
        card.answer.recordedSoundFullPath = @"";
    }
    
    //两种情况，普通youtube，另外一种，本地创建
    NSString *movieFinalPathAnswer;
    if ([Common isValidYoutubeLinkage:card.answer.movieFullPath]){
        //it's youtube link
        movieFinalPathAnswer = card.answer.movieFullPath;
        
    } else {
        movieFinalPathAnswer = [card.answer.movieFullPath lastPathComponent];
    }
    
    NSDictionary *anserDict = [NSDictionary dictionaryWithObjectsAndKeys:card.answer.title,@"title",card.answer.main,@"main",card.answer.sub,@"sub", card.answer.subheading,@"subheading",[card.answer.imageFullPath lastPathComponent],@"image",[card.answer.logoFullPath lastPathComponent],@"logo",[NSString stringWithFormat:@"%d",card.answer.templateID],@"template_id", card.answer.css.subheadingAlign,@"subheading_align",card.answer.css.subheadingColor,@"subheading_color",[NSString stringWithFormat:@"%d",(int)card.answer.css.subheadingSize],@"subheading_size",card.answer.css.mainAlign,@"main_align",card.answer.css.mainColor,@"main_color",[NSString stringWithFormat:@"%d",(int)card.answer.css.mainSize],@"main_size",card.answer.css.subAlign,@"sub_align",card.answer.css.subColor,@"sub_color",[NSString stringWithFormat:@"%d",(int)card.answer.css.subSize],@"sub_size",
        [NSString stringWithFormat:@"%d",card.answer.lineNoSubheading],@"line_number_subheading",
            [NSString stringWithFormat:@"%d",card.answer.lineNoMain],@"line_number_main",
                    [NSString stringWithFormat:@"%d",card.answer.lineNoSub],@"line_number_sub",[card.answer.backgroundImageFullPath lastPathComponent],@"background_image",
                               movieFinalPathAnswer,@"movie",
                                   [card.answer.recordedSoundFullPath lastPathComponent],@"audio",
                                      card.answer.css.subheadingFont,@"subheading_font",
                                      card.answer.css.mainFont,@"main_font",
                                      card.answer.css.subFont,@"sub_font",nil];
    
    NSData *jsonAnswerData = [NSJSONSerialization dataWithJSONObject:anserDict options:NSJSONWritingPrettyPrinted error:&error];
    if (([jsonAnswerData length] >0) && (error == nil)) {
        [jsonAnswerData writeToFile:[cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] atomically:YES];
    } else {
        DDLogError(@"Error to generate answerTextContent.json");
    }
    
    //step 4: zip them
    ZipArchive* zipFile = [[ZipArchive alloc] init];
    NSString *generateCardZipFilePath = [cardAssembleDir stringByAppendingPathComponent:
                                       [NSString stringWithFormat:@"card%d%d.zip", (int)[[NSDate date] timeIntervalSince1970], arc4random()]];
    [zipFile CreateZipFile2:generateCardZipFilePath];
    
    if ([card.answer.logoFullPath lastPathComponent].length > 0) {
        [zipFile addFileToZip:card.answer.logoFullPath newname:[card.answer.logoFullPath lastPathComponent]];
    }
    
    if ([card.answer.imageFullPath lastPathComponent].length > 0) {
        [zipFile addFileToZip:card.answer.imageFullPath newname:[card.answer.imageFullPath lastPathComponent]];
    }
    
    if ([card.answer.backgroundImageFullPath lastPathComponent].length > 0) {
        [zipFile addFileToZip:card.answer.backgroundImageFullPath newname:[card.answer.backgroundImageFullPath lastPathComponent]];
    }
    
    if (([card.answer.movieFullPath lastPathComponent].length > 0)
          && ([card.answer.movieFullPath rangeOfString:@"http://"].location == NSNotFound)){
        [zipFile addFileToZip:card.answer.movieFullPath newname:[card.answer.movieFullPath lastPathComponent]];
    }
    
    if ([card.answer.recordedSoundFullPath lastPathComponent].length > 0) {
        [zipFile addFileToZip:card.answer.recordedSoundFullPath newname:[card.answer.recordedSoundFullPath lastPathComponent]];
    }
    
    if (([card.question.movieFullPath lastPathComponent].length > 0)
          && ([card.question.movieFullPath rangeOfString:@"http://"].location == NSNotFound)){
        [zipFile addFileToZip:card.question.movieFullPath newname:[card.question.movieFullPath lastPathComponent]];
    }
    
    if ([card.question.recordedSoundFullPath lastPathComponent].length > 0) {
        [zipFile addFileToZip:card.question.recordedSoundFullPath newname:[card.question.recordedSoundFullPath lastPathComponent]];
    }
    
    [zipFile addFileToZip:[cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] newname:@"answerTextContent.json"];
    
    if ([card.question.logoFullPath lastPathComponent].length > 0) {
        [zipFile addFileToZip:card.question.logoFullPath newname:[card.question.logoFullPath lastPathComponent]];
    }
    
    if ([card.question.imageFullPath lastPathComponent].length >0) {
        [zipFile addFileToZip:card.question.imageFullPath newname:[card.question.imageFullPath lastPathComponent]];
    }
    
    if ([card.question.backgroundImageFullPath lastPathComponent].length > 0) {
        [zipFile addFileToZip:card.question.backgroundImageFullPath newname:[card.question.backgroundImageFullPath lastPathComponent]];
    }
    
    [zipFile addFileToZip:[cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] newname:@"questionTextContent.json"];
    
    if ([card.coverImageURL lastPathComponent].length > 0) {
        [zipFile addFileToZip:card.coverImageURL newname:[card.coverImageURL lastPathComponent]];
    }
    
    if( ![zipFile CloseZipFile2] )
    {
        DDLogInfo(@"Failure to execute card zip operation");
        return nil;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:[cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] error:nil];
    
    return generateCardZipFilePath;
}

+ (NSString *)getTodayString {
    NSDateFormatter*formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *locationString=[formatter stringFromDate: [NSDate date]];
    return locationString;
}

+ (NSDate *)convertStringToNSDate:(NSString *) str {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:str];
    return dateFromString;
}

+ (BOOL) isPackListOpenedBefore {
    //return [[NSUserDefaults standardUserDefaults] boolForKey:@"isPackListOpenedBefore"];
    return FALSE; // always false
}



+ (BOOL)addSkipBackupAttributeToFileAtPath:(NSString *)aFilePath
{
    DDLogInfo(@"%s",__FUNCTION__);
    assert([[NSFileManager defaultManager] fileExistsAtPath:aFilePath]);
    NSError *error = nil;
    BOOL success = NO;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.1"))
    {
        success = [[NSURL fileURLWithPath:aFilePath] setResourceValue:[NSNumber numberWithBool:YES]
                                                               forKey:NSURLIsExcludedFromBackupKey
                                                                error:&error];
    }
    else if (SYSTEM_VERSION_EQUAL_TO(@"5.0.1"))
    {
        const char* filePath = [aFilePath fileSystemRepresentation];
        const char* attrName = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        success = (result == 0);
    }
    else
    {
        DDLogError(@"Can not add 'do no back up' attribute at systems before 5.0.1");
    }
    
    if(!success)
    {
        DDLogError(@"Error excluding %@ from backup %@", [aFilePath lastPathComponent], error);
    }
    
    return success;
}

+ (NSArray *)listFilesAtPath:(NSString *)path
{
    int count;
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++)
    {
        DDLogError(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    return directoryContent;
}



@end
