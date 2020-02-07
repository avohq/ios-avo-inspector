//
//  SessionTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 05.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoStateOfTracking.h>
#import <AvoStateOfTracking/AvoSessionTracker.h>
#import <AvoStateOfTracking/AvoNetworkCallsHandler.h>
#import <OCMock/OCMock.h>

@interface AvoStateOfTracking ()

@property (readwrite, nonatomic) AvoSessionTracker * sessionTracker;
@property (readwrite, nonatomic) AvoNetworkCallsHandler * networkCallsHandler;

@end

SpecBegin(Session)
describe(@"Sessions", ^{
    
    beforeEach(^{
        [[NSUserDefaults standardUserDefaults] setDouble:INT_MIN forKey:[AvoSessionTracker cacheKey]];
    });

    it(@"session starts when trackSchemaFromEvent", ^{
        id mockNetworkHandler = OCMClassMock([AvoNetworkCallsHandler class]);
        OCMStub([mockNetworkHandler callTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
        OCMStub([mockSessionTracker schemaTracked:[OCMArg any]]).andDo(nil);
        AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey:@"tesApiKey"];
        sut.sessionTracker = mockSessionTracker;
        sut.networkCallsHandler = mockNetworkHandler;
       
        [sut trackSchemaFromEvent:@"Event name" eventParams:[NSDictionary new]];
       
        OCMVerify([mockSessionTracker schemaTracked:[OCMArg any]]);
    });

    it(@"session starts when trackSchema", ^{
        id mockNetworkHandler = OCMClassMock([AvoNetworkCallsHandler class]);
        OCMStub([mockNetworkHandler callTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
        OCMStub([mockSessionTracker schemaTracked:[OCMArg any]]).andDo(nil);
        AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey:@"tesApiKey"];
        sut.sessionTracker = mockSessionTracker;
        sut.networkCallsHandler = mockNetworkHandler;
       
        [sut trackSchema:@"Event name" eventSchema:[NSDictionary new]];
       
        OCMVerify([mockSessionTracker schemaTracked:[OCMArg any]]);
    });

    it(@"two calls of schemaTracked track only one session", ^{
        id mockNetworkHandler = OCMClassMock([AvoNetworkCallsHandler class]);
        OCMStub([mockNetworkHandler callTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        AvoSessionTracker * sut = [[AvoSessionTracker alloc] initWithNetworkHandler: mockNetworkHandler];
       
        __block int sessionStartCallCount = 0;
        OCMStub([mockNetworkHandler callSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
        [sut schemaTracked:@0];
        [sut schemaTracked:@1];
       
        expect(sessionStartCallCount).equal(1);
    });

    it(@"two calls of schemaTracked with (sessionDelay plus 1) track two session", ^{
        id mockNetworkHandler = OCMClassMock([AvoNetworkCallsHandler class]);
        OCMStub([mockNetworkHandler callTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        AvoSessionTracker * sut = [[AvoSessionTracker alloc] initWithNetworkHandler: mockNetworkHandler];
       
        __block int sessionStartCallCount = 0;
        OCMStub([mockNetworkHandler callSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
        [sut schemaTracked:@0];
        [sut schemaTracked:@(20 * 60 * 1000 + 1)];
       
        expect(sessionStartCallCount).equal(2);
    });

    it(@"two calls of schemaTracked with total timespan more than a session but individual timespans less are threated as one session", ^{
        id mockNetworkHandler = OCMClassMock([AvoNetworkCallsHandler class]);
        OCMStub([mockNetworkHandler callTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        AvoSessionTracker * sut = [[AvoSessionTracker alloc] initWithNetworkHandler: mockNetworkHandler];
       
        __block int sessionStartCallCount = 0;
        OCMStub([mockNetworkHandler callSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
        [sut schemaTracked:@0];
        [sut schemaTracked:@(20 * 60 * 1000 - 1)];
        [sut schemaTracked:@(20 * 60 * 1000 - 1)];
       
        expect(sessionStartCallCount).equal(1);
    });
});
SpecEnd
