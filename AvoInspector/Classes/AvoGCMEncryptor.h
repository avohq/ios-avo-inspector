//
//  AvoGCMEncryptor.h
//  AvoInspector
//
//  ObjC-visible interface for AvoGCMEncryptor (implemented in Swift).
//  Declaring the interface here lets AvoEncryption.m use AvoGCMEncryptor
//  without importing the Xcode-generated AvoInspector-Swift.h, which is
//  not available during the dependency-scanning phase of the build.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AvoGCMEncryptor : NSObject
+ (BOOL)encrypt:(NSData *)plaintext
            key:(NSData *)key
             iv:(NSData *)iv
     ciphertext:(NSMutableData *)ciphertext
        authTag:(NSMutableData *)authTag;

/// Decompresses a 33-byte SEC1 compressed P-256 public key using CryptoKit.
/// Returns the 65-byte uncompressed point (0x04 || X || Y), or nil on failure.
/// Requires iOS 16+.
+ (nullable NSData *)decompressPublicKey:(NSData *)compressedKey API_AVAILABLE(ios(16.0));
@end

NS_ASSUME_NONNULL_END
