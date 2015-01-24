//
//  DBCryptoSession.m
//  CryptoShare
//
//  Created by Kevin Nelson on 1/25/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "DBCryptoSession.h"

static DBCryptoSession *_cryptoSession;


@interface DBCryptoSession()

@property (nonatomic, assign) DBCryptoSessionState state;

@end


@implementation DBCryptoSession

@synthesize state = _state;

#pragma mark - Singleton lifecycle
+ (DBCryptoSession *)beginSession
{
    if (_cryptoSession != nil) {
        NSLog(@"Error beginning session! A session is already in progress.");
        return nil;
    }
    _cryptoSession = [[DBCryptoSession alloc] init];
    [_cryptoSession bootstrap];
    return _cryptoSession;
}

+ (DBCryptoSession *)currentSession
{
    return _cryptoSession;
}

+ (void)endSession
{
    if (_cryptoSession == nil) {
        NSLog(@"Error ending session! No session appears to be in progress.");
        return;
    }
    _cryptoSession = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.state = DBCryptoSessionStateUninitialized;
    }
    return self;
}


#pragma mark - Session Setup
- (void)bootstrap
{
    self.state = DBCryptoSessionStateBootstrapping;

    //boostrap process:
    // - look in keychain to see if there's ever been a session before (if not, note that we might be starting completely fresh)
    // - look in dropbox folder to see if there's any files or data at all (if not, and no session before, we're completely green)
    // - set the session state
}

@end
