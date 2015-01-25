//
//  ViewController.m
//  CryptoShare
//
//  Created by Kevin Nelson on 1/24/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "DropboxConnectViewController.h"

#import <Dropbox/Dropbox.h>

@interface DropboxConnectViewController ()

@end

@implementation DropboxConnectViewController

@synthesize connectButton = _connectButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([[DBAccountManager sharedManager] linkedAccount] != nil) {
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectTapped:(id)sender
{
    NSLog(@"Connect tapped");
    [[DBAccountManager sharedManager] linkFromController:self];
}

@end
