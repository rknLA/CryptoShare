//
//  EnterPasswordViewController.m
//  CryptoShare
//
//  Created by Kevin Nelson on 1/26/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "EnterPasswordViewController.h"

#import "DBCryptoSession.h"
#import "DBCJsonStore.h"

@interface EnterPasswordViewController ()

@end

@implementation EnterPasswordViewController

- (void)passwordEntryCompleted:(NSString *)passphrase
{
    NSLog(@"Done entering password");
    DBCryptoSession *session = [DBCryptoSession currentSession];
    if ([session unlockSession:passphrase]) {
        DBCJsonStore *jsonStore = [DBCJsonStore sharedStore];
        if (jsonStore == nil) {
            jsonStore = [[DBCJsonStore alloc] initWithName:@"CryptoSync" andSession:session];
            [DBCJsonStore setSharedStore:jsonStore];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)resetPasswordTapped:(id)sender
{
    [[DBCryptoSession currentSession] resetSession];
    UIStoryboard *theStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *setPasswordVC = [theStoryboard instantiateViewControllerWithIdentifier:@"createPassword"];
    [self presentViewController:setPasswordVC animated:YES completion:^{

    }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"did end editing");
    if (textField == self.passwordEntry) {
        [self passwordEntryCompleted:[textField text]];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"Should return");
    [textField resignFirstResponder];
    return YES;
}


@end
