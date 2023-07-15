//
//  SystemProperties.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import Serializable

public protocol SystemProperties: Decodable {
    var ss58Format: SS58.AddressFormat { get }
}

public struct AnySystemProperties: SystemProperties {
    /// The address format
    public let ss58Format: SS58.AddressFormat
    /// Other properties
    public let other: [String: SerializableValue]
    
    public init(from decoder: Decoder) throws {
        let serializable = try SerializableValue(from: decoder)
        guard var dict = serializable.object else {
            throw DecodingError.typeMismatch(
                SerializableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Value is not an object"))
        }
        let ss58Key = AnyCodableCodingKey("ss58Format")
        guard let ss58Value = dict[ss58Key.stringValue] else {
            throw DecodingError.keyNotFound(
                ss58Key,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Empty ss58Format"))
        }
        dict.removeValue(forKey: ss58Key.stringValue)
        guard let ss58Raw = ss58Value.int, ss58Raw <= UInt16.max else {
            throw DecodingError.typeMismatch(
                SerializableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "specVersion is not UInt16")
            )
        }
        guard let format = SS58.AddressFormat(rawValue: UInt16(ss58Raw)) else {
            throw DecodingError.typeMismatch(
                SerializableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Bad SS58.AddressFormat value \(ss58Raw)")
            )
        }
        self.init(ss58Format: format, other: dict)
    }
    
    public init(ss58Format: SS58.AddressFormat, other: [String: SerializableValue]) {
        self.ss58Format = ss58Format
        self.other = other
    }
}
