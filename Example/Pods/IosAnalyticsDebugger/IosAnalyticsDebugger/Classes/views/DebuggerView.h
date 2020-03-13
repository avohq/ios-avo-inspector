//
//  Header.h
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import "DebuggerEventItem.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DebuggerView

- (void) showEvent:(DebuggerEventItem *)event;
- (void) onClick;

@end

NS_ASSUME_NONNULL_END
