//
//  AvoBatcher.m
//  AvoInspector
//
//  Created by Alex Verein on 18.02.2020.
//

#import "AvoBatcher.h"
#import "AvoInspector.h"

@interface AvoBatcher()

@property (readwrite, nonatomic) AvoNetworkCallsHandler * networkCallsHandler;

@property (readwrite, nonatomic) NSMutableArray * events;

@property (readwrite, nonatomic) NSLock *lock;

@property (readwrite, nonatomic) NSTimeInterval batchFlushAttemptTime;

@end

@implementation AvoBatcher

- (instancetype) initWithNetworkCallsHandler: (AvoNetworkCallsHandler *) networkCallsHandler {
    self = [super init];
    if (self) {
        self.lock = [[NSLock alloc] init];
        self.events = [NSMutableArray new];
        self.networkCallsHandler = networkCallsHandler;
        
        self.batchFlushAttemptTime = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

- (void) removeExtraElements {
    if ([self.events count] > 1000) {
        NSInteger extraElements = [self.events count] - 1000;
        [self.events removeObjectsInRange:NSMakeRange(0, extraElements)];
    }
}

- (void) enterBackground {
    if ([self.events count] == 0) {
        return;
    }
    
    [self.lock lock];
     @try {
         [self removeExtraElements];
     }
     @finally {
         [self.lock unlock];
     }
    
    [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] setValue:self.events forKey:[AvoBatcher cacheKey]];
}

- (void) enterForeground {
    self.events = [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] objectForKey:[AvoBatcher cacheKey]];
    
    if (self.events == nil) {
        self.events = [NSMutableArray new];
    } else {
        self.events = [[NSMutableArray alloc] initWithArray:self.events];
    }
    
    [self postAllAvailableEventsAndClearCache:YES];
}

- (void) handleSessionStarted {
    NSMutableDictionary * sessionStartedBody = [self.networkCallsHandler bodyForSessionStartedCall];
    
    [self saveEvent:sessionStartedBody];
    
    [self checkIfBatchNeedsToBeSent];
}

// schema is [ String : AvoEventSchemaType ]
- (void) handleTrackSchema: (NSString *) eventName schema: (NSDictionary<NSString *, AvoEventSchemaType *> *) schema {
    NSMutableDictionary * trackSchemaBody = [self.networkCallsHandler bodyForTrackSchemaCall:eventName schema: schema];
    
    [self saveEvent:trackSchemaBody];
    
    if ([AvoInspector isLogging]) {
        
        NSString * schemaString = @"";
        
        for(NSString *key in [schema allKeys]) {
            NSString *value = [[schema objectForKey:key] name];
            NSString *entry = [NSString stringWithFormat:@"\t\"%@\": \"%@\";\n", key, value];
            schemaString = [schemaString stringByAppendingString:entry];
        }
        
        NSLog(@"Avo Inspector: Saved event %@ with schema {\n%@}", eventName, schemaString);
    }
    
    [self checkIfBatchNeedsToBeSent];
}

- (void)saveEvent:(NSMutableDictionary *)trackSchemaBody {
    [self.lock lock];
    @try {
        [self.events addObject:trackSchemaBody];
        [self removeExtraElements];
    }
    @finally {
        [self.lock unlock];
    }
}

- (void) checkIfBatchNeedsToBeSent {
    
    NSUInteger batchSize = [self.events count];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeSinceLastFlushAttempt = now - self.batchFlushAttemptTime;
    
    bool sendBySize = batchSize % [AvoInspector getBatchSize] == 0;
    bool sendByTime = timeSinceLastFlushAttempt >= [AvoInspector getBatchFlushSeconds];
    
    if (sendBySize || sendByTime) {
        [self postAllAvailableEventsAndClearCache:NO];
    }
}

- (void) postAllAvailableEventsAndClearCache: (BOOL)shouldClearCache {
    
    [self filterEvents];
    
    if ([self.events count] == 0) {
        if (shouldClearCache) {
            [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] removeObjectForKey:[AvoBatcher cacheKey]];
        }
        return;
    }
    
    self.batchFlushAttemptTime = [[NSDate date] timeIntervalSince1970];
    
    NSArray *sendingEvents = [[NSArray alloc] initWithArray:self.events];
    self.events = [NSMutableArray new];
    
    __weak AvoBatcher *weakSelf = self;
    [self.networkCallsHandler callInspectorWithBatchBody:sendingEvents completionHandler:^(NSError * _Nullable error) {
        if (shouldClearCache) {
            [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] removeObjectForKey:[AvoBatcher cacheKey]];
        }

        if (error != nil) {
            [weakSelf.events addObjectsFromArray:sendingEvents];
        }
    }];
}

- (void) filterEvents {
    NSMutableArray *discardedItems = [NSMutableArray array];
    
    for (id event in self.events) {
        if (![event isKindOfClass:[NSDictionary class]] || [event objectForKey:@"type"] == nil) {
            [discardedItems addObject:event];
        }
    }
    
    [self.events removeObjectsInArray:discardedItems];
}

+ (NSString *) suiteKey {
    return @"AvoBatcherSuiteKey";
}

+ (NSString *) cacheKey {
    return @"AvoBatcherCacheKey";
}

@end
