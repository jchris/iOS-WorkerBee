//
//  SimpleReplicationTest.m
//  Worker Bee
//
//  Created by Arvind on 10/13/11.
//  Copyright 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchTest.h"

#define kPullURL @"http://ec2-50-16-117-7.compute-1.amazonaws.com:5984/ios-tests"


@interface SimpleReplicationTest : BeeCouchTest
@end


@implementation SimpleReplicationTest

- (void) heartbeat {
    if (self.suspended)
        return;
    
    // FIX: This isn't very useful to put in the heartbeat method. It creates a persistent
    // replication, so only the first call to it has any effect.
    // This test also neither logs anything nor finishes, so it doesn't produce any metrics. --Jens
    CouchPersistentReplication* rep;
    rep = [self.database replicationFromDatabaseAtURL:[NSURL URLWithString:kPullURL]];
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 10;
}

@end
