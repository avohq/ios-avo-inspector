//
//  AvoEncryption.h
//  AvoInspector
//
//  ECIES encryption (P-256 + AES-256-GCM) for property value encryption.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AvoEncryption : NSObject

/**
 Encrypts plaintext using ECIES (Elliptic Curve Integrated Encryption Scheme).

 Algorithm:
 1. Parse recipient public key from hex (compressed or uncompressed)
 2. Generate ephemeral P-256 keypair
 3. ECDH shared secret
 4. KDF: SHA-256(sharedSecret) -> 32-byte AES key
 5. AES-256-GCM encrypt with random 16-byte IV
 6. Serialize: [Version(1)] + [EphemeralPubKey(65)] + [IV(16)] + [AuthTag(16)] + [Ciphertext]
 7. Base64 encode

 @param plaintext The string to encrypt
 @param recipientPublicKeyHex The recipient's EC public key in hex (compressed or uncompressed)
 @return Base64-encoded ciphertext, or nil on any error
 */
+ (NSString * _Nullable)encrypt:(NSString * _Nullable)plaintext
         recipientPublicKeyHex:(NSString * _Nullable)recipientPublicKeyHex;

@end

NS_ASSUME_NONNULL_END
