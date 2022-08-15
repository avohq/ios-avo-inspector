//
//  EnvironmentMappingTest.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 13.03.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoNetworkCallsHandler.h>
#import <AvoInspector.h>

@interface AvoNetworkCallsHandler ()

+ (NSString*)formatTypeToString:(int) formatType;

@end

SpecBegin(EnviMapping)
describe(@"Environemtn mapping", ^{
    
     it(@"Test dev env mappings", ^{
        
        AvoInspectorEnv devEnv = AvoInspectorEnvDev;
        
        NSString * devMap = [AvoNetworkCallsHandler formatTypeToString:(int)devEnv];
         
        expect(devMap).to.equal(@"dev");
     });
         
     it(@"Test prod env mappings", ^{
        
        NSString * prodMap = [AvoNetworkCallsHandler formatTypeToString:(int)AvoInspectorEnvProd];
         
        expect(prodMap).to.equal(@"prod");
     });
    
     it(@"Test staging env mappings", ^{
        
        NSString * stageMap = [AvoNetworkCallsHandler formatTypeToString:(int)AvoInspectorEnvStaging];
         
        expect(stageMap).to.equal(@"staging");
     });
         
     it(@"AvoNetworkCallsHandler sends prod env", ^{
         AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appName:@"testAppName" appVersion:@"testAppVersion" libVersion:@"testLibVersion" env:0 endpoint:@"text.proxy"];

         NSMutableDictionary * actualSessionStartedBody = [sut bodyForSessionStartedCall];
         
         expect([actualSessionStartedBody objectForKey:@"env"]).to.equal(@"prod");
     });
         
     it(@"AvoNetworkCallsHandler sends dev env", ^{
         AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appName:@"testAppName" appVersion:@"testAppVersion" libVersion:@"testLibVersion" env:1 endpoint:@"text.proxy"];

         NSMutableDictionary * actualSessionStartedBody = [sut bodyForSessionStartedCall];
         
         expect([actualSessionStartedBody objectForKey:@"env"]).to.equal(@"dev");
     });
     
     it(@"AvoNetworkCallsHandler sends staging env", ^{
         AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appName:@"testAppName" appVersion:@"testAppVersion" libVersion:@"testLibVersion" env:2 endpoint:@"text.proxy"];

         NSMutableDictionary * actualSessionStartedBody = [sut bodyForSessionStartedCall];
         
         expect([actualSessionStartedBody objectForKey:@"env"]).to.equal(@"staging");
     });
});
SpecEnd
