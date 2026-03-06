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
@end

NS_ASSUME_NONNULL_END
