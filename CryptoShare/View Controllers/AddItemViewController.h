//
//  AddItemViewController.h
//  CryptoShare
//
//  Created by Kevin Nelson on 3/2/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddItemViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, assign) NSInteger existingItemIndex;
@property (strong, nonatomic) IBOutlet UITextField *titleText;
@property (strong, nonatomic) IBOutlet UITextField *descriptionText;

@end
