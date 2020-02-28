//
//  BatchingTests.m
//  AvoStateOfTracking_Tests
//
//  Created by Alex Verein on 19.02.2020.
//  Copyright © 2020 Alexey Verein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AvoStateOfTracking/AvoBatcher.h>
#import <AvoStateOfTracking/AvoStateOfTracking.h>
#import <AvoStateOfTracking/AvoNetworkCallsHandler.h>
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
            id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler withNotificationCenter:mockNotificationCenter];
            
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
            id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler withNotificationCenter:mockNotificationCenter];
            id partialMock = OCMPartialMock(sut);
            OCMStub([partialMock postAllAvailableEventsAndClearCache:@YES]).andDo(nil);
        
            // When
            [partialMock enterBackground];
           
            // Then
            NSString *actualValue = [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] valueForKey:[AvoBatcher cacheKey]];
            expect(actualValue).to.beNil();
        });
             
         it(@"Initialize empty array if nothing cached", ^{
             id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
             id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);

             AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler withNotificationCenter:mockNotificationCenter];
             id partialMock = OCMPartialMock(sut);
             OCMStub([partialMock postAllAvailableEventsAndClearCache:@YES]).andDo(nil);
            
             // Then
             expect(sut.events).toNot.beNil();
         });
                    
        it(@"Registers foreground and backround observers", ^{
            
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
            id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
        
            __block int backgroundObserversCount = 0;
            void (^theBackgroundBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
              backgroundObserversCount += 1;
            };
            OCMStub([mockNotificationCenter addObserver:[OCMArg any] selector:[OCMArg anySelector]
                                                   name:UIApplicationDidEnterBackgroundNotification object:nil]).andDo(theBackgroundBlock);
        
            __block int foregroundObserversCount = 0;
            void (^theForegroundBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
              foregroundObserversCount += 1;
            };
            OCMStub([mockNotificationCenter addObserver:[OCMArg any] selector:[OCMArg anySelector]
                                                   name:UIApplicationWillEnterForegroundNotification object:nil]).andDo(theForegroundBlock);
        
            // When
            [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler withNotificationCenter:mockNotificationCenter];
        
            // Then
            expect(backgroundObserversCount).to.equal(1);
            expect(foregroundObserversCount).to.equal(1);
        });

        it(@"Sends batch if number of events is x times batch size", ^{
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
            OCMStub([mockNetworksCallsHandler bodyForSessionStartedCall]).andReturn([NSMutableDictionary new]);
            OCMStub([mockNetworksCallsHandler bodyForTrackSchemaCall:[OCMArg any] schema:[OCMArg any]]).andReturn([NSMutableDictionary new]);
        
            __block int postBatchCount = 0;
            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
              postBatchCount += 1;
            };
            OCMStub([mockNetworksCallsHandler callStateOfTrackingWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);
        
            id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler withNotificationCenter:mockNotificationCenter];
            
            int startBatchCount = postBatchCount;
        
            // When
            for (int i = 0; i < [AvoStateOfTracking getBatchSize] - 1; i++) {
                [sut handleSessionStarted];
            }
        
            // Then
            expect(postBatchCount).to.equal(startBatchCount);
        
            // When
            [sut handleTrackSchema:@"Test" schema:[NSDictionary new]];
        
            // Then
            expect(postBatchCount).to.equal(startBatchCount + 1);
        
            // When
            for (int i = 0; i < [AvoStateOfTracking getBatchSize] - 1; i++) {
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
            [AvoStateOfTracking setBatchSize:30];
        
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
            OCMStub([mockNetworksCallsHandler bodyForSessionStartedCall]).andReturn([NSMutableDictionary new]);
            OCMStub([mockNetworksCallsHandler bodyForTrackSchemaCall:[OCMArg any] schema:[OCMArg any]]).andReturn([NSMutableDictionary new]);

            __block int postBatchCount = 0;
            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
              postBatchCount += 1;
            };
            OCMStub([mockNetworksCallsHandler callStateOfTrackingWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);

            id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler withNotificationCenter:mockNotificationCenter];
            
            int startBatchCount = postBatchCount;

            // When
            [sut handleSessionStarted];

            // Then
            expect(postBatchCount).to.equal(startBatchCount);

            // When
            sut.batchFlushAttemptTime = [[NSDate date] timeIntervalSince1970] - [AvoStateOfTracking getBatchFlushSeconds];
            [sut handleTrackSchema:@"Test" schema:[NSDictionary new]];

            // Then
            expect(postBatchCount).to.equal(startBatchCount + 1);
        });

        it(@"Clears event cache and events on success upload on foreground", ^{
            [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] setValue:@[[NSMutableDictionary new]] forKey:[AvoBatcher cacheKey]];
        
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
            id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);

            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
                __unsafe_unretained void (^batchBody)(NSError *);
                [invocation getArgument:&batchBody atIndex:3];
                
                batchBody(nil);
            };
            OCMStub([mockNetworksCallsHandler callStateOfTrackingWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);
        
            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler withNotificationCenter:mockNotificationCenter];
         
            // Then
            NSString *actualValue = [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] valueForKey:[AvoBatcher cacheKey]];
            expect(actualValue).to.beNil();
            expect([sut.events count]).to.equal(0);
        });

        it(@"Clears event cache and puts events back to events list if sending fails", ^{
            [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] setValue:@[[NSMutableDictionary new]] forKey:[AvoBatcher cacheKey]];
        
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
            void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
                __unsafe_unretained void (^batchBody)(NSError *);
                [invocation getArgument:&batchBody atIndex:3];
                
                batchBody([NSError new]);
            };
            OCMStub([mockNetworksCallsHandler callStateOfTrackingWithBatchBody:[OCMArg any] completionHandler:[OCMArg any]]).andDo(theBlock);
        
            id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler withNotificationCenter:mockNotificationCenter];
        
            // Then
            NSString *actualValue = [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] valueForKey:[AvoBatcher cacheKey]];
            expect(actualValue).to.beNil();
            expect([sut.events count]).to.equal(1);
        });

        it(@"Sets flush attempt timestamp", ^{
            id mockNetworksCallsHandler = OCMClassMock([AvoNetworkCallsHandler class]);
             OCMStub([mockNetworksCallsHandler bodyForSessionStartedCall]).andReturn([NSMutableDictionary new]);
            id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);

            AvoBatcher * sut = [[AvoBatcher alloc] initWithNetworkCallsHandler:mockNetworksCallsHandler withNotificationCenter:mockNotificationCenter];
            sut.batchFlushAttemptTime = 0;
            
            // When
            for (int i = 0; i < [AvoStateOfTracking getBatchSize]; i++) {
               [sut handleSessionStarted];
            }
        
            // Then
            double now = [[NSDate date] timeIntervalSince1970];
            expect(sut.batchFlushAttemptTime).toNot.equal(0);
            expect(sut.batchFlushAttemptTime).to.beLessThan(now);
            expect(sut.batchFlushAttemptTime).to.beGreaterThan(now - 1);
        });

    });

SpecEnd
