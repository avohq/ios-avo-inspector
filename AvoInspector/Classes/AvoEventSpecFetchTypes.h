#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Wire format - Property constraints with short field names.
/// At most one constraint type will be present per property.
@interface AvoPropertyConstraintsWire : NSObject

/// Type name (for reference only, not validated)
@property (nonatomic, copy) NSString *t;
/// Required flag (for reference only, not validated)
@property (nonatomic, assign) BOOL r;
/// List flag - true if this is an array/list of the type
@property (nonatomic, strong, nullable) NSNumber *l;
/// Pinned values: pinnedValue -> eventIds that require this exact value
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSArray<NSString *> *> *p;
/// Allowed values: JSON array string -> eventIds that accept these values
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSArray<NSString *> *> *v;
/// Regex patterns: pattern -> eventIds that require matching this regex
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSArray<NSString *> *> *rx;
/// Min/max ranges: "min,max" -> eventIds that require value in this range
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSArray<NSString *> *> *minmax;
/// Nested property constraints for object properties
@property (nonatomic, copy, nullable) NSDictionary<NSString *, AvoPropertyConstraintsWire *> *children;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

/// Wire format - Event spec entry with short field names.
/// A single event entry (base event + its variants).
/// Multiple events can match the same name request due to name mapping.
@interface AvoEventSpecEntryWire : NSObject

/// Branch identifier
@property (nonatomic, copy) NSString *b;
/// Base event ID
@property (nonatomic, copy) NSString *eventId;
/// Variant IDs (baseEventId + variantIds = complete set)
@property (nonatomic, copy) NSArray<NSString *> *vids;
/// Property constraints keyed by property name
@property (nonatomic, copy) NSDictionary<NSString *, AvoPropertyConstraintsWire *> *p;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

/// Metadata returned with the event spec response.
@interface AvoEventSpecMetadata : NSObject

/// Schema identifier
@property (nonatomic, copy) NSString *schemaId;
/// Branch identifier
@property (nonatomic, copy) NSString *branchId;
/// Latest action identifier
@property (nonatomic, copy) NSString *latestActionId;
/// Optional source identifier
@property (nonatomic, copy, nullable) NSString *sourceId;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

/// Wire format - Response from getEventSpec endpoint.
/// Contains array of events that match the requested name (due to name mapping).
@interface AvoEventSpecResponseWire : NSObject

/// Array of events matching the requested name
@property (nonatomic, copy) NSArray<AvoEventSpecEntryWire *> *events;
/// Schema metadata (keeps long names - small, one per response)
@property (nonatomic, strong) AvoEventSpecMetadata *metadata;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

/// Internal - Property constraints with meaningful field names.
/// At most one constraint type will be present per property.
@interface AvoPropertyConstraints : NSObject

/// Type name (for reference only, not validated)
@property (nonatomic, copy) NSString *type;
/// Required flag (for reference only, not validated)
@property (nonatomic, assign) BOOL required;
/// List flag - true if this is an array/list of items
@property (nonatomic, strong, nullable) NSNumber *isList;
/// Pinned values: pinnedValue -> eventIds that require this exact value
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSArray<NSString *> *> *pinnedValues;
/// Allowed values: JSON array string -> eventIds that accept these values
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSArray<NSString *> *> *allowedValues;
/// Regex patterns: pattern -> eventIds that require matching this regex
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSArray<NSString *> *> *regexPatterns;
/// Min/max ranges: "min,max" -> eventIds that require value in this range
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSArray<NSString *> *> *minMaxRanges;
/// Nested property constraints for object properties (for objects or list of objects)
@property (nonatomic, copy, nullable) NSDictionary<NSString *, AvoPropertyConstraints *> *children;

- (instancetype)initFromWire:(AvoPropertyConstraintsWire *)wire;

@end

/// Internal - Event spec entry with meaningful field names.
/// A single event entry (base event + its variants).
@interface AvoEventSpecEntry : NSObject

/// Branch identifier
@property (nonatomic, copy) NSString *branchId;
/// Base event ID
@property (nonatomic, copy) NSString *baseEventId;
/// Variant IDs (baseEventId + variantIds = complete set)
@property (nonatomic, copy) NSArray<NSString *> *variantIds;
/// Property constraints keyed by property name
@property (nonatomic, copy) NSDictionary<NSString *, AvoPropertyConstraints *> *props;

- (instancetype)initFromWire:(AvoEventSpecEntryWire *)wire;

@end

/// Internal - Parsed response from getEventSpec endpoint.
/// Contains array of events that match the requested name (due to name mapping).
@interface AvoEventSpecResponse : NSObject

/// Array of events matching the requested name
@property (nonatomic, copy) NSArray<AvoEventSpecEntry *> *events;
/// Schema metadata
@property (nonatomic, strong) AvoEventSpecMetadata *metadata;

- (instancetype)initFromWire:(AvoEventSpecResponseWire *)wire;

@end

/// Cache entry for storing event specs with metadata.
@interface AvoEventSpecCacheEntry : NSObject

/// The cached event specification response (internal format)
@property (nonatomic, strong, nullable) AvoEventSpecResponse *spec;
/// Timestamp when this entry was cached (used for TTL expiration)
@property (nonatomic, assign) long long timestamp;
/// Timestamp when this entry was last accessed (used for LRU eviction)
@property (nonatomic, assign) long long lastAccessed;
/// Number of cache hits since this entry was cached
@property (nonatomic, assign) int eventCount;

- (instancetype)initWithSpec:(AvoEventSpecResponse * _Nullable)spec
                   timestamp:(long long)timestamp;

@end

/// Parameters for fetching event specifications from the API.
@interface AvoFetchEventSpecParams : NSObject

/// The API key
@property (nonatomic, copy) NSString *apiKey;
/// The stream ID
@property (nonatomic, copy) NSString *streamId;
/// The name of the event
@property (nonatomic, copy) NSString *eventName;

- (instancetype)initWithApiKey:(NSString *)apiKey
                      streamId:(NSString *)streamId
                     eventName:(NSString *)eventName;

@end

/// Result of validating a single property.
/// Contains either failedEventIds or passedEventIds (whichever is smaller for bandwidth).
@interface AvoPropertyValidationResult : NSObject

/// Event/variant IDs that FAILED validation (present if smaller or equal to passed)
@property (nonatomic, copy, nullable) NSArray<NSString *> *failedEventIds;
/// Event/variant IDs that PASSED validation (present if smaller than failed)
@property (nonatomic, copy, nullable) NSArray<NSString *> *passedEventIds;
/// Nested validation results for child properties of object properties
@property (nonatomic, copy, nullable) NSDictionary<NSString *, AvoPropertyValidationResult *> *children;

@end

/// Result of validating all properties in an event.
/// Maps property name to its validation result.
@interface AvoValidationResult : NSObject

/// Event spec metadata
@property (nonatomic, strong, nullable) AvoEventSpecMetadata *metadata;
/// Validation results per property
@property (nonatomic, copy) NSDictionary<NSString *, AvoPropertyValidationResult *> *propertyResults;

@end

NS_ASSUME_NONNULL_END