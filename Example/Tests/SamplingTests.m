//
//  SamplingTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 07.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoNetworkCallsHandler.h>
#import <OCMock/OCMock.h>

@interface AvoNetworkCallsHandler ()

- (BOOL)sendHttpRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSError *error))completionHandler;

@property (readwrite, atomic) double samplingRate;

@end

SpecBegin(Sampling)
describe(@"Sampling", ^{
         
    it(@"Do not send data with sampling rate set to 0", ^{
    AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appName:@"testAppName" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
        sut.samplingRate = 0.0;
    
        id partialMock = OCMPartialMock(sut);

        __block int httpRequestsCount = 0;
        void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
            httpRequestsCount += 1;
        };
        OCMStub([partialMock sendHttpRequest:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);
    
        for (int i = 0; i < 999; i++) {
            [sut callStateOfTrackingWithBatchBody:@[[sut bodyForSessionStartedCall]] completionHandler:^(NSError * _Nonnull error) {}];
            [sut callStateOfTrackingWithBatchBody:@[[sut bodyForTrackSchemaCall:@"Schema" schema:[NSDictionary new]]] completionHandler:^(NSError * _Nonnull error) {}];
        }
           
        expect(httpRequestsCount).to.equal(0);
    });
         
     it(@"Sends data every time with sampling rate set to 1", ^{
         AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appName:@"testAppName" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
         sut.samplingRate = 1.0;
     
         id partialMock = OCMPartialMock(sut);

         __block int httpRequestsCount = 0;
         void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
             httpRequestsCount += 1;
         };
         OCMStub([partialMock sendHttpRequest:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);
     
         for (int i = 0; i < 1000; i++) {
             [sut callStateOfTrackingWithBatchBody:@[[sut bodyForSessionStartedCall]] completionHandler:^(NSError * _Nonnull error) {}];
             [sut callStateOfTrackingWithBatchBody:@[[sut bodyForTrackSchemaCall:@"Schema" schema:[NSDictionary new]]] completionHandler:^(NSError * _Nonnull error) {}];
         }
            
         expect(httpRequestsCount).to.equal(2000);
     });
});

SpecEnd
