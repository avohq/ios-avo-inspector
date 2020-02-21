//
//  InitializationTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 04.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoStateOfTracking.h>

SpecBegin(Init)

it(@"inititalizes with app version", ^{
   AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey: @"apiKey" isDebug: NO];

   NSString * appVersion = sut.appVersion;

   expect(appVersion).to.equal(@"app build version");
});

it(@"inititalizes with lib version", ^{
   AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey: @"apiKey" isDebug: NO];

   NSInteger libVersion = sut.libVersion;

   expect(libVersion).to.equal(1);
});

it(@"inititalizes with app id", ^{
    AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey: @"apiKey" isDebug: NO];

   expect(sut.apiKey).to.equal(@"apiKey");
});
   
it(@"inititalizes with session tracker", ^{
   AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey:@"apiKey" isDebug: NO];

  expect(sut.sessionTracker).notTo.beNil();
});

it(@"debug inititalization sets batch size to 1", ^{
   [AvoStateOfTracking setBatchFlushSeconds:30];
   
   AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey:@"apiKey" isDebug: YES];

  expect([AvoStateOfTracking getBatchFlushSeconds]).to.equal(3);
});

it(@"debug inititalization sets logs on", ^{
   [AvoStateOfTracking setLogging:NO];
   
   AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey:@"apiKey" isDebug: YES];

  expect([AvoStateOfTracking isLogging]).to.equal(YES);
});

it(@"not debug inititalization does not set batch size to 1", ^{
   [AvoStateOfTracking setBatchSize:30];
   
   AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey:@"apiKey" isDebug: NO];

  expect([AvoStateOfTracking getBatchSize]).to.equal(30);
});

SpecEnd
