//
//  DBCJsonStore.h
//  CryptoShare
//
//  Created by Kevin Nelson on 3/2/15.
//  Copyright (c) 2015 rknLA. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBCryptoSession.h"

@interface DBCJsonStore : NSObject

+ (DBCJsonStore *)sharedStore;
+ (void)setSharedStore:(DBCJsonStore *)jsonStore;

- (id)initWithName:(NSString *)name andSession:(DBCryptoSession *)session;

- (NSArray *)keys;

- (id)objectForKey:(id<NSCopying>)key;

- (void)setObject:(id)jsonSerializableObject forKey:(id<NSCopying>)key;

- (void)save;


@end
