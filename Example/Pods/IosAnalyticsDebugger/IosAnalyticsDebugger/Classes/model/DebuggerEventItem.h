//
//  DebuggerEventItem.h
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DebuggerMessage.h"
#import "DebuggerProp.h"

NS_ASSUME_NONNULL_BEGIN

@interface DebuggerEventItem : NSObject

@property (strong, nonatomic, readwrite) NSString *identifier;
@property NSTimeInterval timestamp;
@property (strong, nonatomic, readwrite) NSString *name;
@property (strong, nonatomic, readwrite) NSMutableArray<DebuggerMessage *> *messages;
@property (strong, nonatomic, readwrite) NSMutableArray<DebuggerProp *> *eventProps;
@property (strong, nonatomic, readwrite) NSMutableArray<DebuggerProp *> *userProps;

@end

NS_ASSUME_NONNULL_END
