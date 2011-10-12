//
//  SavedTestRun.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/10/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "SavedTestRun.h"
#import "AppDelegate.h"
#import "BeeTest.h"
#import "UIDevice-Hardware.h"


@implementation SavedTestRun


CouchDatabase* sDatabase;
NSString* sVersion;
NSUInteger sCount;


+ (NSURL*) serverURL {
    return ((AppDelegate*)[[UIApplication sharedApplication] delegate]).serverURL;
}

+ (CouchDatabase*) database {
    if (!sDatabase) {
        sDatabase = [[CouchDatabase databaseNamed: @"workerbee-tests"
                                  onServerWithURL: [self serverURL]] retain];
        NSError* error;
        if (![sDatabase ensureCreated: &error])
            NSAssert(NO, @"Error creating db: %@", error);   // TODO: Real alert
        sCount = [sDatabase getDocumentCount];
        sVersion = [[sDatabase.server getVersion: NULL] copy];
        
    }
    return sDatabase;
}

@dynamic device, serverVersion, testName, startTime, endTime, duration,
         stoppedByUser, status, error, log;

- (void) recordTest: (BeeTest*)test {
    UIDevice* deviceInfo = [UIDevice currentDevice];
    NSMutableDictionary* deviceDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                   deviceInfo.name, @"name",
                   deviceInfo.platformString, @"hardware",
                   deviceInfo.uniqueIdentifier, @"UDID",
                   [NSArray arrayWithObjects: @"iOS", deviceInfo.systemVersion, nil], @"OS",
                   [NSNumber numberWithUnsignedInteger: deviceInfo.cpuFrequency], @"CPUSpeed",
                   [NSNumber numberWithUnsignedInteger: deviceInfo.busFrequency], @"BusSpeed",
                   [NSNumber numberWithUnsignedInteger: deviceInfo.totalMemory], @"RAM",
                   [NSNumber numberWithUnsignedInteger: deviceInfo.userMemory], @"userRAM",
                   deviceInfo.totalDiskSpace, @"diskSize",
                   deviceInfo.freeDiskSpace, @"diskFree",
                   nil];
    
    float batteryLevel = deviceInfo.batteryLevel;
    if (batteryLevel >= 0)
        [deviceDict setObject: [NSNumber numberWithFloat: batteryLevel]
                       forKey: @"batteryLevel"];
    UIDeviceBatteryState state = deviceInfo.batteryState;
    if (state > UIDeviceBatteryStateUnknown && state <= UIDeviceBatteryStateFull) {
        static NSString* kBatteryStates[4] = {nil, @"unplugged", @"charging", @"full"};
        [deviceDict setObject: kBatteryStates[state] forKey: @"batteryState"];
    }
    
    self.device = deviceDict;
    self.serverVersion = sVersion;
    self.testName = [[test class] testName];
    self.startTime = test.startTime;
    self.endTime = test.endTime;
    self.duration = [test.endTime timeIntervalSinceDate: test.startTime];
    if (test.stoppedByUser)
        self.stoppedByUser = YES;
    self.status = test.status;
    self.error = test.errorMessage;
    self.log = [test.messages componentsJoinedByString: @"\n"];
}

+ (SavedTestRun*) forTest: (BeeTest*)test {
    SavedTestRun* instance = [[self alloc] initWithNewDocumentInDatabase: [self database]];
    [instance recordTest: test];
    ++sCount;
    return [instance autorelease];
}

+ (NSString*) serverVersion {
    return sVersion;
}

+ (NSUInteger) savedTestCount {
    if (!sDatabase && [self serverURL])
        [self database];    // trigger connection
    return sCount;
}

+ (BOOL) uploadAllTo: (NSURL*)upstreamURL error: (NSError**)outError {
    CouchReplication* repl = [[self database] pushToDatabaseAtURL: upstreamURL options: 0];
    while (repl.running) {
        NSLog(@"Waiting for replication to finish...");
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                 beforeDate: [NSDate distantFuture]];
    }
    
    if (outError) *outError = repl.error;
    NSLog(@"...Replication finished. Error = %@", repl.error);
    if (repl.error)
        return NO;
    return [self forgetAll: outError];
}

+ (BOOL) forgetAll: (NSError**)outError {
    // Delete the entire database because we don't need to keep the test
    // results around anymore. (Just deleting the documents would leave tombstones behind,
    // which would propagate to the server on the next push and delete them there too. Bad.)
    RESTOperation* op = [[self database] DELETE];
    if (![op wait]) {
        if (outError) *outError = op.error;
        return NO;
    }
    [sDatabase release];
    sDatabase = nil;
    sCount = 0;
    return YES;
}

@end
