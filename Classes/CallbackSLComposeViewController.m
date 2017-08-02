//
//  CallbackSLComposeViewController.m
//  FlashCardCreator
//
//  Created by internetics on 2/8/17.
//  Copyright © 2017 Internetics. All rights reserved.
//

#import "CallbackSLComposeViewController.h"

@interface CallbackSLComposeViewController ()

@end

@implementation CallbackSLComposeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_SHARE_ACTIONSHEET_NOTIFICATION object:nil userInfo:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
