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
#import <AnalyticsDebugger.h>

@interface AvoInspector ()

@property (readwrite, nonatomic) AvoSessionTracker * sessionTracker;
@property (readwrite, nonatomic) AvoBatcher * avoBatcher;
@property (readwrite, nonatomic) AnalyticsDebugger * debugger;

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
    
    it(@"Batcher and visual debugger invoked with proper params and event id and event hash when avoSchemaTrackSchemaFromEvent", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
        id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
        OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvDev];
        sut.sessionTracker = mockSessionTracker;
        sut.avoBatcher = mockAvoBatcher;
        sut.debugger = OCMClassMock([AnalyticsDebugger class]);
       
        NSMutableDictionary * params = [NSMutableDictionary new];
        params[@"avoFunctionEventId"] = @"testEventId";
        params[@"avoFunctionEventHash"] = @"testEventHash";
        
        [sut avoFunctionTrackSchemaFromEvent:@"Event name" eventParams:params];
       
        OCMVerify([mockAvoBatcher handleTrackSchema:@"Event name" schema:[NSDictionary new] eventId:@"testEventId" eventHash:@"testEventHash"]);
        OCMVerify([sut.debugger publishEvent:@"Schema: Event name" withTimestamp:[OCMArg any]
                              withProperties:[NSArray new] withErrors:[NSArray new]]);
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

    it(@"Visual inspector invoked when trackSchema in dev", ^{
        id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
        OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
        id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
        OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvDev];
        sut.sessionTracker = mockSessionTracker;
        sut.avoBatcher = mockAvoBatcher;
        sut.debugger = OCMClassMock([AnalyticsDebugger class]);
    
        [sut trackSchema:@"Event name" eventSchema:[NSDictionary new]];

        OCMVerify([sut.debugger publishEvent:@"Schema: Event name" withTimestamp:[OCMArg any]
                                    withProperties:[OCMArg any] withErrors:[OCMArg any]]);
    });
         
     it(@"Visual inspector invoked when trackSchemaFromEvent in dev", ^{
         id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
         OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
         id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
         OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
         AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvDev];
         sut.sessionTracker = mockSessionTracker;
         sut.avoBatcher = mockAvoBatcher;
         sut.debugger = OCMClassMock([AnalyticsDebugger class]);
     
         [sut trackSchemaFromEvent:@"Event name" eventParams:[NSDictionary new]];

         OCMVerify([sut.debugger publishEvent:@"Event: Event name" withTimestamp:[OCMArg any]
                                     withProperties:[OCMArg any] withErrors:[OCMArg any]]);
     });
         
     it(@"Visual inspector not invoked when trackSchema in prod and not visible inspector", ^{
         id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
         OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
         id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
         OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
         AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvProd];
         sut.sessionTracker = mockSessionTracker;
         sut.avoBatcher = mockAvoBatcher;
         sut.debugger = OCMClassMock([AnalyticsDebugger class]);

         OCMReject([sut.debugger publishEvent:[OCMArg any] withTimestamp:[OCMArg any]
                                 withProperties:[OCMArg any] withErrors:[OCMArg any]]);
    
         [sut trackSchema:@"Event name" eventSchema:[NSDictionary new]];
     });
         
     it(@"Visual inspector not invoked when trackSchemaFromEvent in prod and not visible inspector", ^{
         id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
         OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
         id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
         OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
         AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvProd];
         sut.sessionTracker = mockSessionTracker;
         sut.avoBatcher = mockAvoBatcher;
         sut.debugger = OCMClassMock([AnalyticsDebugger class]);
     
        OCMReject([sut.debugger publishEvent:[OCMArg any] withTimestamp:[OCMArg any]
                              withProperties:[OCMArg any] withErrors:[OCMArg any]]);
    
         [sut trackSchemaFromEvent:@"Event name" eventParams:[NSDictionary new]];
     });
         
     it(@"Visual inspector is invoked when trackSchema in prod and visible inspector", ^{
          id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
          OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
          id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
          OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
          AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvProd];
          sut.sessionTracker = mockSessionTracker;
          sut.avoBatcher = mockAvoBatcher;
          sut.debugger = OCMClassMock([AnalyticsDebugger class]);
          OCMStub([sut.debugger isEnabled]).andReturn(YES);

          [sut trackSchema:@"Event name" eventSchema:[NSDictionary new]];
    
          OCMVerify([sut.debugger publishEvent:@"Schema: Event name" withTimestamp:[OCMArg any]
                              withProperties:[OCMArg any] withErrors:[NSMutableArray new]]);
      });
         
     it(@"Visual inspector is invoked when trackSchemaFromEvent in prod and visible inspector", ^{
           id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
           OCMStub([mockAvoBatcher handleTrackSchema:[OCMArg any] schema:[OCMArg any] eventId:nil eventHash:nil]).andDo(nil);
           id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
           OCMStub([mockSessionTracker startOrProlongSession:[OCMArg any]]).andDo(nil);
           AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"tesApiKey" env: AvoInspectorEnvProd];
           sut.sessionTracker = mockSessionTracker;
           sut.avoBatcher = mockAvoBatcher;
           sut.debugger = OCMClassMock([AnalyticsDebugger class]);
           OCMStub([sut.debugger isEnabled]).andReturn(YES);

           [sut trackSchemaFromEvent:@"Event name" eventParams:[NSDictionary new]];
     
           OCMVerify([sut.debugger publishEvent:@"Event: Event name" withTimestamp:[OCMArg any]
                               withProperties:[OCMArg any] withErrors:[NSMutableArray new]]);
       });
});
SpecEnd
