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

/// Check if a regex pattern contains nested quantifiers that could cause ReDoS.
+ (BOOL)isPatternPotentiallyDangerous:(NSString *)pattern;

/// Execute regex matching with a timeout to prevent ReDoS.
/// Returns NSNotFound if the operation times out.
+ (NSUInteger)safeNumberOfMatchesWithRegex:(NSRegularExpression *)regex
                                  inString:(NSString *)string
                                   timeout:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
