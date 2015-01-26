//
//  EnterPasswordViewController.m
//  CryptoShare
//
//  Created by Kevin Nelson on 1/26/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "EnterPasswordViewController.h"

#import "DBCryptoSession.h"

@interface EnterPasswordViewController ()

@end

@implementation EnterPasswordViewController

- (void)passwordEntryCompleted:(NSString *)passphrase
{
    NSLog(@"Done entering password");
    [[DBCryptoSession currentSession] unlockSession:passphrase];
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
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
