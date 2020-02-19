//
//  NetworkCallsHandlerTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 07.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoNetworkCallsHandler.h>
#import <AvoStateOfTracking/AvoList.h>
#import <AvoStateOfTracking/AvoInt.h>
#import <AvoStateOfTracking/AvoFloat.h>
#import <AvoStateOfTracking/AvoBoolean.h>
#import <AvoStateOfTracking/AvoNull.h>
#import <AvoStateOfTracking/AvoString.h>
#import <AvoStateOfTracking/AvoUnknownType.h>
#import <OCMock/OCMock.h>

@interface AvoNetworkCallsHandler ()

- (void) callStateOfTrackingWithBatchBody: (NSArray *) body;

@property (readwrite, nonatomic) double samplingRate;

@end

SpecBegin(NetworkCalls)
describe(@"Handling network calls", ^{
         
    it(@"AvoNetworkCallsHandler saves values when init", ^{
        AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
        
        expect(sut.apiKey).to.equal(@"testApiKey");
        expect(sut.appVersion).to.equal(@"testAppVersion");
        expect(sut.libVersion).to.equal(@"testLibVersion");
        expect(sut.samplingRate).to.equal(1.0);
    });
         
    it(@"AvoNetworkCallsHandler builds proper body for session tracking", ^{
        AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];

        NSMutableDictionary * actualSessionStartedBody = [sut bodyForSessionStartedCall];
        
        expect([actualSessionStartedBody objectForKey:@"type"]).to.equal(@"sessionStarted");
        expect([actualSessionStartedBody objectForKey:@"apiKey"]).to.equal(@"testApiKey");
        expect([actualSessionStartedBody objectForKey:@"appVersion"]).to.equal(@"testAppVersion");
        expect([actualSessionStartedBody objectForKey:@"libVersion"]).to.equal(@"testLibVersion");
        expect([actualSessionStartedBody objectForKey:@"libPlatform"]).to.equal(@"ios");
        expect([actualSessionStartedBody objectForKey:@"createdAt"]).toNot.beNil();
        expect([actualSessionStartedBody objectForKey:@"trackingId"]).toNot.beNil();
    });
         
    it(@"AvoNetworkCallsHandler builds proper body for schema tracking", ^{
         AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
    
        NSMutableDictionary * schema = [NSMutableDictionary new];
        AvoList * list = [AvoList new];
        list.subtypes = [[NSMutableArray alloc] initWithArray:@[[AvoInt new], [AvoFloat new], [AvoBoolean new], [AvoString new], [AvoNull new], [AvoUnknownType new], [AvoList new]]];
        [schema setObject:list forKey:@"list key"];
        [schema setObject:[AvoInt new] forKey:@"int key"];
        [schema setObject:[AvoFloat new] forKey:@"float key"];
        [schema setObject:[AvoBoolean new] forKey:@"boolean key"];
        [schema setObject:[AvoString new] forKey:@"string key"];
        [schema setObject:[AvoNull new] forKey:@"null key"];
        [schema setObject:[AvoUnknownType new] forKey:@"unknown type key"];
        // TODO verify other properties except list
    
        NSMutableDictionary * actualTrackSchemaBody = [sut bodyForTrackSchemaCall:@"Test Event Name" schema:schema];
    
        NSDictionary * expectedListSchema = @{@"propertyName" : @"list key", @"propertyValue" : @"list(int|float|boolean|string|null|unknown|list())"};
           
        expect([actualTrackSchemaBody objectForKey:@"type"]).to.equal(@"event");
        expect([actualTrackSchemaBody objectForKey:@"eventName"]).to.equal(@"Test Event Name");
        expect([actualTrackSchemaBody objectForKey:@"eventProperties"][0]).to.equal(expectedListSchema);
              
        expect([actualTrackSchemaBody objectForKey:@"apiKey"]).to.equal(@"testApiKey");
        expect([actualTrackSchemaBody objectForKey:@"appVersion"]).to.equal(@"testAppVersion");
        expect([actualTrackSchemaBody objectForKey:@"libVersion"]).to.equal(@"testLibVersion");
        expect([actualTrackSchemaBody objectForKey:@"libPlatform"]).to.equal(@"ios");
        expect([actualTrackSchemaBody objectForKey:@"createdAt"]).toNot.beNil();
        expect([actualTrackSchemaBody objectForKey:@"trackingId"]).toNot.beNil();
    });
});

SpecEnd
