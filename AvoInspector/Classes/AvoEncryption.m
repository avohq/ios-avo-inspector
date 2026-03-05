//
//  AvoEncryption.m
//  AvoInspector
//
//  ECIES encryption (P-256 + AES-256-GCM) for property value encryption.
//

#import "AvoEncryption.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>
#import "AvoInspector-Swift.h"

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

        // 5. Generate random IV
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
        NSLog(@"[avo] Avo Inspector: Encryption failed: %@", exception);
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
    const uint8_t *bytes = compressedKey.bytes;
    BOOL yOdd = (bytes[0] == 0x03);

    // Extract X coordinate (32 bytes after prefix)
    NSData *xData = [compressedKey subdataWithRange:NSMakeRange(1, 32)];

    // secp256r1 curve parameters
    // p = FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF
    // a = FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC
    // b = 5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B

    // We need to compute Y from X using the curve equation: y^2 = x^3 + ax + b (mod p)
    // For secp256r1, p ≡ 3 (mod 4), so y = (y^2)^((p+1)/4) mod p

    // Use OpenSSL-free big number arithmetic via SecKey
    // Strategy: create a temporary key with both coordinates to validate,
    // using the mathematical approach with CC_SHA256 for big number ops.

    // Actually, the simplest approach on iOS is to use the curve equation directly
    // with big number arithmetic. Since we don't have a BigInteger class,
    // we'll implement modular arithmetic on byte arrays.

    NSData *yData = [self computeYFromX:xData yOdd:yOdd];
    if (yData == nil) {
        return nil;
    }

    // Build uncompressed point: 0x04 + X(32) + Y(32)
    NSMutableData *uncompressed = [NSMutableData dataWithCapacity:65];
    uint8_t prefix = 0x04;
    [uncompressed appendBytes:&prefix length:1];
    [uncompressed appendData:xData];
    [uncompressed appendData:yData];
    return uncompressed;
}

// Big number arithmetic for secp256r1 Y-coordinate recovery
// All numbers are 32-byte big-endian unsigned integers

// secp256r1 prime p
static const uint8_t secp256r1_p[32] = {
    0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
};

// secp256r1 a = p - 3
static const uint8_t secp256r1_a[32] = {
    0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFC
};

// secp256r1 b
static const uint8_t secp256r1_b[32] = {
    0x5A, 0xC6, 0x35, 0xD8, 0xAA, 0x3A, 0x93, 0xE7,
    0xB3, 0xEB, 0xBD, 0x55, 0x76, 0x98, 0x86, 0xBC,
    0x65, 0x1D, 0x06, 0xB0, 0xCC, 0x53, 0xB0, 0xF6,
    0x3B, 0xCE, 0x3C, 0x3E, 0x27, 0xD2, 0x60, 0x4B
};

// (p + 1) / 4 — used for modular square root since p ≡ 3 (mod 4)
static const uint8_t secp256r1_p_plus1_div4[32] = {
    0x3F, 0xFF, 0xFF, 0xFF, 0xC0, 0x00, 0x00, 0x00,
    0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

// Modular multiplication: (a * b) mod p using 64-byte intermediate
+ (void)bigMulMod:(const uint8_t *)a b:(const uint8_t *)b p:(const uint8_t *)p result:(uint8_t *)result {
    // Compute a * b into a 64-byte buffer
    uint8_t product[64];
    memset(product, 0, 64);

    for (int i = 31; i >= 0; i--) {
        uint16_t carry = 0;
        for (int j = 31; j >= 0; j--) {
            uint32_t val = (uint32_t)product[i + j + 1] + (uint32_t)a[i] * (uint32_t)b[j] + carry;
            product[i + j + 1] = (uint8_t)(val & 0xFF);
            carry = (uint16_t)(val >> 8);
        }
        product[i] += (uint8_t)carry;
    }

    // Reduce product mod p
    [self bigMod:product len:64 p:p result:result];
}

// Modular reduction: num (len bytes, big-endian) mod p (32 bytes) -> result (32 bytes)
// Uses schoolbook byte-by-byte long division with repeated subtraction.
+ (void)bigMod:(const uint8_t *)num len:(int)len p:(const uint8_t *)p result:(uint8_t *)result {
    // 33-byte accumulator: one extra byte for overflow during shift
    uint8_t remainder[33];
    memset(remainder, 0, 33);

    for (int i = 0; i < len; i++) {
        // remainder = (remainder << 8) | num[i]
        for (int j = 0; j < 32; j++) {
            remainder[j] = remainder[j + 1];
        }
        remainder[32] = num[i];

        // Reduce: while remainder >= p, subtract p
        while ([self bigCompare33:remainder p:p] >= 0) {
            [self bigSub33:remainder p:p];
        }
    }

    // Result is in remainder[1..32]
    memcpy(result, remainder + 1, 32);
}

+ (int)bigCompare33:(const uint8_t *)a p:(const uint8_t *)p {
    // Compare 33-byte a with 32-byte p (p has implicit leading zero)
    if (a[0] != 0) return 1; // a has a non-zero 33rd byte, so a > p
    return [self bigCompare:a + 1 len:32 p:p];
}

+ (void)bigSub33:(uint8_t *)a p:(const uint8_t *)p {
    // Subtract 32-byte p from 33-byte a, result in a
    int16_t borrow = 0;
    for (int i = 32; i >= 1; i--) {
        int16_t diff = (int16_t)a[i] - (int16_t)p[i - 1] - borrow;
        if (diff < 0) {
            diff += 256;
            borrow = 1;
        } else {
            borrow = 0;
        }
        a[i] = (uint8_t)diff;
    }
    a[0] = (uint8_t)((int16_t)a[0] - borrow);
}

+ (int)bigCompare:(const uint8_t *)a len:(int)aLen p:(const uint8_t *)p {
    // Compare a (aLen bytes) with p (32 bytes)
    // Skip leading zeros in a
    int aStart = 0;
    while (aStart < aLen - 32 && a[aStart] == 0) aStart++;

    if (aLen - aStart > 32) return 1;
    if (aLen - aStart < 32) return -1;

    for (int i = 0; i < 32; i++) {
        if (a[aStart + i] > p[i]) return 1;
        if (a[aStart + i] < p[i]) return -1;
    }
    return 0;
}

// Modular addition: (a + b) mod p, all 32 bytes
+ (void)bigAddMod:(const uint8_t *)a b:(const uint8_t *)b p:(const uint8_t *)p result:(uint8_t *)result {
    uint16_t carry = 0;
    uint8_t sum[33];
    sum[0] = 0;
    for (int i = 31; i >= 0; i--) {
        uint16_t s = (uint16_t)a[i] + (uint16_t)b[i] + carry;
        sum[i + 1] = (uint8_t)(s & 0xFF);
        carry = s >> 8;
    }
    sum[0] = (uint8_t)carry;

    // Reduce mod p
    while ([self bigCompare33:sum p:p] >= 0) {
        [self bigSub33:sum p:p];
    }
    memcpy(result, sum + 1, 32);
}

// Modular exponentiation: base^exp mod p (all 32 bytes)
+ (void)bigModPow:(const uint8_t *)base exp:(const uint8_t *)exp p:(const uint8_t *)p result:(uint8_t *)result {
    uint8_t r[32];
    memset(r, 0, 32);
    r[31] = 1; // r = 1

    uint8_t b[32];
    memcpy(b, base, 32);

    // Square-and-multiply from LSB
    for (int byteIdx = 31; byteIdx >= 0; byteIdx--) {
        for (int bitIdx = 0; bitIdx < 8; bitIdx++) {
            if ((exp[byteIdx] >> bitIdx) & 1) {
                uint8_t temp[32];
                [self bigMulMod:r b:b p:p result:temp];
                memcpy(r, temp, 32);
            }
            uint8_t temp2[32];
            [self bigMulMod:b b:b p:p result:temp2];
            memcpy(b, temp2, 32);
        }
    }

    memcpy(result, r, 32);
}

// Modular subtraction: (p - a) mod p
+ (void)bigSubFromP:(const uint8_t *)a p:(const uint8_t *)p result:(uint8_t *)result {
    int16_t borrow = 0;
    for (int i = 31; i >= 0; i--) {
        int16_t diff = (int16_t)p[i] - (int16_t)a[i] - borrow;
        if (diff < 0) {
            diff += 256;
            borrow = 1;
        } else {
            borrow = 0;
        }
        result[i] = (uint8_t)diff;
    }
}

+ (NSData * _Nullable)computeYFromX:(NSData *)xData yOdd:(BOOL)yOdd {
    const uint8_t *x = xData.bytes;
    const uint8_t *p = secp256r1_p;
    const uint8_t *a = secp256r1_a;
    const uint8_t *b = secp256r1_b;

    // Compute y^2 = x^3 + a*x + b (mod p)
    // Step 1: x^2 mod p
    uint8_t x2[32];
    [self bigMulMod:x b:x p:p result:x2];

    // Step 2: x^3 mod p
    uint8_t x3[32];
    [self bigMulMod:x2 b:x p:p result:x3];

    // Step 3: a*x mod p
    uint8_t ax[32];
    [self bigMulMod:a b:x p:p result:ax];

    // Step 4: x^3 + a*x mod p
    uint8_t sum1[32];
    [self bigAddMod:x3 b:ax p:p result:sum1];

    // Step 5: x^3 + a*x + b mod p
    uint8_t ySquared[32];
    [self bigAddMod:sum1 b:b p:p result:ySquared];

    // Step 6: y = ySquared^((p+1)/4) mod p (since p ≡ 3 mod 4)
    uint8_t y[32];
    [self bigModPow:ySquared exp:secp256r1_p_plus1_div4 p:p result:y];

    // Check parity
    BOOL yIsOdd = (y[31] & 1) != 0;
    if (yIsOdd != yOdd) {
        uint8_t negY[32];
        [self bigSubFromP:y p:p result:negY];
        return [NSData dataWithBytes:negY length:32];
    }

    return [NSData dataWithBytes:y length:32];
}

#pragma mark - SecKey Operations

+ (SecKeyRef _Nullable)createECPublicKeyFromUncompressedData:(NSData *)uncompressedData {
    // The Security framework on iOS expects the key data to include the 0x04 prefix
    // for uncompressed EC points when using kSecAttrKeyTypeECSECPrimeRandom
    NSDictionary *attributes = @{
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
        (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPublic,
        (id)kSecAttrKeySizeInBits: @256,
    };

    CFErrorRef error = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)uncompressedData,
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
    return [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
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
