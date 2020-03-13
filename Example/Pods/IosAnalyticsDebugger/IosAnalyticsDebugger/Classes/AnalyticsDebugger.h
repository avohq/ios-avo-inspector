//
//  Debugger.h
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DebuggerEventItem.h"
#import "DebuggerPropError.h"

NS_ASSUME_NONNULL_BEGIN

static NSMutableArray *analyticsDebuggerEvents;

typedef void (^ _Nullable OnNewEventCallback)(DebuggerEventItem *);
static OnNewEventCallback onNewEventCallback;

@interface AnalyticsDebugger : NSObject

+(NSMutableArray*) events;
+(void) setOnNewEventCallback:(nullable OnNewEventCallback) callback;

-(void) showBarDebugger;
-(void) showBubbleDebugger;
-(void) hideDebugger;
-(void) publishEvent:(NSString *) eventName withParams:(NSDictionary *) params;
-(void) publishEvent:(NSString *) eventName withTimestamp:(NSNumber *) timestamp withProperties:(NSArray<DebuggerProp *> *) props withErrors:(NSArray<DebuggerPropError *> *) errors;
-(BOOL) isEnabled;
-(void) setSchemaId:(NSString *) schemaId;

@end

NS_ASSUME_NONNULL_END
