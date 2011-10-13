//
//  NullTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeTest.h"

@interface CountTest : BeeTest

@property int count;
@property int limit;

@end


@implementation CountTest

@synthesize count = _count, limit = _limit;

- (void) heartbeat {
    [self logFormat: @"Hi there! %i", ++_count, 45];
    if (_count % 5 == 0)
        self.status = [NSString stringWithFormat: @"Reached %i", _count];
    if (_limit > 0 && _count >= _limit) {
        self.errorMessage = @"O noes, count overflowed!!!";
        self.running = NO;
    }
}

- (void) setUp {
    [super setUp];
    _count = 0;
    self.heartbeatInterval = 1.0;
}

@end


@interface ShortCountTest : CountTest
@end


@implementation ShortCountTest

- (id)init {
    self = [super init];
    if (self) {
        self.limit = 10;
    }
    return self;
}

@end