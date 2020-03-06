//
//  InitializationTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 04.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoInspector/AvoInspector.h>

SpecBegin(Init)

it(@"inititalizes with app version", ^{
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" isDev: NO];

   NSString * appVersion = sut.appVersion;

   expect(appVersion).to.equal(@"app build version");
});

it(@"inititalizes with lib version", ^{
   AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" isDev: NO];

   NSInteger libVersion = sut.libVersion;

   expect(libVersion).to.equal(2);
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

SpecEnd
