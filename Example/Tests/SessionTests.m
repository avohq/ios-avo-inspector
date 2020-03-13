//
//  SessionTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 05.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoInspector/AvoInspector.h>
#import <AvoInspector/AvoSessionTracker.h>
#import <AvoInspector/AvoBatcher.h>
#import <OCMock/OCMock.h>

@interface AvoInspector ()

@property (readwrite, nonatomic) AvoSessionTracker * sessionTracker;
@property (readwrite, nonatomic) AvoBatcher * avoBatcher;

@end

SpecBegin(Session)
describe(@"Sessions", ^{
    
    beforeEach(^{
        [[NSUserDefaults standardUserDefaults] setDouble:INT_MIN forKey:[AvoSessionTracker cacheKey]];
    });

    it(@"session starts when trackSchemaFromEvent", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
        OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvProd];
        sut.sessionTracker = mockSessionTracker;
        sut.avoBatcher = mockAvoBatcher;
       
        [sut trackSchemaFromEvent:@"Event name" eventParams:[NSDictionary new]];
       
        OCMVerify([mockSessionTracker startOrProlongSession:[OCMArg any]]);
    });

    it(@"session starts when trackSchema", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
        OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvProd];
        sut.sessionTracker = mockSessionTracker;
        sut.avoBatcher = mockAvoBatcher;
       
        [sut trackSchema:@"Event name" eventSchema:[NSDictionary new]];
       
        OCMVerify([mockSessionTracker startOrProlongSession:[OCMArg any]]);
    });

    it(@"two calls of schemaTracked track only one session", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        AvoSessionTracker * sut = [[AvoSessionTracker alloc] initWithBatcher:mockAvoBatcher];
       
        __block int sessionStartCallCount = 0;
        OCMStub([mockAvoBatcher handleSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
        [sut startOrProlongSession:@0];
        [sut startOrProlongSession:@1];
       
        expect(sessionStartCallCount).equal(1);
    });

    it(@"two calls of schemaTracked with (sessionDelay plus 1) track two session", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        AvoSessionTracker * sut = [[AvoSessionTracker alloc] initWithBatcher:mockAvoBatcher];
       
        __block int sessionStartCallCount = 0;
        OCMStub([mockAvoBatcher handleSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
        [sut startOrProlongSession:@0];
        [sut startOrProlongSession:@(20 * 60 * 1000 + 1)];
       
        expect(sessionStartCallCount).equal(2);
    });

    it(@"two calls of schemaTracked with total timespan more than a session but individual timespans less are threated as one session", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any]]).andDo(nil);
        AvoSessionTracker * sut = [[AvoSessionTracker alloc] initWithBatcher:mockAvoBatcher];
       
        __block int sessionStartCallCount = 0;
        OCMStub([mockAvoBatcher handleSessionStarted]).andDo(^(NSInvocation *invocation) {
            ++sessionStartCallCount;
        });
       
        [sut startOrProlongSession:@0];
        [sut startOrProlongSession:@(5 * 60 - 1)];
        [sut startOrProlongSession:@(5 * 60 - 1)];
       
        expect(sessionStartCallCount).equal(1);
    });
});
SpecEnd
