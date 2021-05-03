//
//  TransactionStatus.swift
//  
//
//  Created by Ostap Danylovych on 30.04.2021.
//

import Foundation

public enum TransactionStatus<H: Hash, BlockHash: Hash> {
    case future
    case ready
    case broadcast([String])
    case inBlock(BlockHash)
    case retracted(BlockHash)
    case finalityTimeout(BlockHash)
    case finalized(BlockHash)
    case usurped(H)
    case dropped
    case invalid
    
    fileprivate enum ComplexKey: String, CodingKey {
        case broadcast = "broadcast"
        case inBlock = "inBlock"
        case retracted = "retracted"
        case finalityTimeout = "finalityTimeout"
        case finalized = "finalized"
        case usurped = "usurped"
    }
}

extension TransactionStatus: Codable {
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            switch simple {
            case "future": self = .future
            case "ready": self = .ready
            case "dropped": self = .dropped
            case "invalid": self = .invalid
            default:
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Unknown case \(simple)")
            }
            return
        } else {
            let container2 = try decoder.container(keyedBy: ComplexKey.self)
            guard let key = container2.allKeys.first else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
            }
            switch key {
            case .broadcast:
                self = try .broadcast(container2.decode([String].self, forKey: key))
            case .inBlock:
                self = try .inBlock(container2.decode(BlockHash.self, forKey: key))
            case .retracted:
                self = try .retracted(container2.decode(BlockHash.self, forKey: key))
            case .finalityTimeout:
                self = try .finalityTimeout(container2.decode(BlockHash.self, forKey: key))
            case .finalized:
                self = try .finalized(container2.decode(BlockHash.self, forKey: key))
            case .usurped:
                self = try .usurped(container2.decode(H.self, forKey: key))
            default:
                throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .future:
            var container = encoder.singleValueContainer()
            try container.encode("future")
        case .ready:
            var container = encoder.singleValueContainer()
            try container.encode("ready")
        case .dropped:
            var container = encoder.singleValueContainer()
            try container.encode("dropped")
        case .invalid:
            var container = encoder.singleValueContainer()
            try container.encode("invalid")
        case .broadcast(let body):
            var container = encoder.container(keyedBy: ComplexKey.self)
            try container.encode(body, forKey: .broadcast)
        case .inBlock(let body):
            var container = encoder.container(keyedBy: ComplexKey.self)
            try container.encode(body, forKey: .inBlock)
        case .retracted(let body):
            var container = encoder.container(keyedBy: ComplexKey.self)
            try container.encode(body, forKey: .retracted)
        case .finalityTimeout(let body):
            var container = encoder.container(keyedBy: ComplexKey.self)
            try container.encode(body, forKey: .finalityTimeout)
        case .finalized(let body):
            var container = encoder.container(keyedBy: ComplexKey.self)
            try container.encode(body, forKey: .finalized)
        case .usurped(let body):
            var container = encoder.container(keyedBy: ComplexKey.self)
            try container.encode(body, forKey: .usurped)
        }
    }
}
