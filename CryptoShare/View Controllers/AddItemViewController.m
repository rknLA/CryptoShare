//
//  AddItemViewController.m
//  CryptoShare
//
//  Created by Kevin Nelson on 3/2/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "AddItemViewController.h"

#import "DBCJsonStore.h"

@interface AddItemViewController() {
    NSMutableDictionary *_existingItem;
    NSString *_existingItemKey;
}

@end

@implementation AddItemViewController

@synthesize existingItemIndex = _existingItemIndex;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _existingItemIndex = -1;
    }
    return self;
}

- (void)viewDidLoad
{
    if (_existingItemIndex >= 0) {
        [self setExistingItemIndex:_existingItemIndex];
    }
    [self.titleText becomeFirstResponder];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveItem)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)setExistingItemIndex:(NSInteger)existingItemIndex
{
    _existingItemIndex = existingItemIndex;
    if (self.titleText != nil && self.descriptionText != nil) {
        DBCJsonStore *store = [DBCJsonStore sharedStore];
        _existingItemKey = [[store keys] objectAtIndex:_existingItemIndex];
        _existingItem = [[store objectForKey:_existingItemKey] mutableCopy];
        self.titleText.text = [_existingItem objectForKey:@"title"];
        self.descriptionText.text = [_existingItem objectForKey:@"description"];
    }
}

- (void)saveItem
{
    NSLog(@"Creating item");

    DBCJsonStore *store = [DBCJsonStore sharedStore];

    NSDictionary *item;
    NSString *destinationKey;

    if (_existingItemIndex >= 0 && _existingItem != nil && _existingItemKey != nil) {
        [_existingItem setObject:[self.titleText text] forKey:@"title"];
        [_existingItem setObject:[self.descriptionText text] forKey:@"description"];
        item = [NSDictionary dictionaryWithDictionary:_existingItem];
        destinationKey = _existingItemKey;
    } else {
        item = @{
                 @"title": [self.titleText text],
                 @"description": [self.descriptionText text]
                 };
        destinationKey = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    }

    [store setObject:item forKey:destinationKey];
    [store save];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"did end editing");
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.titleText) {
        [self.titleText resignFirstResponder];
        [self.descriptionText becomeFirstResponder];
    } else if (textField == self.descriptionText) {
        [self.descriptionText resignFirstResponder];
    }
    return YES;
}

@end
