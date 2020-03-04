//
//  NetworkCallsHandler.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 07.02.2020.
//

#import "AvoNetworkCallsHandler.h"
#import "AvoInstallationId.h"
#import "AvoUtils.h"
#import "AvoStateOfTracking.h"
#import "AvoObject.h"

@interface AvoNetworkCallsHandler()

@property (readwrite, nonatomic) NSString *apiKey;
@property (readwrite, nonatomic) Boolean isDev;
@property (readwrite, nonatomic) NSString *appName;
@property (readwrite, nonatomic) NSString *appVersion;
@property (readwrite, nonatomic) NSString *libVersion;

@property (readwrite, nonatomic) double samplingRate;

@end

@implementation AvoNetworkCallsHandler

- (instancetype) initWithApiKey: (NSString *) apiKey appName: (NSString *)appName appVersion: (NSString *) appVersion libVersion: (NSString *) libVersion isDev: (Boolean) isDev {
    self = [super init];
    if (self) {
        self.appVersion = appVersion;
        self.libVersion = libVersion;
        self.appName = appName;
        self.apiKey = apiKey;
        self.samplingRate = 1.0;
        self.isDev = isDev;
    }
    return self;
}

- (NSMutableDictionary *) bodyForTrackSchemaCall:(NSString *) eventName schema:(NSDictionary *) schema {
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
    [body setValue:self.isDev ? @"dev" : @"prod" forKey:@"env"];
    [body setValue:@"ios" forKey:@"libPlatform"];
    [body setValue:[[NSUUID UUID] UUIDString] forKey:@"messageId"];
    [body setValue:[[AvoInstallationId new] getInstallationId] forKey:@"trackingId"];
    [body setValue:[AvoUtils currentTimeAsISO8601UTCString] forKey:@"createdAt"];

    return body;
}

- (void) callStateOfTrackingWithBatchBody: (NSArray *) batchBody completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    if (batchBody == nil) {
        return;
    }
    
    if (drand48() > self.samplingRate) {
         if ([AvoStateOfTracking isLogging]) {
             NSLog(@"Last event schema dropped due to sampling rate");
         }
         return;
    }
    
    if ([AvoStateOfTracking isLogging]) {
        for(NSDictionary *batchItem in batchBody) {
            NSString * eventName = [batchItem objectForKey:@"eventName"];
            NSString * eventProps = [batchItem objectForKey:@"eventProperties"];
            
            NSLog(@"Avo State Of Tracking: Sending event %@ with schema {\n%@}\n\n", eventName, [eventProps description]);
        }
    }
    
    NSError *error;
    NSData *bodyData = [NSJSONSerialization  dataWithJSONObject:batchBody
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:&error];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.avo.app/datascope/v0/track"]];
    [request setHTTPMethod:@"POST"];

    [self writeCallHeader:request];
    [request setHTTPBody:bodyData];

    [self sendHttpRequest:request completionHandler:completionHandler];
}

- (void)sendHttpRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSError *error))completionHandler {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    
    __weak AvoNetworkCallsHandler *weakSelf = self;
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
        } else if ([AvoStateOfTracking isLogging]) {
            NSLog(@"Avo State Of Tracking: Failed sending events. Will retry later.");
        }
        
        completionHandler(error);
    }];
    
    [postDataTask resume];
}

- (void) writeCallHeader:(NSMutableURLRequest *) request {
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
}

@end
