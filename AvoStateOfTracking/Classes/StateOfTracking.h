//
//  StateOfTracking.h
//  AvoStateOfTracking
//
//  Created by Alex Verein on 28.01.2020.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol StateOfTracking <NSObject>

@property (readwrite, nonatomic) BOOL isLogging;

-(NSDictionary *) trackSchemaFromEvent:(NSString *) eventName eventParams:(NSDictionary *) params;
-(void) trackSchema:(NSString *) eventName eventSchema:(NSDictionary *) schema;

-(NSDictionary *) extractSchema:(NSDictionary *) eventParams;

@end

NS_ASSUME_NONNULL_END
