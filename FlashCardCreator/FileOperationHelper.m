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

@implementation FileOperationHelper

#pragma mark -
#pragma mark - Basic utilies

+ (NSString *)cachesDirectory{
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cacheFolderPath = searchPaths[0];
	return cacheFolderPath;
}

+ (NSString *)documentsPathForFileNamed:(NSString *)fileName{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentFolderPath = searchPaths[0];
	return [documentFolderPath stringByAppendingPathComponent:fileName];
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
    NSString *returnPath = [[self cachesDirectory] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:returnPath]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:returnPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", returnPath);
        }
    }
	return returnPath;
}

+ (NSString *)assembleFactoryDirectory{
    NSString *returnPath = [[self cachesDirectory] stringByAppendingPathComponent:@"Card Assemble Factory"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:returnPath]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:returnPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", returnPath);
        }
    }
	return returnPath;
}

+ (NSString *)downloadedZipPackFileFixedPath {
    NSString *dir = [FileOperationHelper downloadedPackFileDirectory ];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", dir);
        }
    }
    
    NSString *path = [dir stringByAppendingPathComponent:@"downloadedZipFile314159.zip"];
    
    return path;
}

+ (NSString *)downloadedPackFileDirectory {
    NSString *dir = [[FileOperationHelper cachesDirectory] stringByAppendingPathComponent:@"Downloaded Pack"];
    NSError *error = nil;
    if(![[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"Failed to create directory at %@", dir);
    }
    
    return dir;
}

#pragma mark -
#pragma mark - Generate unique file name

+ (NSString *) generateUniqueJPEGImageFilePath {
    NSString *path = [[self cachesDirectory] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", path);
        }
    }
    
    
    NSString *uid = [NSString stringWithFormat:@"%f%d.jpg", [[NSDate date] timeIntervalSince1970], arc4random()];
    return ([path stringByAppendingPathComponent:uid]);
}

#pragma mark -
#pragma mark - Zip action

+ (NSString *) zipPackForUpload:(Pack *)pack  {
    //Step1: exception 
    if (pack == nil) {
        [Common alertViewCommon:@"Selected pack is empty"];
        return nil;
    }
    
    //Step2: Directory to exectue zip operaton
    NSString *cardAssembleDir = [FileOperationHelper assembleFactoryDirectory];
    
    //step 3: build packInformation.json
    NSError *error = nil;
    NSDictionary *packDict = [NSDictionary dictionaryWithObjectsAndKeys:pack.packName,@"pack_name",[pack.coverImageURL lastPathComponent],@"cover_image", pack.creator,@"creator",nil];
    NSData *jsonPackData = [NSJSONSerialization dataWithJSONObject:packDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *packInfoJsonFilePath = [cardAssembleDir stringByAppendingPathComponent:@"packInformation.json"];
    if (([jsonPackData length] >0) && (error == nil)) {
        [jsonPackData writeToFile:packInfoJsonFilePath atomically:YES];
    } else {
        NSLog(@"Error to generate %@",packInfoJsonFilePath);
    }
    
    //Step3: zip them
    ZipArchive* zipFile = [[ZipArchive alloc] init];
    NSString *generatePackZipFilePath = [cardAssembleDir stringByAppendingPathComponent:
                                     [NSString stringWithFormat:@"pack%f%d.zip", [[NSDate date] timeIntervalSince1970], arc4random()]];
    [zipFile CreateZipFile2:generatePackZipFilePath];

    NSString *generateCardZipFilePath = nil;
    
    for (Card *card in [pack cards]) {
        generateCardZipFilePath = [self zipCardForUpload:card];
        [zipFile addFileToZip:generateCardZipFilePath newname:[generateCardZipFilePath lastPathComponent]];
        [[NSFileManager defaultManager] removeItemAtPath:generateCardZipFilePath error:nil];
    }
    
    [zipFile addFileToZip:packInfoJsonFilePath newname:[packInfoJsonFilePath lastPathComponent]];
    [zipFile addFileToZip:pack.coverImageURL newname:[pack.coverImageURL lastPathComponent]];
    
    if( ![zipFile CloseZipFile2] )
    {
        NSLog(@"Failure to execute pack zip operation");
        return nil;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:packInfoJsonFilePath error:nil];
    
    return generatePackZipFilePath;
}

//We put all the necessary files for uploading under Documents/Card Assemble Factory
+ (NSString *) zipCardForUpload:(Card *) card {
    
    if (card == nil) {
        return nil;
    }
    
    //step 1: build and verify directory structure
    NSString *cardAssembleDir = [FileOperationHelper assembleFactoryDirectory];
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cardAssembleDir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:cardAssembleDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", cardAssembleDir);
        }
    }
    
    //step : build questionTextContent.json
    NSDictionary *questionDict = [NSDictionary dictionaryWithObjectsAndKeys:card.question.title,@"title",card.question.main,@"main",card.question.sub,@"sub",card.question.subheading,@"subheading",[card.question.imageFullPath lastPathComponent],@"image",[card.question.logoFullPath lastPathComponent],@"logo", card.question.logoURLLinkage,@"logo_url",card.creator,@"creator",[card.coverImageURL lastPathComponent],@"cover_image",[NSString stringWithFormat:@"%d",card.cardSN],@"cardSN",[NSString stringWithFormat:@"%d",card.templateID],@"template_id",card.question.css.subheadingAlign,@"subheading_align",card.question.css.subheadingColor,@"subheading_color",[NSString stringWithFormat:@"%d",card.question.css.subheadingSize],@"subheading_size",card.question.css.mainAlign,@"main_align",card.question.css.mainColor,@"main_color",[NSString stringWithFormat:@"%d",card.question.css.mainSize],@"main_size",card.question.css.subAlign,@"sub_align",card.question.css.subColor,@"sub_color",[NSString stringWithFormat:@"%d",card.question.css.subSize],@"sub_size",nil];
    
    NSData *jsonQuestionData = [NSJSONSerialization dataWithJSONObject:questionDict options:NSJSONWritingPrettyPrinted error:&error];
    if (([jsonQuestionData length] >0) && (error == nil)) {
        [jsonQuestionData writeToFile:[cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] atomically:YES];
    } else {
        NSLog(@"Error to generate questionTextContent.json");
    }
    
    //step 3: build answerTextContent.json
    NSDictionary *anserDict = [NSDictionary dictionaryWithObjectsAndKeys:card.answer.title,@"title",card.answer.main,@"main",card.answer.sub,@"sub", card.answer.subheading,@"subheading",[card.answer.imageFullPath lastPathComponent],@"image",[card.answer.logoFullPath lastPathComponent],@"logo",card.answer.css.subheadingAlign,@"subheading_align",card.answer.css.subheadingColor,@"subheading_color",[NSString stringWithFormat:@"%d",card.answer.css.subheadingSize],@"subheading_size",card.answer.css.mainAlign,@"main_align",card.answer.css.mainColor,@"main_color",[NSString stringWithFormat:@"%d",card.answer.css.mainSize],@"main_size",card.answer.css.subAlign,@"sub_align",card.answer.css.subColor,@"sub_color",[NSString stringWithFormat:@"%d",card.answer.css.subSize],@"sub_size",nil];
    NSData *jsonAnswerData = [NSJSONSerialization dataWithJSONObject:anserDict options:NSJSONWritingPrettyPrinted error:&error];
    if (([jsonAnswerData length] >0) && (error == nil)) {
        [jsonAnswerData writeToFile:[cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] atomically:YES];
    } else {
        NSLog(@"Error to generate answerTextContent.json");
    }
    
    //step 4: zip them
    ZipArchive* zipFile = [[ZipArchive alloc] init];
    NSString *generateCardZipFilePath = [cardAssembleDir stringByAppendingPathComponent:
                                       [NSString stringWithFormat:@"card%f%d.zip", [[NSDate date] timeIntervalSince1970], arc4random()]];
    [zipFile CreateZipFile2:generateCardZipFilePath];
    
    [zipFile addFileToZip:card.answer.logoFullPath newname:[card.answer.logoFullPath lastPathComponent]];
    [zipFile addFileToZip:card.answer.imageFullPath newname:[card.answer.imageFullPath lastPathComponent]];
    [zipFile addFileToZip:[cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] newname:@"answerTextContent.json"];
    
    [zipFile addFileToZip:card.question.logoFullPath newname:[card.question.logoFullPath lastPathComponent]];
    [zipFile addFileToZip:card.question.imageFullPath newname:[card.question.imageFullPath lastPathComponent]];
    [zipFile addFileToZip:[cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] newname:@"questionTextContent.json"];
    
    [zipFile addFileToZip:card.coverImageURL newname:[card.coverImageURL lastPathComponent]];
    
    if( ![zipFile CloseZipFile2] )
    {
        NSLog(@"Failure to execute card zip operation");
        return nil;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:[cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] error:nil];
    
    return generateCardZipFilePath;
}

+ (NSString *)getTodayString {
    NSDateFormatter*formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSString *locationString=[formatter stringFromDate: [NSDate date]];
    return locationString;
}

+ (NSDate *)convertStringToNSDate:(NSString *) str {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSDate *dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:str];
    return dateFromString;
}


@end
