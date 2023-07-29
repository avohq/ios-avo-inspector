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

@interface AvoInspector ()

@property (readwrite, nonatomic) AvoSessionTracker * sessionTracker;

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

@end

@implementation AvoInspector

static BOOL logging = NO;
static int maxBatchSize = 30;
static int batchFlushTime = 30;

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

-(instancetype) initWithApiKey: (NSString *) apiKey envInt: (NSNumber *) envInt {
    self = [self initWithApiKey:apiKey env:[envInt intValue]];
    return self;
}

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env proxyEndpoint: (NSString *) proxyEndpoint {
    self = [super init];
    if (self) {
        if (env != AvoInspectorEnvProd && env != AvoInspectorEnvDev && env != AvoInspectorEnvStaging) {
            self.env = AvoInspectorEnvDev;
        } else {
            self.env = env;
        }
        
        self.avoSchemaExtractor = [AvoSchemaExtractor new];
                
        if (env == AvoInspectorEnvDev) {
            [AvoInspector setBatchSize:1];
            [AvoInspector setLogging:YES];
        } else {
            [AvoInspector setBatchSize:30];
            [AvoInspector setBatchFlushSeconds:30];
            [AvoInspector setLogging:NO];
        }
        
        if (env != AvoInspectorEnvProd) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
            });
        }
        
        self.appName = [[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleIdentifierKey];
        self.appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
        self.libVersion = @"2.0.0";
        
        self.notificationCenter = [NSNotificationCenter defaultCenter];
        
        self.networkCallsHandler = [[AvoNetworkCallsHandler alloc] initWithApiKey:apiKey appName:self.appName appVersion:self.appVersion libVersion:self.libVersion env:(int)self.env endpoint: proxyEndpoint];
        self.avoBatcher = [[AvoBatcher alloc] initWithNetworkCallsHandler:self.networkCallsHandler];
        
        self.sessionTracker = [[AvoSessionTracker alloc] initWithBatcher:self.avoBatcher];
        
        self.avoDeduplicator = [AvoDeduplicator sharedDeduplicator];
        
        self.apiKey = apiKey;
        
        [self enterForeground];
        
        [self addObservers];
    }
    return self;
}

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env {
    self = [self initWithApiKey:apiKey env:env proxyEndpoint:@"https://api.avo.app/inspector/v1/track"];
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
        [self.sessionTracker startOrProlongSession:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
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
        
        [self internalTrackSchema:eventName eventSchema:schema eventId:eventId eventHash:eventHash];
        
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
            [self internalTrackSchema:eventName eventSchema:schema eventId:nil eventHash:nil];
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

-(void) internalTrackSchema:(NSString *) eventName eventSchema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString *) eventId eventHash:(NSString *) eventHash {
    
    @try {
        for(NSString *key in [schema allKeys]) {
            if (![[schema objectForKey:key] isKindOfClass:[AvoEventSchemaType class]]) {
                [NSException raise:@"Schema types should be of type AvoEventSchemaType" format:@"Provided %@", [[[schema objectForKey:key] class] description]];
            }
        }
        
        [self.sessionTracker startOrProlongSession:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
        
        [self.avoBatcher handleTrackSchema:eventName schema:schema eventId: eventId eventHash:eventHash];
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
