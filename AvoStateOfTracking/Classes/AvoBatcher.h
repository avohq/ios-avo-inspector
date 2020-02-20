//
//  AvoBatcher.h
//  AvoStateOfTracking
//
//  Created by Alex Verein on 18.02.2020.
//

#import <Foundation/Foundation.h>

#import "AvoNetworkCallsHandler.h"
#import "AvoEventSchemaType.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoBatcher : NSObject

- (instancetype) initWithNetworkCallsHandler: (AvoNetworkCallsHandler *) networkCallsHandler withNotificationCenter: (NSNotificationCenter *) center;

- (void) handleSessionStarted;
- (void) handleTrackSchema: (NSString *) eventName schema: (NSDictionary<NSString *, AvoEventSchemaType *> *) schema;

@end

NS_ASSUME_NONNULL_END
