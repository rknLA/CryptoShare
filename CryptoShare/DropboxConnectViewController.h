//
//  ViewController.h
//  CryptoShare
//
//  Created by Kevin Nelson on 1/24/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DropboxConnectViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIButton *connectButton;

- (IBAction)connectTapped:(id)sender;

@end

