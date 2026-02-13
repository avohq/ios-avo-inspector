//
//  NetworkCallsHandler.h
//  AvoInspector
//
//  Created by Alex Verein on 07.02.2020.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AvoValidationResult;
@class AvoEventSpecMetadata;
@class AvoEventSchemaType;

@interface AvoNetworkCallsHandler : NSObject

@property (readonly, nonatomic) NSString *apiKey;
@property (readonly, nonatomic) NSString *appName;
@property (readonly, nonatomic) NSString *appVersion;
@property (readonly, nonatomic) NSString *libVersion;

- (instancetype) initWithApiKey: (NSString *) apiKey appName: (NSString *)appName appVersion: (NSString *) appVersion libVersion: (NSString *) libVersion env: (int) env endpoint: (NSString *) endpoint;

- (instancetype) initWithApiKey: (NSString *) apiKey appName: (NSString *)appName appVersion: (NSString *) appVersion libVersion: (NSString *) libVersion env: (int) env endpoint: (NSString *) endpoint publicEncryptionKey: (NSString * _Nullable) publicEncryptionKey;

- (void) callInspectorWithBatchBody: (NSArray *) batchBody completionHandler:(void (^)(NSError *error))completionHandler;

- (NSMutableDictionary *) bodyForTrackSchemaCall:(NSString *) eventName schema:(NSDictionary *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash;

- (NSMutableDictionary *) bodyForTrackSchemaCall:(NSString *) eventName schema:(NSDictionary *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash eventProperties:(NSDictionary * _Nullable) eventProperties;

- (NSMutableDictionary *) bodyForValidatedEventSchemaCall:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash validationResult:(AvoValidationResult *) validationResult streamId:(NSString *) streamId;

- (NSMutableDictionary *) bodyForValidatedEventSchemaCall:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash validationResult:(AvoValidationResult *) validationResult streamId:(NSString *) streamId eventProperties:(NSDictionary * _Nullable) eventProperties;

- (BOOL) shouldEncrypt;

+ (NSString * _Nullable) jsonStringifyValue:(id) value;

- (void) reportValidatedEvent:(NSDictionary *) body;

+ (NSString *)formatTypeToString:(int)formatType;

@end

NS_ASSUME_NONNULL_END
