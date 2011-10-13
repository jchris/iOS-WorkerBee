//
//  DocumentOperationsTest.m
//  Worker Bee
//
//  Created by Arvind on 10/6/11.
//  Copyright 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchTest.h"

@interface DocumentOperationsTest : BeeCouchTest
- (void) push;
@end


#define kDocumentBatchSize 10 //TEMP 100
#define kPushURL @"http://sidius.iriscouch.com/test"


static NSString* createUUID() {
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *guid = NSMakeCollectable(CFUUIDCreateString(nil, uuid));
    CFRelease(uuid);
    return [guid autorelease];
}


@implementation DocumentOperationsTest

{
    int _sequence;
    CouchReplication* _repl;
}

- (void) setUp {
    [super setUp];
    _sequence = 0;
    self.heartbeatInterval = 10;
}


- (void)dealloc {
    [_repl removeObserver: self forKeyPath: @"running"];
    [_repl release];
    [super dealloc];
}


- (void) heartbeat {
    if (self.suspended)
        return;
    
    [self logFormat: @"Adding docs %i--%i ...",
                     _sequence+1, _sequence+kDocumentBatchSize];
    NSMutableArray *ids = [NSMutableArray array];
    __block int nCompleted = 0;
    for (int i = 0; i < kDocumentBatchSize; i++) {
        ++_sequence;
        NSString* dateStr = [RESTBody JSONObjectWithDate: [NSDate date]];
        NSString *docId = [NSString stringWithFormat:@"%@-%@", dateStr, createUUID()];
        //NSLog(@"added %i", _sequence);
        [ids addObject:docId];
        
        NSDictionary* props = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInt: _sequence], @"sequence",
                               dateStr, @"date", nil];
        CouchDocument* doc = [self.database documentWithID:docId];
        RESTOperation* op = [doc putProperties: props];
        [op onCompletion: ^{
            if (op.error) {
                [self logFormat: @"!!! Failed to create doc %@", props];
                self.error = op.error;
            } else {
                if (++nCompleted == kDocumentBatchSize) {
                    [self logFormat: @"All %d docs created, now pushing...", nCompleted];
                    [self push];
                }
            }
        }];
    }
}


- (void) push {
    if (_repl.running) {
        [self logMessage: @"Not starting push (still running)"];
        return;
    }
    
    [self logMessage: @"Starting push..."];
    if (!_repl) {
        _repl = [[self.database pushToDatabaseAtURL:[NSURL URLWithString:kPushURL] options:0] 
                     retain];
        [_repl addObserver: self forKeyPath: @"running" options: 0 context: NULL];
    }
    [_repl start];
}


- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context
{
    if (object == _repl) {
        if (!_repl.running) {
            if (_repl.error) {
                [self logMessage: @"Replication failed!"];
                self.error = _repl.error;
            } else {
                [self logMessage: @"Replication finished"];
            }
        }
    }
}

@end
