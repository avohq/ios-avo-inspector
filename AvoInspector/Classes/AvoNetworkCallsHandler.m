//
//  NetworkCallsHandler.m
//  AvoInspector
//
//  Created by Alex Verein on 07.02.2020.
//

#import "AvoNetworkCallsHandler.h"
#import "AvoUtils.h"
#import "AvoInspector.h"
#import "AvoObject.h"
#import "AvoAnonymousId.h"
#import "AvoEventSpecFetchTypes.h"
#import "AvoEncryption.h"
#import "AvoList.h"

@interface AvoNetworkCallsHandler()

@property (readwrite, nonatomic) NSString *apiKey;
@property (readwrite, nonatomic) int env;
@property (readwrite, nonatomic) NSString *appName;
@property (readwrite, nonatomic) NSString *appVersion;
@property (readwrite, nonatomic) NSString *libVersion;
@property (readwrite, nonatomic) NSURLSession *urlSession;
@property (readwrite, nonatomic) NSString *endpoint;
@property (readwrite, nonatomic, nullable) NSString *publicEncryptionKey;

@property (readwrite, nonatomic) double samplingRate;

@end

@implementation AvoNetworkCallsHandler

- (instancetype) initWithApiKey: (NSString *) apiKey appName: (NSString *)appName appVersion: (NSString *) appVersion libVersion: (NSString *) libVersion env: (int) env endpoint: (NSString *) endpoint {
    return [self initWithApiKey:apiKey appName:appName appVersion:appVersion libVersion:libVersion env:env endpoint:endpoint publicEncryptionKey:nil];
}

- (instancetype) initWithApiKey: (NSString *) apiKey appName: (NSString *)appName appVersion: (NSString *) appVersion libVersion: (NSString *) libVersion env: (int) env endpoint: (NSString *) endpoint publicEncryptionKey: (NSString * _Nullable) publicEncryptionKey {
    self = [super init];
    if (self) {
        self.endpoint = endpoint;
        self.appVersion = appVersion;
        self.libVersion = libVersion;
        self.appName = appName;
        self.apiKey = apiKey;
        self.samplingRate = 1.0;
        self.env = env;
        self.urlSession = [NSURLSession sharedSession];
        self.publicEncryptionKey = publicEncryptionKey;
    }
    return self;
}

- (NSMutableDictionary *) bodyForTrackSchemaCall:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash {
    return [self bodyForTrackSchemaCall:eventName schema:schema eventId:eventId eventHash:eventHash eventProperties:nil];
}

- (NSMutableDictionary *) bodyForTrackSchemaCall:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash eventProperties:(NSDictionary * _Nullable) eventProperties {
    NSMutableArray * propsSchema = [NSMutableArray new];

    for(NSString *key in [schema allKeys]) {
        NSString *value = [[schema objectForKey:key] name];

        NSMutableDictionary *prop = [NSMutableDictionary new];

        [prop setObject:key forKey:@"propertyName"];
        if ([[schema objectForKey:key] isKindOfClass:[AvoObject class]]) {
            NSError *error = nil;
            id nestedSchema = [NSJSONSerialization
                              JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding]
                              options:0
                              error:&error];
            if (!error && [nestedSchema isKindOfClass:[NSDictionary class]]) {
                NSDictionary *results = nestedSchema;

                [prop setObject:@"object" forKey:@"propertyType"];

                [prop setObject:[self bodyFromJson:results] forKey:@"children"];
            }
        } else {
            [prop setObject:value forKey:@"propertyType"];
        }
        [propsSchema addObject:prop];
    }

    if ([self shouldEncrypt] && eventProperties != nil) {
        [AvoNetworkCallsHandler addEncryptedValues:propsSchema eventProperties:eventProperties publicEncryptionKey:self.publicEncryptionKey];
    }

    NSMutableDictionary * baseBody = [self createBaseCallBody];

    if (eventId != nil) {
        [baseBody setValue:@YES forKey:@"avoFunction"];
        [baseBody setValue:eventId forKey:@"eventId"];
        [baseBody setValue:eventHash forKey:@"eventHash"];
    } else {
        [baseBody setValue:@NO forKey:@"avoFunction"];
    }

    [baseBody setValue:@"event" forKey:@"type"];
    [baseBody setValue:eventName forKey:@"eventName"];
    [baseBody setValue:propsSchema forKey:@"eventProperties"];

    return baseBody;
}

- (NSMutableArray *) bodyFromJson:(NSDictionary *) schema {
    NSMutableArray * propsSchema = [NSMutableArray new];
    
    for(NSString *key in [schema allKeys]) {
        id value = [schema objectForKey:key];
        
        NSMutableDictionary *prop = [NSMutableDictionary new];
        
        [prop setObject:key forKey:@"propertyName"];
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *results = value;
            
            [prop setObject:@"object" forKey:@"propertyType"];
            [prop setObject:[self bodyFromJson:results] forKey:@"children"];
        } else {
            [prop setObject:value forKey:@"propertyType"];
        }
        [propsSchema addObject:prop];
    }
    
    return propsSchema;
}

// Shared network logic

- (NSMutableDictionary *) createBaseCallBody {
    NSMutableDictionary *body = [NSMutableDictionary new];
    [body setValue:self.apiKey forKey:@"apiKey"];
    [body setValue:self.appName forKey:@"appName"];
    [body setValue:self.appVersion forKey:@"appVersion"];
    [body setValue:self.libVersion forKey:@"libVersion"];
    [body setValue:@(self.samplingRate) forKey:@"samplingRate"];
    [body setValue:@"" forKey:@"sessionId"];
    [body setValue:@"" forKey:@"trackingId"];
    [body setValue:[AvoAnonymousId anonymousId] forKey:@"anonymousId"];
    [body setValue:[AvoNetworkCallsHandler formatTypeToString:self.env] forKey:@"env"];
    [body setValue:@"ios" forKey:@"libPlatform"];
    [body setValue:[[NSUUID UUID] UUIDString] forKey:@"messageId"];
    [body setValue:[AvoUtils currentTimeAsISO8601UTCString] forKey:@"createdAt"];

    if (self.publicEncryptionKey != nil && self.publicEncryptionKey.length > 0) {
        [body setValue:self.publicEncryptionKey forKey:@"publicEncryptionKey"];
    }

    return body;
}

- (void) callInspectorWithBatchBody: (NSArray *) batchBody completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    if (batchBody == nil) {
        return;
    }
    
    if (drand48() > self.samplingRate) {
         if ([AvoInspector isLogging]) {
             NSLog(@"[avo] Avo Inspector: Last event schema dropped due to sampling rate");
         }
         return;
    }
    
    if ([AvoInspector isLogging]) {
        for (NSDictionary *batchItem in batchBody) {
            NSString * type = [batchItem objectForKey:@"type"];

            if ([type  isEqual:@"event"]) {
                NSString * eventName = [batchItem objectForKey:@"eventName"];
                NSString * eventProps = [batchItem objectForKey:@"eventProperties"];

                NSLog(@"[avo] Avo Inspector: Sending event %@ with schema {\n%@\n}\n", eventName, [eventProps description]);
            } else {
                NSLog(@"[avo] Avo Inspector: Error! Unknown event type.");
            }

        }
    }
    
    NSError *error;
    NSData *bodyData = [NSJSONSerialization  dataWithJSONObject:batchBody
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:&error];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.endpoint]];
    [request setHTTPMethod:@"POST"];

    [self writeCallHeader:request];
    [request setHTTPBody:bodyData];

    [self sendHttpRequest:request completionHandler:completionHandler];
}

- (void)sendHttpRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSError *error))completionHandler {
    __weak AvoNetworkCallsHandler *weakSelf = self;
    NSURLSessionDataTask *postDataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error == nil)
        {
            if (error != nil || data == nil) {
                return;
            }
            NSError *jsonError = nil;
            NSDictionary *responseJSON = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            NSNumber *rate = responseJSON[@"samplingRate"];
            if (rate != nil && weakSelf.samplingRate != [rate doubleValue]) {
                weakSelf.samplingRate = [rate doubleValue];
            }
            
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Successfully sent events.");
            }
        } else if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Failed sending events. Will retry later.");
        }
        
        completionHandler(error);
    }];
    
    [postDataTask resume];
}

- (void) writeCallHeader:(NSMutableURLRequest *) request {
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
}

- (NSMutableDictionary *) bodyForValidatedEventSchemaCall:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash validationResult:(AvoValidationResult *) validationResult streamId:(NSString *) streamId {
    return [self bodyForValidatedEventSchemaCall:eventName schema:schema eventId:eventId eventHash:eventHash validationResult:validationResult streamId:streamId eventProperties:nil];
}

- (NSMutableDictionary *) bodyForValidatedEventSchemaCall:(NSString *) eventName schema:(NSDictionary<NSString *, AvoEventSchemaType *> *) schema eventId:(NSString * _Nullable) eventId eventHash:(NSString * _Nullable) eventHash validationResult:(AvoValidationResult *) validationResult streamId:(NSString *) streamId eventProperties:(NSDictionary * _Nullable) eventProperties {

    NSMutableArray *propsSchema = [NSMutableArray new];

    for (NSString *key in [schema allKeys]) {
        NSString *value = [[schema objectForKey:key] name];

        NSMutableDictionary *prop = [NSMutableDictionary new];
        [prop setObject:key forKey:@"propertyName"];

        if ([[schema objectForKey:key] isKindOfClass:[AvoObject class]]) {
            NSError *error = nil;
            id nestedSchema = [NSJSONSerialization
                              JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding]
                              options:0
                              error:&error];
            if (!error && [nestedSchema isKindOfClass:[NSDictionary class]]) {
                [prop setObject:@"object" forKey:@"propertyType"];
                [prop setObject:[self bodyFromJson:nestedSchema] forKey:@"children"];
            }
        } else {
            [prop setObject:value forKey:@"propertyType"];
        }

        // Add validation results for this property
        if (validationResult != nil && validationResult.propertyResults != nil) {
            AvoPropertyValidationResult *propResult = validationResult.propertyResults[key];
            if (propResult != nil) {
                [self addValidationToProperty:prop result:propResult];
            }
        }

        [propsSchema addObject:prop];
    }

    if ([self shouldEncrypt] && eventProperties != nil) {
        [AvoNetworkCallsHandler addEncryptedValues:propsSchema eventProperties:eventProperties publicEncryptionKey:self.publicEncryptionKey];
    }

    NSMutableDictionary *baseBody = [self createBaseCallBody];

    if (eventId != nil) {
        [baseBody setValue:@YES forKey:@"avoFunction"];
        [baseBody setValue:eventId forKey:@"eventId"];
        [baseBody setValue:eventHash forKey:@"eventHash"];
    } else {
        [baseBody setValue:@NO forKey:@"avoFunction"];
    }

    [baseBody setValue:@"event" forKey:@"type"];
    [baseBody setValue:eventName forKey:@"eventName"];
    [baseBody setValue:propsSchema forKey:@"eventProperties"];
    [baseBody setValue:streamId forKey:@"streamId"];

    // Add event spec metadata
    if (validationResult.metadata != nil) {
        NSMutableDictionary *metadataDict = [NSMutableDictionary dictionary];
        if (validationResult.metadata.schemaId != nil) {
            metadataDict[@"schemaId"] = validationResult.metadata.schemaId;
        }
        if (validationResult.metadata.branchId != nil) {
            metadataDict[@"branchId"] = validationResult.metadata.branchId;
        }
        if (validationResult.metadata.latestActionId != nil) {
            metadataDict[@"latestActionId"] = validationResult.metadata.latestActionId;
        }
        if (validationResult.metadata.sourceId != nil) {
            metadataDict[@"sourceId"] = validationResult.metadata.sourceId;
        }
        [baseBody setValue:metadataDict forKey:@"eventSpecMetadata"];
    }

    return baseBody;
}

- (void)addValidationToProperty:(NSMutableDictionary *)prop result:(AvoPropertyValidationResult *)result {
    if (result.failedEventIds != nil) {
        [prop setObject:result.failedEventIds forKey:@"failedEventIds"];
    }
    if (result.passedEventIds != nil) {
        [prop setObject:result.passedEventIds forKey:@"passedEventIds"];
    }
    if (result.children != nil) {
        NSArray *existingChildren = prop[@"children"];
        if (existingChildren != nil && [existingChildren isKindOfClass:[NSArray class]]) {
            NSMutableArray *updatedChildren = [NSMutableArray arrayWithArray:existingChildren];
            for (NSMutableDictionary *childProp in updatedChildren) {
                if (![childProp isKindOfClass:[NSMutableDictionary class]]) continue;
                NSString *childName = childProp[@"propertyName"];
                if (childName != nil) {
                    AvoPropertyValidationResult *childResult = result.children[childName];
                    if (childResult != nil) {
                        [self addValidationToProperty:childProp result:childResult];
                    }
                }
            }
        }
    }
}

- (void) reportValidatedEvent:(NSDictionary *) body {
    @try {
        NSError *error;
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:@[body]
                                                          options:0
                                                            error:&error];
        if (error != nil) {
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Failed to serialize validated event body: %@", error);
            }
            return;
        }

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.endpoint]];
        [request setHTTPMethod:@"POST"];
        [request setTimeoutInterval:5.0];
        [self writeCallHeader:request];
        [request setHTTPBody:bodyData];

        NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *taskError) {
            if (taskError != nil) {
                if ([AvoInspector isLogging]) {
                    NSLog(@"[avo] Avo Inspector: Failed to send validated event: %@", taskError);
                }
            } else if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Successfully sent validated event.");
            }
        }];
        [task resume];
    } @catch (NSException *e) {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Exception sending validated event: %@", e);
        }
    }
}

+ (NSString*)formatTypeToString:(int) formatType {
    NSString *result = nil;

    switch(formatType) {
        case 0:
            result = @"prod";
            break;
        case 1:
            result = @"dev";
            break;
        case 2:
            result = @"staging";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }

    return result;
}

#pragma mark - Encryption

- (BOOL) shouldEncrypt {
    return self.publicEncryptionKey != nil
        && self.publicEncryptionKey.length > 0
        && (self.env == 1 || self.env == 2); // dev = 1, staging = 2
}

+ (void) addEncryptedValues:(NSMutableArray *)properties eventProperties:(NSDictionary *)eventProperties publicEncryptionKey:(NSString *)publicEncryptionKey {
    if (properties == nil || eventProperties == nil || publicEncryptionKey == nil) {
        return;
    }

    for (NSUInteger i = 0; i < properties.count; i++) {
        @try {
            NSMutableDictionary *prop = properties[i];
            NSString *propertyName = prop[@"propertyName"];
            NSString *propertyType = prop[@"propertyType"];
            id value = eventProperties[propertyName];

            if (value == nil) {
                continue;
            }

            if ([propertyType isEqualToString:@"object"] && prop[@"children"] != nil && [value isKindOfClass:[NSDictionary class]]) {
                // Recurse into object children
                NSMutableArray *children = prop[@"children"];
                [self addEncryptedValues:children eventProperties:(NSDictionary *)value publicEncryptionKey:publicEncryptionKey];
            } else if (![propertyType hasPrefix:@"list"]) {
                // Primitive type: encrypt the JSON-stringified value
                NSString *jsonValue = [self jsonStringifyValue:value];
                if (jsonValue != nil) {
                    NSString *encrypted = [AvoEncryption encrypt:jsonValue recipientPublicKeyHex:publicEncryptionKey];
                    if (encrypted != nil) {
                        prop[@"encryptedPropertyValue"] = encrypted;
                    }
                }
            }
            // list types are skipped
        } @catch (NSException *e) {
            if ([AvoInspector isLogging]) {
                NSLog(@"[avo] Avo Inspector: Failed to encrypt property at index %lu: %@", (unsigned long)i, e);
            }
        }
    }
}

+ (NSString * _Nullable) jsonStringifyValue:(id) value {
    @try {
        // Wrap value in an array to get proper JSON representation
        NSArray *wrapper = @[value];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:wrapper options:0 error:nil];
        if (jsonData == nil) {
            return nil;
        }
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (json == nil || json.length < 2) {
            return nil;
        }
        // Strip surrounding brackets: [value] -> value
        return [json substringWithRange:NSMakeRange(1, json.length - 2)];
    } @catch (NSException *e) {
        return nil;
    }
}

@end
