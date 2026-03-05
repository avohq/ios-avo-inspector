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
            ciphertext.setData(sealedBox.ciphertext as NSData)
            authTag.setData(sealedBox.tag as NSData)
            return true
        } catch {
            NSLog("[avo] Avo Inspector: AES-GCM encryption failed: \(error)")
            return false
        }
    }
}
