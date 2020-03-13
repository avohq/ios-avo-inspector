//
//  DebuggerMessage.h
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DebuggerMessage : NSObject

@property (strong, nonatomic, readwrite) NSString *propertyId;
@property (strong, nonatomic, readwrite) NSString *message;
@property (strong, nonatomic, readwrite) NSArray *allowedTypes;
@property (strong, nonatomic, readwrite) NSString *providedType;

- (instancetype)initWithPropertyId:(NSString *)propertyId withMessage:(NSString *)message withAllowedTypes:(NSArray *)allowedTypes withProvidedType:(NSString *)providedType;

@end

NS_ASSUME_NONNULL_END
