//
//  SelectTemplateBackgroundTableViewController.m
//  FlashCardCreator
//
//  Created by Wang Bourne on 11/03/13.
//  Copyright (c) 2013 Internetics. All rights reserved.
//

#import "SelectTemplateBackgroundTableViewController.h"

@interface SelectTemplateBackgroundTableViewController ()

@end

@implementation SelectTemplateBackgroundTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    UIView* bgview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    bgview.opaque = YES;
    [cell setBackgroundView:bgview];
    
    switch (indexPath.row) {
        case 0:
            bgview.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
            break;
        case 1:
            bgview.backgroundColor = [UIColor blueColor];
            break;
        case 2:
            bgview.backgroundColor = [UIColor redColor];
            break;
        case 3:
            bgview.backgroundColor = [UIColor grayColor];
            break;
        case 4:
            bgview.backgroundColor = [UIColor purpleColor];
            break;
        default:
            break;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TEMPLATE_BACKGROUND_SELECTED_NOTIFICATION object:[NSString stringWithFormat:@"%d",indexPath.row]];
}

@end
