//
//  PlayOptionViewController.m
//  FlashCardCreator
//
//  Created by Internetics on 4/12/2015.
//  Copyright © 2015 Internetics. All rights reserved.
//

#import "PlayOptionViewController.h"
#import "Common.h"

@interface PlayOptionViewController () <UITableViewDelegate, UITableViewDataSource>{
    UITableView *_alertTable;
}

@end

@implementation PlayOptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _alertTable = [[UITableView alloc] initWithFrame:self.view.bounds];
    _alertTable.delegate = self;
    _alertTable.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _alertTable.dataSource = self;
    _alertTable.opaque = NO;
    _alertTable.backgroundView = nil;
    _alertTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    _alertTable.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    [self.view addSubview:_alertTable];
    
    self.title = @"Manual/Auto Play";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedString(@"Optional_Play_Manually",@"");
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = NSLocalizedString(@"Optional_Auto_Play",@"");
    }
    else if (indexPath.row == 2)
    {
        cell.textLabel.text = NSLocalizedString(@"Optional_Auto_Play_Loop",@"");
    }
    
    int playOption = [Common getPlayOption];
    if (indexPath.row == playOption) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        cell.tintColor = [UIColor whiteColor];
    }
    
    cell.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [Common setPlayOption:indexPath.row];
    [_alertTable reloadData];
}

@end
