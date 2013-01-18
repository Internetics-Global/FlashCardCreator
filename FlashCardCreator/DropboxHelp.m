//
//  DropboxHelp.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 17/01/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "DropboxHelp.h"
#import "Card.h"
#import "Question.h"
#import "Answer.h"
#import "FileOperationHelper.h"
#import "ZipArchive.h"


@implementation DropboxHelp

- (NSString *) zipCardForUpload:(Card *) card {
    
    if (card == nil) {
        return nil;
    }
    
    NSError *error = nil;
    //step 1: verify directory structure
    [self verifyDirectoryStructure];
    
    //step : build questionTextContent.json
    NSDictionary *questionDict = [NSDictionary dictionaryWithObjectsAndKeys:card.question.title,@"title",card.question.content,@"content",[card.question.imageFullPath lastPathComponent],@"image",[card.question.logoFullPath lastPathComponent],@"logo",@"not use",@"type",nil];
    
    NSData *jsonQuestionData = [NSJSONSerialization dataWithJSONObject:questionDict options:NSJSONWritingPrettyPrinted error:&error];
    if (([jsonQuestionData length] >0) && (error == nil)) {
        [jsonQuestionData writeToFile:[_cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] atomically:YES];
    } else {
        NSLog(@"Error to generate questionTextContent.json");
    }
    
    //step 3: build answerTextContent.json
    NSDictionary *anserDict = [NSDictionary dictionaryWithObjectsAndKeys:card.answer.title,@"title",card.answer.content,@"content",[card.answer.imageFullPath lastPathComponent],@"image",[card.answer.logoFullPath lastPathComponent],@"logo",nil];
    NSData *jsonAnswerData = [NSJSONSerialization dataWithJSONObject:anserDict options:NSJSONWritingPrettyPrinted error:&error];
    if (([jsonAnswerData length] >0) && (error == nil)) {
        [jsonAnswerData writeToFile:[_cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] atomically:YES];
    } else {
        NSLog(@"Error to generate answerTextContent.json");
    }
    
    //step 4: zip them 
    ZipArchive* zipFile = [[ZipArchive alloc] init];
    NSString *generateZipFilePath = [_cardAssembleDir stringByAppendingPathComponent:@"tempZipFileForUpload.zip"];
    [zipFile CreateZipFile2:generateZipFilePath];
    
    [zipFile addFileToZip:card.answer.logoFullPath newname:[card.answer.logoFullPath lastPathComponent]];
    [zipFile addFileToZip:card.answer.imageFullPath newname:[card.answer.imageFullPath lastPathComponent]];
    [zipFile addFileToZip:[_cardAssembleDir stringByAppendingPathComponent:@"answerTextContent.json"] newname:@"answerTextContent.json"];
    
    [zipFile addFileToZip:card.question.logoFullPath newname:[card.question.logoFullPath lastPathComponent]];
    [zipFile addFileToZip:card.question.imageFullPath newname:[card.question.imageFullPath lastPathComponent]];
    [zipFile addFileToZip:[_cardAssembleDir stringByAppendingPathComponent:@"questionTextContent.json"] newname:@"questionTextContent.json"];
    
    
    if( ![zipFile CloseZipFile2] )
    {
        NSLog(@"Failure to execute zip operation");
        return nil;
    }
    
    
    return generateZipFilePath;
}


/* 
Check following directory structure under Document/
 -Card Assemble Factory
     -xxxdsfs.png   //answer image
     -xxdff3d.png   //answer logo
     -answerTextContent.json
     -xxvsffe.png   //question image
     -xx2fddf.png   //question logo
     -questionTextContent.json
*/
- (void) verifyDirectoryStructure {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,    NSUserDomainMask ,YES );
    _cardAssembleDir = [paths[0] stringByAppendingPathComponent:@"Card Assemble Factory"];
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_cardAssembleDir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:_cardAssembleDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory at %@", _cardAssembleDir);
            return;
        }
    }
}

@end
