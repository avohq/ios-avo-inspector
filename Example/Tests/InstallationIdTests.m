//
//  InstallationIdTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 06.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoInstallationId.h>

SpecBegin(InstallationId)
describe(@"Installation id between restarts", ^{

    it(@"AvoInstallationId reads installation id from disk when created", ^{
        [[NSUserDefaults standardUserDefaults] setObject:@"disk installationId" forKey:[AvoInstallationId cacheKey]];
        AvoInstallationId * sut = [AvoInstallationId new];
       
        NSString * installationId = [sut getInstallationId];
       
        expect(installationId).equal(@"disk installationId");
    });
         
    it(@"AvoInstallationId writes installation id from disk when created if nothing is stored", ^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[AvoInstallationId cacheKey]];
        AvoInstallationId * sut = [AvoInstallationId new];

        NSString * installationId = [sut getInstallationId];

        expect([[NSUserDefaults standardUserDefaults] stringForKey:[AvoInstallationId cacheKey]]).equal(installationId);
    });
});
SpecEnd
