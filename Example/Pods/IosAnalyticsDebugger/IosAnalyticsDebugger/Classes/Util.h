//
//  Util.h
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebuggerEventItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface Util : NSObject

+(NSString *) timeString:(NSTimeInterval)timestamp;
+(BOOL) eventHaveErrors:(DebuggerEventItem *)event;
+(NSInteger) barBottomOffset;
+(CGFloat) statusBarHeight;

@end

NS_ASSUME_NONNULL_END
