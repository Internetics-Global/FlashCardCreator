//
//  FirebaseSignInViewController.m
//  FlashCardCreator
//
//  Created by internetics on 9/1/17.
//  Copyright © 2017 Internetics. All rights reserved.
//

#import "FirebaseSignInViewController.h"

@import Firebase;

@interface FirebaseSignInViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;


@end

@implementation FirebaseSignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)didTapSignIn:(id)sender {
    
    NSString *email = _emailTextField.text;
    NSString *password = _passwordTextField.text;
    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                             if (error) {
                                 NSLog(@"%@", error.localizedDescription);
                                 return;
                             }
                             [self signedIn:user];
                         }];
}


- (IBAction)didTapSignUp:(id)sender {
    
    NSString *email = _emailTextField.text;
    NSString *password = _passwordTextField.text;
    [[FIRAuth auth] createUserWithEmail:email
                               password:password
                             completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                                 if (error) {
                                     NSLog(@"%@", error.localizedDescription);
                                     return;
                                 }
                                 [self setDisplayName:user];
                             }];
}


- (IBAction)didRequestPasswordReset:(id)sender {
    
    UIAlertController *prompt =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"Email:"
                                 preferredStyle:UIAlertControllerStyleAlert];
    __weak UIAlertController *weakPrompt = prompt;
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * _Nonnull action) {
                                   UIAlertController *strongPrompt = weakPrompt;
                                   NSString *userInput = strongPrompt.textFields[0].text;
                                   if (!userInput.length)
                                   {
                                       return;
                                   }
                                   [[FIRAuth auth] sendPasswordResetWithEmail:userInput
                                                                   completion:^(NSError * _Nullable error) {
                                                                       if (error) {
                                                                           NSLog(@"%@", error.localizedDescription);
                                                                           return;
                                                                       }
                                                                   }];
                                   
                               }];
    [prompt addTextFieldWithConfigurationHandler:nil];
    [prompt addAction:okAction];
    [self presentViewController:prompt animated:YES completion:nil];
}

- (void)signedIn:(FIRUser *)user {
    
}

- (void)setDisplayName:(FIRUser *)user {
}

@end
