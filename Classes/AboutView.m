//
//  AboutView.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 13/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "AboutView.h"

@implementation AboutView

@synthesize linkButton;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        int width = 0;
        if (isUserInterfaceIdiomPhone) {
            width = IPHONE_UI_WIDTH - 20;
        } else {
            width = 300;
        }
        
		if (isUserInterfaceIdiomPhone) {
            textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, width, 205)];
        } else {
            textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, width, 280)];
        }
        
		textView.backgroundColor = [UIColor clearColor];
		textView.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
		//textView.text = @"Direct Digital is a smart publisher that publishes smart things like this app. Based in Brisbane, Australia, Direct Digital likes doing things that other people like us doing. Another thing that people seem to like is the\n\n\nwebsite. Check it out and see if you like to too.";
		textView.text = @"Flash Card Creator has been developed by Flip Flash Cards Pty Ltd in conjunction with development team Internetics Pty Ltd.\n\nCopyright Flip Flash Cards 2013. All rights reserved.\n\nFor information on how to use the application, please click the (i) information button above.\n\nPlease submit any technical feedback to fcc@internetics.net.au\n\nThank you for your interest in Flash Card Creator and Flip Flash Cards Pty Ltd.";
		textView.textColor = [UIColor whiteColor];
        textView.userInteractionEnabled = false;
		[self addSubview:textView];
		UILabel *linkLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
		linkLabel.backgroundColor = [UIColor clearColor];
		linkLabel.text = @"http://www.internetics.net.au";
        linkLabel.textAlignment = NSTextAlignmentCenter;
		linkLabel.textColor = [UIColor colorWithRed:0.9 green:0.25 blue:0.59 alpha:1.0];
		linkLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
		linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
		linkButton.frame = CGRectMake(0, (textView.frame.origin.y + textView.frame.size.height + 5), 300, 20);
		[linkButton addSubview:linkLabel];
		[self addSubview:linkButton];
        
        UILabel *verionLable = [[UILabel alloc] initWithFrame:CGRectMake(0, (linkButton.frame.origin.y + linkButton.frame.size.height), width, 20)];
		verionLable.backgroundColor = [UIColor clearColor];
		verionLable.text = [NSString stringWithFormat:@"Version: %@",[Common appVersion]];
        verionLable.textAlignment = NSTextAlignmentCenter;
		verionLable.textColor = [UIColor whiteColor];
		verionLable.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        [self addSubview:verionLable];
        
        UILabel *buildLable = [[UILabel alloc] initWithFrame:CGRectMake(0, (verionLable.frame.origin.y + verionLable.frame.size.height), width, 20)];
		buildLable.backgroundColor = [UIColor clearColor];
		buildLable.text = [NSString stringWithFormat:@"Build: %@",[Common build]];
        buildLable.textAlignment = NSTextAlignmentCenter;
		buildLable.textColor = [UIColor whiteColor];
		buildLable.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        [self addSubview:buildLable];
        
        UILabel *sqliteLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (buildLable.frame.origin.y + verionLable.frame.size.height), width, 20)];
		sqliteLabel.backgroundColor = [UIColor clearColor];
		sqliteLabel.text = [NSString stringWithFormat:@"SQlite: %d",[Common currentInstalledSqliteVersion]];
        sqliteLabel.textAlignment = NSTextAlignmentCenter;
		sqliteLabel.textColor = [UIColor whiteColor];
		sqliteLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        [self addSubview:sqliteLabel];
    }
    return self;
}

@end
