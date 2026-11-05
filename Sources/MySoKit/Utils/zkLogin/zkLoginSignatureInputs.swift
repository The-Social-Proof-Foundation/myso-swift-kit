//
//  zkLoginSignatureInputs.swift
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

import Foundation

/// Represents the inputs for a zkLogin signature
public struct zkLoginSignatureInputs: KeyProtocol, Equatable, Codable {
    public var proofPoints: zkLoginSignatureInputsProofPoints
    public var issBase64Details: zkLoginSignatureInputsClaim
    public var headerBase64: String
    /// Decimal address seed. The chain BCS-encodes this as a string.
    public var addressSeed: String

    public init(
        proofPoints: zkLoginSignatureInputsProofPoints,
        issBase64Details: zkLoginSignatureInputsClaim,
        headerBase64: String,
        addressSeed: String
    ) {
        self.proofPoints = proofPoints
        self.issBase64Details = issBase64Details
        self.headerBase64 = headerBase64
        self.addressSeed = addressSeed
    }

    public func serialize(_ serializer: Serializer) throws {
        try Serializer._struct(serializer, value: self.proofPoints)
        try Serializer._struct(serializer, value: self.issBase64Details)
        try Serializer.str(serializer, self.headerBase64)
        try Serializer.str(serializer, self.addressSeed)
    }

    public static func deserialize(from deserializer: Deserializer) throws -> zkLoginSignatureInputs {
        let proofPoints = try zkLoginSignatureInputsProofPoints.deserialize(from: deserializer)
        let issBase64Details = try zkLoginSignatureInputsClaim.deserialize(from: deserializer)
        let headerBase64 = try Deserializer.string(deserializer)
        let addressSeed = try Deserializer.string(deserializer)
        
        return zkLoginSignatureInputs(
            proofPoints: proofPoints,
            issBase64Details: issBase64Details,
            headerBase64: headerBase64,
            addressSeed: addressSeed
        )
    }
}
