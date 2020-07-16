//
//  AvoDeduplicator.h
//  AvoInspector
//
//  Created by Alex Verein on 10.07.2020.
//

#import <Foundation/Foundation.h>
#import "AvoEventSchemaType.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoDeduplicator : NSObject

- (BOOL) shouldRegisterEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params fromAvoFunction:(BOOL) fromAvoFunction;

- (BOOL) hasSeenEventParams:(NSDictionary<NSString *, id> *) params checkInAvoFunctions:(BOOL) checkInAvoFunctions;

- (BOOL) shouldRegisterSchemaFromManually:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema;

+ (id) sharedDeduplicator;

@end

NS_ASSUME_NONNULL_END
