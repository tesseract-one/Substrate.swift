//
//  AnySystemProperties.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ContextCodable
import Serializable

public struct AnySystemProperties: SystemProperties {
    /// The address format
    public let ss58Format: SS58.AddressFormat?
    /// Other properties
    public let other: [String: SerializableValue]
    
    public init(from decoder: Decoder, context: any Metadata) throws {
        let container = try decoder.container(keyedBy: AnyCodableCodingKey.self)
        let ss58Key = AnyCodableCodingKey("ss58Format")
        let ss58 = try container.decodeIfPresent(UInt16.self, forKey: ss58Key)
        var format: SS58.AddressFormat? = nil
        
        if let ss58 = ss58 {
            guard let fmt = SS58.AddressFormat(rawValue: ss58) else {
                throw DecodingError.dataCorruptedError(
                    forKey: ss58Key, in: container,
                    debugDescription: "Bad SS58.AddressFormat value \(ss58)"
                )
            }
            format = fmt
        }
        
        let otherKeys = container.allKeys.filter { $0 != ss58Key }
        var other: [String: SerializableValue] = [:]
        other.reserveCapacity(otherKeys.count)
        for key in otherKeys {
            other[key.stringValue] = try container.decode(SerializableValue.self,
                                                          forKey: key)
        }
        
        self.init(ss58Format: format, other: other)
    }
    
    public init(ss58Format: SS58.AddressFormat?, other: [String: SerializableValue]) {
        self.ss58Format = ss58Format
        self.other = other
    }
}
