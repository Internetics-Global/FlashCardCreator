//
//  FileOperationHelper.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/12/12.
//  Copyright (c) 2012 Internetics. All rights reserved.
//

#import "FileOperationHelper.h"
#import "ZipArchive.h"
#import "Card.h"
#import "Question.h"
#import "Answer.h"

@implementation FileOperationHelper

+ (NSString *)documentsDirectory{
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentFolderPath = searchPaths[0];
	return documentFolderPath;
}

+ (NSString *)documentsPathForFileNamed:(NSString *)fileName{
	return [[FileOperationHelper documentsDirectory] stringByAppendingPathComponent:fileName];
}

+ (BOOL)fileExistsAtDocumentsPathWithName:(NSString *)fileName{
	return [[NSFileManager defaultManager] fileExistsAtPath:[FileOperationHelper documentsPathForFileNamed:fileName]];
}

+ (NSString *)temporaryDirectory{
	NSString *temporaryDirectory = NSTemporaryDirectory();
	return temporaryDirectory;
}

+ (NSString *)temporaryPathForFileNamed:(NSString *)fileName{
	return [[self temporaryDirectory] stringByAppendingPathComponent:fileName];
}

+ (NSString *) generateUniquePNGImageFilePath {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,    NSUserDomainMask ,YES );
    NSString *cardListDir = [paths[0] stringByAppendingPathComponent:@"Images"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:cardListDir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:cardListDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", cardListDir);
        }
    }
    
    
    NSString *uid = [NSString stringWithFormat:@"%f%d.png", [[NSDate date] timeIntervalSince1970], arc4random()];
    return ([cardListDir stringByAppendingPathComponent:uid]);
}

+ (NSString *) zipCardForUpload:(Card *) card {
    
    if (card == nil) {
        return nil;
    }
    
    //step 1: build and verify directory structure
    NSString *cardAssembleDir = [[FileOperationHelper documentsDirectory] stringByAppendingPathComponent:@"Card Assemble Factory"];
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cardAssembleDir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:cardAssembleDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", cardAssembleDir);
        }
    }
    
    //step : build questionTextContent.json
    NSDictionary *questionDict = [NSDictionary dictionaryWithObjectsAndKeys:card.question.title,@"title",card.question.content,@"content",[card.question.imageFullPath lastPathComponent],@"image",[card.question.logoFullPath lastPathComponent],@"logo",@"not use",@"type",[card.coverImageURL lastPathComponent],@"cover_image",nil];
    
    NSData *jsonQuestionData = [NSJSONSerialization dataWithJSONObject:questionDict options:NSJSONWritingPrettyPrinted error:&error];
    if (([jsonQuestionData length] >0) && (error == nil)) {
        [jsonQuestionData writeToFile:[cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] atomically:YES];
    } else {
        NSLog(@"Error to generate questionTextContent.json");
    }
    
    //step 3: build answerTextContent.json
    NSDictionary *anserDict = [NSDictionary dictionaryWithObjectsAndKeys:card.answer.title,@"title",card.answer.content,@"content",[card.answer.imageFullPath lastPathComponent],@"image",[card.answer.logoFullPath lastPathComponent],@"logo",nil];
    NSData *jsonAnswerData = [NSJSONSerialization dataWithJSONObject:anserDict options:NSJSONWritingPrettyPrinted error:&error];
    if (([jsonAnswerData length] >0) && (error == nil)) {
        [jsonAnswerData writeToFile:[cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] atomically:YES];
    } else {
        NSLog(@"Error to generate answerTextContent.json");
    }
    
    //step 4: zip them
    ZipArchive* zipFile = [[ZipArchive alloc] init];
    NSString *generateZipFilePath = [cardAssembleDir stringByAppendingPathComponent:@"tempZipFileForUpload.zip"];
    [zipFile CreateZipFile2:generateZipFilePath];
    
    [zipFile addFileToZip:card.answer.logoFullPath newname:[card.answer.logoFullPath lastPathComponent]];
    [zipFile addFileToZip:card.answer.imageFullPath newname:[card.answer.imageFullPath lastPathComponent]];
    [zipFile addFileToZip:[cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] newname:@"answerTextContent.json"];
    
    [zipFile addFileToZip:card.question.logoFullPath newname:[card.question.logoFullPath lastPathComponent]];
    [zipFile addFileToZip:card.question.imageFullPath newname:[card.question.imageFullPath lastPathComponent]];
    [zipFile addFileToZip:[cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] newname:@"questionTextContent.json"];
    
    [zipFile addFileToZip:card.coverImageURL newname:[card.coverImageURL lastPathComponent]];
    
    if( ![zipFile CloseZipFile2] )
    {
        NSLog(@"Failure to execute zip operation");
        return nil;
    }
    
    return generateZipFilePath;
}



@end
