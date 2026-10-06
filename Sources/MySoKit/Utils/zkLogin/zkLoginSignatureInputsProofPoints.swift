//
//  zkLoginSignatureInputsProofPoints.swift
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

/// Groth16 proof points. The chain BCS-encodes each limb as a decimal string, not raw field bytes.
public struct zkLoginSignatureInputsProofPoints: KeyProtocol, Equatable, Codable {
    public var a: [String]
    public var b: [[String]]
    public var c: [String]

    public init(
        a: [String],
        b: [[String]],
        c: [String]
    ) {
        self.a = a
        self.b = b
        self.c = c
    }

    public func serialize(_ serializer: Serializer) throws {
        try Serializer.str(serializer, self.a)
        try serializer.uleb128(UInt(self.b.count))
        for pair in self.b {
            try Serializer.str(serializer, pair)
        }
        try Serializer.str(serializer, self.c)
    }

    public static func deserialize(from deserializer: Deserializer) throws -> zkLoginSignatureInputsProofPoints {
        let aCount = try deserializer.uleb128()
        var a: [String] = []
        for _ in 0..<Int(aCount) {
            a.append(try Deserializer.string(deserializer))
        }

        let bCount = try deserializer.uleb128()
        var b: [[String]] = []
        for _ in 0..<Int(bCount) {
            let innerCount = try deserializer.uleb128()
            var pair: [String] = []
            for _ in 0..<Int(innerCount) {
                pair.append(try Deserializer.string(deserializer))
            }
            b.append(pair)
        }

        let cCount = try deserializer.uleb128()
        var c: [String] = []
        for _ in 0..<Int(cCount) {
            c.append(try Deserializer.string(deserializer))
        }

        return zkLoginSignatureInputsProofPoints(a: a, b: b, c: c)
    }
}
