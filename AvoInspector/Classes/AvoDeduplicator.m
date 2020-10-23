//
//  AvoDeduplicator.m
//  AvoInspector
//
//  Created by Alex Verein on 10.07.2020.
//

#import "AvoDeduplicator.h"
#import "AvoSchemaExtractor.h"

@interface AvoDeduplicator()

@property (readwrite, nonatomic) NSMutableDictionary<NSNumber *, NSString *> * avoFunctionsEvents;
@property (readwrite, nonatomic) NSMutableDictionary<NSNumber *, NSString *> * manualEvents;

@property (readwrite, nonatomic) NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> * avoFunctionsEventsParams;
@property (readwrite, nonatomic) NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> * manualEventsParams;

@property (readwrite, nonatomic) AvoSchemaExtractor *avoSchemaExtractor;

@end

@implementation AvoDeduplicator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.avoFunctionsEvents = [NSMutableDictionary new];
        self.manualEvents = [NSMutableDictionary new];
        self.avoFunctionsEventsParams = [NSMutableDictionary new];
        self.manualEventsParams = [NSMutableDictionary new];
        self.avoSchemaExtractor = [AvoSchemaExtractor new];
    }
    return self;
}

- (void) clear
{
    @synchronized (self) {
        self.avoFunctionsEvents = [NSMutableDictionary new];
        self.manualEvents = [NSMutableDictionary new];
        self.avoFunctionsEventsParams = [NSMutableDictionary new];
        self.manualEventsParams = [NSMutableDictionary new];
        self.avoSchemaExtractor = [AvoSchemaExtractor new];
    }
}

+ (id) sharedDeduplicator {
    static AvoDeduplicator *sharedAvoDeduplicator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAvoDeduplicator = [[self alloc] init];
    });
    return sharedAvoDeduplicator;
}

- (BOOL) shouldRegisterEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params fromAvoFunction:(BOOL) fromAvoFunction {
    if (eventName == nil) {
        return NO;
    }
    
    [self clearOldEvents];
    
    @synchronized (self) {
        if (fromAvoFunction) {
            [self.avoFunctionsEvents setObject:eventName forKey:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
            [self.avoFunctionsEventsParams setObject:params forKey:eventName];
        } else {
            [self.manualEvents setObject:eventName forKey:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
            [self.manualEventsParams setObject:params forKey:eventName];
        }
    }
    
    BOOL checkInAvoFunctions = !fromAvoFunction;
    
    return ![self hasSameEventAs:eventName eventParams:params checkInAvoFunctions:checkInAvoFunctions];
}

- (BOOL) hasSeenEventParams:(NSDictionary<NSString *, id> *) params checkInAvoFunctions:(BOOL) checkInAvoFunctions {
    BOOL hasSeen = NO;
    if (checkInAvoFunctions) {
        if ([self lookForEventParams:params in:self.avoFunctionsEventsParams]) {
            hasSeen = YES;
        }
    } else {
        if ([self lookForEventParams:params in:self.manualEventsParams]) {
            hasSeen = YES;
        }
    }
    
    return hasSeen;
}

- (BOOL) lookForEventParams:(NSDictionary<NSString *, id> *) params in:(NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *) eventsStorage {
    __block BOOL result = NO;
    @synchronized (self) {
        [eventsStorage enumerateKeysAndObjectsUsingBlock:^(id otherEventName, id otherEventParams, BOOL* stop) {
            if ([params isEqualToDictionary:otherEventParams]) {
                result = YES;
                *stop = YES;
            }
        }];
    }
    return result;
}

- (BOOL) hasSameEventAs:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params checkInAvoFunctions:(BOOL) checkInAvoFunctions {
    
    BOOL hasSameEvents = NO;
    if (checkInAvoFunctions) {
        if ([self lookForEventName:eventName withParams:params in:self.avoFunctionsEventsParams]) {
            hasSameEvents = YES;
        }
    } else {
        if ([self lookForEventName:eventName withParams:params in:self.manualEventsParams]) {
            hasSameEvents = YES;
        }
    }
    
    if (hasSameEvents) {
        @synchronized (self) {
            [self.avoFunctionsEventsParams removeObjectForKey:eventName];
            [self.manualEventsParams removeObjectForKey:eventName];
        }
    }
    
    return hasSameEvents;
}

- (BOOL) lookForEventName:(NSString *) eventName withParams:(NSDictionary<NSString *, id> *) params in:(NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *) eventsStorage {
    __block BOOL result = NO;
    @synchronized (self) {
        [eventsStorage enumerateKeysAndObjectsUsingBlock: ^(id otherEventName, id otherEventParams, BOOL* stop) {
            if (otherEventName == eventName && [params isEqualToDictionary:otherEventParams]) {
                result = YES;
                *stop = YES;
            }
        }];
    }
    return result;
}

- (BOOL) shouldRegisterSchemaFromManually:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema {
    if (eventName == nil) {
        return NO;
    }
    
    [self clearOldEvents];
    
    BOOL shouldRegisterSchema = YES;
    
    if ([self lookForEventName:eventName withSchema:schema in:self.avoFunctionsEventsParams]) {
        shouldRegisterSchema = NO;
    }
    
    if (!shouldRegisterSchema) {
        @synchronized (self) {
            [self.avoFunctionsEventsParams removeObjectForKey:eventName];
        }
    }
    
    return shouldRegisterSchema;
}

- (BOOL) lookForEventName:(NSString *) eventName withSchema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema in:(NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *) eventsStorage {
    __block BOOL result = NO;
    @synchronized (self) {
        [eventsStorage enumerateKeysAndObjectsUsingBlock:^(id otherEventName, id otherEventParams, BOOL* stop) {
            NSDictionary * otherSchema = [self.avoSchemaExtractor extractSchema:otherEventParams];
            if (otherEventName == eventName && [schema isEqualToDictionary:otherSchema]) {
                result = YES;
                *stop = YES;
            }
        }];
    }
    return result;
}

- (void) clearOldEvents {
    @synchronized (self) {
        NSNumber * now = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        double secondsToConsiderOld = 0.3;
        
        NSMutableArray * timestampsToRemove = [NSMutableArray new];
        for (NSNumber * timestamp in [self.avoFunctionsEvents allKeys]) {
            if ([now doubleValue] - [timestamp doubleValue] > secondsToConsiderOld) {
                NSString * eventName = [self.avoFunctionsEvents objectForKey:timestamp];
                [timestampsToRemove addObject:timestamp];
                if (eventName != nil) {
                    [self.avoFunctionsEventsParams removeObjectForKey:eventName];
                }
            }
        }
        
        for (NSNumber * timestamp in timestampsToRemove) {
            if (timestamp != nil) {
                [self.avoFunctionsEvents removeObjectForKey:timestamp];
            }
        }
        
        timestampsToRemove = [NSMutableArray new];
        for (NSNumber * timestamp in [self.manualEvents allKeys]) {
            if ([now doubleValue] - [timestamp doubleValue] > secondsToConsiderOld) {
                NSString * eventName = [self.manualEvents objectForKey:timestamp];
                [timestampsToRemove addObject:timestamp];
                if (eventName != nil) {
                    [self.manualEventsParams removeObjectForKey:eventName];
                }
            }
        }
        
        for (NSNumber * timestamp in timestampsToRemove) {
            if (timestamp != nil) {
                [self.manualEvents removeObjectForKey:timestamp];
            }
        }
    }
}

@end
