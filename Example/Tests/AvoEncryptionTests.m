//
//  AvoEncryptionTests.m
//  AvoStateOfTracking_Tests
//
//  Tests for AvoEncryption ECIES (P-256 + AES-256-GCM).
//

#import <AvoInspector/AvoEncryption.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonCryptor.h>

// AES-GCM oneshot API — stable exported symbol in libcommonCrypto, not in public headers.
// See AvoEncryption.m header comment for rationale.
extern CCCryptorStatus CCCryptorGCMOneshotDecrypt(
    CCAlgorithm alg,
    const void *key, size_t keyLength,
    const void *iv, size_t ivLength,
    const void *aad, size_t aadLength,
    const void *dataIn, size_t dataInLength,
    void *dataOut,
    const void *tag, size_t tagLength);

@interface AvoEncryptionTestHelper : NSObject
+ (SecKeyRef _Nullable)generateTestPrivateKey;
+ (NSString *)publicKeyHexFromPrivateKey:(SecKeyRef)privateKey;
+ (NSString * _Nullable)decrypt:(NSString *)base64Encrypted privateKey:(SecKeyRef)privateKey;
@end

@implementation AvoEncryptionTestHelper

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

+ (NSString * _Nullable)decrypt:(NSString *)base64Encrypted privateKey:(SecKeyRef)privateKey {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Encrypted options:0];
    if (data == nil || data.length < 95) return nil;

    const uint8_t *bytes = data.bytes;

    // Version byte
    if (bytes[0] != 0x01) return nil;

    // Parse ephemeral public key (65 bytes)
    NSData *ephemeralPubData = [data subdataWithRange:NSMakeRange(1, 65)];
    // Nonce (12 bytes)
    NSData *iv = [data subdataWithRange:NSMakeRange(66, 12)];
    // Auth tag (16 bytes)
    NSData *authTag = [data subdataWithRange:NSMakeRange(78, 16)];
    // Ciphertext (rest)
    NSUInteger ciphertextLen = data.length - 94;
    NSData *ciphertext = [data subdataWithRange:NSMakeRange(94, ciphertextLen)];

    // Reconstruct ephemeral public key
    NSDictionary *keyAttrs = @{
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
        (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPublic,
        (id)kSecAttrKeySizeInBits: @256,
    };
    CFErrorRef error = NULL;
    SecKeyRef ephemeralPubKey = SecKeyCreateWithData((__bridge CFDataRef)ephemeralPubData,
                                                      (__bridge CFDictionaryRef)keyAttrs,
                                                      &error);
    if (ephemeralPubKey == NULL) {
        if (error) CFRelease(error);
        return nil;
    }

    // ECDH shared secret
    NSDictionary *params = @{};
    CFDataRef sharedSecretRef = SecKeyCopyKeyExchangeResult(privateKey,
                                                             kSecKeyAlgorithmECDHKeyExchangeStandard,
                                                             ephemeralPubKey,
                                                             (__bridge CFDictionaryRef)params,
                                                             &error);
    CFRelease(ephemeralPubKey);
    if (sharedSecretRef == NULL) {
        if (error) CFRelease(error);
        return nil;
    }
    NSData *sharedSecret = (__bridge_transfer NSData *)sharedSecretRef;

    // KDF: SHA-256
    uint8_t aesKeyBytes[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(sharedSecret.bytes, (CC_LONG)sharedSecret.length, aesKeyBytes);

    // AES-256-GCM decrypt using oneshot API
    NSMutableData *plaintext = [NSMutableData dataWithLength:ciphertextLen];

    CCCryptorStatus status = CCCryptorGCMOneshotDecrypt(
        kCCAlgorithmAES,
        aesKeyBytes, CC_SHA256_DIGEST_LENGTH,
        iv.bytes, iv.length,
        NULL, 0,  // no AAD
        ciphertext.bytes, ciphertext.length,
        plaintext.mutableBytes,
        authTag.bytes, authTag.length);
    if (status != kCCSuccess) return nil;

    return [[NSString alloc] initWithData:plaintext encoding:NSUTF8StringEncoding];
}

@end

SpecBegin(AvoEncryption)

describe(@"AvoEncryption", ^{

    __block SecKeyRef testPrivateKey;
    __block NSString *testPublicKeyHex;

    beforeAll(^{
        testPrivateKey = [AvoEncryptionTestHelper generateTestPrivateKey];
        expect(testPrivateKey).toNot.beNil();
        testPublicKeyHex = [AvoEncryptionTestHelper publicKeyHexFromPrivateKey:testPrivateKey];
        expect(testPublicKeyHex).toNot.beNil();
    });

    afterAll(^{
        if (testPrivateKey) CFRelease(testPrivateKey);
    });

    it(@"encrypts and decrypts a string value", ^{
        NSString *plaintext = @"\"hello world\"";
        NSString *encrypted = [AvoEncryption encrypt:plaintext recipientPublicKeyHex:testPublicKeyHex];
        expect(encrypted).toNot.beNil();

        NSString *decrypted = [AvoEncryptionTestHelper decrypt:encrypted privateKey:testPrivateKey];
        expect(decrypted).to.equal(plaintext);
    });

    it(@"encrypts and decrypts an integer value", ^{
        NSString *plaintext = @"42";
        NSString *encrypted = [AvoEncryption encrypt:plaintext recipientPublicKeyHex:testPublicKeyHex];
        expect(encrypted).toNot.beNil();

        NSString *decrypted = [AvoEncryptionTestHelper decrypt:encrypted privateKey:testPrivateKey];
        expect(decrypted).to.equal(plaintext);
    });

    it(@"encrypts and decrypts a double value", ^{
        NSString *plaintext = @"3.14";
        NSString *encrypted = [AvoEncryption encrypt:plaintext recipientPublicKeyHex:testPublicKeyHex];
        expect(encrypted).toNot.beNil();

        NSString *decrypted = [AvoEncryptionTestHelper decrypt:encrypted privateKey:testPrivateKey];
        expect(decrypted).to.equal(plaintext);
    });

    it(@"encrypts and decrypts a boolean value", ^{
        NSString *plaintext = @"true";
        NSString *encrypted = [AvoEncryption encrypt:plaintext recipientPublicKeyHex:testPublicKeyHex];
        expect(encrypted).toNot.beNil();

        NSString *decrypted = [AvoEncryptionTestHelper decrypt:encrypted privateKey:testPrivateKey];
        expect(decrypted).to.equal(plaintext);
    });

    it(@"output format has correct structure", ^{
        NSString *encrypted = [AvoEncryption encrypt:@"test" recipientPublicKeyHex:testPublicKeyHex];
        expect(encrypted).toNot.beNil();

        NSData *data = [[NSData alloc] initWithBase64EncodedString:encrypted options:0];
        expect(data).toNot.beNil();

        // Minimum size: 1 (version) + 65 (pubkey) + 12 (nonce) + 16 (tag) = 94
        expect(data.length).to.beGreaterThanOrEqualTo(94);

        const uint8_t *bytes = data.bytes;
        // Version byte
        expect(bytes[0]).to.equal(0x01);
        // Ephemeral public key starts with 0x04 (uncompressed)
        expect(bytes[1]).to.equal(0x04);
    });

    it(@"different encryptions produce different output", ^{
        NSString *plaintext = @"\"same text\"";
        NSString *encrypted1 = [AvoEncryption encrypt:plaintext recipientPublicKeyHex:testPublicKeyHex];
        NSString *encrypted2 = [AvoEncryption encrypt:plaintext recipientPublicKeyHex:testPublicKeyHex];

        expect(encrypted1).toNot.beNil();
        expect(encrypted2).toNot.beNil();
        expect(encrypted1).toNot.equal(encrypted2);

        // Both should decrypt to the same plaintext
        NSString *decrypted1 = [AvoEncryptionTestHelper decrypt:encrypted1 privateKey:testPrivateKey];
        NSString *decrypted2 = [AvoEncryptionTestHelper decrypt:encrypted2 privateKey:testPrivateKey];
        expect(decrypted1).to.equal(plaintext);
        expect(decrypted2).to.equal(plaintext);
    });

    it(@"returns nil for nil key", ^{
        NSString *result = [AvoEncryption encrypt:@"test" recipientPublicKeyHex:nil];
        expect(result).to.beNil();
    });

    it(@"returns nil for empty key", ^{
        NSString *result = [AvoEncryption encrypt:@"test" recipientPublicKeyHex:@""];
        expect(result).to.beNil();
    });

    it(@"returns nil for nil plaintext", ^{
        NSString *result = [AvoEncryption encrypt:nil recipientPublicKeyHex:testPublicKeyHex];
        expect(result).to.beNil();
    });

    it(@"returns nil for invalid key", ^{
        NSString *result = [AvoEncryption encrypt:@"test" recipientPublicKeyHex:@"deadbeef"];
        expect(result).to.beNil();
    });

    it(@"decompresses known secp256r1 test vector correctly", ^{
        // secp256r1 generator point G (a known point on the curve)
        // X = 6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296
        // Y = 4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5
        // Y is odd (last byte 0xF5, bit 0 = 1) → compressed prefix 0x03
        NSString *compressedHex = @"036B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296";

        // Encrypt with the compressed generator point. If decompression is wrong,
        // SecKeyCreateWithData will reject the reconstructed uncompressed key → nil.
        NSString *encrypted = [AvoEncryption encrypt:@"test" recipientPublicKeyHex:compressedHex];
        expect(encrypted).toNot.beNil();

        // Verify the ephemeral key in the output uses the correct uncompressed format
        NSData *data = [[NSData alloc] initWithBase64EncodedString:encrypted options:0];
        const uint8_t *bytes = data.bytes;
        expect(bytes[0]).to.equal(0x01); // version
        expect(bytes[1]).to.equal(0x04); // uncompressed ephemeral key
    });

    it(@"encrypts and decrypts with compressed key", ^{
        // Build compressed key from the test public key
        SecKeyRef pubKey = SecKeyCopyPublicKey(testPrivateKey);
        CFErrorRef error = NULL;
        CFDataRef pubKeyData = SecKeyCopyExternalRepresentation(pubKey, &error);
        CFRelease(pubKey);
        NSData *uncompressed = (__bridge_transfer NSData *)pubKeyData;

        // uncompressed is 0x04 + X(32) + Y(32)
        const uint8_t *ubytes = uncompressed.bytes;
        uint8_t prefix = (ubytes[64] & 1) ? 0x03 : 0x02;

        NSMutableString *compressedHex = [NSMutableString stringWithCapacity:66];
        [compressedHex appendFormat:@"%02x", prefix];
        for (int i = 1; i <= 32; i++) {
            [compressedHex appendFormat:@"%02x", ubytes[i]];
        }
        expect(compressedHex.length).to.equal(66);

        NSString *plaintext = @"\"compressed key test\"";
        NSString *encrypted = [AvoEncryption encrypt:plaintext recipientPublicKeyHex:compressedHex];
        expect(encrypted).toNot.beNil();

        NSString *decrypted = [AvoEncryptionTestHelper decrypt:encrypted privateKey:testPrivateKey];
        expect(decrypted).to.equal(plaintext);
    });
});

SpecEnd
