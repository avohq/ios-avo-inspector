//
//  SessionBetweenRestartsTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 05.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoInspector/AvoSessionTracker.h>
#import <AvoInspector/AvoNetworkCallsHandler.h>
#import <OCMock/OCMock.h>

@interface AvoSessionTracker ()

@property (nonatomic) NSTimeInterval lastSessionTimestamp;

- (void) callSessionStarted;

@end

SpecBegin(SessionBetweenRestarts)
describe(@"Sessions between restarts", ^{

    it(@"AvoSessionTracker reads session timestamp from disk when created", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970] forKey:[AvoSessionTracker timestampCacheKey]];
        AvoSessionTracker * sut = [[AvoSessionTracker alloc] initWithBatcher:mockAvoBatcher];
       
        __block int sessionStartCallCount = 0;
        OCMStub([mockAvoBatcher handleSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
        [sut startOrProlongSession:@([[NSDate date] timeIntervalSince1970])];
       
        expect(sessionStartCallCount).equal(0);
    });
         
     it(@"AvoSessionTracker reads session id from disk when created", ^{
         id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
         [[NSUserDefaults standardUserDefaults] setValue:@"testSessionId" forKey:[AvoSessionTracker idCacheKey]];
         AvoSessionTracker.sessionId = @"";
         AvoSessionTracker * sut = [[AvoSessionTracker alloc] initWithBatcher:mockAvoBatcher];
        
         expect(AvoSessionTracker.sessionId).equal(@"testSessionId");
     });
         
     it(@"AvoSessionTracker writes session timestamp to disk when session is updated", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[AvoSessionTracker timestampCacheKey]];
        AvoSessionTracker * sut = [[AvoSessionTracker alloc] initWithBatcher:mockAvoBatcher];
        
        expect(sut.lastSessionTimestamp).equal(INT_MIN);
    
        double timestamp = [[NSDate date] timeIntervalSince1970];
        [sut startOrProlongSession:@(timestamp)];
    
        expect([[NSUserDefaults standardUserDefaults] doubleForKey:[AvoSessionTracker timestampCacheKey]]).equal(timestamp);
     });
});
SpecEnd

