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

@interface AvoNetworkCallsHandler()

@property (readwrite, nonatomic) NSString *apiKey;
@property (readwrite, nonatomic) NSString *appVersion;
@property (readwrite, nonatomic) NSString *libVersion;

@property (readwrite, nonatomic) double samplingRate;

@end

@implementation AvoNetworkCallsHandler

- (instancetype) initWithApiKey: (NSString *) apiKey appVersion: (NSString *) appVersion libVersion: (NSString *) libVersion {
    self = [super init];
    if (self) {
        self.appVersion = appVersion;
        self.libVersion = libVersion;
        self.apiKey = apiKey;
        self.samplingRate = 1.0;
    }
    return self;
}

- (NSMutableDictionary *) bodyForTrackSchemaCall:(NSString *) eventName schema:(NSDictionary *) schema {
    NSMutableArray * propsSchema = [NSMutableArray new];
    
    for(NSString *key in [schema allKeys]) {
        NSString *value = [[schema objectForKey:key] name];
        
        NSMutableDictionary *prop = [NSMutableDictionary new];
        
        [prop setObject:key forKey:@"propertyName"];
        [prop setObject:value forKey:@"propertyValue"];
        
        [propsSchema addObject:prop];
    }
    
    NSMutableDictionary * baseBody = [self createBaseCallBody];
    
    [baseBody setValue:@"event" forKey:@"type"];
    [baseBody setValue:eventName forKey:@"eventName"];
    [baseBody setValue:propsSchema forKey:@"eventProperties"];
    
    return baseBody;
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
    [body setValue:self.appVersion forKey:@"appVersion"];
    [body setValue:self.libVersion forKey:@"libVersion"];
    [body setValue:@"ios" forKey:@"libPlatform"];
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
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.avo.app/datascope/track"]];
    [request setHTTPMethod:@"POST"];

    [self writeCallHeader:request];
    [request setHTTPBody:bodyData];

    [self sendHttpRequest:request completionHandler:completionHandler];
}

- (void)sendHttpRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSError *error))completionHandler {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error == nil)
        {
            if (error != nil || data == nil) {
                return;
            }
            NSError *jsonError = nil;
            NSDictionary *responseJSON = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            NSNumber *rate = responseJSON[@"samplingRate"];
            if (rate != nil && self.samplingRate != [rate doubleValue]) {
                self.samplingRate = [rate doubleValue];
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
