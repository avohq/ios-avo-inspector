//
//  AvoStateOfTracking.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 28.01.2020.
//

#import "AvoStateOfTracking.h"
#import "AvoEventSchemaType.h"
#import "AvoList.h"
#import "AvoInt.h"
#import "AvoFloat.h"
#import "AvoBoolean.h"
#import "AvoString.h"
#import "AvoUnknownType.h"
#import "AvoNull.h"

@interface AvoStateOfTracking ()

@property (readwrite, nonatomic) AvoSessionTracker * sessionTracker;

@property (readwrite, nonatomic) NSString * appVersion;
@property (readwrite, nonatomic) NSInteger libVersion;

@end

@implementation AvoStateOfTracking

@synthesize isLogging;

-(instancetype) init {
    self = [super init];
    if (self) {
        self.appVersion = [[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleVersionKey];
        self.libVersion = [[[NSBundle bundleForClass:[self class]] infoDictionary][(NSString *)kCFBundleVersionKey] intValue];
        self.sessionTracker = [AvoSessionTracker new];
    }
    return self;
}

-(NSDictionary *) trackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary *) params {
    if (self.isLogging) {
        NSLog(@"Avo State Of Tracking: Supplied event %@ with params %@", eventName, [params description]);
    }
    
    NSDictionary * schema = [self extractSchema:params];
    
    [self trackSchema:eventName eventSchema:schema];
    
    return schema;
}

-(void) trackSchema:(NSString *) eventName eventSchema:(NSDictionary *) schema {
    if (self.isLogging) {
        
        NSString * schemaString = @"";
        
        for(NSString *key in [schema allKeys]) {
            NSString *value = [[schema objectForKey:key] name];
            NSString *entry = [NSString stringWithFormat:@"\t\"%@\": \"%@\";\n", key, value];
            schemaString = [schemaString stringByAppendingString:entry];
        }
        
        NSLog(@"Avo State Of Tracking: Tracked event %@ with schema {\n%@}", eventName, schemaString);
    }
    
    [self.sessionTracker schemaTracked:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
}

-(NSDictionary *) extractSchema:(NSDictionary *) eventParams {
    NSMutableDictionary * result = [NSMutableDictionary new];
    
    for (id paramName in [eventParams allKeys]) {
        id paramValue = [eventParams valueForKey:paramName];
            
        AvoEventSchemaType * paramType = [self objectToAvoSchemaType:paramValue];
        
        [result setObject:paramType forKey:paramName];
    }
    
    return result;
}

-(AvoEventSchemaType *)objectToAvoSchemaType: (id) obj {
    if (obj == [NSNull null]) {
        return [AvoNull new];
    }
    
    Class cl = [obj class];
    NSString * paramType = [cl description];
    
    if ([paramType isEqual: @"__NSCFNumber"]) {
        const char *objCtype = [obj objCType];
        
        if ([@"i" isEqualToString:@(objCtype)]
            || [@"s" isEqualToString:@(objCtype)]
            || [@"q" isEqualToString:@(objCtype)]) {
            return [AvoInt new];
        } else if ([@"c" isEqualToString:@(objCtype)]) {
            return [AvoString new];
        } else {
            return [AvoFloat new];
        }
    } else if ([paramType  isEqual: @"__NSCFBoolean"]) {
        return [AvoBoolean new];
    } else if ([paramType  isEqual: @"__NSCFConstantString"] ||
               [paramType  isEqual: @"__NSCFString"] ||
               [paramType   isEqual: @"NSTaggedPointerString"]) {
        return [AvoString new];
    } else if ([paramType  isEqual: @"__NSArrayI"] ||
               [paramType  isEqual: @"__NSArrayM"]) {
        AvoList * result = [AvoList new];
        
        for (id item in obj) {
            if (item == NSNull.null) {
                [result.subtypes addObject:[AvoNull new]];
            } else {
                [result.subtypes addObject:[self objectToAvoSchemaType:item]];
            }
        }
        
        return result;
    } else {
        return [AvoUnknownType new];
    }
}

@end
