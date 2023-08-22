//
//  AnyRuntimeVersion.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ContextCodable
import Serializable

public struct AnyRuntimeVersion: RuntimeVersion {
    public typealias TVersion = UInt32
    
    public let specVersion: TVersion
    public let transactionVersion: TVersion
    public let other: [String: SerializableValue]
    
    public init(from decoder: Decoder, context: any Metadata) throws {
        let serializable = try SerializableValue(from: decoder)
        guard var dict = serializable.object else {
            throw DecodingError.typeMismatch(
                SerializableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Value is not an object"))
        }
        let spVersionKey = AnyCodableCodingKey("specVersion")
        let txVersionKey = AnyCodableCodingKey("transactionVersion")
        guard let spVersionValue = dict[spVersionKey.stringValue] else {
            throw DecodingError.keyNotFound(
                spVersionKey,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Empty specVersion"))
        }
        guard let txVersionValue = dict[txVersionKey.stringValue] else {
            throw DecodingError.keyNotFound(
                txVersionKey,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Empty transactionVersion"))
        }
        dict.removeValue(forKey: spVersionKey.stringValue)
        dict.removeValue(forKey: txVersionKey.stringValue)
        guard let spVersion = spVersionValue.int, spVersion <= UInt32.max else {
            throw DecodingError.typeMismatch(
                SerializableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "specVersion is not UInt32")
            )
        }
        guard let txVersion = txVersionValue.int, txVersion <= UInt32.max else {
            throw DecodingError.typeMismatch(
                SerializableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "transactionVersion is not UInt32")
            )
        }
        self.init(specVersion: UInt32(spVersion), transactionVersion: UInt32(txVersion), other: dict)
    }
    
    public init(specVersion: UInt32, transactionVersion: UInt32, other: [String: SerializableValue]) {
        self.specVersion = specVersion
        self.transactionVersion = transactionVersion
        self.other = other
    }
}
