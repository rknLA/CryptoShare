//
//  CreatePasswordViewController.h
//  CryptoShare
//
//  Created by Kevin Nelson on 1/25/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreatePasswordViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *passwordEntry;

- (void)passwordEntryCompleted:(NSString *)passphrase;

@end
