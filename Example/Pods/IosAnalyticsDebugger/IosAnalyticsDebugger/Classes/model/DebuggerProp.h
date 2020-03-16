//
//  DebuggerProp.h
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DebuggerProp : NSObject

@property (strong, nonatomic, readwrite) NSString *id;
@property (strong, nonatomic, readwrite) NSString *name;
@property (strong, nonatomic, readwrite) id value;

- (instancetype)initWithId:(NSString *)id withName:(NSString *)name withValue:(id)value;

@end

NS_ASSUME_NONNULL_END
