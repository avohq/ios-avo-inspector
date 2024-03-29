//
//  NetworkCallsHandler.m
//  AvoInspector
//
//  Created by Alex Verein on 07.02.2020.
//

#import "AvoNetworkCallsHandler.h"
#import "AvoUtils.h"
#import "AvoInspector.h"
#import "AvoObject.h"

@interface AvoNetworkCallsHandler()

@property (readwrite, nonatomic) NSString *apiKey;
@property (readwrite, nonatomic) int env;
@property (readwrite, nonatomic) NSString *appName;
@property (readwrite, nonatomic) NSString *appVersion;
@property (readwrite, nonatomic) NSString *libVersion;
@property (readwrite, nonatomic) NSURLSession *urlSession;
@property (readwrite, nonatomic) NSString *endpoint;

@property (readwrite, nonatomic) double samplingRate;

@end

@implementation AvoNetworkCallsHandler

- (instancetype) initWithApiKey: (NSString *) apiKey appName: (NSString *)appName appVersion: (NSString *) appVersion libVersion: (NSString *) libVersion env: (int) env endpoint: (NSString *) endpoint {
    self = [super init];
    if (self) {
        self.endpoint = endpoint;
        self.appVersion = appVersion;
        self.libVersion = libVersion;
        self.appName = appName;
        self.apiKey = apiKey;
        self.samplingRate = 1.0;
        self.env = env;
        self.urlSession = [NSURLSession sharedSession];
    }
    return self;
}

- (NSMutableDictionary *) bodyForTrackSchemaCall:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash {
    NSMutableArray * propsSchema = [NSMutableArray new];
    
    for(NSString *key in [schema allKeys]) {
        NSString *value = [[schema objectForKey:key] name];
        
        NSMutableDictionary *prop = [NSMutableDictionary new];
        
        [prop setObject:key forKey:@"propertyName"];
        if ([[schema objectForKey:key] isKindOfClass:[AvoObject class]]) {
            NSError *error = nil;
            id nestedSchema = [NSJSONSerialization
                              JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding]
                              options:0
                              error:&error];
            if (!error && [nestedSchema isKindOfClass:[NSDictionary class]]) {
                NSDictionary *results = nestedSchema;
                
                [prop setObject:@"object" forKey:@"propertyType"];
                
                [prop setObject:[self bodyFromJson:results] forKey:@"children"];
            }
        } else {
            [prop setObject:value forKey:@"propertyType"];
        }
        [propsSchema addObject:prop];
    }
    
    NSMutableDictionary * baseBody = [self createBaseCallBody];
    
    if (eventId != nil) {
        [baseBody setValue:@YES forKey:@"avoFunction"];
        [baseBody setValue:eventId forKey:@"eventId"];
        [baseBody setValue:eventHash forKey:@"eventHash"];
    } else {
        [baseBody setValue:@NO forKey:@"avoFunction"];
    }
    
    [baseBody setValue:@"event" forKey:@"type"];
    [baseBody setValue:eventName forKey:@"eventName"];
    [baseBody setValue:propsSchema forKey:@"eventProperties"];
    
    return baseBody;
}

- (NSMutableArray *) bodyFromJson:(NSDictionary *) schema {
    NSMutableArray * propsSchema = [NSMutableArray new];
    
    for(NSString *key in [schema allKeys]) {
        id value = [schema objectForKey:key];
        
        NSMutableDictionary *prop = [NSMutableDictionary new];
        
        [prop setObject:key forKey:@"propertyName"];
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *results = value;
            
            [prop setObject:@"object" forKey:@"propertyType"];
            [prop setObject:[self bodyFromJson:results] forKey:@"children"];
        } else {
            [prop setObject:value forKey:@"propertyType"];
        }
        [propsSchema addObject:prop];
    }
    
    return propsSchema;
}

- (NSMutableDictionary *) bodyForSessionStartedCall  {
     NSMutableDictionary * baseBody = [self createBaseCallBody];
    
    [baseBody setValue:@"sessionStarted" forKey:@"type"];
    return baseBody;
}

// Shared network logic

- (NSMutableDictionary *) createBaseCallBody {
    NSMutableDictionary *body = [NSMutableDictionary new];
    [body setValue:self.apiKey forKey:@"apiKey"];
    [body setValue:self.appName forKey:@"appName"];
    [body setValue:self.appVersion forKey:@"appVersion"];
    [body setValue:self.libVersion forKey:@"libVersion"];
    [body setValue:@(self.samplingRate) forKey:@"samplingRate"];
    [body setValue:AvoSessionTracker.sessionId forKey:@"sessionId"];
    [body setValue:[AvoNetworkCallsHandler formatTypeToString:self.env] forKey:@"env"];
    [body setValue:@"ios" forKey:@"libPlatform"];
    [body setValue:[[NSUUID UUID] UUIDString] forKey:@"messageId"];
    [body setValue:[AvoUtils currentTimeAsISO8601UTCString] forKey:@"createdAt"];

    return body;
}

- (void) callInspectorWithBatchBody: (NSArray *) batchBody completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    if (batchBody == nil) {
        return;
    }
    
    if (drand48() > self.samplingRate) {
         if ([AvoInspector isLogging]) {
             NSLog(@"[avo] Avo Inspector: Last event schema dropped due to sampling rate");
         }
         return;
    }
    
    if ([AvoInspector isLogging]) {
        for (NSDictionary *batchItem in batchBody) {
            NSString * type = [batchItem objectForKey:@"type"];
            
            if ([type  isEqual:@"sessionStarted"]) {
                NSLog(@"[avo] Avo Inspector: Sending session started event");
            } else if ([type  isEqual:@"event"]) {
                NSString * eventName = [batchItem objectForKey:@"eventName"];
                NSString * eventProps = [batchItem objectForKey:@"eventProperties"];

                NSLog(@"[avo] Avo Inspector: Sending event %@ with schema {\n%@\n}\n", eventName, [eventProps description]);
            } else {
                NSLog(@"[avo] Avo Inspector: Error! Unknown event type.");
            }
            
        }
    }
    
    NSError *error;
    NSData *bodyData = [NSJSONSerialization  dataWithJSONObject:batchBody
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:&error];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.endpoint]];
    [request setHTTPMethod:@"POST"];

    [self writeCallHeader:request];
    [request setHTTPBody:bodyData];

    [self sendHttpRequest:request completionHandler:completionHandler];
}

- (void)sendHttpRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSError *error))completionHandler {
    __weak AvoNetworkCallsHandler *weakSelf = self;
    NSURLSessionDataTask *postDataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error == nil)
        {
            if (error != nil || data == nil) {
                return;
            }
            NSError *jsonError = nil;
            NSDictionary *responseJSON = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            NSNumber *rate = responseJSON[@"samplingRate"];
            if (rate != nil && weakSelf.samplingRate != [rate doubleValue]) {
                weakSelf.samplingRate = [rate doubleValue];
            }
            
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Successfully sent events.");
            }
        } else if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Failed sending events. Will retry later.");
        }
        
        completionHandler(error);
    }];
    
    [postDataTask resume];
}

- (void) writeCallHeader:(NSMutableURLRequest *) request {
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
}

+ (NSString*)formatTypeToString:(int) formatType {
    NSString *result = nil;

    switch(formatType) {
        case 0:
            result = @"prod";
            break;
        case 1:
            result = @"dev";
            break;
        case 2:
            result = @"staging";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }

    return result;
}

@end
