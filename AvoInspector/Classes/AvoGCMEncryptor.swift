import Foundation
import CryptoKit

@objc(AvoGCMEncryptor)
internal class AvoGCMEncryptor: NSObject {

    @objc static func encrypt(_ plaintext: NSData, key: NSData, iv: NSData, ciphertext: NSMutableData, authTag: NSMutableData) -> Bool {
        do {
            let symKey = SymmetricKey(data: key as Data)
            let nonce = try AES.GCM.Nonce(data: iv as Data)
            let sealedBox = try AES.GCM.seal(plaintext as Data, using: symKey, nonce: nonce)
            guard sealedBox.tag.count == 16 else { return false }
            ciphertext.setData(Data(sealedBox.ciphertext))
            authTag.setData(Data(sealedBox.tag))
            return true
        } catch {
            NSLog("[avo] Avo Inspector: AES-GCM encryption failed: \(error)")
            return false
        }
    }

    /// Decompresses a 33-byte SEC1 compressed P-256 public key into the 65-byte
    /// uncompressed form (0x04 || X || Y).  Returns nil on any parse failure.
    /// Requires iOS 16+ for CryptoKit compressed-key parsing.
    @available(iOS 16.0, *)
    @objc static func decompressPublicKey(_ compressedKey: NSData) -> NSData? {
        guard let publicKey = try? P256.KeyAgreement.PublicKey(
            compressedRepresentation: compressedKey as Data
        ) else {
            return nil
        }
        // x963Representation is the 65-byte uncompressed point: 0x04 || X(32) || Y(32)
        return publicKey.x963Representation as NSData
    }
}
