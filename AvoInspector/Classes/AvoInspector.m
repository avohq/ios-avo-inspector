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
@property (readwrite, nonatomic) AnalyticsDebugger * debugger;

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
    maxBatchSize = newBatchSize;
}

+ (int) getBatchFlushSeconds {
    return batchFlushTime;
}

+ (void) setBatchFlushSeconds: (int) newBatchFlushSeconds {
    batchFlushTime = newBatchFlushSeconds;
}

- (AnalyticsDebugger *) getVisualInspector {
    return self.debugger;
}

- (void) showVisualInspector: (AvoVisualInspectorType) type {
    if (self.debugger == nil) {
        self.debugger = [AnalyticsDebugger new];
    }
    
    switch (type) {
        case Bar:
            [self.debugger showBarDebugger];
            break;
        case Bubble:
            [self.debugger showBubbleDebugger];
            break;
        default:
            break;
    }
}

- (void) hideVisualInspector {
    if (self.debugger != nil) {
        [self.debugger hideDebugger];
    }
}

-(instancetype) initWithApiKey: (NSString *) apiKey envInt: (NSNumber *) envInt {
    self = [self initWithApiKey:apiKey env:[envInt intValue]];
    return self;
}

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env {
    self = [super init];
    if (self) {
        if (env != AvoInspectorEnvProd && env != AvoInspectorEnvDev && env != AvoInspectorEnvStaging) {
            self.env = AvoInspectorEnvDev;
        } else {
            self.env = env;
        }

        self.avoSchemaExtractor = [AvoSchemaExtractor new];
        
        self.debugger = [AnalyticsDebugger new];
        
        if (env == AvoInspectorEnvDev) {
            [AvoInspector setBatchFlushSeconds:1];
            [AvoInspector setLogging:YES];
        } else {
            [AvoInspector setBatchFlushSeconds:30];
            [AvoInspector setLogging:NO];
        }

        if (env != AvoInspectorEnvProd) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
                [self showVisualInspector:Bubble];
            });
        }
        
        self.appName = [[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleIdentifierKey];
        self.appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
        self.libVersion = @"1.2.1";
        
        self.notificationCenter = [NSNotificationCenter defaultCenter];
        
        self.networkCallsHandler = [[AvoNetworkCallsHandler alloc] initWithApiKey:apiKey appName:self.appName appVersion:self.appVersion libVersion:self.libVersion env:(int)self.env];
        self.avoBatcher = [[AvoBatcher alloc] initWithNetworkCallsHandler:self.networkCallsHandler];
        
        self.sessionTracker = [[AvoSessionTracker alloc] initWithBatcher:self.avoBatcher];
        
        self.avoDeduplicator = [AvoDeduplicator sharedDeduplicator];
        
        self.apiKey = apiKey;
        
        [self enterForeground];
        
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

- (void)enterBackground {
    [self.avoBatcher enterBackground];
}

- (void)enterForeground {
    [self.avoBatcher enterForeground];
    [self.sessionTracker startOrProlongSession:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
}

// internal API
-(NSDictionary<NSString *, AvoEventSchemaType *> *) avoFunctionTrackSchemaFromEvent:(NSString *) eventName eventParams:(NSMutableDictionary<NSString *, id> *) params {
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

// params are [ String : Any ]
-(NSDictionary<NSString *, AvoEventSchemaType *> *) trackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params {
    
    if ([self.avoDeduplicator shouldRegisterEvent:eventName eventParams:params fromAvoFunction:NO]) {
        return [self internalTrackSchemaFromEvent:eventName eventParams:params eventId:nil eventHash:nil];
    } else {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Deduplicated event %@", eventName);
        }
        return [NSMutableDictionary new];
    }
}


// params are [ String : Any ]
-(NSDictionary<NSString *, AvoEventSchemaType *> *) internalTrackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params eventId:(NSString *) eventId eventHash:(NSString *) eventHash {
    
    @try {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Supplied event %@ with params %@", eventName, [params description]);
        }
        
        [self showEventInVisualInspector:eventName props:params];
        
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
    [self internalTrackSchema:eventName eventSchema:schema eventId:nil eventHash:nil];
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

        [self showSchemaInVisualInspector:eventName schema:schema];
    }
    @catch (NSException *exception) {
        [self.avoSchemaExtractor printAvoParsingError:exception];
    }
}

- (void)showEventInVisualInspector:(NSString *) eventName props:(NSDictionary<NSString *, id> * _Nonnull)eventProps {
    if (self.debugger != nil && (self.env != AvoInspectorEnvProd || [self.debugger isEnabled])) {
        NSMutableArray * props = [NSMutableArray new];
        
        for(NSString *key in [eventProps allKeys]) {
            id value = [eventProps objectForKey:key];
            [props addObject:[[DebuggerProp alloc] initWithId:key withName:key withValue:[value description]]];
        }
        
        [self.debugger publishEvent:[NSString stringWithFormat:@"Event: %@", eventName] withTimestamp:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]
                withProperties:props withErrors:[NSMutableArray new]];
    }
}

- (void)showSchemaInVisualInspector:(NSString *) eventName schema:(NSDictionary<NSString *,AvoEventSchemaType *> * _Nonnull)schema {
    if (self.debugger != nil && (self.env != AvoInspectorEnvProd || [self.debugger isEnabled])) {
        NSMutableArray * props = [NSMutableArray new];
        
        for(NSString *key in [schema allKeys]) {
            NSString *value = [[schema objectForKey:key] name];
            [props addObject:[[DebuggerProp alloc] initWithId:key withName:key withValue:value]];
        }
        
        [self.debugger publishEvent:[NSString stringWithFormat:@"Schema: %@", eventName] withTimestamp:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]
                withProperties:props withErrors:[NSMutableArray new]];
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

@end
