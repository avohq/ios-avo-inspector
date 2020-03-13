//
//  DebuggerPropError.h
//  IosAnalyticsDebugger
//
//  Created by Alex Verein on 31.01.2020.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DebuggerPropError : NSObject

@property (strong, nonatomic, readwrite) NSString *propertyId;
@property (strong, nonatomic, readwrite) NSString *message;

- (instancetype)initWithPropertyId:(NSString *)propertyId withMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
