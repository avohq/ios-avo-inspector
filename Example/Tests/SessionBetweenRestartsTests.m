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

@property (nonatomic) NSTimeInterval lastSessionTimestamp;

- (void) callSessionStarted;

@end

SpecBegin(SessionBetweenRestarts)
describe(@"Sessions between restarts", ^{

    it(@"AvoSessionTracker reads session timestamp from disk when created", ^{
        [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970] forKey:[AvoSessionTracker cacheKey]];
       AvoSessionTracker * sut = [AvoSessionTracker new];
       
       id partialMock = OCMPartialMock(sut);
       
       __block int sessionStartCallCount = 0;
       OCMStub([partialMock callSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
       [partialMock schemaTracked:@([[NSDate date] timeIntervalSince1970])];
       
       expect(sessionStartCallCount).equal(0);
    });
         
     it(@"AvoSessionTracker writes session timestamp to disk when session is updated", ^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[AvoSessionTracker cacheKey]];
        AvoSessionTracker * sut = [AvoSessionTracker new];
        
        expect(sut.lastSessionTimestamp).equal(INT_MIN);
    
        double timestamp = [[NSDate date] timeIntervalSince1970];
        [sut schemaTracked:@(timestamp)];
    
        expect([[NSUserDefaults standardUserDefaults] doubleForKey:[AvoSessionTracker cacheKey]]).equal(timestamp);
     });
});
SpecEnd

