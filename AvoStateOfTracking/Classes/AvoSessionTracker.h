//
//  AvoSessionTracker.h
//  AvoStateOfTracking
//
//  Created by Alex Verein on 05.02.2020.
//

#import <Foundation/Foundation.h>
#import "AvoNetworkCallsHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoSessionTracker : NSObject

-(instancetype) initWithNetworkHandler: (AvoNetworkCallsHandler *) networkCallsHandler;

- (void) schemaTracked: (NSNumber *) atUnixTime;

+ (NSString *) cacheKey;

@end

NS_ASSUME_NONNULL_END
