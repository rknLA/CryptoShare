//
//  DBCJsonStore.m
//  CryptoShare
//
//  Created by Kevin Nelson on 3/2/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import "DBCJsonStore.h"

static DBCJsonStore *_sharedJsonStore;

@interface DBCJsonStore() {
    DBCryptoSession *_session;

    NSString *_fileName;

    NSMutableDictionary *_localFileCache;
}

@end

@implementation DBCJsonStore

+ (DBCJsonStore *)sharedStore
{
    return _sharedJsonStore;
}

+ (void)setSharedStore:(DBCJsonStore *)jsonStore
{
    _sharedJsonStore = jsonStore;
}


- (id)initWithName:(NSString *)name andSession:(DBCryptoSession *)session
{
    self = [super init];
    if (self) {
        _fileName = [name copy];
        _session = session;
        _localFileCache = [NSMutableDictionary dictionaryWithCapacity:20];
    }
    return self;
}

- (void)refreshLocalCache
{
    NSData *dbFileData = [_session decryptedDataFromFile:_fileName];
    NSError *jsonErr;
    if (dbFileData != nil) {
        NSDictionary *fileDict = [NSJSONSerialization JSONObjectWithData:dbFileData
                                                                 options:0
                                                                   error:&jsonErr];
        _localFileCache = [fileDict mutableCopy];
    }
}

- (void)save
{
    NSError *jsonErr;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_localFileCache
                                                       options:0
                                                         error:&jsonErr];
    [_session writeData:jsonData toFile:_fileName];
}


- (NSArray *)keys
{
    [self refreshLocalCache];
    return [_localFileCache allKeys];
}

- (id)objectForKey:(id<NSCopying>)key
{
    [self refreshLocalCache];
    return [_localFileCache objectForKey:key];
}

- (void)setObject:(id)jsonSerializableObject forKey:(id<NSCopying>)key
{
    [_localFileCache setObject:jsonSerializableObject forKey:key];
}

@end
