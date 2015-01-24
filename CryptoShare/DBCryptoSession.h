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


@interface DBCryptoSession : NSObject

+ (DBCryptoSession *)beginSession;
+ (DBCryptoSession *)currentSession;
+ (void)endSession;

@property (nonatomic, readonly) DBCryptoSessionState state;

@end
