//
//  AvoInspector.m
//  AvoInspector
//
//  Created by Alex Verein on 28.01.2020.
//

#import "AvoInspector.h"
#import "AvoEventSchemaType.h"
#import "AvoNetworkCallsHandler.h"
#import "AvoBatcher.h"
#import "AvoDeduplicator.h"
#import "AvoSchemaExtractor.h"
#import "AvoEventSpecFetcher.h"
#import "AvoEventSpecFetchTypes.h"
#import "AvoEventSpecCache.h"
#import "AvoEventValidator.h"
#import "AvoAnonymousId.h"

@interface AvoStorageImpl : NSObject <AvoStorage>
@end

@implementation AvoStorageImpl
- (BOOL)isInitialized { return YES; }
- (NSString *)getItem:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}
- (void)setItem:(NSString *)key :(NSString *)value {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}
@end

@interface AvoInspector ()

@property (readwrite, nonatomic) NSString * appVersion;
@property (readwrite, nonatomic) NSString * appName;
@property (readwrite, nonatomic) NSString * libVersion;
@property (readwrite, nonatomic) NSString * apiKey;

@property (readwrite, nonatomic) AvoNetworkCallsHandler *networkCallsHandler;
@property (readwrite, nonatomic) AvoBatcher *avoBatcher;
@property (readwrite, nonatomic) AvoDeduplicator *avoDeduplicator;
@property (readwrite, nonatomic) AvoSchemaExtractor *avoSchemaExtractor;

@property (readwrite, nonatomic) NSNotificationCenter *notificationCenter;

@property (readwrite, nonatomic) AvoInspectorEnv env;

@property (readwrite, nonatomic, nullable) AvoEventSpecFetcher *eventSpecFetcher;
@property (readwrite, nonatomic, nullable) AvoEventSpecCache *eventSpecCache;
@property (readwrite, nonatomic, nullable) NSString *currentBranchId;
@property (readwrite, nonatomic, nullable) NSString *publicEncryptionKey;

@end

@implementation AvoInspector

static BOOL logging = NO;
static int maxBatchSize = 30;
static int batchFlushTime = 30;

+ (id<AvoStorage>)avoStorage {
    static AvoStorageImpl *sharedStorage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStorage = [[AvoStorageImpl alloc] init];
    });
    return sharedStorage;
}

+ (BOOL) isLogging {
    return logging;
}

+ (void) setLogging: (BOOL) isLogging {
    logging = isLogging;
}

+ (int) getBatchSize {
    return maxBatchSize;
}

+ (void) setBatchSize: (int) newBatchSize {
    if (newBatchSize < 1) {
        maxBatchSize = 1;
    } else {
        maxBatchSize = newBatchSize;
    }
}

+ (int) getBatchFlushSeconds {
    return batchFlushTime;
}

+ (void) setBatchFlushSeconds: (int) newBatchFlushSeconds {
    batchFlushTime = newBatchFlushSeconds;
}

static const NSTimeInterval EVENT_SPEC_FETCH_TIMEOUT = 5.0;

-(instancetype) initWithApiKey: (NSString *) apiKey envInt: (NSNumber *) envInt {
    self = [self initWithApiKey:apiKey env:[envInt intValue]];
    return self;
}

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env proxyEndpoint: (NSString *) proxyEndpoint {
    return [self initWithApiKey:apiKey env:env proxyEndpoint:proxyEndpoint publicEncryptionKey:nil];
}

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env publicEncryptionKey: (NSString * _Nullable) publicEncryptionKey {
    return [self initWithApiKey:apiKey env:env proxyEndpoint:@"https://api.avo.app/inspector/v1/track" publicEncryptionKey:publicEncryptionKey];
}

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env proxyEndpoint: (NSString *) proxyEndpoint publicEncryptionKey: (NSString * _Nullable) publicEncryptionKey {
    self = [super init];
    if (self) {
        if (env != AvoInspectorEnvProd && env != AvoInspectorEnvDev && env != AvoInspectorEnvStaging) {
            self.env = AvoInspectorEnvDev;
        } else {
            self.env = env;
        }

        self.publicEncryptionKey = publicEncryptionKey;
        self.avoSchemaExtractor = [AvoSchemaExtractor new];

        if (env == AvoInspectorEnvDev) {
            [AvoInspector setBatchSize:1];
            [AvoInspector setLogging:YES];
        } else {
            [AvoInspector setBatchSize:30];
            [AvoInspector setBatchFlushSeconds:30];
            [AvoInspector setLogging:NO];
        }

        self.appName = [[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleIdentifierKey];
        self.appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
        self.libVersion = @"2.2.0";

        self.notificationCenter = [NSNotificationCenter defaultCenter];

        self.networkCallsHandler = [[AvoNetworkCallsHandler alloc] initWithApiKey:apiKey appName:self.appName appVersion:self.appVersion libVersion:self.libVersion env:(int)self.env endpoint:proxyEndpoint publicEncryptionKey:publicEncryptionKey];
        self.avoBatcher = [[AvoBatcher alloc] initWithNetworkCallsHandler:self.networkCallsHandler];

        self.avoDeduplicator = [AvoDeduplicator sharedDeduplicator];

        self.apiKey = apiKey;

        if (publicEncryptionKey != nil && publicEncryptionKey.length > 0 && env != AvoInspectorEnvProd) {
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Property value encryption enabled");
            }
        }

        // Initialize event spec fetcher and cache for non-prod environments
        // streamId is the anonymous ID, obtained internally from AvoAnonymousId
        if (self.env != AvoInspectorEnvProd) {
            NSString *streamId = [AvoAnonymousId anonymousId];
            if (streamId != nil && streamId.length > 0 && ![streamId isEqualToString:@"unknown"]) {
                NSString *envString = [AvoNetworkCallsHandler formatTypeToString:(int)self.env];
                self.eventSpecFetcher = [[AvoEventSpecFetcher alloc] initWithTimeout:EVENT_SPEC_FETCH_TIMEOUT env:envString];
                self.eventSpecCache = [[AvoEventSpecCache alloc] init];

                if ([AvoInspector isLogging]) {
                    NSLog(@"[avo] Avo Inspector: Event spec fetcher initialized for env: %@, streamId: %@", envString, streamId);
                }
            }
        }

        [self enterForeground];

        [self addObservers];
    }
    return self;
}

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env {
    self = [self initWithApiKey:apiKey env:env proxyEndpoint:@"https://api.avo.app/inspector/v1/track" publicEncryptionKey:nil];
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

- (void)enterBackground {
    @try {
        [self.avoBatcher enterBackground];
    }
    @catch (NSException *exception) {
        [self printAvoGenericError:exception];
    }
}

- (void)enterForeground {
    @try {
        [self.avoBatcher enterForeground];
    }
    @catch (NSException *exception) {
        [self printAvoGenericError:exception];
    }
}

// internal API
-(NSDictionary<NSString *, AvoEventSchemaType *> *) avoFunctionTrackSchemaFromEvent:(NSString *) eventName eventParams:(NSMutableDictionary<NSString *, id> *) params {
    @try {
        if ([self.avoDeduplicator shouldRegisterEvent:eventName eventParams:params fromAvoFunction:YES]) {
            NSMutableDictionary * objcParams = [NSMutableDictionary new];
            
            [params enumerateKeysAndObjectsUsingBlock:^(id paramName, id paramValue, BOOL* stop) {
                [objcParams setObject:paramValue forKey:paramName];
            }];
            
            NSString * eventId = [objcParams objectForKey:@"avoFunctionEventId"];
            [objcParams removeObjectForKey:@"avoFunctionEventId"];
            NSString * eventHash = [objcParams objectForKey:@"avoFunctionEventHash"];
            [objcParams removeObjectForKey:@"avoFunctionEventHash"];
            
            return [self internalTrackSchemaFromEvent:eventName eventParams:objcParams eventId:eventId eventHash:eventHash];
        } else {
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Deduplicated event %@", eventName);
            }
            return [NSMutableDictionary new];
        }
    }
    @catch (NSException *exception) {
        [self printAvoGenericError:exception];
        return [NSMutableDictionary new];
    }
}

// params are [ String : Any ]
-(NSDictionary<NSString *, AvoEventSchemaType *> *) trackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params {
    @try {
        if ([self.avoDeduplicator shouldRegisterEvent:eventName eventParams:params fromAvoFunction:NO]) {
            return [self internalTrackSchemaFromEvent:eventName eventParams:params eventId:nil eventHash:nil];
        } else {
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Deduplicated event %@", eventName);
            }
            return [NSMutableDictionary new];
        }
    }
    @catch (NSException *exception) {
        [self printAvoGenericError:exception];
        return [NSMutableDictionary new];
    }
}


// params are [ String : Any ]
-(NSDictionary<NSString *, AvoEventSchemaType *> *) internalTrackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params eventId:(NSString *) eventId eventHash:(NSString *) eventHash {

    @try {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Supplied event %@ with params %@", eventName, [params description]);
        }

        NSDictionary * schema = [self.avoSchemaExtractor extractSchema:params];

        [self fetchAndValidateAsync:eventName eventParams:params eventSchema:schema eventId:eventId eventHash:eventHash eventProperties:params];

        return schema;
    }
    @catch (NSException *exception) {
        [self.avoSchemaExtractor printAvoParsingError:exception];
        return [NSMutableDictionary new];
    }
}

// schema is [ String : AvoEventSchemaType ]
-(void) trackSchema:(NSString *) eventName eventSchema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema {
    @try {
        if ([self.avoDeduplicator shouldRegisterSchemaFromManually:eventName schema:schema]) {
            [self internalTrackSchema:eventName eventSchema:schema eventId:nil eventHash:nil eventProperties:nil];
        } else {
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Deduplicated schema %@", eventName);
            }
        }
    }
    @catch (NSException *exception) {
        [self printAvoGenericError:exception];
    }
}

-(void) internalTrackSchema:(NSString *) eventName eventSchema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString *) eventId eventHash:(NSString *) eventHash eventProperties:(NSDictionary * _Nullable) eventProperties {

    @try {
        for(NSString *key in [schema allKeys]) {
            if (![[schema objectForKey:key] isKindOfClass:[AvoEventSchemaType class]]) {
                [NSException raise:@"Schema types should be of type AvoEventSchemaType" format:@"Provided %@", [[[schema objectForKey:key] class] description]];
            }
        }

        if (eventProperties != nil && eventProperties.count > 0) {
            [self.avoBatcher handleTrackSchema:eventName schema:schema eventId:eventId eventHash:eventHash eventProperties:eventProperties];
        } else {
            [self.avoBatcher handleTrackSchema:eventName schema:schema eventId:eventId eventHash:eventHash];
        }
    }
    @catch (NSException *exception) {
        [self.avoSchemaExtractor printAvoParsingError:exception];
    }
}

-(NSDictionary<NSString *, AvoEventSchemaType *> *) extractSchema:(NSDictionary<NSString *, id> *) eventParams {
    if (![self.avoDeduplicator hasSeenEventParams:eventParams checkInAvoFunctions:YES]) {
        NSLog(@"[avo]     WARNING! You are trying to extract schema shape that was just reported by your Avo functions. This is an indicator of duplicate inspector reporting. Please reach out to support@avo.app for advice if you are not sure how to handle this.");
    }
    
    return [self.avoSchemaExtractor extractSchema:eventParams];
}

#pragma mark - Event Spec Fetch & Validate

-(void)fetchAndValidateAsync:(NSString *)eventName eventParams:(NSDictionary<NSString *, id> *)params eventSchema:(NSDictionary<NSString *, AvoEventSchemaType *> *)schema eventId:(NSString *)eventId eventHash:(NSString *)eventHash eventProperties:(NSDictionary * _Nullable) eventProperties {

    // If no fetcher (prod, etc.), fall through to existing path
    NSString *streamId = [AvoAnonymousId anonymousId];
    if (self.eventSpecFetcher == nil || self.eventSpecCache == nil || streamId == nil || [streamId isEqualToString:@"unknown"] || params == nil || params.count == 0) {
        [self internalTrackSchema:eventName eventSchema:schema eventId:eventId eventHash:eventHash eventProperties:eventProperties];
        return;
    }

    NSString *cacheKey = [AvoEventSpecCache generateKey:self.apiKey streamId:streamId eventName:eventName];

    // Check cache first
    if ([self.eventSpecCache contains:cacheKey]) {
        AvoEventSpecResponse *cachedSpec = [self.eventSpecCache get:cacheKey];
        if (cachedSpec != nil) {
            AvoValidationResult *validationResult = [AvoEventValidator validateEvent:params specResponse:cachedSpec];
            if (validationResult != nil) {
                [self sendEventWithValidation:eventName schema:schema eventId:eventId eventHash:eventHash validationResult:validationResult eventProperties:eventProperties];
                return;
            }
        }
        // Cache hit but nil spec or no validation result - use existing path
        [self internalTrackSchema:eventName eventSchema:schema eventId:eventId eventHash:eventHash eventProperties:eventProperties];
        return;
    }

    // Cache miss: fetch spec, validate, then send (aligned with Android/JS implementation)
    if ([AvoInspector isLogging]) {
        NSLog(@"[avo] Avo Inspector: Event spec cache miss for event: %@. Fetching before sending.", eventName);
    }

    AvoFetchEventSpecParams *fetchParams = [[AvoFetchEventSpecParams alloc] initWithApiKey:self.apiKey streamId:streamId eventName:eventName];

    // Defensive copy to prevent caller mutations affecting async validation
    NSDictionary *capturedParams = [params copy];

    __weak AvoInspector *weakSelf = self;
    [self.eventSpecFetcher fetchEventSpec:fetchParams completion:^(AvoEventSpecResponse * _Nullable specResponse) {
        AvoInspector *strongSelf = weakSelf;
        if (strongSelf == nil) return;

        if (specResponse != nil) {
            [strongSelf handleBranchChangeAndCache:cacheKey specResponse:specResponse];

            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Cached event spec for: %@", eventName);
            }

            // Validate and send the validated event
            AvoValidationResult *validationResult = [AvoEventValidator validateEvent:capturedParams specResponse:specResponse];
            if (validationResult != nil) {
                [strongSelf sendEventWithValidation:eventName schema:schema eventId:eventId eventHash:eventHash validationResult:validationResult eventProperties:eventProperties];
            } else {
                // Validation returned nil — send through batched path
                [strongSelf internalTrackSchema:eventName eventSchema:schema eventId:eventId eventHash:eventHash eventProperties:eventProperties];
            }
        } else {
            // Cache nil to avoid re-fetching within TTL, send through batched path
            [strongSelf.eventSpecCache set:cacheKey spec:nil];
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Event spec fetch returned nil for event: %@. Cached empty response. Sending without validation.", eventName);
            }
            [strongSelf internalTrackSchema:eventName eventSchema:schema eventId:eventId eventHash:eventHash eventProperties:eventProperties];
        }
    }];
}

-(void)handleBranchChangeAndCache:(NSString *)cacheKey specResponse:(AvoEventSpecResponse *)specResponse {
    @synchronized (self) {
        if (specResponse.metadata != nil && specResponse.metadata.branchId != nil) {
            NSString *newBranchId = specResponse.metadata.branchId;
            if (self.currentBranchId != nil && ![self.currentBranchId isEqualToString:newBranchId]) {
                if ([AvoInspector isLogging]) {
                    NSLog(@"[avo] Avo Inspector: Branch changed from %@ to %@, clearing cache", self.currentBranchId, newBranchId);
                }
                [self.eventSpecCache clear];
            }
            self.currentBranchId = newBranchId;
        }
        [self.eventSpecCache set:cacheKey spec:specResponse];
    }
}

-(void)sendEventWithValidation:(NSString *)eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *)schema eventId:(NSString *)eventId eventHash:(NSString *)eventHash validationResult:(AvoValidationResult *)validationResult eventProperties:(NSDictionary * _Nullable) eventProperties {
    @try {
        NSString *streamId = [AvoAnonymousId anonymousId];
        NSMutableDictionary *body = [self.networkCallsHandler bodyForValidatedEventSchemaCall:eventName schema:schema eventId:eventId eventHash:eventHash validationResult:validationResult streamId:streamId eventProperties:eventProperties];

        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Sending validated event %@", eventName);
        }

        [self.networkCallsHandler reportValidatedEvent:body];
    } @catch (NSException *e) {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Error sending validated event: %@", e);
        }
    }
}

- (void) dealloc {
    [self.notificationCenter removeObserver:self];
}

-(void)printAvoGenericError:(NSException *) exception {
    NSLog(@"[avo]        ! Avo Inspector Error !");
    NSLog(@"[avo]        Please report the following error to support@avo.app");
    NSLog(@"[avo]        CRASH: %@", exception);
    NSLog(@"[avo]        Stack Trace: %@", [exception callStackSymbols]);
}

@end
