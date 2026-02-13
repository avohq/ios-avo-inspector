//
//  AvoEventValidator.h
//  AvoInspector
//
//  Validates event properties against event spec constraints.
//  Hand-written, ported from Android EventValidator.java.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AvoEventSpecResponse;
@class AvoValidationResult;

@interface AvoEventValidator : NSObject

/// Validate event properties against the given event spec response.
/// Returns nil if no validation could be performed.
+ (AvoValidationResult * _Nullable)validateEvent:(NSDictionary<NSString *, id> *)properties
                                     specResponse:(AvoEventSpecResponse *)specResponse;

@end

NS_ASSUME_NONNULL_END
