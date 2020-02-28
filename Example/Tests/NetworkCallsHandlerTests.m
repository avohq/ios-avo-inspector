//
//  NetworkCallsHandlerTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 07.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoStateOfTracking/AvoNetworkCallsHandler.h>
#import <AvoStateOfTracking/AvoList.h>
#import <AvoStateOfTracking/AvoObject.h>
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
        AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appName: @"testAppName" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
        
        expect(sut.apiKey).to.equal(@"testApiKey");
        expect(sut.appVersion).to.equal(@"testAppVersion");
        expect(sut.libVersion).to.equal(@"testLibVersion");
        expect(sut.appName).to.equal(@"testAppName");
        expect(sut.samplingRate).to.equal(1.0);
    });
         
    it(@"AvoNetworkCallsHandler builds proper body for session tracking", ^{
        AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appName:@"testAppName" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];

        NSMutableDictionary * actualSessionStartedBody = [sut bodyForSessionStartedCall];
        
        expect([actualSessionStartedBody objectForKey:@"type"]).to.equal(@"sessionStarted");
        expect([actualSessionStartedBody objectForKey:@"apiKey"]).to.equal(@"testApiKey");
        expect([actualSessionStartedBody objectForKey:@"appVersion"]).to.equal(@"testAppVersion");
        expect([actualSessionStartedBody objectForKey:@"libVersion"]).to.equal(@"testLibVersion");
        expect([actualSessionStartedBody objectForKey:@"libPlatform"]).to.equal(@"ios");
        expect([actualSessionStartedBody objectForKey:@"appName"]).to.equal(@"testAppName");
        expect([actualSessionStartedBody objectForKey:@"createdAt"]).toNot.beNil();
        expect([actualSessionStartedBody objectForKey:@"trackingId"]).toNot.beNil();
        expect([actualSessionStartedBody objectForKey:@"messageId"]).toNot.beNil();
    });
         
    it(@"AvoNetworkCallsHandler builds proper body for schema tracking", ^{
         AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appName:@"testAppName" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
    
        NSMutableDictionary * schema = [NSMutableDictionary new];
        AvoList * list = [AvoList new];
        list.subtypes = [[NSMutableSet alloc] initWithArray:[[NSMutableArray alloc] initWithArray:@[[AvoInt new], [AvoFloat new], [AvoBoolean new], [AvoString new], [AvoNull new], [AvoUnknownType new], [AvoList new]]]];
        [schema setObject:list forKey:@"list key"];
        [schema setObject:[AvoInt new] forKey:@"int key"];
        [schema setObject:[AvoFloat new] forKey:@"float key"];
        [schema setObject:[AvoBoolean new] forKey:@"boolean key"];
        [schema setObject:[AvoString new] forKey:@"string key"];
        [schema setObject:[AvoNull new] forKey:@"null key"];
        [schema setObject:[AvoUnknownType new] forKey:@"unknown type key"];
    
        NSMutableDictionary * actualTrackSchemaBody = [sut bodyForTrackSchemaCall:@"Test Event Name" schema:schema];
    
        expect([actualTrackSchemaBody objectForKey:@"type"]).to.equal(@"event");
        expect([actualTrackSchemaBody objectForKey:@"eventName"]).to.equal(@"Test Event Name");
        expect([actualTrackSchemaBody objectForKey:@"apiKey"]).to.equal(@"testApiKey");
        expect([actualTrackSchemaBody objectForKey:@"appVersion"]).to.equal(@"testAppVersion");
        expect([actualTrackSchemaBody objectForKey:@"libVersion"]).to.equal(@"testLibVersion");
        expect([actualTrackSchemaBody objectForKey:@"libPlatform"]).to.equal(@"ios");
        expect([actualTrackSchemaBody objectForKey:@"appName"]).to.equal(@"testAppName");
        expect([actualTrackSchemaBody objectForKey:@"createdAt"]).toNot.beNil();
        expect([actualTrackSchemaBody objectForKey:@"trackingId"]).toNot.beNil();
        expect([actualTrackSchemaBody objectForKey:@"messageId"]).toNot.beNil();
    
        expect([[actualTrackSchemaBody objectForKey:@"eventProperties"] count]).to.equal(7);
    
        for (NSDictionary *childProp in [actualTrackSchemaBody objectForKey:@"eventProperties"]) {
            NSString *key = [childProp valueForKey:@"propertyName"];
            
            if ([key isEqual:@"list key"]) {
                 expect([childProp objectForKey:@"propertyValue"]).to.startWith(@"list(");
                 expect([childProp objectForKey:@"propertyValue"]).to.contain(@"int");
                 expect([childProp objectForKey:@"propertyValue"]).to.contain(@"float");
                 expect([childProp objectForKey:@"propertyValue"]).to.contain(@"boolean");
                 expect([childProp objectForKey:@"propertyValue"]).to.contain(@"string");
                 expect([childProp objectForKey:@"propertyValue"]).to.contain(@"null");
                 expect([childProp objectForKey:@"propertyValue"]).to.contain(@"unknown");
                 expect([childProp objectForKey:@"propertyValue"]).to.contain(@"list()");
            } else if ( [key isEqual:@"boolean key"]) {
                 expect([childProp objectForKey:@"propertyValue"]).to.equal(@"boolean");
            } else if ( [key isEqual:@"string key"]) {
                 expect([childProp objectForKey:@"propertyValue"]).to.startWith(@"string");
            } else if ( [key isEqual:@"int key"]) {
                expect([childProp objectForKey:@"propertyValue"]).to.startWith(@"int");
            } else if ( [key isEqual:@"unknown type key"]) {
                expect([childProp objectForKey:@"propertyValue"]).to.startWith(@"unknown");
            } else if ( [key isEqual:@"float key"]) {
                expect([childProp objectForKey:@"propertyValue"]).to.startWith(@"float");
            } else if ( [key isEqual:@"null key"]) {
                expect([childProp objectForKey:@"propertyValue"]).to.startWith(@"null");
            }
        }
    });

     it(@"AvoNetworkCallsHandler builds proper body for object schema tracking", ^{
        AvoNetworkCallsHandler * sut = [[AvoNetworkCallsHandler alloc] initWithApiKey:@"testApiKey" appName:@"testAppName" appVersion:@"testAppVersion" libVersion:@"testLibVersion"];
     
        NSMutableDictionary * schema = [NSMutableDictionary new];
        AvoObject * object = [AvoObject new];
        [object.fields setValue:[AvoString new]  forKey:@"key1"];
        [object.fields setValue:[AvoInt new]  forKey:@"key2"];
        AvoList * list = [AvoList new];
        list.subtypes = [[NSMutableSet alloc] initWithArray:[[NSMutableArray alloc] initWithArray:@[[AvoInt new], [AvoFloat new], [AvoBoolean new], [AvoString new], [AvoNull new], [AvoUnknownType new], [AvoList new]]]];
        [object.fields setValue:list forKey:@"key3"];
        [schema setObject:object forKey:@"obj key"];
        AvoObject * nestedObject = [AvoObject new];
        [nestedObject.fields setValue:[AvoString new] forKey:@"nestedKey1"];
        [nestedObject.fields setValue:[AvoInt new] forKey:@"nestedKey2"];
        [nestedObject.fields setValue:list forKey:@"nestedKey3"];
        [object.fields setValue:nestedObject forKey:@"key4"];
     
        NSMutableDictionary * actualTrackSchemaBody = [sut bodyForTrackSchemaCall:@"Test Event Name" schema:schema];
            
        expect([actualTrackSchemaBody objectForKey:@"type"]).to.equal(@"event");
        expect([actualTrackSchemaBody objectForKey:@"eventName"]).to.equal(@"Test Event Name");
        expect([[actualTrackSchemaBody objectForKey:@"eventProperties"][0] valueForKey:@"propertyName"]).to.equal(@"obj key");
        expect([[actualTrackSchemaBody objectForKey:@"eventProperties"][0] valueForKey:@"propertyValue"]).to.equal(@"object");
    
        NSArray * propertyChildren = [[actualTrackSchemaBody objectForKey:@"eventProperties"][0] valueForKey:@"children"];
        for (NSDictionary *childProp in propertyChildren) {
            NSString *key = [childProp valueForKey:@"propertyName"];
            
            if ([key isEqual:@"key1"]) {
                 expect([childProp objectForKey:@"propertyValue"]).to.equal(@"string");
            } else if ( [key isEqual:@"key2"]) {
                 expect([childProp objectForKey:@"propertyValue"]).to.equal(@"int");
            } else if ( [key isEqual:@"key3"]) {
                 expect([childProp objectForKey:@"propertyValue"]).to.startWith(@"list(");
            } else if ( [key isEqual:@"key4"]) {
                expect([childProp objectForKey:@"propertyValue"]).to.equal(@"object");
                NSArray * nestedPropertyChildren = [childProp valueForKey:@"children"];
                for (NSDictionary *nestedChildProp in nestedPropertyChildren) {
                    NSString *nestedKey = [nestedChildProp valueForKey:@"propertyName"];
                    
                    if ([nestedKey isEqual:@"nestedKey1"]) {
                        expect([nestedChildProp objectForKey:@"propertyValue"]).to.equal(@"string");
                    } else if ( [nestedKey isEqual:@"nestedKey2"]) {
                        expect([nestedChildProp objectForKey:@"propertyValue"]).to.equal(@"int");
                    } else if ( [nestedKey isEqual:@"nestedKey3"]) {
                        expect([nestedChildProp objectForKey:@"propertyValue"]).to.startWith(@"list(");
                    }
                }
            }
        }
     
        expect([actualTrackSchemaBody objectForKey:@"apiKey"]).to.equal(@"testApiKey");
        expect([actualTrackSchemaBody objectForKey:@"appVersion"]).to.equal(@"testAppVersion");
        expect([actualTrackSchemaBody objectForKey:@"libVersion"]).to.equal(@"testLibVersion");
        expect([actualTrackSchemaBody objectForKey:@"libPlatform"]).to.equal(@"ios");
        expect([actualTrackSchemaBody objectForKey:@"appName"]).to.equal(@"testAppName");
        expect([actualTrackSchemaBody objectForKey:@"createdAt"]).toNot.beNil();
        expect([actualTrackSchemaBody objectForKey:@"trackingId"]).toNot.beNil();
        expect([actualTrackSchemaBody objectForKey:@"messageId"]).toNot.beNil();
    });
});

SpecEnd
