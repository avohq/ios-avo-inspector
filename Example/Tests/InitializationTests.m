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

@interface AvoSessionTracker ()

@property (nonatomic) NSTimeInterval lastSessionTimestamp;

@end

@interface AvoInspector ()

@property (readwrite, nonatomic) NSNotificationCenter *notificationCenter;
@property (readwrite, nonatomic) AvoBatcher *avoBatcher;
@property (readwrite, nonatomic) AvoSessionTracker *sessionTracker;

- (void) addObservers;
- (void) enterBackground;
- (void) enterForeground;

@end

@interface AvoBatcher ()

@property (readwrite, nonatomic) NSMutableArray * events;

@end

SpecBegin(Init)

it(@"inititalizes with app version", ^{
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" isDev: NO];

   NSString * appVersion = sut.appVersion;

   expect(appVersion).to.equal(@"1.0.1");
});

it(@"inititalizes with lib version", ^{
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" isDev: NO];

   NSString * libVersion = sut.libVersion;

   expect(libVersion).to.equal(@"0.9.4");
});

it(@"inititalizes with app id", ^{
    AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" isDev: NO];

   expect(sut.apiKey).to.equal(@"apiKey");
});
   
it(@"inititalizes with session tracker", ^{
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: NO];

  expect(sut.sessionTracker).notTo.beNil();
});

it(@"debug inititalization sets batch size to 1", ^{
   [AvoInspector setBatchFlushSeconds:30];
   
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: YES];

  expect([AvoInspector getBatchFlushSeconds]).to.equal(1);
});

it(@"debug inititalization sets logs on", ^{
   [AvoInspector setLogging:NO];
   
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: YES];

  expect([AvoInspector isLogging]).to.equal(YES);
});

it(@"not debug inititalization does not set batch size to 1", ^{
   [AvoInspector setBatchSize:30];
   
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: NO];

  expect([AvoInspector getBatchSize]).to.equal(30);
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
    AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: NO];
    
    sut.notificationCenter = mockNotificationCenter;
    
    [sut addObservers];
   
    // Then
    expect(backgroundObserversCount).to.equal(1);
    expect(foregroundObserversCount).to.equal(1);
});

it(@"Calls batcher on foreground", ^{

   id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: NO];
   sut.avoBatcher = mockAvoBatcher;
   
   // When
   [sut enterForeground];
   
   // Then
   OCMVerify([mockAvoBatcher enterForeground]);
});

it(@"Calls batcher on background", ^{

   id mockAvoBatcher = OCMClassMock([AvoBatcher class]);
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: NO];
   sut.avoBatcher = mockAvoBatcher;
   
   // When
   [sut enterBackground];
   
   // Then
   OCMVerify([mockAvoBatcher enterBackground]);
});

it(@"Calls session tracker on foreground", ^{
   
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[AvoSessionTracker cacheKey]];
   id mockSessionTracker = OCMClassMock([AvoSessionTracker class]);
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: NO];
   sut.sessionTracker = mockSessionTracker;
   
   // When
   [sut enterForeground];
   
   // Then
   OCMVerify([mockSessionTracker startOrProlongSession:[OCMArg any]]);
});

it(@"Saves start session event in the batcher", ^{
   
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[AvoSessionTracker cacheKey]];
    AvoInspector * sut = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: NO];
   
    // When
    sut.sessionTracker.lastSessionTimestamp = 0.0;
    [sut enterForeground];
   
    // Then
    expect([sut.avoBatcher.events count]).equal(1);
    expect([sut.avoBatcher.events[0] objectForKey:@"type"]).equal(@"sessionStarted");
});

SpecEnd
