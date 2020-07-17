//
//  DeduplicatorTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 13.07.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <AvoInspector/AvoDeduplicator.h>
#import <AvoInspector/AvoInspector.h>
#import <AvoInspector/AvoList.h>
#import <AvoInspector/AvoString.h>
#import <AvoInspector/AvoBoolean.h>
#import <AvoInspector/AvoNull.h>
#import <AvoInspector/AvoInt.h>
#import <AvoInspector/AvoFloat.h>

@interface AvoInspector ()

-(NSDictionary<NSString *, AvoEventSchemaType *> *) avoFunctionTrackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params;

@end

@interface AvoDeduplicator()

- (void) clear;

@end

SpecBegin(Deduplicator)
describe(@"Deduplication of same events coming from manual tracking and Avo functions", ^{
    
    beforeEach(^{
        [[AvoDeduplicator sharedDeduplicator] clear];
    });
    
    it(@"Detects duplication when tracking in avo function and then manually", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
       
        NSMutableArray * mutableArray = [NSMutableArray new];
        [mutableArray addObject:@"Hello world"];
        [mutableArray addObject:NSNull.null];
        [mutableArray addObject:@42];
        [mutableArray addObject:@41.1f];
        [mutableArray addObject:@YES];
       
        [testParams setObject:mutableArray forKey:@"string array key"];
       
        AvoDeduplicator * sut = [AvoDeduplicator sharedDeduplicator];
        
        bool avoFunctionTrack = [sut shouldRegisterEvent:@"Test 0" eventParams:testParams fromAvoFunction:YES];
        bool manualTrack = [sut shouldRegisterEvent:@"Test 0" eventParams:testParams fromAvoFunction:NO];

        expect(avoFunctionTrack).to.equal(YES);
        expect(manualTrack).to.equal(NO);
    });
    
    it(@"Detects duplication when tracking in avo function and then schema tracked manually", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
       
        NSMutableArray * mutableArray = [NSMutableArray new];
        [mutableArray addObject:@"Hello world"];
        [mutableArray addObject:NSNull.null];
        [mutableArray addObject:@42];
        [mutableArray addObject:@41.1f];
        [mutableArray addObject:@YES];
       
        [testParams setObject:mutableArray forKey:@"string array key"];
        
        NSMutableDictionary * testSchema = [NSMutableDictionary new];
        
        AvoList * avoList = [[AvoList alloc] init];
        [avoList.subtypes addObject:[AvoString new]];
        [avoList.subtypes addObject:[AvoNull new]];
        [avoList.subtypes addObject:[AvoFloat new]];
        [avoList.subtypes addObject:[AvoInt new]];
        [avoList.subtypes addObject:[AvoBoolean new]];
        
        [testSchema setObject:avoList forKey:@"string array key"];
       
        AvoDeduplicator * sut = [AvoDeduplicator sharedDeduplicator];
        
        bool avoFunctionTrack = [sut shouldRegisterEvent:@"Test 0" eventParams:testParams fromAvoFunction:YES];
        bool manualSchemaTrack = [sut shouldRegisterSchemaFromManually:@"Test 0" schema:testSchema];
        
        expect(avoFunctionTrack).to.equal(YES);
        expect(manualSchemaTrack).to.equal(NO);

    });
    
    it(@"Inspector deduplicates when event tracked manually and then in avo function", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
       
        NSMutableArray * mutableArray = [NSMutableArray new];
        [mutableArray addObject:@"Hello world"];
        [mutableArray addObject:NSNull.null];
        [mutableArray addObject:@42];
        [mutableArray addObject:@41.1f];
        [mutableArray addObject:@YES];
       
        [testParams setObject:mutableArray forKey:@"string array key"];
       
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" env: AvoInspectorEnvDev];
        
        NSDictionary * manualTrack = [sut avoFunctionTrackSchemaFromEvent:@"Test 0" eventParams:testParams];
        NSDictionary * avoFunctionTrack = [sut trackSchemaFromEvent:@"Test 0" eventParams:testParams];
        NSDictionary * manualTrackAgain = [sut avoFunctionTrackSchemaFromEvent:@"Test 0" eventParams:testParams];
        
        expect(manualTrack).toNot.equal([NSMutableDictionary new]);
        expect(avoFunctionTrack).to.equal([NSMutableDictionary new]);
        expect(manualTrackAgain).toNot.equal([NSMutableDictionary new]);
    });
    
    it(@"Inspector deduplicates when event tracked in avo function and then manually", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
       
        NSMutableArray * mutableArray = [NSMutableArray new];
        [mutableArray addObject:@"Hello world"];
        [mutableArray addObject:NSNull.null];
        [mutableArray addObject:@42];
        [mutableArray addObject:@41.1f];
        [mutableArray addObject:@YES];
       
        [testParams setObject:mutableArray forKey:@"string array key"];
       
        AvoInspector * sut = [[AvoInspector alloc] initWithApiKey: @"apiKey" env: AvoInspectorEnvDev];
        
        NSDictionary * avoFunctionTrack = [sut trackSchemaFromEvent:@"Test 0" eventParams:testParams];
        NSDictionary * manualTrack = [sut avoFunctionTrackSchemaFromEvent:@"Test 0" eventParams:testParams];
        NSDictionary * avoFunctionTrackAgain = [sut trackSchemaFromEvent:@"Test 0" eventParams:testParams];
        
        expect(avoFunctionTrack).toNot.equal([NSMutableDictionary new]);
        expect(manualTrack).to.equal([NSMutableDictionary new]);
        expect(avoFunctionTrackAgain).toNot.equal([NSMutableDictionary new]);
    });
    
    it(@"Allows to manually track 2 same events", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
       
        NSMutableArray * mutableArray = [NSMutableArray new];
        [mutableArray addObject:@"Hello world"];
        [mutableArray addObject:NSNull.null];
        [mutableArray addObject:@42];
        [mutableArray addObject:@41.1f];
        [mutableArray addObject:@YES];
       
        [testParams setObject:mutableArray forKey:@"string array key"];
       
        AvoDeduplicator * sut = [AvoDeduplicator sharedDeduplicator];
        
        bool manualTrack = [sut shouldRegisterEvent:@"Test 2" eventParams:testParams fromAvoFunction:NO];
        bool avoFunctionTrack = [sut shouldRegisterEvent:@"Test 2" eventParams:testParams fromAvoFunction:YES];
        bool manualTrackAgain = [sut shouldRegisterEvent:@"Test 2" eventParams:testParams fromAvoFunction:NO];
        
        expect(manualTrack).to.equal(YES);
        expect(avoFunctionTrack).to.equal(NO);
        expect(manualTrackAgain).to.equal(YES);
    });
    
    it(@"Detects duplication when tracking manually and then in avo function", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
       
        NSMutableArray * mutableArray = [NSMutableArray new];
        [mutableArray addObject:@"Hello world"];
        [mutableArray addObject:NSNull.null];
        [mutableArray addObject:@42];
        [mutableArray addObject:@41.1f];
        [mutableArray addObject:@YES];
       
        [testParams setObject:mutableArray forKey:@"string array key"];
       
        AvoDeduplicator * sut = [AvoDeduplicator sharedDeduplicator];
        
        bool manualTrack = [sut shouldRegisterEvent:@"Test 1" eventParams:testParams fromAvoFunction:NO];
        bool avoFunctionTrack = [sut shouldRegisterEvent:@"Test 1" eventParams:testParams fromAvoFunction:YES];
        
        expect(manualTrack).to.equal(YES);
        expect(avoFunctionTrack).to.equal(NO);
    });
    
    it(@"Does not deduplicate if more than 300ms pass", ^{
        NSMutableDictionary * testParams = [NSMutableDictionary new];
       
        NSMutableArray * mutableArray = [NSMutableArray new];
        [mutableArray addObject:@"Hello world"];
        [mutableArray addObject:NSNull.null];
        [mutableArray addObject:@42];
        [mutableArray addObject:@41.1f];
        [mutableArray addObject:@YES];
       
        [testParams setObject:mutableArray forKey:@"string array key"];
       
        AvoDeduplicator * sut = [AvoDeduplicator sharedDeduplicator];
        
        bool avoFunctionTrack = [sut shouldRegisterEvent:@"Test 1" eventParams:testParams fromAvoFunction:YES];
        
        [NSThread sleepForTimeInterval:0.3f];
        
        bool manualTrack = [sut shouldRegisterEvent:@"Test 1" eventParams:testParams fromAvoFunction:NO];
        
        [NSThread sleepForTimeInterval:0.3f];
        
        bool avoFunctionTrackAgain = [sut shouldRegisterEvent:@"Test 1" eventParams:testParams fromAvoFunction:YES];
        
        expect(avoFunctionTrack).to.equal(YES);
        expect(manualTrack).to.equal(YES);
        expect(avoFunctionTrackAgain).to.equal(YES);
    });
});
SpecEnd
