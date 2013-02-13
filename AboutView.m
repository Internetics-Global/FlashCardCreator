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
        //self.frame = CGRectMake(0, 0, 320, 500);
		background = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		background.userInteractionEnabled = NO;
		background.frame = CGRectMake(10, 10, 300, self.frame.size.height - 20);
		[self addSubview:background];
		textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, background.frame.size.width - 20, background.frame.size.height - 20)];
		textView.backgroundColor = [UIColor clearColor];
		textView.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
		//textView.text = @"Direct Digital is a smart publisher that publishes smart things like this app. Based in Brisbane, Australia, Direct Digital likes doing things that other people like us doing. Another thing that people seem to like is the\n\n\nwebsite. Check it out and see if you like to too.";
		textView.text = @"Flash card lessons display three piles of flash cards and a list of phrases or expressions that apply to those cards. On each card there is a picture describing the phrases or words that are attached. Students click on the top card of a pile to hear one of the audio recordings attached to it. They then click on the correct phrase or word which corresponds to the audio they heard. They will hear a bird tweet if they clicked were correct or a squawk if they were incorrect. If correct, a new card comes to the top of the pile and the game continues.\nInitially, all of the pictures are in the pile to the left. After enough correct answers, the ACORNS program will move a top card to the middle pile. After more correct answers, cards move to the rightmost pile. The goal of the game is to get all of the cards to the rightmost pile.";
		textView.textColor = [UIColor blackColor];
		[background addSubview:textView];
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
