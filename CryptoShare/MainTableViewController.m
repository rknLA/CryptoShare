//
//  MainTableViewController.m
//  CryptoShare
//
//  Created by Kevin Nelson on 1/24/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "MainTableViewController.h"

#import <Dropbox/Dropbox.h>

@implementation MainTableViewController

- (void)viewDidAppear:(BOOL)animated
{
    if ([[DBAccountManager sharedManager] linkedAccount] == nil) {
        UIStoryboard *theStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *connectDropboxVC = [theStoryboard instantiateViewControllerWithIdentifier:@"connectDropbox"];

        [self presentViewController:connectDropboxVC animated:YES completion:nil];
    }
}

@end
