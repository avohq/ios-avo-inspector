//
//  SessionTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 05.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoStateOfTracking.h>
#import <AvoStateOfTracking/AvoSessionTracker.h>
#import <OCMock/OCMock.h>

@interface AvoStateOfTracking ()

@property (readwrite, nonatomic) AvoSessionTracker * sessionTracker;

@end

@interface AvoSessionTracker ()

- (void) callSessionStarted;

@end


SpecBegin(Session)
describe(@"Sessions", ^{
    
    beforeEach(^{
        [[NSUserDefaults standardUserDefaults] setDouble:INT_MIN forKey:[AvoSessionTracker cacheKey]];
    });

    it(@"session starts when trackSchemaFromEvent", ^{
       id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
       
       AvoStateOfTracking * sut = [AvoStateOfTracking new];
       sut.sessionTracker = mockSessionTracker;
       
       [sut trackSchemaFromEvent:@"Event name" eventParams:[NSDictionary new]];
       
       OCMVerify([mockSessionTracker schemaTracked:[OCMArg any]]);
    });

    it(@"session starts when trackSchema", ^{
       id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
       
       AvoStateOfTracking * sut = [AvoStateOfTracking new];
       sut.sessionTracker = mockSessionTracker;
       
       [sut trackSchema:@"Event name" eventSchema:[NSDictionary new]];
       
       OCMVerify([mockSessionTracker schemaTracked:[OCMArg any]]);
    });

    it(@"two calls of schemaTracked track only one session", ^{
       AvoSessionTracker * sut = [AvoSessionTracker new];
       
       id partialMock = OCMPartialMock(sut);
       
       __block int sessionStartCallCount = 0;
       OCMStub([partialMock callSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
       [partialMock schemaTracked:@0];
       [partialMock schemaTracked:@1];
       
       expect(sessionStartCallCount).equal(1);
    });

    it(@"two calls of schemaTracked with (sessionDelay plus 1) track two session", ^{
       AvoSessionTracker * sut = [AvoSessionTracker new];
       
       id partialMock = OCMPartialMock(sut);
       
       __block int sessionStartCallCount = 0;
       OCMStub([partialMock callSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
       });
       
       [partialMock schemaTracked:@0];
       [partialMock schemaTracked:@(20 * 60 * 1000 + 1)];
       
       expect(sessionStartCallCount).equal(2);
    });

    it(@"two calls of schemaTracked with total timespan more than a session but individual timespans less are threated as one session", ^{
       AvoSessionTracker * sut = [AvoSessionTracker new];
       
       id partialMock = OCMPartialMock(sut);
       
       __block int sessionStartCallCount = 0;
       OCMStub([partialMock callSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
       [partialMock schemaTracked:@0];
       [partialMock schemaTracked:@(20 * 60 * 1000 - 1)];
       [partialMock schemaTracked:@(20 * 60 * 1000 - 1)];
       
       expect(sessionStartCallCount).equal(1);
    });
});
SpecEnd
