//
//  DebuggerAnalyticsDestination.m
//  IosAnalyticsDebugger
//
//  Created by Alex Verein on 24.02.2020.
//

#import "DebuggerAnalyticsDestination.h"
#import "DebuggerAnalytics.h"

@implementation DebuggerAnalyticsDestination
- (void)identify:(nonnull NSString *)userId {}

- (void)logEvent:(nonnull NSString *)eventName withEventProperties:(nonnull NSDictionary *)eventProperties {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                       initWithURL:[NSURL URLWithString:@"https://api.avo.app/c/v1/track"]];
    [request setHTTPMethod:@"POST"];
    
    [self writeTrackingCallHeader:request];

    [self writeTrackingCallBody:request eventName:eventName eventProps:eventProperties];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];

    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {}];

    [postDataTask resume];
}

- (void)make:(DebuggerAnalyticsAVOEnv)avoEnv {}

- (void)setUserProperties:(nonnull NSString *)userId withUserProperties:(nonnull NSDictionary *)userProperties {}

- (void)unidentify {}

- (void) writeTrackingCallHeader:(NSMutableURLRequest *) request {
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
}

- (void) writeTrackingCallBody:(NSMutableURLRequest *) request eventName:(NSString *) eventName eventProps:(NSDictionary *)eventProperties  {
    UIDevice *device = [UIDevice currentDevice];
    NSString  *deviceId = [[device identifierForVendor]UUIDString];
       
    NSMutableDictionary *body = [NSMutableDictionary new];
    [body setValue:deviceId forKey:@"deviceId"];
    [body setValue:eventName forKey:@"eventName"];
    [body setValue:eventProperties forKey:@"eventProperties"];

    NSError *error;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:&error];
    [request setHTTPBody:bodyData];
}
@end
