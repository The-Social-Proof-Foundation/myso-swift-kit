import MyDataCrypto
import XCTest

final class MessageAADTests: XCTestCase {
	/// Same vector as TS `attachments-manager.test.ts` "parity vector for iOS".
	func testAttachmentAADMatchesTypeScriptVector() throws {
		let aad = try MessagingAttachmentAAD.build(
			groupIdHex: "0x" + String(repeating: "ab", count: 32),
			keyVersion: 3,
			senderAddressHex: "0x" + String(repeating: "cd", count: 32),
			role: .meta
		)
		let expected = String(repeating: "ab", count: 32)
			+ "0300000000000000"
			+ String(repeating: "cd", count: 32)
			+ Data("myso-attachment-v1:meta".utf8).map { String(format: "%02x", $0) }.joined()
		XCTAssertEqual(aad.map { String(format: "%02x", $0) }.joined(), expected)
	}

	func testAttachmentAADRolesDiffer() throws {
		let g = Data(repeating: 1, count: 32)
		let s = Data(repeating: 2, count: 32)
		let data = try MessagingAttachmentAAD.build(groupId: g, keyVersion: 0, senderAddress: s, role: .data)
		let meta = try MessagingAttachmentAAD.build(groupId: g, keyVersion: 0, senderAddress: s, role: .meta)
		XCTAssertNotEqual(data, meta)
	}

	func testAADLayoutMatchesMessagingSpec() throws {
		let groupId = Data(repeating: 0xAB, count: 32)
		let sender = Data(repeating: 0xCD, count: 32)
		let aad = try MessagingMessageAAD.build(groupId: groupId, keyVersion: 1, senderAddress: sender)
		XCTAssertEqual(aad.count, 72)
		XCTAssertEqual(Data(aad.prefix(32)), groupId)
		XCTAssertEqual(Data(aad.suffix(32)), sender)
		// keyVersion 1 as little-endian u64
		XCTAssertEqual(Array(aad[32..<40]), [1, 0, 0, 0, 0, 0, 0, 0])
	}

	func testEnvelopeEncryptDecryptRoundTripWithAAD() throws {
		let dek = Data((0..<32).map { UInt8($0) })
		let nonce = Data((0..<12).map { UInt8($0 &+ 10) })
		let aad = try MessagingMessageAAD.build(
			groupId: Data(repeating: 1, count: 32),
			keyVersion: 0,
			senderAddress: Data(repeating: 2, count: 32)
		)
		let plain = Data("hello messaging".utf8)
		let cipher = try MessagingEnvelopeEncrypt.encrypt(
			dek: dek,
			plaintext: plain,
			nonce: nonce,
			aad: aad
		)
		let opened = try MessagingEnvelopeDecrypt.decrypt(
			dek: dek,
			ciphertext: cipher,
			nonce: nonce,
			aad: aad
		)
		XCTAssertEqual(opened, plain)
	}

	func testEnvelopeEncryptDecryptRoundTripWithoutAAD() throws {
		let dek = Data((0..<32).map { UInt8($0 &+ 3) })
		let nonce = Data((0..<12).map { UInt8($0 &+ 40) })
		let plain = Data("attachment-bytes".utf8)
		let cipher = try MessagingEnvelopeEncrypt.encrypt(
			dek: dek,
			plaintext: plain,
			nonce: nonce,
			aad: nil
		)
		let opened = try MessagingEnvelopeDecrypt.decrypt(
			dek: dek,
			ciphertext: cipher,
			nonce: nonce,
			aad: nil
		)
		XCTAssertEqual(opened, plain)
	}
}
