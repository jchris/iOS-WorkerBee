//
//  ContinuousReplicationTest.m
//  Worker Bee
//
//  Created by Arvind on 10/13/11.
//  Copyright 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchTest.h"

#define kPullURL @"http://farshid:farshid@single.couchbase.net/_utils/database.html?cbstats"

/*
// FIX: This test doesn't work as written. I'm not sure what it's trying to do; but a tight
// do/while loop that spawns replications is going to be really bad for the server, so I don't
// think that's what was intended. --Jens

@interface ContinuousReplicationTest : BeeCouchTest

@end


@implementation ContinuousReplicationTest

{
    int _sequence;
}



- (void) heartbeat {
    if (self.suspended)
        return;
    double teststart = CFAbsoluteTimeGetCurrent();
    double wait = 600;
    do {
        CouchReplication *op;
        op = [self.database pullFromDatabaseAtURL:[NSURL URLWithString:kPullURL]
                                          options:kCouchReplicationContinuous];
    } while ([self.database getDocumentCount] < 10000);
    
    if (CFAbsoluteTimeGetCurrent() - teststart >= wait){    
        RESTOperation *com;
        com = [self.database compact];
    }
}



- (void) setUp {
    [super setUp];
    _sequence = 0;
    self.heartbeatInterval = 10;
}

@end

*/
