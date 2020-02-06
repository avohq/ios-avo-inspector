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
   AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey: @"appId"];

   NSString * appVersion = sut.appVersion;

   expect(appVersion).to.equal(@"app build version");
});

it(@"inititalizes with lib version", ^{
   AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey: @"appId"];

   NSInteger libVersion = sut.libVersion;

   expect(libVersion).to.equal(1);
});

it(@"inititalizes with app id", ^{
    AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey: @"appId"];

   expect(sut.apiKey).to.equal(@"appId");
});
   
it(@"inititalizes with session tracker", ^{
   AvoStateOfTracking * sut = [[AvoStateOfTracking alloc] initWithApiKey:@"apiKey"];

  expect(sut.sessionTracker).notTo.beNil();
});

SpecEnd
