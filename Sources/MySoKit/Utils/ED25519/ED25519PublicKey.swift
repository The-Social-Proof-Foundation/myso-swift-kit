//
//  ED25519PublicKey.swift
//  MySoKit
//
//  Copyright (c) 2025 The Social Proof Foundation, LLC.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import CryptoKit
import Foundation
import Blake2

/// Represents a public key used in the ED25519 signature scheme.
public struct ED25519PublicKey: Equatable, PublicKeyProtocol {
    public typealias DataValue = Data

    /// The length of the public key.
    public static let LENGTH: Int = 32

    public var key: DataValue

    public init(data: Data) throws {
        guard data.count == ED25519PublicKey.LENGTH else {
            throw AccountError.invalidPublicKey
        }
        self.key = data
    }

    public init(hexString: String) throws {
        var hexValue = hexString
        if hexString.hasPrefix("0x") {
            hexValue = String(hexString.dropFirst(2))
        }
        guard Data(hex: hexValue).count == ED25519PublicKey.LENGTH else {
            throw AccountError.invalidPublicKey
        }
        self.key = Data(hex: hexValue)
    }

    public init(value: String) throws {
        guard let result = Data.fromBase64(value) else { throw AccountError.invalidData }
        guard result.count == ED25519PublicKey.LENGTH else {
            throw AccountError.invalidPublicKey
        }
        self.key = result
    }

    public static func == (lhs: ED25519PublicKey, rhs: ED25519PublicKey) -> Bool {
        return lhs.key == rhs.key
    }

    public var description: String {
        return self.hex()
    }

    public func base64() -> String {
        return key.base64EncodedString()
    }

    public func hex() -> String {
        return "0x\(self.key.hexEncodedString())"
    }

    /// RFC 8032 public key for a 32-byte seed via CryptoKit (kept here: the private-key file
    /// imports CryptoSwift, whose `HMAC` clashes with CryptoKit's).
    static func derived(fromSeed seed: Data) -> ED25519PublicKey? {
        guard let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: seed) else { return nil }
        return try? ED25519PublicKey(data: key.publicKey.rawRepresentation)
    }

    /// CryptoKit (BoringSSL) Ed25519 signature for a 32-byte seed. Valid RFC 8032 (verifies
    /// anywhere), orders of magnitude faster than the pure-Swift port, which also re-derives the
    /// public key on every sign. CryptoKit randomizes the nonce, so bytes differ per call; nothing
    /// may rely on signatures being deterministic.
    static func cryptoKitSignature(seed: Data, message: Data) -> Data? {
        guard seed.count == 32,
              let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: seed),
              let signature = try? key.signature(for: message)
        else { return nil }
        return signature
    }

    /// CryptoKit (BoringSSL) verify — same RFC 8032 result as the pure-Swift ed25519swift
    /// port, but orders of magnitude faster (that port dominated chat-open CPU in Instruments).
    public func verify(data: Data, signature: Signature) throws -> Bool {
        guard signature.signature.count == 64,
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: self.key)
        else { return false }
        return key.isValidSignature(signature.signature, for: data)
    }

    public func toMySoAddress() throws -> String {
        var tmp = Data(count: ED25519PublicKey.LENGTH + 1)
        try tmp.set([SignatureSchemeFlags.SIGNATURE_SCHEME_TO_FLAG["ED25519"]!])
        try tmp.set([UInt8](self.key), offset: 1)
        let result = try Inputs.normalizeMySoAddress(
            value: try Blake2b.hash(size: 32, data: tmp).hexEncodedString()[0..<ED25519PublicKey.LENGTH * 2]
        )
        return result
    }

    /// Converts the public key to a MySo address.
    /// - Throws: If any error occurs during conversion.
    /// - Returns: A string representing the MySo address.
    public func toMySoPublicKey() throws -> String {
        let bytes = try self.toMySoBytes()
        return bytes.toBase64()
    }

    /// Converts the public key to MySo bytes.
    /// - Throws: If any error occurs during conversion.
    /// - Returns: An array of bytes representing the MySo public key.
    public func toMySoBytes() throws -> [UInt8] {
        let rawBytes = self.key
        var mysoBytes = Data(count: rawBytes.count + 1)
        try mysoBytes.set([SignatureSchemeFlags.SIGNATURE_SCHEME_TO_FLAG["ED25519"]!])
        try mysoBytes.set([UInt8](rawBytes), offset: 1)

        return [UInt8](mysoBytes)
    }

    public func toSerializedSignature(signature: Signature) throws -> String {
        // Wire format: flag (1) || signature || pubkey
        var serializedSignature = Data()
        serializedSignature.append(SignatureSchemeFlags.SIGNATURE_SCHEME_TO_FLAG["ED25519"]!)
        serializedSignature.append(signature.signature)
        serializedSignature.append(self.key)
        return serializedSignature.base64EncodedString()
    }

    public func verifyTransactionBlock(_ transactionBlock: [UInt8], _ signature: Signature) throws -> Bool {
        return try self.verifyWithIntent(transactionBlock, signature, .TransactionData)
    }

    public func verifyWithIntent(_ bytes: [UInt8], _ signature: Signature, _ intent: IntentScope) throws -> Bool {
        let intentMessage = RawSigner.messageWithIntent(intent, Data(bytes))
        let digest = try Blake2b.hash(size: 32, data: intentMessage)

        return try self.verify(data: digest, signature: signature)
    }

    public func verifyPersonalMessage(_ message: [UInt8], _ signature: Signature) throws -> Bool {
        let ser = Serializer()
        try ser.sequence(message, Serializer.u8)
        return try self.verifyWithIntent([UInt8](ser.output()), signature, .PersonalMessage)
    }

    public static func deserialize(from deserializer: Deserializer) throws -> ED25519PublicKey {
        let key = try Deserializer.toBytes(deserializer)
        if key.count != ED25519PublicKey.LENGTH {
            throw AccountError.lengthMismatch
        }
        return try ED25519PublicKey(data: key)
    }

    public func serialize(_ serializer: Serializer) throws {
        try Serializer.toBytes(serializer, self.key)
    }
}
