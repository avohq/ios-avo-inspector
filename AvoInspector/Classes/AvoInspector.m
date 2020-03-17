//
//  AvoInspector.m
//  AvoInspector
//
//  Created by Alex Verein on 28.01.2020.
//

#import "AvoInspector.h"
#import "AvoEventSchemaType.h"
#import "AvoList.h"
#import "AvoObject.h"
#import "AvoInt.h"
#import "AvoFloat.h"
#import "AvoBoolean.h"
#import "AvoString.h"
#import "AvoUnknownType.h"
#import "AvoNull.h"
#import "AvoNetworkCallsHandler.h"
#import "AvoBatcher.h"

@interface AvoInspector ()

@property (readwrite, nonatomic) AvoSessionTracker * sessionTracker;

@property (readwrite, nonatomic) NSString * appVersion;
@property (readwrite, nonatomic) NSString * appName;
@property (readwrite, nonatomic) NSString * libVersion;
@property (readwrite, nonatomic) NSString * apiKey;

@property (readwrite, nonatomic) AvoNetworkCallsHandler *networkCallsHandler;
@property (readwrite, nonatomic) AvoBatcher *avoBatcher;

@property (readwrite, nonatomic) NSNotificationCenter *notificationCenter;

@property (readwrite, nonatomic) AvoInspectorEnv env;
@property (readwrite, nonatomic) AnalyticsDebugger * debugger;

@end

@implementation AvoInspector

static BOOL logging = NO;
static int maxBatchSize = 30;
static int batchFlushSTime = 30;

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
    return batchFlushSTime;
}

+ (void) setBatchFlushSeconds: (int) newBatchFlushSeconds {
    batchFlushSTime = newBatchFlushSeconds;
}

- (AnalyticsDebugger *) getVisualInspector {
    return self.debugger;
}

- (void) showVisualInspector: (AvoVisualInspectorType) type {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
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
    });
}

- (void) hideVisualInspector {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self.debugger hideDebugger];
    });
}

-(instancetype) initWithApiKey: (NSString *) apiKey env: (AvoInspectorEnv) env {
    self = [super init];
    if (self) {
        self.env = env;
        self.debugger = [AnalyticsDebugger new];
        
        if (env == AvoInspectorEnvDev) {
            [AvoInspector setBatchFlushSeconds:1];
            [AvoInspector setLogging:YES];
        } else {
            [AvoInspector setBatchFlushSeconds:30];
            [AvoInspector setLogging:NO];
        }

        if (env != AvoInspectorEnvProd) {
            [self showVisualInspector:Bar];
        }
        
        self.appName = [[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleIdentifierKey];
        self.appVersion = [[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleVersionKey];
        self.libVersion = [[NSBundle bundleForClass:[self class]] infoDictionary][@"CFBundleShortVersionString"];
        
        self.notificationCenter = [NSNotificationCenter defaultCenter];
        
        self.networkCallsHandler = [[AvoNetworkCallsHandler alloc] initWithApiKey:apiKey appName:self.appName appVersion:self.appVersion libVersion:self.libVersion env:(int)self.env];
        self.avoBatcher = [[AvoBatcher alloc] initWithNetworkCallsHandler:self.networkCallsHandler];
        
        self.sessionTracker = [[AvoSessionTracker alloc] initWithBatcher:self.avoBatcher];
        
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

// params are [ String : Any ]
-(NSDictionary<NSString *, AvoEventSchemaType *> *) trackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params {
    if ([AvoInspector isLogging]) {
        NSLog(@"Avo Inspector: Supplied event %@ with params %@", eventName, [params description]);
    }
    
    [self showEventInVisualInspector:eventName props:params];
    
    NSDictionary * schema = [self extractSchema:params];
    
    [self trackSchema:eventName eventSchema:schema];
    
    return schema;
}

// schema is [ String : AvoEventSchemaType ]
-(void) trackSchema:(NSString *) eventName eventSchema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema {
    for(NSString *key in [schema allKeys]) {
        if (![[schema objectForKey:key] isKindOfClass:[AvoEventSchemaType class]]) {
            [NSException raise:@"Schema types should be of type AvoEventSchemaType" format:@"Provided %@", [[[schema objectForKey:key] class] description]];
        }
    }
    
    if ([AvoInspector isLogging]) {
        
        NSString * schemaString = @"";
        
        for(NSString *key in [schema allKeys]) {
            NSString *value = [[schema objectForKey:key] name];
            NSString *entry = [NSString stringWithFormat:@"\t\"%@\": \"%@\";\n", key, value];
            schemaString = [schemaString stringByAppendingString:entry];
        }
        
        NSLog(@"Avo Inspector: Saved event %@ with schema {\n%@}", eventName, schemaString);
    }
    
    [self.sessionTracker startOrProlongSession:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
    
    [self.avoBatcher handleTrackSchema:eventName schema:schema];
    
    [self showSchemaInVisualInspector:eventName schema:schema];
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
    NSMutableDictionary * result = [NSMutableDictionary new];
    
    for (id paramName in [eventParams allKeys]) {
        id paramValue = [eventParams valueForKey:paramName];
            
        AvoEventSchemaType * paramType = [self objectToAvoSchemaType:paramValue];
        
        [result setObject:paramType forKey:paramName];
    }
    
    return result;
}

-(AvoEventSchemaType *)objectToAvoSchemaType: (id) obj {
    if (obj == [NSNull null]) {
        return [AvoNull new];
    }
    
    Class cl = [obj class];
    NSString * paramType = [cl description];
    
    if ([paramType isEqual: @"__NSCFNumber"]) {
        const char *objCtype = [obj objCType];
        
        if ([@"i" isEqualToString:@(objCtype)]
            || [@"s" isEqualToString:@(objCtype)]
            || [@"q" isEqualToString:@(objCtype)]) {
            return [AvoInt new];
        } else if ([@"c" isEqualToString:@(objCtype)]) {
            return [AvoString new];
        } else {
            return [AvoFloat new];
        }
    } else if ([paramType isEqual: @"__NSCFBoolean"]) {
        return [AvoBoolean new];
    } else if ([paramType isEqual: @"__NSCFConstantString"] ||
               [paramType isEqual: @"__NSCFString"] ||
               [paramType isEqual: @"NSTaggedPointerString"] ||
               [paramType isEqual: @"Swift.__SharedStringStorage"]) {
        return [AvoString new];
    } else if ([paramType containsString: @"NSSet"] ||
               [paramType isEqual: @"__NSSingleObjectSetI"] ||
               [paramType isEqual: @"__NSSingleObjectArrayI"] ||
               [paramType containsString: @"NSArray"]) {
        AvoList * result = [AvoList new];
        
        for (id item in obj) {
            if (item == NSNull.null) {
                [result.subtypes addObject:[AvoNull new]];
            } else {
                [result.subtypes addObject:[self objectToAvoSchemaType:item]];
            }
        }
        
        return result;
    } else if ([paramType containsString: @"NSDictionary"] ||
               [paramType isEqual: @"__NSSingleEntryDictionaryI"]) {
        AvoObject * result = [AvoObject new];
        
        for (id paramName in [obj allKeys]) {
            id paramValue = [obj valueForKey:paramName];
                
            AvoEventSchemaType * paramType = [self objectToAvoSchemaType:paramValue];
            
            [result.fields setObject:paramType forKey:paramName];
        }
        
        return result;
    } else {
        return [AvoUnknownType new];
    }
}

- (void) dealloc {
    [self.notificationCenter removeObserver:self];
}

@end
