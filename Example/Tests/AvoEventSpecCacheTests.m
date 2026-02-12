//
//  AvoEventSpecCacheTests.m
//  AvoStateOfTracking_Tests
//

#import <AvoInspector/AvoEventSpecCache.h>
#import <AvoInspector/AvoEventSpecFetchTypes.h>

@interface AvoEventSpecCache ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, AvoEventSpecCacheEntry *> *cache;
@property (nonatomic, assign) int globalEventCount;
@end

SpecBegin(EventSpecCache)

describe(@"AvoEventSpecCache", ^{

    __block AvoEventSpecCache *cache;

    beforeEach(^{
        cache = [[AvoEventSpecCache alloc] init];
    });

    it(@"starts empty", ^{
        expect([cache size]).to.equal(0);
        expect([cache contains:@"key"]).to.beFalsy();
        expect([cache get:@"key"]).to.beNil();
    });

    it(@"stores and retrieves a spec", ^{
        AvoEventSpecResponse *spec = [[AvoEventSpecResponse alloc] init];
        [cache set:@"key1" spec:spec];

        expect([cache size]).to.equal(1);
        expect([cache contains:@"key1"]).to.beTruthy();
        expect([cache get:@"key1"]).to.equal(spec);
    });

    it(@"stores nil spec (cache miss marker)", ^{
        [cache set:@"key1" spec:nil];

        expect([cache size]).to.equal(1);
        expect([cache contains:@"key1"]).to.beTruthy();
        expect([cache get:@"key1"]).to.beNil();
    });

    it(@"clears all entries", ^{
        AvoEventSpecResponse *spec = [[AvoEventSpecResponse alloc] init];
        [cache set:@"key1" spec:spec];
        [cache set:@"key2" spec:spec];

        expect([cache size]).to.equal(2);

        [cache clear];

        expect([cache size]).to.equal(0);
        expect([cache contains:@"key1"]).to.beFalsy();
        expect([cache contains:@"key2"]).to.beFalsy();
    });

    it(@"generates correct cache key", ^{
        NSString *key = [AvoEventSpecCache generateKey:@"apiKey" streamId:@"stream1" eventName:@"Event Name"];
        expect(key).to.equal(@"apiKey:stream1:Event Name");
    });

    it(@"evicts oldest entry when max event count reached", ^{
        // Fill cache with 50 entries then trigger eviction
        AvoEventSpecResponse *spec = [[AvoEventSpecResponse alloc] init];
        for (int i = 0; i < 49; i++) {
            NSString *key = [NSString stringWithFormat:@"key%d", i];
            [cache set:key spec:spec];
        }
        expect([cache size]).to.equal(49);

        // Backdate key0 to make it the oldest
        AvoEventSpecCacheEntry *oldestEntry = cache.cache[@"key0"];
        oldestEntry.lastAccessed = oldestEntry.lastAccessed - 10000;

        // Add the 50th entry - this triggers eviction of the oldest (key0)
        [cache set:@"key49" spec:spec];

        expect([cache contains:@"key0"]).to.beFalsy();
        expect([cache contains:@"key1"]).to.beTruthy();
        expect([cache contains:@"key49"]).to.beTruthy();
    });

    it(@"overwrites existing key", ^{
        AvoEventSpecResponse *spec1 = [[AvoEventSpecResponse alloc] init];
        AvoEventSpecResponse *spec2 = [[AvoEventSpecResponse alloc] init];

        [cache set:@"key1" spec:spec1];
        [cache set:@"key1" spec:spec2];

        expect([cache size]).to.equal(1);
        expect([cache get:@"key1"]).to.equal(spec2);
    });

    it(@"expires entries after TTL", ^{
        AvoEventSpecResponse *spec = [[AvoEventSpecResponse alloc] init];
        [cache set:@"key1" spec:spec];

        // Manually expire the entry by backdating its timestamp
        AvoEventSpecCacheEntry *entry = cache.cache[@"key1"];
        entry.timestamp = entry.timestamp - 61000; // 61 seconds ago

        expect([cache contains:@"key1"]).to.beFalsy();
        expect([cache get:@"key1"]).to.beNil();
        expect([cache size]).to.equal(0); // entry was removed on access
    });
});

SpecEnd
