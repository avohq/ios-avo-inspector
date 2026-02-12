//
//  AvoEventSpecCache.h
//  AvoInspector
//
//  Event spec cache with TTL and LRU eviction.
//  Hand-written, ported from Android EventSpecCache.java.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AvoEventSpecResponse;
@class AvoEventSpecCacheEntry;

@interface AvoEventSpecCache : NSObject

- (instancetype)init;

/// Get cached spec for the given key. Returns nil if not cached or expired.
- (AvoEventSpecResponse * _Nullable)get:(NSString *)key;

/// Cache a spec response (may be nil to cache a miss).
- (void)set:(NSString *)key spec:(AvoEventSpecResponse * _Nullable)spec;

/// Check if a non-expired entry exists for this key.
- (BOOL)contains:(NSString *)key;

/// Clear the entire cache (e.g. on branch change).
- (void)clear;

/// Current number of entries.
- (NSInteger)size;

/// Generate cache key from components.
+ (NSString *)generateKey:(NSString *)apiKey streamId:(NSString *)streamId eventName:(NSString *)eventName;

@end

NS_ASSUME_NONNULL_END
