//
//  AvoBatcher.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 18.02.2020.
//

#import "AvoBatcher.h"

@interface AvoBatcher()

@property (readwrite, nonatomic) AvoNetworkCallsHandler * networkCallsHandler;

@property (readwrite, nonatomic) NSMutableArray * events;

@property (readwrite, nonatomic) NSLock *lock;

@property (readwrite, nonatomic) NSTimeInterval batchFlushTime;

@end

@implementation AvoBatcher

static NSInteger maxBatchSize = 20;
static NSInteger maxBatchTime = 30;

- (instancetype) initWithNetworkCallsHandler: (AvoNetworkCallsHandler *) networkCallsHandler {
    self = [super init];
    if (self) {
        self.lock = [[NSLock alloc] init];
        
        self.networkCallsHandler = networkCallsHandler;
        
        self.events = [NSMutableArray new];
        
        self.batchFlushTime = [[NSDate date] timeIntervalSince1970];
        
        [self enterForeground];
        [self addObservers];
    }
    return self;
}

- (void) addObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(enterBackground)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(enterForeground)
                   name:UIApplicationWillEnterForegroundNotification
                 object:nil];
}

- (void)enterBackground {
    [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] setValue:self.events forKey:[AvoBatcher cacheKey]];
}

- (void)enterForeground {
    self.events = [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] objectForKey:[AvoBatcher cacheKey]];
    
    [self postAllAvailableEventsAndClearCache:YES];
}

- (void) handleSessionStarted {
    NSMutableDictionary * sessionStartedBody = [self.networkCallsHandler bodyForSessionStartedCall];
    
    [self.lock lock];
    @try {
        [self.events addObject:sessionStartedBody];
    }
    @finally {
        [self.lock unlock];
    }
    
    [self checkIfBatchNeedsToBeSent];
}

// schema is [ String : AvoEventSchemaType ]
- (void) handleTrackSchema: (NSString *) eventName schema: (NSDictionary<NSString *, AvoEventSchemaType *> *) schema {
    NSMutableDictionary * trackSchemaBody = [self.networkCallsHandler bodyForTrackSchemaCall:eventName schema: schema];
    [self.lock lock];
    @try {
        [self.events addObject:trackSchemaBody];
    }
    @finally {
       [self.lock unlock];
    }
    
    [self checkIfBatchNeedsToBeSent];
}

- (void) checkIfBatchNeedsToBeSent {
    
    NSUInteger batchSize = [self.events count];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeSinceLastFlush = now - self.batchFlushTime;
    
    if (batchSize >= maxBatchSize || timeSinceLastFlush >= maxBatchTime) {
        [self postAllAvailableEventsAndClearCache:NO];
    }
}

- (void) postAllAvailableEventsAndClearCache: (BOOL)shouldClearCache {
    self.batchFlushTime = [[NSDate date] timeIntervalSince1970];
    
    [self.networkCallsHandler callStateOfTrackingWithBatchBody:self.events completionHandler:^{
        if (shouldClearCache) {
            [[[NSUserDefaults alloc] initWithSuiteName:[AvoBatcher suiteKey]] removeObjectForKey:[AvoBatcher cacheKey]];
        }
    }];
    
    self.events = [NSMutableArray new];
}

- (void) dealloc {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

+ (NSString *) suiteKey {
    return @"AvoBatcherSuiteKey";
}

+ (NSString *) cacheKey {
    return @"AvoBatcherCacheKey";
}

@end
