//
//  AvoEncryptionIntegrationTests.m
//  AvoStateOfTracking_Tests
//
//  Integration tests for property value encryption in network handler.
//

#import <AvoInspector/AvoNetworkCallsHandler.h>
#import <AvoInspector/AvoEncryption.h>
#import <AvoInspector/AvoString.h>
#import <AvoInspector/AvoInt.h>
#import <AvoInspector/AvoFloat.h>
#import <AvoInspector/AvoBoolean.h>
#import <AvoInspector/AvoList.h>
#import <AvoInspector/AvoObject.h>
#import <AvoInspector/AvoEventSchemaType.h>
#import <Security/Security.h>

@interface AvoNetworkCallsHandler ()

@property (readwrite, nonatomic) double samplingRate;
@property (readwrite, nonatomic) int env;
@property (readwrite, nonatomic) NSString *endpoint;

@end

@interface AvoEncryptionIntegrationTestHelper : NSObject
+ (SecKeyRef _Nullable)generateTestPrivateKey;
+ (NSString *)publicKeyHexFromPrivateKey:(SecKeyRef)privateKey;
@end

@implementation AvoEncryptionIntegrationTestHelper

+ (SecKeyRef _Nullable)generateTestPrivateKey {
    NSDictionary *attributes = @{
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
        (id)kSecAttrKeySizeInBits: @256,
    };
    CFErrorRef error = NULL;
    SecKeyRef privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, &error);
    if (error != NULL) {
        CFRelease(error);
        return NULL;
    }
    return privateKey;
}

+ (NSString *)publicKeyHexFromPrivateKey:(SecKeyRef)privateKey {
    SecKeyRef publicKey = SecKeyCopyPublicKey(privateKey);
    CFErrorRef error = NULL;
    CFDataRef pubKeyData = SecKeyCopyExternalRepresentation(publicKey, &error);
    CFRelease(publicKey);

    NSData *data = (__bridge_transfer NSData *)pubKeyData;
    NSMutableString *hex = [NSMutableString stringWithCapacity:data.length * 2];
    const uint8_t *bytes = data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return hex;
}

@end

SpecBegin(AvoEncryptionIntegration)

describe(@"Encryption Integration", ^{

    __block SecKeyRef testPrivateKey;
    __block NSString *testPublicKeyHex;

    beforeAll(^{
        testPrivateKey = [AvoEncryptionIntegrationTestHelper generateTestPrivateKey];
        expect(testPrivateKey).toNot.beNil();
        testPublicKeyHex = [AvoEncryptionIntegrationTestHelper publicKeyHexFromPrivateKey:testPrivateKey];
        expect(testPublicKeyHex).toNot.beNil();
    });

    afterAll(^{
        if (testPrivateKey) CFRelease(testPrivateKey);
    });

    // =========================================================================
    // Batched event encryption tests
    // =========================================================================

    describe(@"batched event encryption", ^{

        it(@"includes encrypted values in dev mode", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"testApiKey" appName:@"testApp" appVersion:@"1.0.0"
                libVersion:@"7" env:1 endpoint:@"test" publicEncryptionKey:testPublicKeyHex];

            NSMutableDictionary *schema = [NSMutableDictionary new];
            [schema setObject:[AvoString new] forKey:@"userId"];
            [schema setObject:[AvoInt new] forKey:@"count"];

            NSDictionary *eventProperties = @{@"userId": @"user123", @"count": @42};

            NSMutableDictionary *body = [handler bodyForTrackSchemaCall:@"TestEvent"
                                                                schema:schema
                                                               eventId:nil
                                                             eventHash:nil
                                                       eventProperties:eventProperties];

            NSArray *properties = body[@"eventProperties"];
            expect(properties).toNot.beNil();

            BOOL foundEncryptedUserId = NO;
            BOOL foundEncryptedCount = NO;
            for (NSDictionary *prop in properties) {
                if ([prop[@"propertyName"] isEqualToString:@"userId"]) {
                    expect(prop[@"encryptedPropertyValue"]).toNot.beNil();
                    foundEncryptedUserId = YES;
                }
                if ([prop[@"propertyName"] isEqualToString:@"count"]) {
                    expect(prop[@"encryptedPropertyValue"]).toNot.beNil();
                    foundEncryptedCount = YES;
                }
            }
            expect(foundEncryptedUserId).to.beTruthy();
            expect(foundEncryptedCount).to.beTruthy();
        });

        it(@"includes encrypted values in staging mode", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"testApiKey" appName:@"testApp" appVersion:@"1.0.0"
                libVersion:@"7" env:2 endpoint:@"test" publicEncryptionKey:testPublicKeyHex];

            NSMutableDictionary *schema = [NSMutableDictionary new];
            [schema setObject:[AvoString new] forKey:@"name"];

            NSDictionary *eventProperties = @{@"name": @"test"};

            NSMutableDictionary *body = [handler bodyForTrackSchemaCall:@"TestEvent"
                                                                schema:schema
                                                               eventId:nil
                                                             eventHash:nil
                                                       eventProperties:eventProperties];

            NSArray *properties = body[@"eventProperties"];
            NSDictionary *prop = properties[0];
            expect(prop[@"encryptedPropertyValue"]).toNot.beNil();
        });

        it(@"no encryption in prod even with key", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"testApiKey" appName:@"testApp" appVersion:@"1.0.0"
                libVersion:@"7" env:0 endpoint:@"test" publicEncryptionKey:testPublicKeyHex];

            NSMutableDictionary *schema = [NSMutableDictionary new];
            [schema setObject:[AvoString new] forKey:@"userId"];

            NSDictionary *eventProperties = @{@"userId": @"user123"};

            NSMutableDictionary *body = [handler bodyForTrackSchemaCall:@"TestEvent"
                                                                schema:schema
                                                               eventId:nil
                                                             eventHash:nil
                                                       eventProperties:eventProperties];

            NSArray *properties = body[@"eventProperties"];
            for (NSDictionary *prop in properties) {
                expect(prop[@"encryptedPropertyValue"]).to.beNil();
            }
        });

        it(@"no encryption when key is nil", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"testApiKey" appName:@"testApp" appVersion:@"1.0.0"
                libVersion:@"7" env:1 endpoint:@"test" publicEncryptionKey:nil];

            NSMutableDictionary *schema = [NSMutableDictionary new];
            [schema setObject:[AvoString new] forKey:@"userId"];

            NSDictionary *eventProperties = @{@"userId": @"user123"};

            NSMutableDictionary *body = [handler bodyForTrackSchemaCall:@"TestEvent"
                                                                schema:schema
                                                               eventId:nil
                                                             eventHash:nil
                                                       eventProperties:eventProperties];

            NSArray *properties = body[@"eventProperties"];
            for (NSDictionary *prop in properties) {
                expect(prop[@"encryptedPropertyValue"]).to.beNil();
            }
        });
    });

    // =========================================================================
    // publicEncryptionKey in base body tests
    // =========================================================================

    describe(@"publicEncryptionKey in base body", ^{

        it(@"includes publicEncryptionKey when present", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"testApiKey" appName:@"testApp" appVersion:@"1.0.0"
                libVersion:@"7" env:1 endpoint:@"test" publicEncryptionKey:testPublicKeyHex];

            NSMutableDictionary *body = [handler bodyForTrackSchemaCall:@"TestEvent"
                                                                schema:[NSMutableDictionary new]
                                                               eventId:nil
                                                             eventHash:nil
                                                       eventProperties:nil];

            expect(body[@"publicEncryptionKey"]).to.equal(testPublicKeyHex);
        });

        it(@"does not include publicEncryptionKey when nil", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"testApiKey" appName:@"testApp" appVersion:@"1.0.0"
                libVersion:@"7" env:1 endpoint:@"test" publicEncryptionKey:nil];

            NSMutableDictionary *body = [handler bodyForTrackSchemaCall:@"TestEvent"
                                                                schema:[NSMutableDictionary new]
                                                               eventId:nil
                                                             eventHash:nil
                                                       eventProperties:nil];

            expect(body[@"publicEncryptionKey"]).to.beNil();
        });
    });

    // =========================================================================
    // Nested object and list tests
    // =========================================================================

    describe(@"nested objects and lists", ^{

        it(@"nested object children are encrypted", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"testApiKey" appName:@"testApp" appVersion:@"1.0.0"
                libVersion:@"7" env:1 endpoint:@"test" publicEncryptionKey:testPublicKeyHex];

            AvoObject *addressObj = [AvoObject new];
            [addressObj.fields setObject:[AvoString new] forKey:@"street"];
            [addressObj.fields setObject:[AvoInt new] forKey:@"zip"];

            NSMutableDictionary *schema = [NSMutableDictionary new];
            [schema setObject:addressObj forKey:@"address"];

            NSDictionary *innerProps = @{@"street": @"123 Main St", @"zip": @90210};
            NSDictionary *eventProperties = @{@"address": innerProps};

            NSMutableDictionary *body = [handler bodyForTrackSchemaCall:@"TestEvent"
                                                                schema:schema
                                                               eventId:nil
                                                             eventHash:nil
                                                       eventProperties:eventProperties];

            NSArray *properties = body[@"eventProperties"];
            NSDictionary *addressProp = nil;
            for (NSDictionary *p in properties) {
                if ([p[@"propertyName"] isEqualToString:@"address"]) {
                    addressProp = p;
                    break;
                }
            }
            expect(addressProp).toNot.beNil();
            expect(addressProp[@"encryptedPropertyValue"]).to.beNil();

            NSArray *children = addressProp[@"children"];
            expect(children).toNot.beNil();

            BOOL foundEncryptedStreet = NO;
            BOOL foundEncryptedZip = NO;
            for (NSDictionary *child in children) {
                if ([child[@"propertyName"] isEqualToString:@"street"]) {
                    expect(child[@"encryptedPropertyValue"]).toNot.beNil();
                    foundEncryptedStreet = YES;
                }
                if ([child[@"propertyName"] isEqualToString:@"zip"]) {
                    expect(child[@"encryptedPropertyValue"]).toNot.beNil();
                    foundEncryptedZip = YES;
                }
            }
            expect(foundEncryptedStreet).to.beTruthy();
            expect(foundEncryptedZip).to.beTruthy();
        });

        it(@"list values are NOT encrypted", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"testApiKey" appName:@"testApp" appVersion:@"1.0.0"
                libVersion:@"7" env:1 endpoint:@"test" publicEncryptionKey:testPublicKeyHex];

            AvoList *list = [AvoList new];
            list.subtypes = [[NSMutableSet alloc] initWithArray:@[[AvoString new]]];

            NSMutableDictionary *schema = [NSMutableDictionary new];
            [schema setObject:list forKey:@"tags"];

            NSDictionary *eventProperties = @{@"tags": @[@"a", @"b", @"c"]};

            NSMutableDictionary *body = [handler bodyForTrackSchemaCall:@"TestEvent"
                                                                schema:schema
                                                               eventId:nil
                                                             eventHash:nil
                                                       eventProperties:eventProperties];

            NSArray *properties = body[@"eventProperties"];
            for (NSDictionary *prop in properties) {
                if ([prop[@"propertyName"] isEqualToString:@"tags"]) {
                    expect(prop[@"encryptedPropertyValue"]).to.beNil();
                }
            }
        });
    });

    // =========================================================================
    // shouldEncrypt tests
    // =========================================================================

    describe(@"shouldEncrypt", ^{

        it(@"returns YES for dev with key", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"key" appName:@"app" appVersion:@"1.0"
                libVersion:@"7" env:1 endpoint:@"test" publicEncryptionKey:testPublicKeyHex];
            expect([handler shouldEncrypt]).to.beTruthy();
        });

        it(@"returns YES for staging with key", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"key" appName:@"app" appVersion:@"1.0"
                libVersion:@"7" env:2 endpoint:@"test" publicEncryptionKey:testPublicKeyHex];
            expect([handler shouldEncrypt]).to.beTruthy();
        });

        it(@"returns NO for prod", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"key" appName:@"app" appVersion:@"1.0"
                libVersion:@"7" env:0 endpoint:@"test" publicEncryptionKey:testPublicKeyHex];
            expect([handler shouldEncrypt]).to.beFalsy();
        });

        it(@"returns NO for nil key", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"key" appName:@"app" appVersion:@"1.0"
                libVersion:@"7" env:1 endpoint:@"test" publicEncryptionKey:nil];
            expect([handler shouldEncrypt]).to.beFalsy();
        });

        it(@"returns NO for empty key", ^{
            AvoNetworkCallsHandler *handler = [[AvoNetworkCallsHandler alloc]
                initWithApiKey:@"key" appName:@"app" appVersion:@"1.0"
                libVersion:@"7" env:1 endpoint:@"test" publicEncryptionKey:@""];
            expect([handler shouldEncrypt]).to.beFalsy();
        });
    });

    // =========================================================================
    // JSON stringify value tests
    // =========================================================================

    describe(@"jsonStringifyValue", ^{

        it(@"stringifies a string", ^{
            expect([AvoNetworkCallsHandler jsonStringifyValue:@"hello"]).to.equal(@"\"hello\"");
        });

        it(@"stringifies an integer", ^{
            expect([AvoNetworkCallsHandler jsonStringifyValue:@42]).to.equal(@"42");
        });

        it(@"stringifies a double", ^{
            NSString *result = [AvoNetworkCallsHandler jsonStringifyValue:@3.14];
            // NSJSONSerialization may produce "3.14" or "3.1400000000000001" depending on precision
            expect([result hasPrefix:@"3.14"]).to.beTruthy();
        });

        it(@"stringifies a boolean true", ^{
            expect([AvoNetworkCallsHandler jsonStringifyValue:@YES]).to.equal(@"true");
        });

        it(@"stringifies a boolean false", ^{
            expect([AvoNetworkCallsHandler jsonStringifyValue:@NO]).to.equal(@"false");
        });
    });
});

SpecEnd
