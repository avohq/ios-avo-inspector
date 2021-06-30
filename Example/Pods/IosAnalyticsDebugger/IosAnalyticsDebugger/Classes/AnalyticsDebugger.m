//
//  Debugger.m
//  IosAnalyticsDebugger
//
//  Copyright © 2019. All rights reserved.
//

#import "AnalyticsDebugger.h"
#import "BubbleDebuggerView.h"
#import "BarDebuggerView.h"
#import "EventsListScreenViewController.h"
#import "Util.h"
#import "DebuggerMessage.h"
#import "DebuggerProp.h"
#import "DebuggerPropError.h"
#import <Foundation/Foundation.h>
#import "DebuggerAnalytics.h"
#import "DebuggerAnalyticsDestination.h"

static UIView<DebuggerView> *debuggerView = nil;

@interface AnalyticsDebugger ()

@property (strong, nonatomic, readwrite) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation AnalyticsDebugger

CGFloat screenHeight;
CGFloat screenWidth;

NSString *currentSchemaId;

- (instancetype)init {
    if (!(self = [super init])) {
        return nil;
    }
    
    analyticsDebuggerEvents = [NSMutableArray new];
    
    NSString *version = [[[NSBundle bundleForClass:[AnalyticsDebugger class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [DebuggerAnalytics initAvoWithEnv:AVOEnvProd version:version
              customNodeJsDestination:[DebuggerAnalyticsDestination new]];
    
    return self;
}

-(void) showBarDebugger {
    if (debuggerView != nil) {
        [self hideDebugger];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        screenHeight = screenRect.size.height;
         
        NSInteger bottomOffset = [Util barBottomOffset];
    
        debuggerView = [[BarDebuggerView alloc] initWithFrame: CGRectMake(0, screenHeight - 30 - bottomOffset, screenWidth, 30) ];

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
               [[[UIApplication sharedApplication] keyWindow] addSubview:debuggerView];
        });
         
        self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(drugBar:)];
        
        [debuggerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openEventsListScreen)]];
        [debuggerView addGestureRecognizer:self.panGestureRecognizer];
        
        if ([analyticsDebuggerEvents count] > 0) {
            [debuggerView showEvent:[analyticsDebuggerEvents objectAtIndex:0]];
        }
        
        [DebuggerAnalytics debuggerStartedWithFrameLocation:nil schemaId:currentSchemaId];
    });
}

- (void) drugBar:(UIPanGestureRecognizer*)sender {
    CGPoint translation = [sender translationInView:debuggerView];
    
    CGFloat statusBarHeight = [Util statusBarHeight];
    NSInteger bottomOffset = [Util barBottomOffset];
    
    CGFloat newY = MIN(debuggerView.center.y + translation.y, screenHeight - bottomOffset);
    newY = MAX(statusBarHeight + (CGRectGetHeight(debuggerView.bounds) / 2), newY);
    debuggerView.center = CGPointMake(debuggerView.center.x, newY);
    [sender setTranslation:CGPointZero inView:debuggerView];
}

-(void) showBubbleDebugger {
    if (debuggerView != nil) {
        [self hideDebugger];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        screenWidth = screenRect.size.width;
        screenHeight = screenRect.size.height;
        NSInteger bottomOffset = [Util barBottomOffset];
        
        debuggerView = [[BubbleDebuggerView alloc] initWithFrame: CGRectMake(screenWidth - 40, screenHeight - 80 - bottomOffset, 40, 40)];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
           dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
               [[[UIApplication sharedApplication] keyWindow] addSubview:debuggerView];
        });
         
        self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(drugBubble:)];
         
        [debuggerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openEventsListScreen)]];
        [debuggerView addGestureRecognizer:self.panGestureRecognizer];
        
        for (int index = (int)[analyticsDebuggerEvents count] - 1; index >= 0; index--) {
            DebuggerEventItem * event = [analyticsDebuggerEvents objectAtIndex:index];
            [debuggerView showEvent:event];
        }
        
        [DebuggerAnalytics debuggerStartedWithFrameLocation:nil schemaId:currentSchemaId];
    });
}

- (void) drugBubble:(UIPanGestureRecognizer*)sender {
    CGPoint translation = [sender translationInView:debuggerView];
    
    CGFloat statusBarHeight = [Util statusBarHeight];
    NSInteger bottomOffset = [Util barBottomOffset];
    
    CGFloat newY = MIN(debuggerView.center.y + translation.y, screenHeight - bottomOffset);
    newY = MAX(statusBarHeight + (CGRectGetHeight(debuggerView.bounds) / 2), newY);
    
    CGFloat newX = MIN(debuggerView.center.x + translation.x, screenWidth);
    newX = MAX((CGRectGetWidth(debuggerView.bounds) / 2), newX);
    
    debuggerView.center = CGPointMake(newX, newY);
    [sender setTranslation:CGPointZero inView:debuggerView];
}

- (void) openEventsListScreen {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if (debuggerView != nil) {
            [debuggerView onClick];
            
            UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
            
            NSURL *bundleURL = [[[NSBundle bundleForClass:self.class] resourceURL] URLByAppendingPathComponent:@"IosAnalyticsDebugger.bundle"];
            NSBundle *resBundle = [NSBundle bundleWithURL:bundleURL];
            
            EventsListScreenViewController *eventsListViewController = [[EventsListScreenViewController alloc] initWithNibName:@"EventsListScreenViewController" bundle:resBundle];
            [eventsListViewController setModalPresentationStyle:UIModalPresentationFullScreen];
            
            [rootViewController presentViewController:eventsListViewController animated:YES completion:nil];
        }
    });
}

- (void) hideDebugger {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if (debuggerView != nil) {
            [debuggerView removeFromSuperview];
            debuggerView = nil;
        }
    });
}

- (void) setSchemaId:(NSString *)schemaId {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        currentSchemaId = schemaId;
    });
}

- (void) publishEvent:(NSString *) eventName withTimestamp:(NSNumber *) timestamp withProperties:(NSArray<DebuggerProp *> *) props withErrors:(NSArray<DebuggerPropError *> *) errors {
    
    DebuggerEventItem * event = [DebuggerEventItem new];
    
    event.name = eventName;
    event.timestamp = [timestamp doubleValue];
    event.messages = [NSMutableArray new];
    for (id error in errors) {
        DebuggerMessage * debuggerMessage = [self createMessageWithError:error];

        if (debuggerMessage != nil) {
            [event.messages addObject:debuggerMessage];
        }
    }
    event.eventProps = [NSMutableArray new];
    for (id prop in props) {
        if (prop != nil) {
            [event.eventProps addObject:prop];
        }
    }
    
    [self sendEventToAnalyticsDebugger:event];
}

- (void) publishEvent:(NSString *) eventName withParams:(NSDictionary *) params {
    
    NSNumber * timestamp = [params objectForKey: @"timestamp"];
    NSString * eventId = [params objectForKey: @"id"];
    NSArray<NSDictionary *> * messages = [params objectForKey: @"messages"];
    NSArray<NSDictionary *> * eventProps = [params objectForKey: @"eventProps"];
    NSArray<NSDictionary *> * userProps = [params objectForKey: @"userProps"];
    
    DebuggerEventItem * event = [DebuggerEventItem new];
    event.name = eventName;
    event.identifier = eventId;
    event.timestamp = [timestamp doubleValue];
    event.messages = [NSMutableArray new];
    for (id message in messages) {
        DebuggerMessage * debuggerMessage = [self createMessageWithDictionary:message];

        if (debuggerMessage != nil) {
            [event.messages addObject:debuggerMessage];
        }
    }
    event.eventProps = [NSMutableArray new];
    for (id prop in eventProps) {
        DebuggerProp * eventProp = [self createPropWithDictionary:prop];

        if (eventProp != nil) {
            [event.eventProps addObject:eventProp];
        }
    }
    event.userProps = [NSMutableArray new];
    for (id prop in userProps) {
        DebuggerProp * userProp = [self createPropWithDictionary:prop];

        if (userProp != nil) {
            [event.userProps addObject:userProp];
        }
    }
    
    [self sendEventToAnalyticsDebugger:event];
}

-(void) sendEventToAnalyticsDebugger:(DebuggerEventItem *) event {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSInteger insertIndex = 0;
        for (int i = 0; i < [analyticsDebuggerEvents count]; i++) {
            DebuggerEventItem *presentEvent = [analyticsDebuggerEvents objectAtIndex:i];
            
            if (presentEvent.timestamp > event.timestamp) {
                insertIndex += 1;
            } else {
                break;
            }
        }
        [analyticsDebuggerEvents insertObject:event atIndex:insertIndex];
        
        if (debuggerView != nil) {
            [debuggerView showEvent:event];
        }
        
        if (onNewEventCallback != nil) {
            onNewEventCallback(event);
        }
    });
}

- (DebuggerMessage *) createMessageWithError: (DebuggerPropError *) error {
    NSString * propertyId = error.propertyId;
    NSString * message = error.message;

    if (propertyId == nil || message == nil) {
        return nil;
    }

    return [[DebuggerMessage alloc] initWithPropertyId:propertyId withMessage:message withAllowedTypes:[NSArray new] withProvidedType:@""];
}

- (DebuggerMessage *) createMessageWithDictionary: (NSDictionary *) messageDict {
    NSString * propertyId = [messageDict objectForKey:@"propertyId"];
    NSString * message = [messageDict objectForKey:@"message"];

    if (propertyId == nil || message == nil) {
        return nil;
    }

    NSArray * allowedTypes = [[NSArray alloc] init];
    NSString * allowedTypesString = [messageDict objectForKey:@"allowedTypes"];
    if (allowedTypesString != nil) {
        allowedTypes = [allowedTypesString componentsSeparatedByString: @","];
    }

    return [[DebuggerMessage alloc] initWithPropertyId:propertyId withMessage:message withAllowedTypes:allowedTypes
                               withProvidedType:[messageDict objectForKey:@"providedType"]];
}

- (DebuggerProp *) createPropWithDictionary: (NSDictionary *) propDict {
    NSString * id = [propDict objectForKey:@"id"];
    NSString * name = [propDict objectForKey:@"name"];
    NSString * value = [propDict objectForKey:@"value"];
    
    if (id == nil || name == nil || value == nil) {
        return nil;
    }
    
    return [[DebuggerProp alloc] initWithId:id withName:name withValue:value];
}

- (BOOL) isEnabled {
    return debuggerView != nil;
}

+ (NSMutableArray*) events {
    return analyticsDebuggerEvents;
}

+(void) setOnNewEventCallback:(nullable OnNewEventCallback) callback {
    onNewEventCallback = callback;
}

@end
