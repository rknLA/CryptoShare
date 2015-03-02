//
//  MainTableViewController.m
//  CryptoShare
//
//  Created by Kevin Nelson on 1/24/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "MainTableViewController.h"

#import <Dropbox/Dropbox.h>

#import "AddItemViewController.h"
#import "DBCryptoSession.h"
#import "DBCJsonStore.h"

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
    UIStoryboard *theStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([[DBAccountManager sharedManager] linkedAccount] == nil) {
        UIViewController *connectDropboxVC = [theStoryboard instantiateViewControllerWithIdentifier:@"connectDropbox"];

        [self presentViewController:connectDropboxVC animated:YES completion:nil];
        return;
    }

    DBCryptoSession *cryptoSession = [DBCryptoSession currentSession];
    if (cryptoSession == nil) {
        cryptoSession = [DBCryptoSession beginSession];
    }

    if (cryptoSession.state == DBCryptoSessionStateUnconfigured) {
        UIViewController *setPasswordVC = [theStoryboard instantiateViewControllerWithIdentifier:@"createPassword"];
        [self presentViewController:setPasswordVC animated:YES completion:nil];
    } else if (cryptoSession.state == DBCryptoSessionStateLocked) {
        UIViewController *enterPasswordVC = [theStoryboard instantiateViewControllerWithIdentifier:@"enterPassword"];
        [self presentViewController:enterPasswordVC animated:YES completion:nil];
    } else {
        DBCJsonStore *jsonStore = [DBCJsonStore sharedStore];
        if (jsonStore == nil) {
            jsonStore = [[DBCJsonStore alloc] initWithName:@"CryptoSync" andSession:cryptoSession];
            [DBCJsonStore setSharedStore:jsonStore];
        }
        NSLog(@"Should do json store stuff");
        [self.tableView reloadData];
    }
}

#pragma mark - Table View
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[DBCJsonStore sharedStore] keys] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"CryptoShareIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }

    DBCJsonStore *sharedStore = [DBCJsonStore sharedStore];
    NSString *itemKey = [[sharedStore keys] objectAtIndex:indexPath.row];
    if (itemKey != nil) {
        NSDictionary *data = [sharedStore objectForKey:itemKey];
        if (data != nil) {
            cell.textLabel.text = [data objectForKey:@"title"];
            cell.detailTextLabel.text = [data objectForKey:@"description"];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected row at %lu", (long)indexPath.row);

    UIStoryboard *theStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    AddItemViewController *addItemVC = (AddItemViewController *)[theStoryboard instantiateViewControllerWithIdentifier:@"addItemVC"];
    addItemVC.existingItemIndex = indexPath.row;
    [self.navigationController pushViewController:addItemVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UI Handlers

- (void)addEncryptedItem
{
    NSLog(@"Should add item");

    UIStoryboard *theStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *addItemVC = [theStoryboard instantiateViewControllerWithIdentifier:@"addItemVC"];
    [self.navigationController pushViewController:addItemVC animated:YES];
}

@end
