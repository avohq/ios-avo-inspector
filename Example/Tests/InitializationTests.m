//
//  InitializationTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 04.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoStateOfTracking.h>

SpecBegin(InitSpecs)

it(@"inititalizes with app version", ^{
   AvoStateOfTracking * sut = [AvoStateOfTracking new];

   NSString * appVersion = sut.appVersion;

   expect(appVersion).equal(@"app build version");
});

it(@"inititalizes with lib version", ^{
   AvoStateOfTracking * sut = [AvoStateOfTracking new];

   NSInteger libVersion = sut.libVersion;

   expect(libVersion).equal(1);
});

SpecEnd
