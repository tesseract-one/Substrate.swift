//
//  TransactionStatus.swift
//  
//
//  Created by Ostap Danylovych on 30.04.2021.
//

import Foundation
import ScaleCodec

public protocol SomeTransactionStatus<BlockHash>: Swift.Decodable {
    associatedtype BlockHash: Hash
    
    var isFinalized: Bool { get }
    var isFinished: Bool { get }
    var isInBlock: Bool { get }
    var blockHash: BlockHash? { get }
}

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
}

extension TransactionStatus: SomeTransactionStatus {
    public typealias BlockHash = BlockHash
    
    public var isFinalized: Bool {
        switch self {
        case .finalized(_): return true
        default: return false
        }
    }
    
    public var isFinished: Bool {
        switch self {
        case .finalized(_), .finalityTimeout(_), .invalid, .dropped, .usurped(_): return true
        default: return false
        }
    }
    
    public var isInBlock: Bool {
        switch self {
        case .finalized(_), .inBlock(_), .retracted(_): return true
        default: return false
        }
    }
    
    public var blockHash: BlockHash? {
        switch self {
        case .inBlock(let h), .retracted(let h), .finalityTimeout(let h), .finalized(let h): return h
        default: return nil
        }
    }
}

extension TransactionStatus: Swift.Codable {
    public init(from decoder: Swift.Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            switch simple {
            case "future": self = .future
            case "ready": self = .ready
            case "dropped": self = .dropped
            case "invalid": self = .invalid
            default:
                throw Swift.DecodingError.dataCorruptedError(in: container1,
                                                             debugDescription: "Unknown case \(simple)")
            }
            return
        } else {
            let container2 = try decoder.container(keyedBy: CodableComplexKey<CKeyMarker>.self)
            guard let key = container2.allKeys.first else {
                throw Swift.DecodingError.dataCorruptedError(in: container1,
                                                             debugDescription: "Empty case object")
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
                throw Swift.DecodingError.dataCorruptedError(forKey: key, in: container2,
                                                             debugDescription: "Unknow enum case")
            }
        }
    }
    
    public func encode(to encoder: Swift.Encoder) throws {
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
            var container = encoder.container(keyedBy: CodableComplexKey<CKeyMarker>.self)
            try container.encode(body, forKey: .broadcast)
        case .inBlock(let body):
            var container = encoder.container(keyedBy: CodableComplexKey<CKeyMarker>.self)
            try container.encode(body, forKey: .inBlock)
        case .retracted(let body):
            var container = encoder.container(keyedBy: CodableComplexKey<CKeyMarker>.self)
            try container.encode(body, forKey: .retracted)
        case .finalityTimeout(let body):
            var container = encoder.container(keyedBy: CodableComplexKey<CKeyMarker>.self)
            try container.encode(body, forKey: .finalityTimeout)
        case .finalized(let body):
            var container = encoder.container(keyedBy: CodableComplexKey<CKeyMarker>.self)
            try container.encode(body, forKey: .finalized)
        case .usurped(let body):
            var container = encoder.container(keyedBy: CodableComplexKey<CKeyMarker>.self)
            try container.encode(body, forKey: .usurped)
        }
    }
}

private enum CKeyMarker: Equatable {}

private extension CodableComplexKey where T == CKeyMarker {
    static let broadcast = Self(stringValue: "broadcast")!
    static let inBlock = Self(stringValue: "inBlock")!
    static let retracted = Self(stringValue: "retracted")!
    static let finalityTimeout = Self(stringValue: "finalityTimeout")!
    static let finalized = Self(stringValue: "finalized")!
    static let usurped = Self(stringValue: "usurped")!
}
