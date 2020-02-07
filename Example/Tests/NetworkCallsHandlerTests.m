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

@end

SpecBegin(NetworkCalls)
describe(@"Handling network calls", ^{
         
    it(@"AvoNetworkCallsHandler saves values when init", ^{
        AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
        
        expect(sut.apiKey).to.equal(@"testApiKey");
        expect(sut.appVersion).to.equal(@"testAppVersion");
        expect(sut.libVersion).to.equal(@"testLibVersion");
    });
         
    it(@"AvoNetworkCallsHandler builds proper body for session tracking", ^{
        AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
        id partialMock = OCMPartialMock(sut);

        __block int blockCallsCount = 0;
        void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
            __unsafe_unretained NSArray * batchBody;
            [invocation getArgument:&batchBody atIndex:2];
            
            NSDictionary * sessionStartedBody = batchBody[0];
            expect([sessionStartedBody objectForKey:@"type"]).to.equal(@"sessionStarted");
            expect([sessionStartedBody objectForKey:@"apiKey"]).to.equal(@"testApiKey");
            expect([sessionStartedBody objectForKey:@"appVersion"]).to.equal(@"testAppVersion");
            expect([sessionStartedBody objectForKey:@"libVersion"]).to.equal(@"testLibVersion");
            expect([sessionStartedBody objectForKey:@"platform"]).to.equal(@"ios");
            expect([sessionStartedBody objectForKey:@"createdAt"]).toNot.beNil();
            expect([sessionStartedBody objectForKey:@"trackingId"]).toNot.beNil();
            
            blockCallsCount += 1;
        };
        OCMStub([partialMock callStateOfTrackingWithBatchBody:[OCMArg any]]).andDo(theBlock);
    
        [partialMock callSessionStarted];
        
        expect(blockCallsCount).to.beGreaterThan(0);
    });
         
    it(@"AvoNetworkCallsHandler builds proper body for schema tracking", ^{
         AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
        id partialMock = OCMPartialMock(sut);
    
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

        __block int blockCallsCount = 0;
        void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
            NSDictionary * expectedListSchema = @{@"propertyName" : @"list key", @"propertyValue" : @"list(int|float|boolean|string|null|unknown|list())"};
            
            __unsafe_unretained NSArray * batchBody;
            [invocation getArgument:&batchBody atIndex:2];
            
            NSDictionary * sessionStartedBody = batchBody[0];
            expect([sessionStartedBody objectForKey:@"type"]).to.equal(@"event");
            expect([sessionStartedBody objectForKey:@"eventName"]).to.equal(@"Test Event Name");
            expect([sessionStartedBody objectForKey:@"eventProperties"][0]).to.equal(expectedListSchema);
            
            expect([sessionStartedBody objectForKey:@"apiKey"]).to.equal(@"testApiKey");
            expect([sessionStartedBody objectForKey:@"appVersion"]).to.equal(@"testAppVersion");
            expect([sessionStartedBody objectForKey:@"libVersion"]).to.equal(@"testLibVersion");
            expect([sessionStartedBody objectForKey:@"platform"]).to.equal(@"ios");
            expect([sessionStartedBody objectForKey:@"createdAt"]).toNot.beNil();
            expect([sessionStartedBody objectForKey:@"trackingId"]).toNot.beNil();
            
            blockCallsCount += 1;
        };
        OCMStub([partialMock callStateOfTrackingWithBatchBody:[OCMArg any]]).andDo(theBlock);
    
        [partialMock callTrackSchema:@"Test Event Name" schema:schema];
        
        expect(blockCallsCount).to.beGreaterThan(0);
    });
});

SpecEnd
