//  AvoEventSpecFetchTypes.m
//
//  Types for event spec fetching and validation.
//  Auto-generated from SoT: EventFetcherTypes.res

#import <Foundation/Foundation.h>
#import "AvoEventSpecFetchTypes.h"

@implementation AvoPropertyConstraintsWire

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _t = dict[@"t"] ?: @"";
        _r = [dict[@"r"] boolValue];
        _l = dict[@"l"];

        _p = dict[@"p"];
        _v = dict[@"v"];
        _rx = dict[@"rx"];
        _minmax = dict[@"minmax"];
        
        NSDictionary *childrenDict = dict[@"children"];
        if (childrenDict) {
            NSMutableDictionary *parsedChildren = [NSMutableDictionary dictionary];
            for (NSString *key in childrenDict) {
                AvoPropertyConstraintsWire *child = [[AvoPropertyConstraintsWire alloc] initWithDictionary:childrenDict[key]];
                parsedChildren[key] = child;
            }
            _children = [parsedChildren copy];
        }
    }
    return self;
}

@end

@implementation AvoEventSpecEntryWire

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _b = dict[@"b"] ?: @"";
        _eventId = dict[@"id"] ?: @"";
        _vids = dict[@"vids"] ?: @[];

        NSDictionary *propsDict = dict[@"p"];
        if (propsDict) {
            NSMutableDictionary *parsedProps = [NSMutableDictionary dictionary];
            for (NSString *key in propsDict) {
                AvoPropertyConstraintsWire *constraint = [[AvoPropertyConstraintsWire alloc] initWithDictionary:propsDict[key]];
                parsedProps[key] = constraint;
            }
            _p = [parsedProps copy];
        } else {
            _p = @{};
        }
    }
    return self;
}

@end

@implementation AvoEventSpecMetadata

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _schemaId = dict[@"schemaId"] ?: @"";
        _branchId = dict[@"branchId"] ?: @"";
        _latestActionId = dict[@"latestActionId"] ?: @"";
        _sourceId = dict[@"sourceId"];
    }
    return self;
}

@end

@implementation AvoEventSpecResponseWire

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        NSArray *eventsArray = dict[@"events"];
        if (eventsArray) {
            NSMutableArray *parsedEvents = [NSMutableArray arrayWithCapacity:eventsArray.count];
            for (NSDictionary *eventDict in eventsArray) {
                AvoEventSpecEntryWire *entry = [[AvoEventSpecEntryWire alloc] initWithDictionary:eventDict];
                [parsedEvents addObject:entry];
            }
            _events = [parsedEvents copy];
        } else {
            _events = @[];
        }
        
        NSDictionary *metadataDict = dict[@"metadata"];
        if (metadataDict) {
            _metadata = [[AvoEventSpecMetadata alloc] initWithDictionary:metadataDict];
        }
    }
    return self;
}

@end

@implementation AvoPropertyConstraints

- (instancetype)initFromWire:(AvoPropertyConstraintsWire *)wire {
    self = [super init];
    if (self) {
        _type = wire.t;
        _required = wire.r;
        _isList = wire.l;
        _pinnedValues = wire.p;
        _allowedValues = wire.v;
        _regexPatterns = wire.rx;
        _minMaxRanges = wire.minmax;
        
        if (wire.children) {
            NSMutableDictionary *parsedChildren = [NSMutableDictionary dictionary];
            for (NSString *key in wire.children) {
                AvoPropertyConstraints *child = [[AvoPropertyConstraints alloc] initFromWire:wire.children[key]];
                parsedChildren[key] = child;
            }
            _children = [parsedChildren copy];
        }
    }
    return self;
}

@end

@implementation AvoEventSpecEntry

- (instancetype)initFromWire:(AvoEventSpecEntryWire *)wire {
    self = [super init];
    if (self) {
        _branchId = wire.b;
        _baseEventId = wire.eventId;
        _variantIds = wire.vids;

        if (wire.p) {
            NSMutableDictionary *parsedProps = [NSMutableDictionary dictionary];
            for (NSString *key in wire.p) {
                AvoPropertyConstraints *constraint = [[AvoPropertyConstraints alloc] initFromWire:wire.p[key]];
                parsedProps[key] = constraint;
            }
            _props = [parsedProps copy];
        } else {
            _props = @{};
        }
    }
    return self;
}

@end

@implementation AvoEventSpecResponse

- (instancetype)initFromWire:(AvoEventSpecResponseWire *)wire {
    self = [super init];
    if (self) {
        if (wire.events) {
            NSMutableArray *parsedEvents = [NSMutableArray arrayWithCapacity:wire.events.count];
            for (AvoEventSpecEntryWire *entryWire in wire.events) {
                AvoEventSpecEntry *entry = [[AvoEventSpecEntry alloc] initFromWire:entryWire];
                [parsedEvents addObject:entry];
            }
            _events = [parsedEvents copy];
        } else {
            _events = @[];
        }
        _metadata = wire.metadata;
    }
    return self;
}

@end

@implementation AvoEventSpecCacheEntry

- (instancetype)initWithSpec:(AvoEventSpecResponse *)spec
                   timestamp:(long long)timestamp {
    self = [super init];
    if (self) {
        _spec = spec;
        _timestamp = timestamp;
        _lastAccessed = timestamp;
        _eventCount = 0;
    }
    return self;
}

@end

@implementation AvoFetchEventSpecParams

- (instancetype)initWithApiKey:(NSString *)apiKey
                      streamId:(NSString *)streamId
                     eventName:(NSString *)eventName {
    self = [super init];
    if (self) {
        _apiKey = [apiKey copy];
        _streamId = [streamId copy];
        _eventName = [eventName copy];
    }
    return self;
}

@end

@implementation AvoPropertyValidationResult

- (instancetype)init {
    self = [super init];
    if (self) {
        _failedEventIds = nil;
        _passedEventIds = nil;
        _children = nil;
    }
    return self;
}

@end

@implementation AvoValidationResult

- (instancetype)init {
    self = [super init];
    if (self) {
        _metadata = nil;
        _propertyResults = @{};
    }
    return self;
}

@end