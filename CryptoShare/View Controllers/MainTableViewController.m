//
//  MainTableViewController.m
//  CryptoShare
//
//  Created by Kevin Nelson on 1/24/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "MainTableViewController.h"

#import <Dropbox/Dropbox.h>
#import "DBCryptoSession.h"

@implementation MainTableViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [self.navigationItem setTitle:@"CryptoShare"];

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addEncryptedItem)];
    self.navigationItem.rightBarButtonItem = addButton;

}

- (void)viewDidAppear:(BOOL)animated
{
    if ([[DBAccountManager sharedManager] linkedAccount] == nil) {
        UIStoryboard *theStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *connectDropboxVC = [theStoryboard instantiateViewControllerWithIdentifier:@"connectDropbox"];

        [self presentViewController:connectDropboxVC animated:YES completion:nil];
        return;
    }

    DBCryptoSession *cryptoSession = [DBCryptoSession beginSession];

    if (cryptoSession.state == DBCryptoSessionStateUnconfigured) {
        
    }
}



#pragma mark - UI Handlers

- (void)addEncryptedItem
{
    NSLog(@"Should add item");
    
}

@end
