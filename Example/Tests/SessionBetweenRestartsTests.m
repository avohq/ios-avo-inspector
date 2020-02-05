//
//  SessionBetweenRestartsTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 05.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoSessionTracker.h>
#import <OCMock/OCMock.h>

@interface AvoSessionTracker ()

- (void) callSessionStarted;

@end

SpecBegin(SessionBetweenRestartsSpecs)
describe(@"Sessions between restarts", ^{
    
    beforeAll(^{
        [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970] forKey:@"AvoStateOfTrackingSession"];
    });

    it(@"AvoSessionTracker reads session timestamp from disk when created", ^{
       AvoSessionTracker * sut = [AvoSessionTracker new];
       
       id partialMock = OCMPartialMock(sut);
       
       __block int sessionStartCallCount = 0;
       OCMStub([partialMock callSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
       [partialMock schemaTracked:@([[NSDate date] timeIntervalSince1970])];
       
       expect(sessionStartCallCount).equal(0);
    });
});
SpecEnd

