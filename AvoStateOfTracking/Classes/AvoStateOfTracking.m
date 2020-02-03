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

@property (readwrite, nonatomic) NSInteger appVersion;
@property (readwrite, nonatomic) NSInteger libVersion;

@end

@implementation AvoStateOfTracking

@synthesize isLogging;

-(NSDictionary *) trackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary *) params {
    return [NSDictionary new];
}

-(NSDictionary *) trackSchema:(NSString *) eventName eventSchema:(NSDictionary *) schema {
    return [NSDictionary new];
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
        
        if ([@"i" isEqualToString:@(objCtype)]) {
            return [AvoInt new];
        } else {
            return [AvoFloat new];
        }
    } else if ([paramType  isEqual: @"__NSCFBoolean"]) {
        return [AvoBoolean new];
    } else if ([paramType  isEqual: @"__NSCFConstantString"] ||
               [paramType  isEqual: @"__NSCFString"]) {
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
