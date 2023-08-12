//
//  SystemProperties.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ContextCodable
import Serializable

public protocol SystemProperties: ContextDecodable where DecodingContext == (any Metadata) {
    var ss58Format: SS58.AddressFormat? { get }
}

public struct AnySystemProperties: SystemProperties {
    /// The address format
    public let ss58Format: SS58.AddressFormat?
    /// Other properties
    public let other: [String: SerializableValue]
    
    public init(from decoder: Decoder, context: any Metadata) throws {
        let serializable = try SerializableValue(from: decoder)
        guard var dict = serializable.object else {
            throw DecodingError.typeMismatch(
                SerializableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Value is not an object"))
        }
        var format: SS58.AddressFormat? = nil
        let ss58Key = AnyCodableCodingKey("ss58Format")
        if let ss58Value = dict[ss58Key.stringValue] {
            dict.removeValue(forKey: ss58Key.stringValue)
            guard let ss58Raw = ss58Value.int, ss58Raw <= UInt16.max else {
                throw DecodingError.typeMismatch(
                    SerializableValue.self,
                    DecodingError.Context(codingPath: decoder.codingPath,
                                          debugDescription: "\(ss58Key.stringValue) is not UInt16")
                )
            }
            guard let fmt = SS58.AddressFormat(rawValue: UInt16(ss58Raw)) else {
                throw DecodingError.typeMismatch(
                    SerializableValue.self,
                    DecodingError.Context(codingPath: decoder.codingPath,
                                          debugDescription: "Bad SS58.AddressFormat value \(ss58Raw)")
                )
            }
            format = fmt
        }
        self.init(ss58Format: format, other: dict)
    }
    
    public init(ss58Format: SS58.AddressFormat?, other: [String: SerializableValue]) {
        self.ss58Format = ss58Format
        self.other = other
    }
}
