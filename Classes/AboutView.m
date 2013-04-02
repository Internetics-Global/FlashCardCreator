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
		textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, self.frame.size.width - 20, self.frame.size.height - 20)];
        textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		textView.backgroundColor = [UIColor clearColor];
		textView.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
		//textView.text = @"Direct Digital is a smart publisher that publishes smart things like this app. Based in Brisbane, Australia, Direct Digital likes doing things that other people like us doing. Another thing that people seem to like is the\n\n\nwebsite. Check it out and see if you like to too.";
		textView.text = @"Flash Card Creator has been developed by Flip Flash Cards Pty Ltd in conjunction with development team Internetics Pty Ltd.\nCopyright Flip Flash Cards 2013. All rights reserved.\nFor information on how to use the application, please click the (i) information button above.\nPlease submit any technical feedback to fcc@internetics.net.au\nThank you for your interest in Flash Card Creator and Flip Flash Cards Pty Ltd.";
		textView.textColor = [UIColor whiteColor];
		[self addSubview:textView];
		UILabel *linkLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
		linkLabel.backgroundColor = [UIColor clearColor];
		linkLabel.text = @"http://www.internetics.net.au";
		linkLabel.textColor = [UIColor colorWithRed:0.9 green:0.25 blue:0.59 alpha:1.0];
		linkLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
		linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
		linkButton.frame = CGRectMake(400, 296, 220, 20);
		[linkButton addSubview:linkLabel];
		[self addSubview:linkButton];
    }
    return self;
}

@end
