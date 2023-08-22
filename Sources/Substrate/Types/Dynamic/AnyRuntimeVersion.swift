//
//  AnyRuntimeVersion.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import ContextCodable
import Serializable

public struct AnyRuntimeVersion<V: ConfigUnsignedInteger>: RuntimeVersion {
    public typealias TVersion = V
    
    public let specVersion: TVersion
    public let transactionVersion: TVersion
    public let other: [String: SerializableValue]
    
    public init(from decoder: Swift.Decoder, context: any Metadata) throws {
        let container = try decoder.container(keyedBy: AnyCodableCodingKey.self)
        let spVersionKey = AnyCodableCodingKey("specVersion")
        let txVersionKey = AnyCodableCodingKey("transactionVersion")
        let spVersion = try container.decode(HexOrNumber<TVersion>.self,
                                             forKey: spVersionKey)
        let txVersion = try container.decode(HexOrNumber<TVersion>.self,
                                             forKey: txVersionKey)
        let otherKeys = container.allKeys.filter { $0 != spVersionKey && $0 != txVersionKey }
        var other: [String: SerializableValue] = [:]
        other.reserveCapacity(otherKeys.count)
        for key in otherKeys {
            other[key.stringValue] = try container.decode(SerializableValue.self,
                                                          forKey: key)
        }
        self.init(specVersion: spVersion.value, transactionVersion: txVersion.value, other: other)
    }
    
    public init(specVersion: TVersion, transactionVersion: TVersion, other: [String: SerializableValue]) {
        self.specVersion = specVersion
        self.transactionVersion = transactionVersion
        self.other = other
    }
}
