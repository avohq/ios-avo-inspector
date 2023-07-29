//
//  TrackTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 13.03.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoInspector/AvoInspector.h>
#import <AvoInspector/AvoSessionTracker.h>
#import <AvoInspector/AvoBatcher.h>
#import <OCMock/OCMock.h>

@interface AvoInspector ()

@property (readwrite, nonatomic) AvoSessionTracker * sessionTracker;
@property (readwrite, nonatomic) AvoBatcher * avoBatcher;

-(NSDictionary<NSString *, AvoEventSchemaType *> *) avoFunctionTrackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params;

@end

SpecBegin(Track)
describe(@"Tracking", ^{

    it(@"Batcher invoked when trackSchemaFromEvent", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
        id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
        OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvProd];
        sut.sessionTracker = mockSessionTracker;
        sut.avoBatcher = mockAvoBatcher;
       
        [sut trackSchemaFromEvent:@"Event name" eventParams:[NSDictionary new]];
       
        OCMVerify([mockAvoBatcher handleTrackSchema:@"Event name" schema:[NSDictionary new] eventId:nil eventHash:nil]);
    });
    
    it(@"Tracking nil event does nothing", ^{
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvProd];
       
        NSString * eventName = nil;
        
        NSDictionary * trackedSchema = [sut trackSchemaFromEvent:eventName eventParams:[NSDictionary new]];
       
        expect(trackedSchema).equal([NSMutableDictionary new]);
    });
    
    it(@"Batcher шы invoked with proper params and event id and event hash when avoSchemaTrackSchemaFromEvent", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
        id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
        OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvDev];
        sut.sessionTracker = mockSessionTracker;
        sut.avoBatcher = mockAvoBatcher;
       
        NSMutableDictionary * params = [NSMutableDictionary new];
        params[@"avoFunctionEventId"] = @"testEventId";
        params[@"avoFunctionEventHash"] = @"testEventHash";
        
        [sut avoFunctionTrackSchemaFromEvent:@"Event name" eventParams:params];
       
        OCMVerify([mockAvoBatcher handleTrackSchema:@"Event name" schema:[NSDictionary new] eventId:@"testEventId" eventHash:@"testEventHash"]);
    });

    it(@"Batcher invoked when trackSchema", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
        id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
        OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvProd];
        sut.sessionTracker = mockSessionTracker;
        sut.avoBatcher = mockAvoBatcher;
       
        [sut trackSchema:@"Event name" eventSchema:[NSDictionary new]];
       
        OCMVerify([mockAvoBatcher handleTrackSchema:@"Event name" schema:[NSDictionary new] eventId:nil eventHash:nil]);
    });
});
SpecEnd
