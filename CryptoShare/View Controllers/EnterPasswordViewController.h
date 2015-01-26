//
//  EnterPasswordViewController.h
//  CryptoShare
//
//  Created by Kevin Nelson on 1/26/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EnterPasswordViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *passwordEntry;

@end
