//
//  InitializationTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 04.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoInspector/AvoInspector.h>
#import <AvoInspector/AvoBatcher.h>
#import <AvoInspector/AvoSessionTracker.h>
#import <OCMock/OCMock.h>
#import <AnalyticsDebugger.h>

@interface AvoSessionTracker ()

@property (nonatomic) NSTimeInterval lastSessionTimestamp;

@end

@interface AvoInspector ()

@property (readwrite, nonatomic) NSNotificationCenter *notificationCenter;
@property (readwrite, nonatomic) AvoBatcher *avoBatcher;
@property (readwrite, nonatomic) AvoSessionTracker *sessionTracker;
@property (readwrite, nonatomic) AnalyticsDebugger *debugger;

- (void) addObservers;
- (void) enterBackground;
- (void) enterForeground;

@end

@interface AvoBatcher ()

@property (readwrite, nonatomic) NSMutableArray * events;

@end

SpecBegin(Init)

it(@"inititalizes with app version", ^{
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" env: AvoInspectorEnvProd];

   NSString * appVersion = sut.appVersion;

   expect(appVersion).to.equal(@"1.0.3");
});

it(@"inititalizes with lib version", ^{
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" env: AvoInspectorEnvProd];

   NSString * libVersion = sut.libVersion;

   expect(libVersion).to.equal(@"1.0.2");
});

it(@"inititalizes with app id", ^{
    AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" env: AvoInspectorEnvProd];

   expect(sut.apiKey).to.equal(@"apiKey");
});
   
it(@"inititalizes with session tracker", ^{
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvProd];

  expect(sut.sessionTracker).notTo.beNil();
});

it(@"debug inititalization sets batch size to 1", ^{
   [AvoInspector setBatchFlushSeconds:30];
   
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvDev];

  expect([AvoInspector getBatchFlushSeconds]).to.equal(1);
});

it(@"debug inititalization sets logs on", ^{
   [AvoInspector setLogging:NO];
   
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvDev];

  expect([AvoInspector isLogging]).to.equal(YES);
});

it(@"debug inititalization shows visual inspector", ^{
   [AvoInspector setLogging:NO];
   
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvDev];
   sut.debugger = OCMClassMock([AnalyticsDebugger class]);
 
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait"];
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:1 handler:nil];
   OCMVerify([sut.debugger showBarDebugger]);

});

it(@"not debug inititalization sets timeout to 30", ^{
   [AvoInspector setBatchFlushSeconds:1];
   
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvProd];

  expect([AvoInspector getBatchFlushSeconds]).to.equal(30);
});

it(@"Registers foreground and backround observers", ^{
    
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    
    __block int backgroundObserversCount = 0;
    void (^theBackgroundBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
        backgroundObserversCount += 1;
    };
    OCMStub([mockNotificationCenter addObserver:[OCMArg any] selector:[OCMArg anySelector]
                                           name:UIApplicationDidEnterBackgroundNotification object:nil]).andDo(theBackgroundBlock);
    
    __block int foregroundObserversCount = 0;
    void (^theForegroundBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
        foregroundObserversCount += 1;
    };
    OCMStub([mockNotificationCenter addObserver:[OCMArg any] selector:[OCMArg anySelector]
                                           name:UIApplicationWillEnterForegroundNotification object:nil]).andDo(theForegroundBlock);
    
    // When
    AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvProd];
    
    sut.notificationCenter = mockNotificationCenter;
    
    [sut addObservers];
   
    // Then
    expect(backgroundObserversCount).to.equal(1);
    expect(foregroundObserversCount).to.equal(1);
});

it(@"Calls batcher on foreground", ^{

   id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvProd];
   sut.avoBatcher = mockAvoBatcher;
   
   // When
   [sut enterForeground];
   
   // Then
   OCMVerify([mockAvoBatcher enterForeground]);
});

it(@"Calls batcher on background", ^{

   id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvProd];
   sut.avoBatcher = mockAvoBatcher;
   
   // When
   [sut enterBackground];
   
   // Then
   OCMVerify([mockAvoBatcher enterBackground]);
});

it(@"Calls session tracker on foreground", ^{
   
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[AvoSessionTracker timestampCacheKey]];
   id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvProd];
   sut.sessionTracker = mockSessionTracker;
   
   // When
   [sut enterForeground];
   
   // Then
   OCMVerify([mockSessionTracker startOrProlongSession:[OCMArg any]]);
});

it(@"Saves start session event in the batcher", ^{
   
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[AvoSessionTracker timestampCacheKey]];
    AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvProd];
   
    // When
    sut.sessionTracker.lastSessionTimestamp = 0.0;
    [sut enterForeground];
   
    // Then
    expect([sut.avoBatcher.events count]).equal(1);
    expect([sut.avoBatcher.events[0] objectForKey:@"type"]).equal(@"sessionStarted");
});

SpecEnd
