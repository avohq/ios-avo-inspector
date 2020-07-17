//
//  AvoSchemaExtractor.m
//  AvoInspector
//
//  Created by Alex Verein on 15.07.2020.
//

#import "AvoSchemaExtractor.h"
#import "AvoEventSchemaType.h"
#import "AvoList.h"
#import "AvoObject.h"
#import "AvoInt.h"
#import "AvoFloat.h"
#import "AvoBoolean.h"
#import "AvoString.h"
#import "AvoUnknownType.h"
#import "AvoNull.h"

@implementation AvoSchemaExtractor

-(NSDictionary<NSString *, AvoEventSchemaType *> *) extractSchema:(NSDictionary<NSString *, id> *) eventParams {
    @try {
        NSMutableDictionary * result = [NSMutableDictionary new];
        
        for (id paramName in [eventParams allKeys]) {
            id paramValue = [eventParams valueForKey:paramName];
                
            AvoEventSchemaType * paramType = [self objectToAvoSchemaType:paramValue];
            
            [result setObject:paramType forKey:paramName];
        }
        
        return result;
    }
    @catch (NSException *exception) {
        [self printAvoParsingError:exception];
        return [NSMutableDictionary new];
    }
}

-(AvoEventSchemaType *) objectToAvoSchemaType: (id) obj {
     @try {
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
        } else if ([paramType isEqual: @"__NSCFBoolean"]) {
            return [AvoBoolean new];
        } else if ([paramType containsString: @"NSSet"] ||
                   [paramType isEqual: @"__NSSingleObjectSetI"] ||
                   [paramType isEqual: @"__NSSingleObjectArrayI"] ||
                   [paramType containsString: @"NSArray"]) {
            AvoList * result = [AvoList new];
            
            for (id item in obj) {
                if (item == NSNull.null) {
                    [result.subtypes addObject:[AvoNull new]];
                } else {
                    [result.subtypes addObject:[self objectToAvoSchemaType:item]];
                }
            }
            
            return result;
        } else if ([paramType containsString: @"NSDictionary"] ||
                   [paramType isEqual: @"__NSSingleEntryDictionaryI"]) {
            AvoObject * result = [AvoObject new];
            
            [obj enumerateKeysAndObjectsUsingBlock:^(id paramName, id paramValue, BOOL* stop) {
              if ([paramName isKindOfClass:[NSString class]]) {
                   AvoEventSchemaType * paramType = [self objectToAvoSchemaType:paramValue];
                   
                   [result.fields setObject:paramType forKey:paramName];
               } else {
                   NSArray<NSString *> *stringParamNameParts = [[paramName description] componentsSeparatedByString:@"."];
                   NSString * stringParamName;
          
                   if (stringParamNameParts.count >= 2) {
                      stringParamName = [NSString stringWithFormat:@"%@.%@", stringParamNameParts[[stringParamNameParts count] - 2], stringParamNameParts[[stringParamNameParts count] - 1]];
                   } else {
                       stringParamName = stringParamNameParts[0];
                   }
                   
                   AvoEventSchemaType * paramType = [self objectToAvoSchemaType:paramValue];
                   
                   [result.fields setObject:paramType forKey:stringParamName];
               }
            }];
            
            return result;
        } else if ([paramType containsString: @"String"] ||
                   [paramType isEqual: @"__NSCFConstantString"] ||
                   [paramType isEqual: @"__NSCFString"] ||
                   [paramType isEqual: @"NSTaggedPointerString"] ||
                   [paramType isEqual: @"Swift.__SharedStringStorage"]) {
            return [AvoString new];
        } else {
            return [AvoUnknownType new];
        }
    }
    @catch (NSException *exception) {
        [self printAvoParsingError:exception];
        return [AvoUnknownType new];
    }
}

-(void)printAvoParsingError:(NSException *) exception {
    NSLog(@"[avo]        !!!!!!!!! Avo Inspector Parsing Error !!!!!!!!!");
    NSLog(@"[avo]        Please report the following error to support@avo.app");
    NSLog(@"[avo]        CRASH: %@", exception);
    NSLog(@"[avo]        Stack Trace: %@", [exception callStackSymbols]);
}

@end
