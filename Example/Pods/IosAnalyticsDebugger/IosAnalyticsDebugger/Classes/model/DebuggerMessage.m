//
//  DebuggerMessage.m
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import "DebuggerMessage.h"

@implementation DebuggerMessage

- (instancetype)initWithPropertyId:(NSString *)propertyId withMessage:(NSString *)message withAllowedTypes:(NSArray *)allowedTypes withProvidedType:(NSString *)providedType
{
    self = [super init];
    if (self) {
        self.propertyId = propertyId;
        self.message = message;
        self.allowedTypes = allowedTypes;
        self.providedType = providedType;
    }
    return self;
}


@end
