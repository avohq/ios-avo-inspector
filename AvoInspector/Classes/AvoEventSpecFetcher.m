//  AvoEventSpecFetcher.m
//
//  Event spec fetcher for iOS.
//  Auto-generated from SoT: EventFetcher.res

#import <Foundation/Foundation.h>
#import "AvoEventSpecFetcher.h"
#import "AvoEventSpecFetchTypes.h"
#import "AvoInspector.h"

@interface AvoEventSpecFetcher ()

@property (nonatomic, copy, readonly) NSString *baseUrl;
@property (nonatomic, assign, readonly) NSTimeInterval timeout;
@property (nonatomic, copy, readonly) NSString *env;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSMutableArray<void (^)(AvoEventSpecResponse * _Nullable)> *> *inFlightCallbacks;

@end

@implementation AvoEventSpecFetcher

- (instancetype)initWithTimeout:(NSTimeInterval)timeout env:(NSString *)env {
    return [self initWithTimeout:timeout env:env baseUrl:@"https://api.avo.app"];
}

- (instancetype)initWithTimeout:(NSTimeInterval)timeout env:(NSString *)env baseUrl:(NSString *)baseUrl {
    self = [super init];
    if (self) {
        _baseUrl = [baseUrl copy];
        _timeout = timeout;
        _env = [env copy];
        _inFlightCallbacks = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)generateRequestKey:(AvoFetchEventSpecParams *)params {
    return [NSString stringWithFormat:@"%@:%@", params.streamId, params.eventName];
}

- (void)fetchEventSpec:(AvoFetchEventSpecParams *)params completion:(void (^)(AvoEventSpecResponse * _Nullable))completion {
    NSString *requestKey = [self generateRequestKey:params];

    @synchronized (self.inFlightCallbacks) {
        NSMutableArray *existing = self.inFlightCallbacks[requestKey];
        if (existing != nil) {
            [existing addObject:completion];
            return;
        }
        NSMutableArray *callbacks = [NSMutableArray array];
        [callbacks addObject:completion];
        self.inFlightCallbacks[requestKey] = callbacks;
    }

    [self fetchInternal:params requestKey:requestKey];
}

- (void)fetchInternal:(AvoFetchEventSpecParams *)params requestKey:(NSString *)requestKey {
    if (!([self.env isEqualToString:@"dev"] || [self.env isEqualToString:@"staging"])) {
        [self deliverResult:requestKey result:nil];
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AvoEventSpecResponse *result = nil;
        @try {
            NSString *url = [self buildUrl:params];

            if ([AvoInspector isLogging]) {
                NSLog(@"[Avo Inspector] Fetching event spec for event: %@ url: %@", params.eventName, url);
            }

            AvoEventSpecResponseWire *wireResponse = [self makeRequest:url];

            if (wireResponse == nil) {
                if ([AvoInspector isLogging]) {
                    NSLog(@"[Avo Inspector] Failed to fetch event spec for: %@", params.eventName);
                }
            } else if (![self hasExpectedShape:wireResponse]) {
                if ([AvoInspector isLogging]) {
                    NSLog(@"[Avo Inspector] Invalid event spec response for: %@", params.eventName);
                }
            } else {
                result = [[AvoEventSpecResponse alloc] initFromWire:wireResponse];
                if ([AvoInspector isLogging]) {
                    NSLog(@"[Avo Inspector] Successfully fetched event spec for: %@ with %lu events",
                          params.eventName, (unsigned long)(result.events ? result.events.count : 0));
                }
            }
        } @catch (NSException *e) {
            if ([AvoInspector isLogging]) {
                NSLog(@"[Avo Inspector] Error fetching event spec for: %@ %@", params.eventName, e);
            }
        }

        [self deliverResult:requestKey result:result];
    });
}

- (void)deliverResult:(NSString *)requestKey result:(AvoEventSpecResponse * _Nullable)result {
    NSMutableArray<void (^)(AvoEventSpecResponse * _Nullable)> *callbacks;
    @synchronized (self.inFlightCallbacks) {
        callbacks = self.inFlightCallbacks[requestKey];
        [self.inFlightCallbacks removeObjectForKey:requestKey];
    }
    if (callbacks != nil) {
        for (void (^cb)(AvoEventSpecResponse * _Nullable) in callbacks) {
            @try {
                cb(result);
            } @catch (NSException *e) {
                if ([AvoInspector isLogging]) {
                    NSLog(@"[Avo Inspector] Exception in EventSpecFetchCallback: %@", e);
                }
            }
        }
    }
}

- (NSString *)buildUrl:(AvoFetchEventSpecParams *)params {
    NSString *apiKey = [self encodeURIComponent:params.apiKey];
    NSString *streamId = [self encodeURIComponent:params.streamId];
    NSString *eventName = [self encodeURIComponent:params.eventName];
    return [NSString stringWithFormat:@"%@/trackingPlan/eventSpec?apiKey=%@&streamId=%@&eventName=%@",
            self.baseUrl, apiKey, streamId, eventName];
}

- (NSString *)encodeURIComponent:(NSString *)value {
    NSCharacterSet *allowedChars = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encoded = [value stringByAddingPercentEncodingWithAllowedCharacters:allowedChars];
    return encoded ? encoded : @"";
}

- (AvoEventSpecResponseWire * _Nullable)makeRequest:(NSString *)url {
    __block AvoEventSpecResponseWire *wireResponse = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    NSURL *requestUrl = [NSURL URLWithString:url];
    if (requestUrl == nil) {
        return nil;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = self.timeout;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            if ([AvoInspector isLogging]) {
                NSLog(@"[Avo Inspector] Network error occurred: %@", error);
            }
            dispatch_semaphore_signal(semaphore);
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            if ([AvoInspector isLogging]) {
                NSLog(@"[Avo Inspector] Request failed with status: %ld", (long)httpResponse.statusCode);
            }
            dispatch_semaphore_signal(semaphore);
            return;
        }

        if (data == nil) {
            dispatch_semaphore_signal(semaphore);
            return;
        }

        @try {
            NSError *jsonError = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError == nil && [json isKindOfClass:[NSDictionary class]]) {
                wireResponse = [[AvoEventSpecResponseWire alloc] initWithDictionary:json];
            } else {
                if ([AvoInspector isLogging]) {
                    NSLog(@"[Avo Inspector] Failed to parse response: %@", jsonError);
                }
            }
        } @catch (NSException *e) {
            if ([AvoInspector isLogging]) {
                NSLog(@"[Avo Inspector] Failed to parse response: %@", e);
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];

    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeout * NSEC_PER_SEC)));

    return wireResponse;
}

- (BOOL)hasExpectedShape:(AvoEventSpecResponseWire *)response {
    return response != nil
        && response.events != nil
        && response.metadata != nil
        && response.metadata.schemaId != nil
        && ![response.metadata.schemaId isEqualToString:@""]
        && response.metadata.branchId != nil
        && ![response.metadata.branchId isEqualToString:@""]
        && response.metadata.latestActionId != nil
        && ![response.metadata.latestActionId isEqualToString:@""];
}

@end