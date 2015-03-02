//
//  DBCryptoSession.h
//  CryptoShare
//
//  Created by Kevin Nelson on 1/25/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Dropbox/Dropbox.h>

typedef enum {
    DBCryptoSessionStateUninitialized = 0,
    DBCryptoSessionStateBootstrapping,
    DBCryptoSessionStateUnconfigured,
    DBCryptoSessionStateLocked,
    DBCryptoSessionStateUnlocked
} DBCryptoSessionState;

static const long kDefaultNumberOfIterations = 100000;
static NSString const * kPassphraseCheckPayload = @"I am just a string to check if the passphrase was decoded.";

@interface DBCryptoSession : NSObject

+ (DBCryptoSession *)beginSession;
+ (DBCryptoSession *)currentSession;
+ (void)endSession;

@property (nonatomic, readonly) DBCryptoSessionState state;

- (void)setPassphrase:(NSString *)passphrase;
- (BOOL)unlockSession:(NSString *)passphrase;
- (void)lockSession;

- (void)resetSession;

@end
