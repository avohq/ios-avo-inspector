//
//  AvoEventSchemaType.m
//  AvoStateOfTracking
//
//  Created by Alex Verein on 01.02.2020.
//

#import <Foundation/Foundation.h>
#import "AvoEventSchemaType.h"

@implementation AvoEventSchemaType

- (NSString *) name {
    return @"base";
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [[self name] isEqual:[other name]];
}

- (NSString *) description {
    return [self name];
}

- (NSUInteger) hash {
    return [[self name] hash];
}

@end
