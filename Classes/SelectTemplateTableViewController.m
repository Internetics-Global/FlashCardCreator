//
//  SelectTemplateTableViewController.m
//  FFC
//
//  Created by Wang Bourne on 6/02/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "SelectTemplateTableViewController.h"

@interface SelectTemplateTableViewController ()

@end

@implementation SelectTemplateTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
        
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSelectTemplateView)];
        self.navigationItem.rightBarButtonItem = closeButton;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Title_Select_Template",@"");
    self.view.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 17; //2 is the latest added as request from client
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            cell.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
    
    NSString *imageName;
    if (isUserInterfaceIdiomPhone) {
        if (_isQuestionShowing == YES) {
            //templateScreenshot0_answer.png
            imageName= [NSString stringWithFormat:@"templateScreenshot%ld_question.png",indexPath.row];
        } else {
            imageName= [NSString stringWithFormat:@"templateScreenshot%ld_answer.png",indexPath.row];
        }
    } else {
        if (_isQuestionShowing == YES) {
            imageName= [NSString stringWithFormat:@"templateScreenshot%ld_question_iPad.png",indexPath.row];
        } else {
            imageName= [NSString stringWithFormat:@"templateScreenshot%ld_answer_iPad.png",indexPath.row];
        }   
    }
    
    cell.imageView.image = [UIImage imageNamed:imageName];
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TEMPLATE_SELECTED_NOTIFICATION object:[NSString stringWithFormat:@"%d",indexPath.row]];
    
    if (isUserInterfaceIdiomPhone) {
        #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self dismissModalViewControllerAnimated:YES];    
    }
}

#pragma mark -
#pragma mark - Action

- (void) closeSelectTemplateView {
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark – Rotate control
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotate {
    
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskLandscape;
}

@end
