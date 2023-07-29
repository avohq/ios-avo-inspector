//
//  AvoInspector.h
//  AvoInspector
//
//  Created by Alex Verein on 28.01.2020.
//

#import <Foundation/Foundation.h>
#import "AvoEventSchemaType.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AvoVisualInspectorType) {
    Bar = 0,
    Bubble = 1
};

@protocol Inspector <NSObject>

-(NSDictionary<NSString *, AvoEventSchemaType *> *) trackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary<NSString *, id> *) params;
-(void) trackSchema:(NSString *) eventName eventSchema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema;

-(NSDictionary<NSString *, AvoEventSchemaType *> *) extractSchema:(NSDictionary<NSString *, id> *) eventParams;

+ (BOOL) isLogging;
+ (void) setLogging: (BOOL) isLogging;

+ (int) getBatchSize;
+ (void) setBatchSize: (int) newBatchSize;

+ (int) getBatchFlushSeconds;
+ (void) setBatchFlushSeconds: (int) newBatchFlushSeconds;

@end

NS_ASSUME_NONNULL_END
