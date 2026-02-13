//
//  AvoBatcher.h
//  AvoInspector
//
//  Created by Alex Verein on 18.02.2020.
//

#import <Foundation/Foundation.h>

#import "AvoNetworkCallsHandler.h"
#import "AvoEventSchemaType.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvoBatcher : NSObject

@property (readonly, nonatomic) AvoNetworkCallsHandler *networkCallsHandler;

- (instancetype) initWithNetworkCallsHandler: (AvoNetworkCallsHandler *) networkCallsHandler;

- (void) handleTrackSchema: (NSString *) eventName schema: (NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash;

- (void) handleTrackSchema: (NSString *) eventName schema: (NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash eventProperties:(NSDictionary * _Nullable) eventProperties;

- (void) enterBackground;
- (void) enterForeground;

@end

NS_ASSUME_NONNULL_END
