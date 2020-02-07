//
//  NetworkCallsHandler.h
//  AvoStateOfTracking
//
//  Created by Alex Verein on 07.02.2020.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AvoNetworkCallsHandler : NSObject

@property (readonly, nonatomic) NSString *apiKey;
@property (readonly, nonatomic) NSString *appVersion;
@property (readonly, nonatomic) NSString *libVersion;

- (instancetype) initWithApiKey: (NSString *) apiKey appVersion: (NSString *) appVersion libVersion: (NSString *) libVersion;

- (void) callSessionStarted;
- (void) callTrackSchema: (NSString *) eventName schema: (NSDictionary *) schema;

@end

NS_ASSUME_NONNULL_END
