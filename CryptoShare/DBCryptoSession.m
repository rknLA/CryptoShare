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
@property (nonatomic, strong) NSDictionary *sessionAuthenticationMetadata;

@end


@implementation DBCryptoSession

@synthesize state = _state;
@synthesize sessionAuthenticationMetadata = _sessionAuthenticationMetadata;

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
    // - look in dropbox folder to see if there's any files or data at all (if not, and no session before, we're completely green)
    // - load auth metadata required to "unlock" the crypto safe
    // - set the session state

    DBPath *packagePath = [[DBPath root] childPath:@"CryptoShare.crypt"];
    DBError *dbErr;
    DBFileInfo *packageInfo = [[DBFilesystem sharedFilesystem] fileInfoForPath:packagePath error:&dbErr];
    
    if (packageInfo == nil && [dbErr code] == DBErrorNotFound) {
        [self createMainPackage];
    } else {
        [self loadAuthDictionary];
    }

    NSString *salt = [_sessionAuthenticationMetadata objectForKey:@"salt"];
    NSString *authId = [_sessionAuthenticationMetadata objectForKey:@"id"];
    NSString *data = [_sessionAuthenticationMetadata objectForKey:@"data"];

    if ([salt isEqualToString:@""] ||
        [authId isEqualToString:@""] |
        [data isEqualToString:@""]) {
        self.state = DBCryptoSessionStateUnconfigured;
    } else {
        self.state = DBCryptoSessionStateLocked;
    }
}

#pragma mark - Dropbox Files

- (void)createMainPackage
{
    _sessionAuthenticationMetadata = @{
                                       @"salt": @"",
                                       @"iterations": @100000,
                                       @"id": @"",
                                       @"data": @""
                                       };

    DBError *dbErr;
    DBPath *packagePath = [[DBPath root] childPath:@"CryptoShare.crypt"];
    [[DBFilesystem sharedFilesystem] createFolder:packagePath error:&dbErr];

    if (dbErr != nil) {
        NSLog(@"Error creating Package. %@", [dbErr localizedDescription]);
    }

    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Auth" ofType:@"plist"];
    [_sessionAuthenticationMetadata writeToFile:plistPath atomically:YES];

    DBPath *dbAuthPath = [packagePath childPath:@"Auth.plist"];
    DBFile *dbAuthPlist = [[DBFilesystem sharedFilesystem] openFile:dbAuthPath error:&dbErr];
    if (dbErr != nil) {
        NSLog(@"Error opening auth plist file on Dropbox");
    }

    [dbAuthPlist writeContentsOfFile:plistPath shouldSteal:YES error:&dbErr];
    if (dbErr != nil) {
        NSLog(@"Error copying plist file from local to dropbox");
    }
    [dbAuthPlist close];
}

- (void)loadAuthDictionary
{
    DBError *dbErr;
    DBPath *packagePath = [[DBPath root] childPath:@"CryptoShare.crypt"];
    DBPath *dbAuthPath = [packagePath childPath:@"Auth.plist"];

    DBFile *authFile = [[DBFilesystem sharedFilesystem] openFile:dbAuthPath error:&dbErr];
    if (dbErr != nil) {
        NSLog(@"Error opening auth file.");
    }

    NSData *authData = [authFile readData:&dbErr];
    if (dbErr != nil) {
        NSLog(@"Error reading data from Dropbox");
    }

    CFPropertyListRef plist = CFPropertyListCreateWithData(kCFAllocatorDefault,
                                                           (__bridge CFDataRef)authData,
                                                           kCFPropertyListImmutable,
                                                           nil,
                                                           nil);
    if (![(__bridge id)plist isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Error deserializing plist");
    }
    _sessionAuthenticationMetadata = (__bridge NSDictionary *)plist;
}

@end
