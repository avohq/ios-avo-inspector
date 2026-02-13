//
//  AvoEventSpecCache.m
//  AvoInspector
//
//  Event spec cache with TTL and LRU eviction.
//  Hand-written, ported from Android EventSpecCache.java.
//

#import "AvoEventSpecCache.h"
#import "AvoEventSpecFetchTypes.h"
#import "AvoInspector.h"

static const long long TTL_MS = 60000;
static const int MAX_EVENT_COUNT = 50;

@interface AvoEventSpecCache ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, AvoEventSpecCacheEntry *> *cache;
@property (nonatomic, assign) int globalEventCount;

@end

@implementation AvoEventSpecCache

- (instancetype)init {
    self = [super init];
    if (self) {
        _cache = [NSMutableDictionary dictionary];
        _globalEventCount = 0;
    }
    return self;
}

- (long long)currentTimeMillis {
    return (long long)([[NSDate date] timeIntervalSince1970] * 1000);
}

- (AvoEventSpecResponse * _Nullable)get:(NSString *)key {
    @synchronized (self.cache) {
        AvoEventSpecCacheEntry *entry = self.cache[key];
        if (entry == nil) {
            return nil;
        }

        long long now = [self currentTimeMillis];
        if ([self shouldEvict:entry now:now]) {
            [self.cache removeObjectForKey:key];
            return nil;
        }

        entry.lastAccessed = now;
        return entry.spec;
    }
}

- (void)set:(NSString *)key spec:(AvoEventSpecResponse * _Nullable)spec {
    @synchronized (self.cache) {
        long long now = [self currentTimeMillis];
        BOOL isUpdate = (self.cache[key] != nil);

        self.globalEventCount++;
        if (!isUpdate && self.cache.count >= MAX_EVENT_COUNT) {
            [self evictOldest];
        }

        AvoEventSpecCacheEntry *entry = [[AvoEventSpecCacheEntry alloc] initWithSpec:spec timestamp:now];
        entry.eventCount = self.globalEventCount;
        self.cache[key] = entry;
    }
}

- (BOOL)contains:(NSString *)key {
    @synchronized (self.cache) {
        AvoEventSpecCacheEntry *entry = self.cache[key];
        if (entry == nil) {
            return NO;
        }

        long long now = [self currentTimeMillis];
        if ([self shouldEvict:entry now:now]) {
            [self.cache removeObjectForKey:key];
            return NO;
        }

        return YES;
    }
}

- (void)clear {
    @synchronized (self.cache) {
        [self.cache removeAllObjects];
    }
}

- (NSInteger)size {
    @synchronized (self.cache) {
        return self.cache.count;
    }
}

- (BOOL)shouldEvict:(AvoEventSpecCacheEntry *)entry now:(long long)now {
    long long age = now - entry.timestamp;
    return age > TTL_MS;
}

- (void)evictOldest {
    NSString *oldestKey = nil;
    long long oldestAccess = LLONG_MAX;

    for (NSString *key in self.cache) {
        AvoEventSpecCacheEntry *entry = self.cache[key];
        if (entry.lastAccessed < oldestAccess) {
            oldestAccess = entry.lastAccessed;
            oldestKey = key;
        }
    }

    if (oldestKey != nil) {
        [self.cache removeObjectForKey:oldestKey];
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Evicted oldest cache entry: %@", oldestKey);
        }
    }
}

+ (NSString *)generateKey:(NSString *)apiKey streamId:(NSString *)streamId eventName:(NSString *)eventName {
    return [NSString stringWithFormat:@"%@:%@:%@", apiKey, streamId, eventName];
}

@end
