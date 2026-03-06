#!/usr/bin/env node
// generate-fixture.js
// Generates ECIES v0x01 and v0x00 test fixtures for InspectorStream__CryptoHelper tests
// Uses Node.js built-in crypto module (no external dependencies)
//
// Usage: node generate-fixture.js
//
// v0x01 wire format: [version(1)] [ephemeralPublicKey(65, uncompressed)] [nonce(12)] [authTag(16)] [ciphertext]
// v0x00 wire format: [version(1)] [ephemeralPublicKey(65, uncompressed)] [iv(16)] [authTag(16)] [ciphertext]
//
// Note: iOS Security.framework always produces 65-byte uncompressed ephemeral public keys.
// v0x01 uses 65-byte uncompressed keys to match the actual iOS SDK wire format.

import crypto from "crypto";

// Test private key (32 bytes)
const TEST_PRIVATE_KEY_HEX =
  "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20";

// The plaintext to encrypt (JSON-encoded string value)
const PLAINTEXT = '"hello v01"';

// --- Helper: hex string to Buffer ---
function hexToBuffer(hex) {
  return Buffer.from(hex, "hex");
}

// --- Helper: Buffer to base64 ---
function toBase64(buf) {
  return buf.toString("base64");
}

// --- Generate v0x01 fixture ---
async function generateV1Fixture() {
  const subtle = crypto.webcrypto.subtle;

  const privateKeyBytes = hexToBuffer(TEST_PRIVATE_KEY_HEX);

  // Use node's ECDH for key operations
  const recipientECDH = crypto.createECDH("prime256v1");
  recipientECDH.setPrivateKey(privateKeyBytes);
  const recipientPublicKeyUncompressed = recipientECDH.getPublicKey(); // 65 bytes, uncompressed

  // Generate ephemeral key pair
  const ephemeralECDH = crypto.createECDH("prime256v1");
  ephemeralECDH.generateKeys();

  // Use UNCOMPRESSED form (65 bytes) for v0x01 — iOS Security.framework always produces 65-byte uncompressed keys
  const ephemeralPublicKeyUncompressed = ephemeralECDH.getPublicKey(); // 65 bytes, uncompressed (default)

  // ECDH: compute shared secret
  const sharedSecretBytes = ephemeralECDH.computeSecret(recipientPublicKeyUncompressed);

  // SHA-256 KDF
  const derivedKeyBuffer = crypto.createHash("sha256").update(sharedSecretBytes).digest();

  // Generate 12 random nonce bytes (v0x01 uses 12-byte nonce)
  const nonce = crypto.randomBytes(12);

  // AES-GCM encrypt the plaintext
  const plaintextBytes = Buffer.from(PLAINTEXT, "utf8");

  // Import key into Web Crypto for AES-GCM
  const aesKey = await subtle.importKey(
    "raw",
    derivedKeyBuffer,
    { name: "AES-GCM" },
    false,
    ["encrypt"]
  );

  const encryptedResult = await subtle.encrypt(
    { name: "AES-GCM", iv: nonce, tagLength: 128 },
    aesKey,
    plaintextBytes
  );

  // Web Crypto returns ciphertext + auth tag concatenated
  const encryptedBytes = Buffer.from(encryptedResult);
  // Last 16 bytes are auth tag
  const ciphertext = encryptedBytes.slice(0, encryptedBytes.length - 16);
  const authTag = encryptedBytes.slice(encryptedBytes.length - 16);

  // Assemble v0x01 wire format:
  // [version(1)] [ephemeralPublicKey(65, uncompressed)] [nonce(12)] [authTag(16)] [ciphertext]
  const version = Buffer.from([0x01]);
  const wireFormat = Buffer.concat([version, ephemeralPublicKeyUncompressed, nonce, authTag, ciphertext]);

  return {
    version: "v0x01",
    privateKeyHex: TEST_PRIVATE_KEY_HEX,
    plaintext: PLAINTEXT,
    ephemeralPublicKeyHex: ephemeralPublicKeyUncompressed.toString("hex"),
    nonceHex: nonce.toString("hex"),
    authTagHex: authTag.toString("hex"),
    ciphertextHex: ciphertext.toString("hex"),
    encryptedBase64: toBase64(wireFormat),
    wireFormatDescription: "version(1) + ephemeralPublicKey(65, uncompressed) + nonce(12) + authTag(16) + ciphertext",
    totalHeaderBytes: 1 + 65 + 12 + 16,
  };
}

// --- Generate v0x00 fixture ---
async function generateV0Fixture() {
  const subtle = crypto.webcrypto.subtle;

  const privateKeyBytes = hexToBuffer(TEST_PRIVATE_KEY_HEX);

  // Use node's ECDH
  const recipientECDH = crypto.createECDH("prime256v1");
  recipientECDH.setPrivateKey(privateKeyBytes);
  const recipientPublicKeyUncompressed = recipientECDH.getPublicKey();

  // Ephemeral key pair
  const ephemeralECDH = crypto.createECDH("prime256v1");
  ephemeralECDH.generateKeys();
  const ephemeralPublicKeyUncompressed = ephemeralECDH.getPublicKey(); // 65 bytes uncompressed

  // ECDH shared secret
  const sharedSecretBytes = ephemeralECDH.computeSecret(recipientPublicKeyUncompressed);

  // SHA-256 KDF
  const derivedKeyBuffer = crypto.createHash("sha256").update(sharedSecretBytes).digest();

  // Generate 16-byte IV (v0x00 uses 16-byte IV)
  const iv = crypto.randomBytes(16);

  // Plaintext (same as v0x01)
  const plaintextBytes = Buffer.from(PLAINTEXT, "utf8");

  // AES-GCM encrypt
  const aesKey = await subtle.importKey(
    "raw",
    derivedKeyBuffer,
    { name: "AES-GCM" },
    false,
    ["encrypt"]
  );

  const encryptedResult = await subtle.encrypt(
    { name: "AES-GCM", iv: iv, tagLength: 128 },
    aesKey,
    plaintextBytes
  );

  const encryptedBytes = Buffer.from(encryptedResult);
  const ciphertext = encryptedBytes.slice(0, encryptedBytes.length - 16);
  const authTag = encryptedBytes.slice(encryptedBytes.length - 16);

  // v0x00 wire format:
  // [version(1)] [ephemeralPublicKey(65, uncompressed)] [iv(16)] [authTag(16)] [ciphertext]
  const version = Buffer.from([0x00]);
  const wireFormat = Buffer.concat([version, ephemeralPublicKeyUncompressed, iv, authTag, ciphertext]);

  return {
    version: "v0x00",
    privateKeyHex: TEST_PRIVATE_KEY_HEX,
    plaintext: PLAINTEXT,
    ephemeralPublicKeyHex: ephemeralPublicKeyUncompressed.toString("hex"),
    ivHex: iv.toString("hex"),
    authTagHex: authTag.toString("hex"),
    ciphertextHex: ciphertext.toString("hex"),
    encryptedBase64: toBase64(wireFormat),
    wireFormatDescription: "version(1) + ephemeralPublicKey(65, uncompressed) + iv(16) + authTag(16) + ciphertext",
    totalHeaderBytes: 1 + 65 + 16 + 16,
  };
}

async function main() {
  const v1Fixture = await generateV1Fixture();
  const v0Fixture = await generateV0Fixture();

  const output = {
    v1: v1Fixture,
    v0: v0Fixture,
  };

  console.log(JSON.stringify(output, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
