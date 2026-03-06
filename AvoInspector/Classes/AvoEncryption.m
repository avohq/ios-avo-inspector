//
//  AvoEncryption.m
//  AvoInspector
//
//  ECIES encryption (P-256 + AES-256-GCM) for property value encryption.
//

#import "AvoEncryption.h"
#import "AvoInspector.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>
#import "AvoGCMEncryptor.h"

// AES-GCM constants
static const NSInteger kNonceLength = 12;
static const NSInteger kAuthTagLength = 16;
static const NSInteger kUncompressedKeyLength = 65;
static const NSInteger kVersionByteLength = 1;
static const uint8_t kVersionByte = 0x01;

@implementation AvoEncryption

#pragma mark - Public API

+ (NSString * _Nullable)encrypt:(NSString * _Nullable)plaintext
         recipientPublicKeyHex:(NSString * _Nullable)recipientPublicKeyHex {
    @try {
        if (plaintext == nil || recipientPublicKeyHex == nil || recipientPublicKeyHex.length == 0) {
            return nil;
        }

        // 1. Parse recipient public key from hex
        NSData *pubKeyBytes = [self hexToBytes:recipientPublicKeyHex];
        if (pubKeyBytes == nil) {
            return nil;
        }

        NSData *uncompressedPubKeyData = [self parseAndUncompressPublicKey:pubKeyBytes];
        if (uncompressedPubKeyData == nil) {
            return nil;
        }

        SecKeyRef recipientKey = [self createECPublicKeyFromUncompressedData:uncompressedPubKeyData];
        if (recipientKey == NULL) {
            return nil;
        }

        // 2. Generate ephemeral P-256 keypair
        SecKeyRef ephemeralPrivateKey = NULL;
        SecKeyRef ephemeralPublicKey = NULL;
        BOOL keyGenOk = [self generateEphemeralKeyPairPrivate:&ephemeralPrivateKey public:&ephemeralPublicKey];
        if (!keyGenOk) {
            CFRelease(recipientKey);
            return nil;
        }

        // 3. ECDH shared secret
        NSData *sharedSecret = [self computeECDHSharedSecret:ephemeralPrivateKey withPublicKey:recipientKey];
        CFRelease(recipientKey);
        if (sharedSecret == nil) {
            CFRelease(ephemeralPrivateKey);
            CFRelease(ephemeralPublicKey);
            return nil;
        }

        // 4. KDF: SHA-256(sharedSecret) -> 32-byte AES key
        NSData *aesKey = [self sha256:sharedSecret];

        // 5. Generate random nonce
        NSMutableData *nonce = [NSMutableData dataWithLength:kNonceLength];
        int result = SecRandomCopyBytes(kSecRandomDefault, kNonceLength, nonce.mutableBytes);
        if (result != errSecSuccess) {
            CFRelease(ephemeralPrivateKey);
            CFRelease(ephemeralPublicKey);
            return nil;
        }

        // 6. AES-256-GCM encrypt
        NSData *plaintextData = [plaintext dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableData *ciphertext = [NSMutableData dataWithLength:plaintextData.length];
        NSMutableData *authTag = [NSMutableData dataWithLength:kAuthTagLength];

        BOOL encryptOk = [AvoGCMEncryptor encrypt:plaintextData
                                         key:aesKey
                                          iv:nonce
                                  ciphertext:ciphertext
                                     authTag:authTag];
        CFRelease(ephemeralPrivateKey);

        if (!encryptOk) {
            CFRelease(ephemeralPublicKey);
            return nil;
        }

        // 7. Encode ephemeral public key as uncompressed point
        NSData *ephemeralPubData = [self exportUncompressedPublicKey:ephemeralPublicKey];
        CFRelease(ephemeralPublicKey);
        if (ephemeralPubData == nil || ephemeralPubData.length != kUncompressedKeyLength) {
            return nil;
        }

        // 8. Assemble: [Version(1)] + [EphemeralPubKey(65)] + [Nonce(12)] + [AuthTag(16)] + [Ciphertext]
        NSMutableData *output = [NSMutableData dataWithCapacity:
                                 kVersionByteLength + kUncompressedKeyLength + kNonceLength + kAuthTagLength + ciphertext.length];
        uint8_t version = kVersionByte;
        [output appendBytes:&version length:1];
        [output appendData:ephemeralPubData];
        [output appendData:nonce];
        [output appendData:authTag];
        [output appendData:ciphertext];

        // 9. Base64 encode (no line breaks)
        return [output base64EncodedStringWithOptions:0];
    }
    @catch (NSException *exception) {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Encryption failed: %@", exception);
        }
        return nil;
    }
}

#pragma mark - Key Parsing

+ (NSData * _Nullable)hexToBytes:(NSString *)hex {
    if (hex == nil || hex.length == 0) {
        return nil;
    }

    // Remove 0x prefix if present
    if ([hex hasPrefix:@"0x"] || [hex hasPrefix:@"0X"]) {
        hex = [hex substringFromIndex:2];
    }

    if (hex.length % 2 != 0) {
        return nil;
    }

    NSMutableData *data = [NSMutableData dataWithCapacity:hex.length / 2];
    for (NSUInteger i = 0; i < hex.length; i += 2) {
        NSString *byteString = [hex substringWithRange:NSMakeRange(i, 2)];
        unsigned int byteValue;
        NSScanner *scanner = [NSScanner scannerWithString:byteString];
        if (![scanner scanHexInt:&byteValue]) {
            return nil;
        }
        uint8_t byte = (uint8_t)byteValue;
        [data appendBytes:&byte length:1];
    }
    return data;
}

+ (NSData * _Nullable)parseAndUncompressPublicKey:(NSData *)pubKeyBytes {
    const uint8_t *bytes = pubKeyBytes.bytes;
    NSUInteger length = pubKeyBytes.length;

    if (length == 33 && (bytes[0] == 0x02 || bytes[0] == 0x03)) {
        // Compressed key: prefix (1 byte) + X (32 bytes)
        return [self decompressPublicKey:pubKeyBytes];
    } else if (length == 65 && bytes[0] == 0x04) {
        // Uncompressed with 0x04 prefix
        return pubKeyBytes;
    } else if (length == 64) {
        // Raw X + Y without prefix, add 0x04
        NSMutableData *uncompressed = [NSMutableData dataWithCapacity:65];
        uint8_t prefix = 0x04;
        [uncompressed appendBytes:&prefix length:1];
        [uncompressed appendData:pubKeyBytes];
        return uncompressed;
    }

    return nil;
}

+ (NSData * _Nullable)decompressPublicKey:(NSData *)compressedKey {
    if (@available(iOS 16.0, *)) {
        // CryptoKit can parse compressed keys directly (iOS 16+).
        // Returns the 65-byte uncompressed point (0x04 || X || Y).
        return [AvoGCMEncryptor decompressPublicKey:compressedKey];
    }
    // iOS 13–15: Attempt to decompress via Security framework round-trip.
    // SecKeyCreateWithData may accept compressed EC keys on some OS versions,
    // and SecKeyCopyExternalRepresentation always returns uncompressed form.
    NSDictionary *attributes = @{
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
        (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPublic,
        (id)kSecAttrKeySizeInBits: @256,
    };
    CFErrorRef error = NULL;
    SecKeyRef tempKey = SecKeyCreateWithData((__bridge CFDataRef)compressedKey,
                                             (__bridge CFDictionaryRef)attributes,
                                             &error);
    if (tempKey == NULL) {
        if (error != NULL) CFRelease(error);
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Compressed public key (0x02/0x03 prefix) is not supported on iOS 13-15. Please provide an uncompressed key (0x04 prefix, 65 bytes) or target iOS 16+. Encryption will be skipped.");
        }
        return nil;
    }
    NSData *uncompressed = [self exportUncompressedPublicKey:tempKey];
    CFRelease(tempKey);
    if (uncompressed == nil) {
        if ([AvoInspector isLogging]) {
            NSLog(@"[avo] Avo Inspector: Failed to decompress public key on iOS 13-15. Please provide an uncompressed key (0x04 prefix, 65 bytes). Encryption will be skipped.");
        }
    }
    return uncompressed;
}

#pragma mark - SecKey Operations

+ (SecKeyRef _Nullable)createECPublicKeyFromUncompressedData:(NSData *)keyData {
    // Expects a 65-byte uncompressed EC public key (0x04 || X || Y).
    // Compressed keys are resolved to uncompressed form in decompressPublicKey:
    // before reaching this method.
    NSDictionary *attributes = @{
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
        (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPublic,
        (id)kSecAttrKeySizeInBits: @256,
    };

    CFErrorRef error = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)keyData,
                                          (__bridge CFDictionaryRef)attributes,
                                          &error);
    if (error != NULL) {
        CFRelease(error);
        return NULL;
    }
    return key;
}

+ (BOOL)generateEphemeralKeyPairPrivate:(SecKeyRef *)privateKey public:(SecKeyRef *)publicKey {
    NSDictionary *attributes = @{
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
        (id)kSecAttrKeySizeInBits: @256,
    };

    CFErrorRef error = NULL;
    *privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, &error);
    if (*privateKey == NULL) {
        if (error != NULL) CFRelease(error);
        return NO;
    }

    *publicKey = SecKeyCopyPublicKey(*privateKey);
    if (*publicKey == NULL) {
        CFRelease(*privateKey);
        *privateKey = NULL;
        return NO;
    }

    return YES;
}

+ (NSData * _Nullable)computeECDHSharedSecret:(SecKeyRef)privateKey withPublicKey:(SecKeyRef)publicKey {
    NSDictionary *params = @{};
    CFErrorRef error = NULL;
    CFDataRef sharedSecretRef = SecKeyCopyKeyExchangeResult(privateKey,
                                                             kSecKeyAlgorithmECDHKeyExchangeStandard,
                                                             publicKey,
                                                             (__bridge CFDictionaryRef)params,
                                                             &error);
    if (sharedSecretRef == NULL) {
        if (error != NULL) CFRelease(error);
        return nil;
    }

    NSData *sharedSecret = (__bridge_transfer NSData *)sharedSecretRef;
    return sharedSecret;
}

+ (NSData *)sha256:(NSData *)data {
    uint8_t hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    NSData *hashData = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
    memset_s(hash, CC_SHA256_DIGEST_LENGTH, 0, CC_SHA256_DIGEST_LENGTH);
    return hashData;
}

+ (NSData * _Nullable)exportUncompressedPublicKey:(SecKeyRef)publicKey {
    CFErrorRef error = NULL;
    CFDataRef keyData = SecKeyCopyExternalRepresentation(publicKey, &error);
    if (keyData == NULL) {
        if (error != NULL) CFRelease(error);
        return nil;
    }

    NSData *data = (__bridge_transfer NSData *)keyData;

    // On iOS, the external representation of an EC public key is the
    // uncompressed point: 0x04 + X(32) + Y(32) = 65 bytes
    if (data.length == kUncompressedKeyLength) {
        return data;
    }

    return nil;
}

@end
