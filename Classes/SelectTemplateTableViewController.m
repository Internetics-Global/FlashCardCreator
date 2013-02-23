//
//  SelectTemplateTableViewController.m
//  FlashCardCreator
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
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 95;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    NSString *imageName = [NSString stringWithFormat:@"templateScreenshot%d.png",indexPath.row];
    cell.imageView.image = [UIImage imageNamed:imageName];
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TEMPLATE_SELECTED_NOTIFICATION object:[NSString stringWithFormat:@"%d",indexPath.row]];
    
    if (isUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];    
    }
}

@end
