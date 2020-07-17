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
    self.avoFunctionsEvents = [NSMutableDictionary new];
    self.manualEvents = [NSMutableDictionary new];
    self.avoFunctionsEventsParams = [NSMutableDictionary new];
    self.manualEventsParams = [NSMutableDictionary new];
    self.avoSchemaExtractor = [AvoSchemaExtractor new];
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
    [self clearOldEvents];
    
    if (fromAvoFunction) {
        [self.avoFunctionsEvents setObject:eventName forKey:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
        [self.avoFunctionsEventsParams setObject:params forKey:eventName];
    } else {
        [self.manualEvents setObject:eventName forKey:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
        [self.manualEventsParams setObject:params forKey:eventName];
    }
    
    BOOL checkInAvoFunctions = !fromAvoFunction;
    
    return ![self hasSameEventAs:eventName eventParams:params checkInAvoFunctions:checkInAvoFunctions];
}

- (BOOL) hasSeenEventParams:(NSDictionary<NSString *, id> *) params checkInAvoFunctions:(BOOL) checkInAvoFunctions {
    __block BOOL result = NO;
    if (checkInAvoFunctions) {
        [self.avoFunctionsEventsParams enumerateKeysAndObjectsUsingBlock:^(id otherEventName, id otherEventParams, BOOL* stop) {
            if ([params isEqualToDictionary:otherEventParams]) {
                result = YES;
                *stop = YES;
            }
        }];
    } else {
        [self.manualEventsParams enumerateKeysAndObjectsUsingBlock: ^(id otherEventName, id otherEventParams, BOOL* stop) {
          if ([params isEqualToDictionary:otherEventParams]) {
              result = YES;
              *stop = YES;
          }
        }];
    }
    
    return result;
}

- (BOOL) hasSameEventAs:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params checkInAvoFunctions:(BOOL) checkInAvoFunctions {
    
    __block BOOL result = NO;
    if (checkInAvoFunctions) {
        [self.avoFunctionsEventsParams enumerateKeysAndObjectsUsingBlock:^(id otherEventName, id otherEventParams, BOOL* stop) {
            if (otherEventName == eventName && [params isEqualToDictionary:otherEventParams]) {
                result = YES;
                *stop = YES;
            }
        }];
    } else {
        [self.manualEventsParams enumerateKeysAndObjectsUsingBlock: ^(id otherEventName, id otherEventParams, BOOL* stop) {
          if (otherEventName == eventName && [params isEqualToDictionary:otherEventParams]) {
              result = YES;
              *stop = YES;
          }
        }];
    }
    
    if (result) {
        [self.avoFunctionsEventsParams removeObjectForKey:eventName];
        [self.manualEventsParams removeObjectForKey:eventName];
    }
    
    return result;
}

- (BOOL) shouldRegisterSchemaFromManually:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema {
    [self clearOldEvents];
    
      __block BOOL result = YES;

      [self.avoFunctionsEventsParams enumerateKeysAndObjectsUsingBlock:^(id otherEventName, id otherEventParams, BOOL* stop) {
          NSDictionary * otherSchema = [self.avoSchemaExtractor extractSchema:otherEventParams];
          if (otherEventName == eventName && [schema isEqualToDictionary:otherSchema]) {
              result = NO;
              *stop = YES;
          }
      }];
      
      if (result) {
          [self.avoFunctionsEventsParams removeObjectForKey:eventName];
      }
      
      return result;
}
 
- (void) clearOldEvents {
    NSNumber * now = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    double secondsToConsiderOld = 0.3;
    
    NSMutableArray * timestampsToRemove = [NSMutableArray new];
    for (NSNumber * timestamp in [self.avoFunctionsEvents allKeys]) {
        if ([now doubleValue] - [timestamp doubleValue] > secondsToConsiderOld) {
            NSString * eventName = [self.avoFunctionsEvents objectForKey:timestamp];
            [timestampsToRemove addObject:timestamp];
            [self.avoFunctionsEventsParams removeObjectForKey:eventName];
        }
    }
    
    for (NSNumber * timestamp in timestampsToRemove) {
        [self.avoFunctionsEvents removeObjectForKey:timestamp];
    }
    
    timestampsToRemove = [NSMutableArray new];
    for (NSNumber * timestamp in [self.manualEvents allKeys]) {
        if ([now doubleValue] - [timestamp doubleValue] > secondsToConsiderOld) {
            NSString * eventName = [self.manualEvents objectForKey:timestamp];
            [timestampsToRemove addObject:timestamp];
            [self.manualEventsParams removeObjectForKey:eventName];
        }
    }
    
    for (NSNumber * timestamp in timestampsToRemove) {
        [self.manualEvents removeObjectForKey:timestamp];
    }
}

@end
