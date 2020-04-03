//
//  BatchingTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 19.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AvoInspector/AvoBatcher.h>
#import <AvoInspector/AvoInspector.h>
#import <AvoInspector/AvoNetworkCallsHandler.h>
#import <OCMock/OCMock.h>

@interface AvoBatcher ()

- (void) postAllAvailableEventsAndClearCache: (BOOL)shouldClearCache;

- (void)enterBackground;
- (void)enterForeground;

@property (readwrite, nonatomic) NSMutableArray * events;
@property (readwrite, nonatomic) NSTimeInterval batchFlushAttemptTime;

+ (NSString *) suiteKey;
+ (NSString *) cacheKey;

@end

SpecBegin(Batching)
    describe(@"Batching", ^{

        beforeEach(^{
            [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] removeObjectForKey:[AvoBatcher cacheKey]];
        });
             
        it(@"Saves up to 1000 events on background and restores on foreground", ^{
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            [sut enterForeground];
        
            id partialMock = OCMPartialMock(sut);
            __block int postBatchCount = 0;
            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
              postBatchCount += 1;
            };
            OCMStub([partialMock postAllAvailableEventsAndClearCache:@YES]).andDo(theBlock);
      
            for (int i = 0; i < 5600; i++) {
                [sut.events addObject:@[[[NSString alloc] initWithFormat:@"%d", i]]];
            }
            
            // When
            [sut enterBackground];
            [sut enterForeground];
        
            // Then
            expect([sut.events count]).to.equal(1000);
            expect(postBatchCount).to.equal(1);
        });
             
        it(@"Do not write cache if no events are present", ^{
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            id partialMock = OCMPartialMock(sut);
            OCMStub([partialMock postAllAvailableEventsAndClearCache:YES]).andDo(nil);
        
            // When
            [partialMock enterBackground];
           
            // Then
            NSString *actualValue = [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] valueForKey:[AvoBatcher cacheKey]];
            expect(actualValue).to.beNil();
        });
             
         it(@"Initialize empty array if nothing cached", ^{
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            id partialMock = OCMPartialMock(sut);
            OCMStub([partialMock postAllAvailableEventsAndClearCache:YES]).andDo(nil);
            [sut enterForeground];
            
            // Then
            expect(sut.events).toNot.beNil();
         });
             
         it(@"Not calls network if nothing is cached", ^{
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
            OCMReject([mockNetworksCallsHandler callInspectorWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            id partialMock = OCMPartialMock(sut);
            OCMStub([partialMock postAllAvailableEventsAndClearCache:YES]).andDo(nil);
         });

        it(@"Sends batch if number of events is x times batch size", ^{
            [AvoInspector setBatchSize:10];
            
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
            OCMStub([mockNetworksCallsHandler bodyForSessionStartedCall]).andReturn([NSMutableDictionary new]);
            OCMStub([mockNetworksCallsHandler bodyForTrackSchemaCall:[OCMArg any] schema:[OCMArg any]]).andReturn(@{@"type": @"test"});
        
            __block int postBatchCount = 0;
            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
              postBatchCount += 1;
            };
            OCMStub([mockNetworksCallsHandler callInspectorWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            [sut enterForeground];
            int startBatchCount = postBatchCount;
        
            // When
            for (int i = 0; i < [AvoInspector getBatchSize] - 1; i++) {
                [sut handleSessionStarted];
            }
        
            // Then
            expect(postBatchCount).to.equal(startBatchCount);
        
            // When
            [sut handleTrackSchema:@"Test" schema:[NSDictionary new]];
        
            // Then
            expect(postBatchCount).to.equal(startBatchCount + 1);
        
            // When
            for (int i = 0; i < [AvoInspector getBatchSize] - 1; i++) {
                [sut handleTrackSchema:@"Test" schema:[NSDictionary new]];
            }
        
            // Then
            expect(postBatchCount).to.equal(startBatchCount + 1);
        
            // When
            [sut handleSessionStarted];
        
            // Then
            expect(postBatchCount).to.equal(startBatchCount + 2);
        });

        it(@"Sends batch if time has come", ^{
            [AvoInspector setBatchSize:30];
        
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
            OCMStub([mockNetworksCallsHandler bodyForSessionStartedCall]).andReturn([NSMutableDictionary new]);
            OCMStub([mockNetworksCallsHandler bodyForTrackSchemaCall:[OCMArg any] schema:[OCMArg any]]).andReturn(@{@"type": @"test"});

            __block int postBatchCount = 0;
            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
              postBatchCount += 1;
            };
            OCMStub([mockNetworksCallsHandler callInspectorWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            [sut enterForeground];
            int startBatchCount = postBatchCount;

            // When
            [sut handleSessionStarted];

            // Then
            expect(postBatchCount).to.equal(startBatchCount);

            // When
            sut.batchFlushAttemptTime = [[NSDate date] timeIntervalSince1970] - [AvoInspector getBatchFlushSeconds];
            [sut handleTrackSchema:@"Test" schema:[NSDictionary new]];

            // Then
            expect(postBatchCount).to.equal(startBatchCount + 1);
        });
             
        it(@"Sets session id on new session", ^{
            AvoNetworkCallsHandler * networkCallsHandler = [AvoNetworkCallsHandler new];
            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:networkCallsHandler];
        
            expect(networkCallsHandler.sessionId).to.equal(nil);
        
            [sut handleSessionStarted];
        
            expect(networkCallsHandler.sessionId).toNot.equal(nil);
        });

        it(@"Clears event cache and events on success upload on foreground", ^{
            [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] setValue:@[[NSMutableDictionary new]] forKey:[AvoBatcher cacheKey]];
        
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);

            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
                __unsafe_unretained void (^batchBody)(NSError *);
                [invocation getArgument:&batchBody atIndex:3];
                
                batchBody(nil);
            };
            OCMStub([mockNetworksCallsHandler callInspectorWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);
        
            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            [sut enterForeground];
        
            // Then
            NSString *actualValue = [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] valueForKey:[AvoBatcher cacheKey]];
            expect(actualValue).to.beNil();
            expect([sut.events count]).to.equal(0);
        });

        it(@"Clears event cache and puts events back to events list if sending fails", ^{
            [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] setValue:@[@{@"type": @"test"}] forKey:[AvoBatcher cacheKey]];
        
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
                __unsafe_unretained void (^batchBody)(NSError *);
                [invocation getArgument:&batchBody atIndex:3];
                
                batchBody([NSError new]);
            };
            OCMStub([mockNetworksCallsHandler callInspectorWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            [sut enterForeground];
        
            // Then
            NSString *actualValue = [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] valueForKey:[AvoBatcher cacheKey]];
            expect(actualValue).to.beNil();
            expect([sut.events count]).to.equal(1);
        });

        it(@"Sets flush attempt timestamp", ^{
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
             OCMStub([mockNetworksCallsHandler bodyForSessionStartedCall]).andReturn(@{@"type": @"test"});

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            sut.batchFlushAttemptTime = 0;
            [sut enterForeground];
            
            // When
            for (int i = 0; i < [AvoInspector getBatchSize]; i++) {
               [sut handleSessionStarted];
            }
        
            // Then
            double now = [[NSDate date] timeIntervalSince1970];
            expect(sut.batchFlushAttemptTime).toNot.equal(0);
            expect(sut.batchFlushAttemptTime).to.beLessThan(now);
            expect(sut.batchFlushAttemptTime).to.beGreaterThan(now - 1);
        });

         it(@"Filters malformed events before sending", ^{
             id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
             OCMStub([mockNetworksCallsHandler bodyForSessionStartedCall]).andReturn(@{@"no-type": @"malformed-test"});

             AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler];
            
            __block int postBatchCount = 0;
            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
              postBatchCount += 1;
            };
            OCMStub([mockNetworksCallsHandler callInspectorWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);
        
             // When
            [sut.events addObject:@""];
            for (int i = 0; i < 10 * [AvoInspector getBatchSize]; i++) {
                [sut handleSessionStarted];
            }
         
             // Then
             expect(postBatchCount).to.equal(0);
         });
    });

SpecEnd
