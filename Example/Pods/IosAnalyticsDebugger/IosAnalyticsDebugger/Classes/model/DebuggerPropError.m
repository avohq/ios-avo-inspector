//
//  DebuggerPropError.m
//  IosAnalyticsDebugger
//
//  Created by Alex Verein on 31.01.2020.
//

#import "DebuggerPropError.h"

@implementation DebuggerPropError

- (instancetype)initWithPropertyId:(NSString *)propertyId withMessage:(NSString *)message;
{
    self = [super init];
    if (self) {
        self.propertyId = propertyId;
        self.message = message;
    }
    return self;
}

@end
