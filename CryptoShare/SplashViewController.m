//
//  ViewController.m
//  CryptoShare
//
//  Created by Kevin Nelson on 1/24/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "SplashViewController.h"

@interface SplashViewController ()

@end

@implementation SplashViewController

@synthesize connectButton = _connectButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectTapped:(id)sender
{
    NSLog(@"Connect tapped");
}

@end
