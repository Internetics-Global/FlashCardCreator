//
//  MoreMoreInfoTableViewController.m
//  
//
//  Created by Internetics on 14/07/2015.
//
//

#import "MoreMoreInfoTableViewController.h"

@implementation MoreMoreInfoTableViewController


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"More";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (isUserInterfaceIdiomPhone) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NavigationBarItem_Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    
    self.tableView.backgroundColor = [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor colorWithRed:67.0/255 green:67.0/255 blue:67.0/255 alpha:0.95];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        if (isUserInterfaceIdiomPhone == FALSE) {
            if (isUserInterfaceIdiomPhone == FALSE) {
                [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}



#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1;
}




- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SwitchCell";
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
    }
    

    cell.textLabel.text = @"Male Voice";
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    UISwitch *voiceSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
    [voiceSwitch addTarget:self action:@selector(voiceSwitchAction) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = voiceSwitch;
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isMaleVoice"];
    [voiceSwitch setOn:b];
    
    return cell;
}

- (void) voiceSwitchAction {
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"isMaleVoice"];
    [[NSUserDefaults standardUserDefaults] setBool:!b forKey:@"isMaleVoice"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark - UICtonrol Action
- (void) backButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}


@end
