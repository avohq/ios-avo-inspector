//
//  AvoEventValidator.m
//  AvoInspector
//
//  Validates event properties against event spec constraints.
//  Hand-written, ported from Android EventValidator.java.
//

#import "AvoEventValidator.h"
#import "AvoEventSpecFetchTypes.h"
#import "AvoInspector.h"

static const int MAX_CHILD_DEPTH = 2;

@implementation AvoEventValidator

static NSCache *regexCache = nil;
static NSCache *allowedValuesCache = nil;

+ (void)initialize {
    if (self == [AvoEventValidator class]) {
        regexCache = [[NSCache alloc] init];
        regexCache.countLimit = 100;
        allowedValuesCache = [[NSCache alloc] init];
        allowedValuesCache.countLimit = 100;
    }
}

#pragma mark - Public

+ (AvoValidationResult * _Nullable)validateEvent:(NSDictionary<NSString *, id> *)properties
                                     specResponse:(AvoEventSpecResponse *)specResponse {
    if (specResponse == nil || specResponse.events == nil || specResponse.events.count == 0) {
        return nil;
    }

    @try {
        NSArray<NSString *> *allEventIds = [self collectAllEventIds:specResponse];
        if (allEventIds.count == 0) {
            return nil;
        }

        NSDictionary<NSString *, AvoPropertyConstraints *> *mergedConstraints =
            [self collectConstraintsByPropertyName:specResponse];

        AvoValidationResult *result = [[AvoValidationResult alloc] init];
        result.metadata = specResponse.metadata;

        NSMutableDictionary<NSString *, AvoPropertyValidationResult *> *propertyResults =
            [NSMutableDictionary dictionary];

        // Iterate over event properties (not spec constraints) — aligned with Android
        for (NSString *propName in properties) {
            id value = properties[propName];
            AvoPropertyConstraints *constraints = mergedConstraints[propName];

            if (constraints == nil) {
                // Property not in spec — no constraints to fail
                propertyResults[propName] = [[AvoPropertyValidationResult alloc] init];
            } else {
                AvoPropertyValidationResult *propResult =
                    [self validatePropertyConstraints:constraints
                                               value:value
                                         allEventIds:allEventIds
                                               depth:0];

                if (propResult != nil) {
                    propertyResults[propName] = propResult;
                } else {
                    propertyResults[propName] = [[AvoPropertyValidationResult alloc] init];
                }
            }
        }

        result.propertyResults = [propertyResults copy];
        return result;
    } @catch (NSException *e) {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Error validating event: %@", e);
        }
        return nil;
    }
}

#pragma mark - Collect Event IDs

+ (NSArray<NSString *> *)collectAllEventIds:(AvoEventSpecResponse *)specResponse {
    NSMutableArray<NSString *> *ids = [NSMutableArray array];
    for (AvoEventSpecEntry *entry in specResponse.events) {
        if (entry.baseEventId != nil) {
            [ids addObject:entry.baseEventId];
        }
        if (entry.variantIds != nil) {
            [ids addObjectsFromArray:entry.variantIds];
        }
    }
    return [ids copy];
}

#pragma mark - Merge Constraints

+ (NSDictionary<NSString *, AvoPropertyConstraints *> *)collectConstraintsByPropertyName:(AvoEventSpecResponse *)specResponse {
    NSMutableDictionary<NSString *, AvoPropertyConstraints *> *merged = [NSMutableDictionary dictionary];

    for (AvoEventSpecEntry *entry in specResponse.events) {
        if (entry.props == nil) continue;

        for (NSString *propName in entry.props) {
            AvoPropertyConstraints *constraint = entry.props[propName];
            AvoPropertyConstraints *existing = merged[propName];

            if (existing == nil) {
                merged[propName] = [self deepCopyConstraints:constraint];
            } else {
                [self mergeConstraintsInto:existing from:constraint];
            }
        }
    }

    return [merged copy];
}

+ (AvoPropertyConstraints *)deepCopyConstraints:(AvoPropertyConstraints *)src {
    AvoPropertyConstraints *copy = [[AvoPropertyConstraints alloc] init];
    copy.type = src.type;
    copy.required = src.required;
    copy.isList = src.isList;
    copy.pinnedValues = src.pinnedValues ? [self deepCopyMapping:src.pinnedValues] : nil;
    copy.allowedValues = src.allowedValues ? [self deepCopyMapping:src.allowedValues] : nil;
    copy.regexPatterns = src.regexPatterns ? [self deepCopyMapping:src.regexPatterns] : nil;
    copy.minMaxRanges = src.minMaxRanges ? [self deepCopyMapping:src.minMaxRanges] : nil;

    if (src.children != nil) {
        NSMutableDictionary *childCopy = [NSMutableDictionary dictionary];
        for (NSString *key in src.children) {
            childCopy[key] = [self deepCopyConstraints:src.children[key]];
        }
        copy.children = [childCopy copy];
    }

    return copy;
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)deepCopyMapping:(NSDictionary<NSString *, NSArray<NSString *> *> *)src {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:src.count];
    for (NSString *key in src) {
        result[key] = [src[key] mutableCopy];
    }
    return [result copy];
}

+ (void)mergeConstraintsInto:(AvoPropertyConstraints *)target from:(AvoPropertyConstraints *)source {
    target.pinnedValues = [self mergeMapping:target.pinnedValues with:source.pinnedValues];
    target.allowedValues = [self mergeMapping:target.allowedValues with:source.allowedValues];
    target.regexPatterns = [self mergeMapping:target.regexPatterns with:source.regexPatterns];
    target.minMaxRanges = [self mergeMapping:target.minMaxRanges with:source.minMaxRanges];

    if (source.children != nil) {
        if (target.children == nil) {
            NSMutableDictionary *childCopy = [NSMutableDictionary dictionary];
            for (NSString *key in source.children) {
                childCopy[key] = [self deepCopyConstraints:source.children[key]];
            }
            target.children = [childCopy copy];
        } else {
            NSMutableDictionary *mergedChildren = [target.children mutableCopy];
            for (NSString *key in source.children) {
                AvoPropertyConstraints *existingChild = mergedChildren[key];
                if (existingChild == nil) {
                    mergedChildren[key] = [self deepCopyConstraints:source.children[key]];
                } else {
                    [self mergeConstraintsInto:existingChild from:source.children[key]];
                }
            }
            target.children = [mergedChildren copy];
        }
    }
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> * _Nullable)mergeMapping:(NSDictionary<NSString *, NSArray<NSString *> *> * _Nullable)target
                                                                       with:(NSDictionary<NSString *, NSArray<NSString *> *> * _Nullable)source {
    if (source == nil) return target;
    if (target == nil) return [self deepCopyMapping:source];

    NSMutableDictionary *result = [target mutableCopy];
    for (NSString *key in source) {
        NSMutableArray *existing = [result[key] mutableCopy];
        if (existing == nil) {
            result[key] = [source[key] mutableCopy];
        } else {
            NSMutableSet *existingSet = [NSMutableSet setWithArray:existing];
            for (NSString *id_ in source[key]) {
                if (![existingSet containsObject:id_]) {
                    [existing addObject:id_];
                    [existingSet addObject:id_];
                }
            }
            result[key] = [existing copy];
        }
    }
    return [result copy];
}

#pragma mark - Validate Property

+ (AvoPropertyValidationResult * _Nullable)validatePropertyConstraints:(AvoPropertyConstraints *)constraints
                                                                 value:(id _Nullable)value
                                                           allEventIds:(NSArray<NSString *> *)allEventIds
                                                                 depth:(int)depth {
    if (constraints.isList != nil && [constraints.isList boolValue]) {
        return [self validateListProperty:constraints value:value allEventIds:allEventIds depth:depth];
    }

    if (constraints.children != nil && constraints.children.count > 0) {
        return [self validateObjectProperty:constraints value:value allEventIds:allEventIds depth:depth];
    }

    return [self validatePrimitiveProperty:constraints value:value allEventIds:allEventIds];
}

#pragma mark - Primitive Validation

+ (AvoPropertyValidationResult * _Nullable)validatePrimitiveProperty:(AvoPropertyConstraints *)constraints
                                                               value:(id _Nullable)value
                                                         allEventIds:(NSArray<NSString *> *)allEventIds {

    // Skip validation for null values on non-required properties (aligned with Android)
    if ((value == nil || value == [NSNull null]) && !constraints.required) {
        return nil;
    }

    NSMutableSet<NSString *> *failedIds = [NSMutableSet set];

    if (constraints.pinnedValues != nil) {
        [self checkPinnedValues:constraints.pinnedValues value:value failedIds:failedIds];
    }

    if (constraints.allowedValues != nil) {
        [self checkAllowedValues:constraints.allowedValues value:value failedIds:failedIds];
    }

    if (constraints.regexPatterns != nil) {
        [self checkRegexPatterns:constraints.regexPatterns value:value failedIds:failedIds];
    }

    if (constraints.minMaxRanges != nil) {
        [self checkMinMaxRanges:constraints.minMaxRanges value:value failedIds:failedIds];
    }

    if (failedIds.count == 0) {
        return nil;
    }

    return [self buildValidationResult:failedIds allEventIds:allEventIds];
}

#pragma mark - Object Validation

+ (AvoPropertyValidationResult * _Nullable)validateObjectProperty:(AvoPropertyConstraints *)constraints
                                                             value:(id _Nullable)value
                                                       allEventIds:(NSArray<NSString *> *)allEventIds
                                                             depth:(int)depth {
    if (depth >= MAX_CHILD_DEPTH) {
        return nil;
    }

    AvoPropertyValidationResult *selfResult =
        [self validatePrimitiveProperty:constraints value:value allEventIds:allEventIds];

    NSDictionary *objectValue = nil;
    if ([value isKindOfClass:[NSDictionary class]]) {
        objectValue = (NSDictionary *)value;
    }

    NSMutableDictionary<NSString *, AvoPropertyValidationResult *> *childResults = nil;

    if (constraints.children != nil) {
        for (NSString *childName in constraints.children) {
            AvoPropertyConstraints *childConstraints = constraints.children[childName];
            id childValue = objectValue != nil ? objectValue[childName] : nil;

            AvoPropertyValidationResult *childResult =
                [self validatePropertyConstraints:childConstraints
                                           value:childValue
                                     allEventIds:allEventIds
                                           depth:depth + 1];

            if (childResult != nil) {
                if (childResults == nil) {
                    childResults = [NSMutableDictionary dictionary];
                }
                childResults[childName] = childResult;
            }
        }
    }

    if (selfResult == nil && childResults == nil) {
        return nil;
    }

    AvoPropertyValidationResult *result = selfResult != nil ? selfResult : [[AvoPropertyValidationResult alloc] init];
    if (childResults != nil) {
        result.children = [childResults copy];
    }
    return result;
}

#pragma mark - List Validation

+ (AvoPropertyValidationResult * _Nullable)validateListProperty:(AvoPropertyConstraints *)constraints
                                                           value:(id _Nullable)value
                                                     allEventIds:(NSArray<NSString *> *)allEventIds
                                                           depth:(int)depth {
    if (depth >= MAX_CHILD_DEPTH) {
        return nil;
    }

    NSArray *listValue = nil;
    if ([value isKindOfClass:[NSArray class]]) {
        listValue = (NSArray *)value;
    }

    if (listValue == nil || listValue.count == 0) {
        return [self validatePrimitiveProperty:constraints value:value allEventIds:allEventIds];
    }

    NSMutableSet<NSString *> *allFailed = [NSMutableSet set];
    NSMutableDictionary<NSString *, AvoPropertyValidationResult *> *allChildResults = nil;

    for (id item in listValue) {
        AvoPropertyValidationResult *itemResult;

        if (constraints.children != nil && constraints.children.count > 0) {
            itemResult = [self validateObjectProperty:constraints value:item allEventIds:allEventIds depth:depth];
        } else {
            itemResult = [self validatePrimitiveProperty:constraints value:item allEventIds:allEventIds];
        }

        if (itemResult != nil) {
            if (itemResult.failedEventIds != nil) {
                [allFailed addObjectsFromArray:itemResult.failedEventIds];
            }
            if (itemResult.passedEventIds != nil) {
                NSMutableSet *passedAsInverted = [NSMutableSet setWithArray:allEventIds];
                [passedAsInverted minusSet:[NSSet setWithArray:itemResult.passedEventIds]];
                [allFailed unionSet:passedAsInverted];
            }
            if (itemResult.children != nil) {
                if (allChildResults == nil) {
                    allChildResults = [NSMutableDictionary dictionary];
                }
                for (NSString *key in itemResult.children) {
                    AvoPropertyValidationResult *existingChild = allChildResults[key];
                    AvoPropertyValidationResult *newChild = itemResult.children[key];
                    if (existingChild == nil) {
                        allChildResults[key] = newChild;
                    } else {
                        [self mergeValidationResults:existingChild from:newChild allEventIds:allEventIds];
                    }
                }
            }
        }
    }

    if (allFailed.count == 0 && allChildResults == nil) {
        return nil;
    }

    AvoPropertyValidationResult *result;
    if (allFailed.count > 0) {
        result = [self buildValidationResult:allFailed allEventIds:allEventIds];
    } else {
        result = [[AvoPropertyValidationResult alloc] init];
    }

    if (allChildResults != nil) {
        result.children = [allChildResults copy];
    }

    return result;
}

+ (void)mergeValidationResults:(AvoPropertyValidationResult *)target
                          from:(AvoPropertyValidationResult *)source
                   allEventIds:(NSArray<NSString *> *)allEventIds {
    NSMutableSet<NSString *> *targetFailed = [NSMutableSet set];

    if (target.failedEventIds != nil) {
        [targetFailed addObjectsFromArray:target.failedEventIds];
    } else if (target.passedEventIds != nil) {
        [targetFailed addObjectsFromArray:allEventIds];
        [targetFailed minusSet:[NSSet setWithArray:target.passedEventIds]];
    }

    if (source.failedEventIds != nil) {
        [targetFailed addObjectsFromArray:source.failedEventIds];
    } else if (source.passedEventIds != nil) {
        NSMutableSet *sourceFailed = [NSMutableSet setWithArray:allEventIds];
        [sourceFailed minusSet:[NSSet setWithArray:source.passedEventIds]];
        [targetFailed unionSet:sourceFailed];
    }

    if (targetFailed.count > 0) {
        AvoPropertyValidationResult *merged = [self buildValidationResult:targetFailed allEventIds:allEventIds];
        target.failedEventIds = merged.failedEventIds;
        target.passedEventIds = merged.passedEventIds;
    }

    if (source.children != nil) {
        NSMutableDictionary<NSString *, AvoPropertyValidationResult *> *mergedChildren =
            target.children != nil ? [target.children mutableCopy] : [NSMutableDictionary dictionary];

        for (NSString *key in source.children) {
            AvoPropertyValidationResult *existingChild = mergedChildren[key];
            AvoPropertyValidationResult *newChild = source.children[key];
            if (existingChild == nil) {
                mergedChildren[key] = newChild;
            } else {
                [self mergeValidationResults:existingChild from:newChild allEventIds:allEventIds];
            }
        }

        target.children = [mergedChildren copy];
    }
}

#pragma mark - Constraint Checks

+ (void)checkPinnedValues:(NSDictionary<NSString *, NSArray<NSString *> *> *)pinnedValues
                    value:(id _Nullable)value
                failedIds:(NSMutableSet<NSString *> *)failedIds {
    NSString *stringValue = [self convertValueToString:value];

    for (NSString *pinnedValue in pinnedValues) {
        NSArray<NSString *> *eventIds = pinnedValues[pinnedValue];
        if (![pinnedValue isEqualToString:stringValue]) {
            [failedIds addObjectsFromArray:eventIds];
        }
    }
}

+ (void)checkAllowedValues:(NSDictionary<NSString *, NSArray<NSString *> *> *)allowedValues
                     value:(id _Nullable)value
                 failedIds:(NSMutableSet<NSString *> *)failedIds {
    NSString *stringValue = [self convertValueToString:value];

    for (NSString *allowedJsonArray in allowedValues) {
        NSArray<NSString *> *eventIds = allowedValues[allowedJsonArray];
        NSArray<NSString *> *allowed = [self getOrParseAllowedValues:allowedJsonArray];

        if (allowed == nil) continue;

        BOOL found = NO;
        for (NSString *allowedItem in allowed) {
            if ([allowedItem isEqualToString:stringValue]) {
                found = YES;
                break;
            }
        }

        if (!found) {
            [failedIds addObjectsFromArray:eventIds];
        }
    }
}

+ (void)checkRegexPatterns:(NSDictionary<NSString *, NSArray<NSString *> *> *)regexPatterns
                     value:(id _Nullable)value
                 failedIds:(NSMutableSet<NSString *> *)failedIds {
    NSString *stringValue = [self convertValueToString:value];
    if (stringValue == nil) {
        for (NSString *pattern in regexPatterns) {
            [failedIds addObjectsFromArray:regexPatterns[pattern]];
        }
        return;
    }

    for (NSString *pattern in regexPatterns) {
        NSArray<NSString *> *eventIds = regexPatterns[pattern];
        NSRegularExpression *regex = [self getOrCompileRegex:pattern];

        if (regex == nil) continue;

        NSUInteger matches = [self safeNumberOfMatchesWithRegex:regex inString:stringValue timeout:2.0];
        if (matches == NSNotFound) {
            // Timed out — skip this constraint (fail-open) and log warning
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Skipping regex constraint '%@' due to timeout", pattern);
            }
            continue;
        }
        if (matches == 0) {
            [failedIds addObjectsFromArray:eventIds];
        }
    }
}

+ (void)checkMinMaxRanges:(NSDictionary<NSString *, NSArray<NSString *> *> *)minMaxRanges
                    value:(id _Nullable)value
                failedIds:(NSMutableSet<NSString *> *)failedIds {
    if (value == nil || ![value isKindOfClass:[NSNumber class]]) {
        for (NSString *range in minMaxRanges) {
            [failedIds addObjectsFromArray:minMaxRanges[range]];
        }
        return;
    }

    double numericValue = [value doubleValue];

    for (NSString *range in minMaxRanges) {
        NSArray<NSString *> *eventIds = minMaxRanges[range];
        NSArray<NSString *> *parts = [range componentsSeparatedByString:@","];

        if (parts.count != 2) continue;

        NSString *minStr = [parts[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *maxStr = [parts[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        BOOL failed = NO;

        if (minStr.length > 0) {
            double minVal = [minStr doubleValue];
            if (numericValue < minVal) {
                failed = YES;
            }
        }

        if (!failed && maxStr.length > 0) {
            double maxVal = [maxStr doubleValue];
            if (numericValue > maxVal) {
                failed = YES;
            }
        }

        if (failed) {
            [failedIds addObjectsFromArray:eventIds];
        }
    }
}

#pragma mark - ReDoS Protection

+ (BOOL)isPatternPotentiallyDangerous:(NSString *)pattern {
    // Detect nested quantifiers: a group containing a quantifier that is itself quantified
    // e.g. (a+)+, (.*)*$, ([a-z]+)*, etc.
    NSError *error = nil;
    NSRegularExpression *nestedQuantifier =
        [NSRegularExpression regularExpressionWithPattern:@"\\([^)]*[+*][^)]*\\)[+*]"
                                                 options:0
                                                   error:&error];
    if (error != nil || nestedQuantifier == nil) {
        return NO;
    }

    NSUInteger matches = [nestedQuantifier numberOfMatchesInString:pattern
                                                           options:0
                                                             range:NSMakeRange(0, pattern.length)];
    if (matches > 0) {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Potentially dangerous regex pattern rejected: '%@'", pattern);
        }
        return YES;
    }
    return NO;
}

+ (NSUInteger)safeNumberOfMatchesWithRegex:(NSRegularExpression *)regex
                                  inString:(NSString *)string
                                   timeout:(NSTimeInterval)timeout {
    __block NSUInteger result = NSNotFound;

    static dispatch_queue_t regexQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regexQueue = dispatch_queue_create("com.avo.inspector.regex", DISPATCH_QUEUE_SERIAL);
    });
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_async(regexQueue, ^{
        result = [regex numberOfMatchesInString:string
                                        options:0
                                          range:NSMakeRange(0, string.length)];
        dispatch_semaphore_signal(semaphore);
    });

    long timedOut = dispatch_semaphore_wait(semaphore,
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));

    if (timedOut != 0) {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Regex execution timed out after %.0fs for pattern '%@'",
                  timeout, regex.pattern);
        }
        return NSNotFound;
    }

    return result;
}

#pragma mark - Helpers

+ (NSString * _Nullable)convertValueToString:(id _Nullable)value {
    if (value == nil || value == [NSNull null]) {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *num = value;
        // Check for boolean: NSNumber wrapping BOOL is of class __NSCFBoolean
        // Use CFBooleanGetTypeID to reliably detect booleans
        if (CFGetTypeID((__bridge CFTypeRef)num) == CFBooleanGetTypeID()) {
            return [num boolValue] ? @"true" : @"false";
        }
        return [num stringValue];
    }
    return [NSString stringWithFormat:@"%@", value];
}

+ (AvoPropertyValidationResult *)buildValidationResult:(NSMutableSet<NSString *> *)failedIds
                                            allEventIds:(NSArray<NSString *> *)allEventIds {
    AvoPropertyValidationResult *result = [[AvoPropertyValidationResult alloc] init];

    NSMutableSet<NSString *> *passedIds = [NSMutableSet setWithArray:allEventIds];
    [passedIds minusSet:failedIds];

    // If both are empty, return empty result
    if (failedIds.count == 0 && passedIds.count == 0) {
        return result;
    }

    // Prefer passedEventIds only when strictly smaller AND non-empty (aligned with Android)
    if (passedIds.count < failedIds.count && passedIds.count > 0) {
        result.passedEventIds = [passedIds allObjects];
    } else if (failedIds.count > 0) {
        result.failedEventIds = [failedIds allObjects];
    }

    return result;
}

+ (NSRegularExpression * _Nullable)getOrCompileRegex:(NSString *)pattern {
    NSRegularExpression *cached = [regexCache objectForKey:pattern];
    if (cached != nil) {
        return cached;
    }

    if ([self isPatternPotentiallyDangerous:pattern]) {
        return nil;
    }

    @try {
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        if (error != nil) {
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Failed to compile regex '%@': %@", pattern, error);
            }
            return nil;
        }
        [regexCache setObject:regex forKey:pattern];
        return regex;
    } @catch (NSException *e) {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Exception compiling regex '%@': %@", pattern, e);
        }
        return nil;
    }
}

+ (NSArray<NSString *> * _Nullable)getOrParseAllowedValues:(NSString *)jsonArrayString {
    NSArray *cached = [allowedValuesCache objectForKey:jsonArrayString];
    if (cached != nil) {
        return cached;
    }

    @try {
        NSData *data = [jsonArrayString dataUsingEncoding:NSUTF8StringEncoding];
        if (data == nil) return nil;

        NSError *error = nil;
        id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error != nil || ![parsed isKindOfClass:[NSArray class]]) {
            return nil;
        }

        NSMutableArray<NSString *> *result = [NSMutableArray array];
        for (id item in parsed) {
            [result addObject:[NSString stringWithFormat:@"%@", item]];
        }

        NSArray *immutable = [result copy];
        [allowedValuesCache setObject:immutable forKey:jsonArrayString];
        return immutable;
    } @catch (NSException *e) {
        return nil;
    }
}

@end
