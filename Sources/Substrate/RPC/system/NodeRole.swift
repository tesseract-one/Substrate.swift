//
//  NodeRole.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public enum NodeRole: Codable, Equatable {
    case full
    case lightClient
    case authority
    case unknown(UInt8)
    
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            switch simple {
            case "Full": self = .full
            case "LightClient": self = .lightClient
            case "Authority": self = .authority
            default:
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Unknown case \(simple)")
            }
        } else {
            let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
            guard let key = container2.allKeys.first else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
            }
            guard key == .unknown else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
            }
            self = try .unknown(container2.decode(UInt8.self, forKey: key))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .full:
            var container = encoder.singleValueContainer()
            try container.encode("Full")
        case .lightClient:
            var container = encoder.singleValueContainer()
            try container.encode("LightClient")
        case .authority:
            var container = encoder.singleValueContainer()
            try container.encode("Authority")
        case .unknown(let u):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(u, forKey: .unknown)
        }
    }
}

private extension CodableComplexKey where T == NodeRole {
    static let unknown = Self(stringValue: "UnknownRole")!
}
