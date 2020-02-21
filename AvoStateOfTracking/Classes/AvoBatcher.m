//
//  AvoBatcher.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 18.02.2020.
//

#import "AvoBatcher.h"
#import "AvoStateOfTracking.h"

@interface AvoBatcher()

@property (readwrite, nonatomic) AvoNetworkCallsHandler * networkCallsHandler;

@property (readwrite, nonatomic) NSMutableArray * events;

@property (readwrite, nonatomic) NSLock *lock;

@property (readwrite, nonatomic) NSTimeInterval batchFlushAttemptTime;

@property (readwrite, nonatomic) NSNotificationCenter *notificationCenter;

@end

@implementation AvoBatcher

- (instancetype) initWithNetworkCallsHandler: (AvoNetworkCallsHandler *) networkCallsHandler withNotificationCenter: (NSNotificationCenter *) center {
    self = [super init];
    if (self) {
        self.lock = [[NSLock alloc] init];
        
        self.networkCallsHandler = networkCallsHandler;
        
        self.batchFlushAttemptTime = [[NSDate date] timeIntervalSince1970];
        
        [self enterForeground];
        
        self.notificationCenter = center;
        [self addObservers];
    }
    return self;
}

- (void) addObservers {
    [self.notificationCenter addObserver:self
               selector:@selector(enterBackground)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
    
    [self.notificationCenter addObserver:self
               selector:@selector(enterForeground)
                   name:UIApplicationWillEnterForegroundNotification
                 object:nil];
}

- (void)removeExtraElements {
    if ([self.events count] > 1000) {
        NSInteger extraElements = [self.events count] - 1000;
        [self.events removeObjectsInRange:NSMakeRange(0, extraElements)];
    }
}

- (void)enterBackground {
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

- (void)enterForeground {
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
    
    if (batchSize % [AvoStateOfTracking getBatchSize] == 0 || timeSinceLastFlushAttempt >= [AvoStateOfTracking getBatchFlushSeconds]) {
        [self postAllAvailableEventsAndClearCache:NO];
    }
}

- (void) postAllAvailableEventsAndClearCache: (BOOL)shouldClearCache {
    self.batchFlushAttemptTime = [[NSDate date] timeIntervalSince1970];
    
    NSArray *sendingEvents = [[NSArray alloc] initWithArray:self.events];
    self.events = [NSMutableArray new];
    
    __weak AvoBatcher *weakSelf = self;
    [self.networkCallsHandler callStateOfTrackingWithBatchBody:sendingEvents completionHandler:^(NSError * _Nullable error) {
        if (shouldClearCache) {
            [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] removeObjectForKey:[AvoBatcher cacheKey]];
        }

        if (error != nil) {
            [weakSelf.events addObjectsFromArray:sendingEvents];
        }
    }];
}

- (void) dealloc {
    [self.notificationCenter removeObserver:self];
}

+ (NSString *) suiteKey {
    return @"AvoBatcherSuiteKey";
}

+ (NSString *) cacheKey {
    return @"AvoBatcherCacheKey";
}

@end
