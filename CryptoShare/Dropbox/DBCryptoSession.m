//
//  DBCryptoSession.m
//  CryptoShare
//
//  Created by Kevin Nelson on 1/25/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "DBCryptoSession.h"

#import <CommonCrypto/CommonCrypto.h>

static DBCryptoSession *_cryptoSession;


@interface DBCryptoSession() {
    uint8_t _aesKey[32];
    uint8_t _hmacKey[32];
}

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

    DBFilesystem *sharedFilesystem = [DBFilesystem sharedFilesystem];
    if (sharedFilesystem == nil) {
        sharedFilesystem = [[DBFilesystem alloc] initWithAccount:[[DBAccountManager sharedManager] linkedAccount]];
        [DBFilesystem setSharedFilesystem:sharedFilesystem];
    }

    DBError *dbErr;
    DBFileInfo *packageInfo = [[DBFilesystem sharedFilesystem] fileInfoForPath:[self rootPath] error:&dbErr];
    
    if (packageInfo == nil || [dbErr code] == DBErrorNotFound) {
        [self createMainPackage];
    } else {
        [self loadAuthDictionary];
    }

    NSString *aesSalt = [_sessionAuthenticationMetadata objectForKey:@"na"];
    NSString *hmacSalt = [_sessionAuthenticationMetadata objectForKey:@"cl"];
    NSString *authId = [_sessionAuthenticationMetadata objectForKey:@"id"];
    NSString *data = [_sessionAuthenticationMetadata objectForKey:@"data"];

    if ([aesSalt isEqualToString:@""] ||
        [hmacSalt isEqualToString:@""] ||
        [authId isEqualToString:@""] ||
        [data isEqualToString:@""]) {
        self.state = DBCryptoSessionStateUnconfigured;
    } else {
        self.state = DBCryptoSessionStateLocked;
    }
}

- (void)setPassphrase:(NSString *)passphrase
{
    NSLog(@"Should set the passphrase to: %@", passphrase);

    NSData *passData = [passphrase dataUsingEncoding:NSUTF8StringEncoding];

    // generate passphrase UUID
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);

    // generate salt
    NSData *aesSalt = [self generateSalt256];
    NSData *hmacSalt = [self generateSalt256];

    // generate password check
    CCKeyDerivationPBKDF(kCCPBKDF2,
                         passData.bytes,
                         passData.length,
                         aesSalt.bytes,
                         aesSalt.length,
                         kCCPRFHmacAlgSHA256,
                         kDefaultNumberOfIterations,
                         _aesKey,
                         32);

    CCKeyDerivationPBKDF(kCCPBKDF2,
                         passData.bytes,
                         passData.length,
                         hmacSalt.bytes,
                         hmacSalt.length,
                         kCCPRFHmacAlgSHA256,
                         kDefaultNumberOfIterations,
                         _hmacKey,
                         32);

    NSData *payloadData = [kPassphraseCheckPayload dataUsingEncoding:NSUTF8StringEncoding];
    NSString *passphraseCheck = [self cryptThenMacThenEncode:payloadData cryptoKey:_aesKey macKey:_hmacKey];

    NSMutableDictionary *mutableAuthMetadata = [_sessionAuthenticationMetadata mutableCopy];
    NSString *aesSaltStr = [aesSalt base64EncodedStringWithOptions:0];
    NSString *macSaltStr = [hmacSalt base64EncodedStringWithOptions:0];
    [mutableAuthMetadata setObject:aesSaltStr forKey:@"na"];
    [mutableAuthMetadata setObject:macSaltStr forKey:@"cl"];
    [mutableAuthMetadata setObject:uuidString forKey:@"id"];
    [mutableAuthMetadata setObject:passphraseCheck forKey:@"data"];
    _sessionAuthenticationMetadata = [NSDictionary dictionaryWithDictionary:mutableAuthMetadata];
    [self writeAuthMetadata];

    // set state to locked
    self.state = DBCryptoSessionStateLocked;

    // auto-unlock with password
    [self unlockSession:passphrase];
}

- (BOOL)unlockSession:(NSString *)passphrase
{
    // -- generate key from passphrase --
    NSData *passData = [passphrase dataUsingEncoding:NSUTF8StringEncoding];

    // retrieve salts
    NSData *aesSalt = [[NSData alloc] initWithBase64EncodedString:[_sessionAuthenticationMetadata objectForKey:@"na"]
                                                          options:0];
    NSData *hmacSalt = [[NSData alloc] initWithBase64EncodedString:[_sessionAuthenticationMetadata objectForKey:@"cl"]
                                                           options:0];

    uint8_t computedAesKey[32];
    uint8_t computedMacKey[32];

    // generate password check
    CCKeyDerivationPBKDF(kCCPBKDF2,
                         passData.bytes,
                         passData.length,
                         aesSalt.bytes,
                         aesSalt.length,
                         kCCPRFHmacAlgSHA256,
                         kDefaultNumberOfIterations,
                         computedAesKey,
                         32);

    CCKeyDerivationPBKDF(kCCPBKDF2,
                         passData.bytes,
                         passData.length,
                         hmacSalt.bytes,
                         hmacSalt.length,
                         kCCPRFHmacAlgSHA256,
                         kDefaultNumberOfIterations,
                         computedMacKey,
                         32);

    // attempt to decrypt password check
    NSString *storedPasswordCheck = [_sessionAuthenticationMetadata objectForKey:@"data"];

    NSData *decoded = [self decodeThenMacThenDecrypt:storedPasswordCheck cryptoKey:computedAesKey macKey:computedMacKey];

    if (decoded == nil || ![decoded isEqualToData:[kPassphraseCheckPayload dataUsingEncoding:NSUTF8StringEncoding]]) {
        NSLog(@"invalid passphrase!");
        return NO;
    } else {
        NSLog(@"Correct password!");
    }

    // if successful, store key in RAM, set state to unlocked.
    memcpy(_aesKey, computedAesKey, kCCKeySizeAES256);
    memcpy(_hmacKey, computedMacKey, kCCKeySizeAES256);
    self.state = DBCryptoSessionStateUnlocked;

    // return whether successful or not
    return YES;
}


- (void)lockSession
{
    if (self.state == DBCryptoSessionStateUnlocked) {
        memset(_aesKey, 0, kCCKeySizeAES256);
        memset(_hmacKey, 0, kCCKeySizeAES256);

        // maybe also close dropbox files?

        self.state = DBCryptoSessionStateLocked;
    }

}

#pragma mark - Public Facing Encrypt/Decrypt
- (NSString *)encryptData:(NSData *)payload
{
    if (self.state != DBCryptoSessionStateUnlocked) {
        NSLog(@"You're trying to encrypt data without unlocking the datastore!");
        return nil;
    }

    NSString *ciphertext = [self cryptThenMacThenEncode:payload
                                              cryptoKey:_aesKey
                                                 macKey:_hmacKey];
    return ciphertext;
}

- (NSData *)decryptData:(NSString *)ciphertext
{
    if (self.state != DBCryptoSessionStateUnlocked) {
        NSLog(@"You're trying to decrypt data without unlocking the datastore!");
        return nil;
    }

    NSData *payload = [self decodeThenMacThenDecrypt:ciphertext
                                           cryptoKey:_aesKey
                                              macKey:_hmacKey];
    return payload;
}

#pragma mark - Crypto functions

- (NSData*)generateSalt256 {
    unsigned char salt[32];
    for (int i=0; i<32; i++) {
        salt[i] = (unsigned char)arc4random();
    }
    return [NSData dataWithBytes:salt length:32];
}

- (NSString *)cryptThenMacThenEncode:(NSData *)payload cryptoKey:(uint8_t *)cryptoKey macKey:(uint8_t *)macKey
{
    // generate IV
    NSData *iv = [self generateRandomBytes:kCCKeySizeAES256];

    size_t outLength;
    NSMutableData *cipherText = [NSMutableData dataWithLength:(payload.length + kCCBlockSizeAES128)];

    // run the encryption
    CCCryptorStatus result = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     cryptoKey,
                                     kCCKeySizeAES256,
                                     iv.bytes,
                                     payload.bytes,
                                     payload.length,
                                     cipherText.mutableBytes,
                                     cipherText.length,
                                     &outLength);

    if (result != kCCSuccess) {
        NSLog(@"Error encrypting text: %d", result);
        return nil;
    }

    cipherText.length = outLength;
    NSMutableData *ivCipher = [[NSMutableData alloc] init];
    [ivCipher appendBytes:iv.bytes length:iv.length];
    [ivCipher appendBytes:cipherText.bytes length:cipherText.length];

    // compute the HMAC of the iv+cipher
    NSMutableData *signature = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256,
           macKey,
           kCCKeySizeAES256,
           ivCipher.bytes,
           ivCipher.length,
           signature.mutableBytes);

    [ivCipher appendData:signature];

    NSString *output = [ivCipher base64EncodedStringWithOptions:0];
    return output;
}

- (NSData *)decodeThenMacThenDecrypt:(NSString *)ciphertext cryptoKey:(uint8_t *)cryptoKey macKey:(uint8_t *)macKey
{
    NSData *decoded = [[NSData alloc] initWithBase64EncodedString:ciphertext options:0];
    uint64_t signatureIndex = decoded.length - CC_SHA256_DIGEST_LENGTH;
    NSData *expectedSignature = [decoded subdataWithRange:NSMakeRange(signatureIndex, CC_SHA256_DIGEST_LENGTH)];
    NSData *signedData = [decoded subdataWithRange:NSMakeRange(0, signatureIndex)];

    NSMutableData *computedSignature = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256,
           macKey,
           kCCKeySizeAES256,
           signedData.bytes,
           signedData.length,
           computedSignature.mutableBytes);

    if (![expectedSignature isEqualToData:computedSignature]) {
        NSLog(@"Invalid Hmac signature, so must be a bad key!");
        return nil;
    }

    NSData *iv = [signedData subdataWithRange:NSMakeRange(0, kCCKeySizeAES256)];
    uint64_t cipherLength = signedData.length - kCCKeySizeAES256;
    NSData *cipherText = [signedData subdataWithRange:NSMakeRange(kCCKeySizeAES256, cipherLength)];

    size_t outLength;
    NSMutableData *clearText = [NSMutableData dataWithLength:(cipherText.length + kCCBlockSizeAES128)];

    // run the encryption
    CCCryptorStatus result = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     cryptoKey,
                                     kCCKeySizeAES256,
                                     iv.bytes,
                                     cipherText.bytes,
                                     cipherText.length,
                                     clearText.mutableBytes,
                                     clearText.length,
                                     &outLength);

    if (result != kCCSuccess) {
        NSLog(@"Error decrypting text: %d", result);
        return nil;
    }

    clearText.length = outLength;

    return clearText;
}

- (NSData *)generateRandomBytes:(size_t)length
{
    NSMutableData *data = [NSMutableData dataWithLength:length];

    int result = SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
    NSAssert(result == 0, @"Unable to generate random bytes: %d", errno);

    return data;
}


#pragma mark - Dropbox Files

- (DBPath *)rootPath
{
    DBPath *packagePath = [[DBPath root] childPath:@"CryptoShare.crypt"];
    return packagePath;
}

- (DBPath *)dataPath
{
    return [[self rootPath] childPath:@"data"];
}

- (NSData *)rawDataFromFileWithName:(NSString *)fileName
{
    DBError *dbErr;
    DBPath *filePath = [[self dataPath] childPath:fileName];
    DBFile *dataFile = [[DBFilesystem sharedFilesystem] openFile:filePath error:&dbErr];

    if (dataFile == nil || dbErr != nil) {
        NSLog(@"Error reading from file named %@", fileName);
        return nil;
    }

    NSData *fileData = [dataFile readData:&dbErr];
    return fileData;
}

- (DBFile *)getOrCreateDataFileWithName:(NSString *)fileName
{
    DBError *dbErr;
    DBPath *filePath = [[self dataPath] childPath:fileName];
    DBFileInfo *fileInfo = [[DBFilesystem sharedFilesystem] fileInfoForPath:filePath error:&dbErr];
    DBFile *theFile;
    if (fileInfo == nil && [dbErr code] == DBErrorNotFound) {
        theFile = [[DBFilesystem sharedFilesystem] createFile:filePath error:&dbErr];
    } else {
        theFile = [[DBFilesystem sharedFilesystem] openFile:filePath error:&dbErr];
    }

    return theFile;
}


- (void)createMainPackage
{
    _sessionAuthenticationMetadata = @{
                                       @"na": @"",
                                       @"cl": @"",
                                       @"iterations": [NSNumber numberWithLong:kDefaultNumberOfIterations],
                                       @"id": @"",
                                       @"data": @""
                                       };

    DBError *dbErr;
    DBPath *packagePath = [self rootPath];
    BOOL createdFolder = [[DBFilesystem sharedFilesystem] createFolder:packagePath error:&dbErr];

    if (dbErr != nil || !createdFolder) {
        NSLog(@"Error creating Package. %@", [dbErr localizedDescription]);
    }

    DBPath *dbAuthPath = [packagePath childPath:@"Auth.plist"];
    DBFile *dbAuthPlist = [[DBFilesystem sharedFilesystem] createFile:dbAuthPath error:&dbErr];
    if (dbErr != nil) {
        NSLog(@"Error creating auth plist file on Dropbox");
    }
    [dbAuthPlist close];

    DBPath *dbDataPath = [self dataPath];
    BOOL createdDataFolder = [[DBFilesystem sharedFilesystem] createFolder:dbDataPath error:&dbErr];
    if (dbErr != nil || !createdDataFolder) {
        NSLog(@"Error creating data folder in Package. %@", [dbErr localizedDescription]);
    }
    [self writeAuthMetadata];
}


- (void)resetSession
{
    // clears out any previously stored data.  obviously this is
    // dangerous if done with production data
    DBError *dbErr;
    BOOL successDelete = [[DBFilesystem sharedFilesystem] deletePath:[self rootPath] error:&dbErr];
}

- (void)writeAuthMetadata
{
    DBError *dbErr;
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *plistPath = [docsDir stringByAppendingPathComponent:@"Auth.plist"];
    BOOL wroteToLocalFS = [_sessionAuthenticationMetadata writeToFile:plistPath atomically:YES];
    if (!wroteToLocalFS) {
        NSLog(@"Error writing Plist to local FS");
    }

    DBPath *dbAuthPath = [[self rootPath] childPath:@"Auth.plist"];
    DBFile *dbAuthPlist = [[DBFilesystem sharedFilesystem] openFile:dbAuthPath error:&dbErr];
    if (dbErr != nil) {
        NSLog(@"Error creating auth plist file on Dropbox");
    }

    BOOL writeSuccess = [dbAuthPlist writeContentsOfFile:plistPath shouldSteal:YES error:&dbErr];
    if (dbErr != nil || !writeSuccess) {
        NSLog(@"Error copying plist file from local to dropbox");
    }
    [dbAuthPlist close];
}

- (void)loadAuthDictionary
{
    DBError *dbErr;
    DBPath *dbAuthPath = [[self rootPath] childPath:@"Auth.plist"];

    DBFile *authFile = [[DBFilesystem sharedFilesystem] openFile:dbAuthPath error:&dbErr];
    if (dbErr != nil) {
        NSLog(@"Error opening auth file.");
        [self createMainPackage];
        authFile = [[DBFilesystem sharedFilesystem] openFile:dbAuthPath error:&dbErr];
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

#pragma mark - Public-facing encrypted file access
- (NSData *)decryptedDataFromFile:(NSString *)fileName
{
    NSData *rawData = [self rawDataFromFileWithName:fileName];
    if (rawData == nil || [rawData length] == 0) {
        return nil;
    }
    NSString *dataString = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
    NSData *payload = [self decryptData:dataString];
    return payload;
}

- (void)writeData:(NSData *)unecryptedData toFile:(NSString *)fileName
{
    NSString *ciphertext = [self encryptData:unecryptedData];
    DBFile *destination = [self getOrCreateDataFileWithName:fileName];
    DBError *dbErr;
    [destination writeString:ciphertext error:&dbErr];
    [destination close];
}

@end
