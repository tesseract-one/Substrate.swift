//
//  SubstrateBlock.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec
import Tuples

public typealias ConsensusEnngineId = Tuple4<UInt8, UInt8, UInt8, UInt8>

public struct SubstrateBlock<H: StaticFixedHasher,
                             N: UnsignedInteger & DataConvertible & Swift.Decodable & ScaleCodec.Encodable,
                             E: OpaqueExtrinsic>: StaticBlock
{
    public typealias THeader = Header
    public typealias TExtrinsic = E
    
    public let header: THeader
    public let extrinsics: [TExtrinsic]
    
    enum CodingKeys: CodingKey {
        case header
        case extrinsics
    }
    
    public init(from decoder: Swift.Decoder, runtime: Runtime) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        header = try container.decode(THeader.self, forKey: .header, context: .init(runtime: runtime))
        extrinsics = try container.decode([TExtrinsic].self, forKey: .extrinsics, context: .init(runtime: runtime))
    }
}

public extension SubstrateBlock {
    struct Header: SomeBlockHeader, RuntimeSwiftDecodable, RuntimeEncodable {
        public typealias TNumber = N
        public typealias THasher = H
        
        public let number: TNumber
        public let parentHash: THasher.THash
        public let stateRoot: THasher.THash
        public let extrinsicRoot: THasher.THash
        public let digest: Digest
        
        private var _runtime: any Runtime
        
        enum CodingKeys: CodingKey {
            case number
            case parentHash
            case stateRoot
            case extrinsicRoot
            case digest
        }
        
        public init(from decoder: Swift.Decoder, runtime: Runtime) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            _runtime = runtime
            number = try container.decode(HexOrNumber<TNumber>.self, forKey: .number).value
            parentHash = try container.decode(THasher.THash.self, forKey: .parentHash)
            stateRoot = try container.decode(THasher.THash.self, forKey: .stateRoot)
            extrinsicRoot = try container.decode(THasher.THash.self, forKey: .extrinsicRoot)
            digest = try container.decode(Digest.self, forKey: .digest, context: .init(runtime: runtime))
        }
        
        public var hash: THasher.THash {
            let data = try! _runtime.encode(value: self)
            return try! _runtime.hash(type: THasher.THash.self, data: data)
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
            try encoder.encode(number)
            try encoder.encode(parentHash)
            try encoder.encode(stateRoot)
            try encoder.encode(extrinsicRoot)
            try encoder.encode(digest)
        }
    }
}

public extension SubstrateBlock.Header {
    struct Digest: RuntimeSwiftDecodable, ScaleCodec.Encodable {
        public let logs: [DigestItem]
        
        enum CodingKeys: CodingKey {
            case logs
        }
        
        public init(from decoder: Swift.Decoder, runtime: any Runtime) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let logs = try container.decode([Data].self, forKey: .logs)
            self.logs = try logs.map { try runtime.decode(from: $0) }
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(logs)
        }
    }
    
    enum DigestItem: ScaleCodec.Codable, RuntimeCodable {
        public enum ItemType: UInt32 {
            case other = 0
            case consensus = 4
            case seal = 5
            case preRuntime = 6
            case runtimeEnvironmentUpdated = 8
        }
        
        case preRuntime(ConsensusEnngineId, Data)
        case consensus(ConsensusEnngineId, Data)
        case seal(ConsensusEnngineId, Data)
        case other(Data)
        case runtimeEnvironmentUpdated
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            let caseId = try decoder.decode(UInt32.self)
            guard let type = ItemType(rawValue: caseId) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        path: decoder.path,
                        description: "Wrong case index: \(caseId)"
                    )
                )
            }
            switch type {
            case .preRuntime: self = try .preRuntime(decoder.decode(), decoder.decode())
            case .consensus: self = try .consensus(decoder.decode(), decoder.decode())
            case .seal: self = try .seal(decoder.decode(), decoder.decode())
            case .other: self = try .other(decoder.decode())
            case .runtimeEnvironmentUpdated: self = .runtimeEnvironmentUpdated
            }
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            switch self {
            case .preRuntime(let id, let val):
                try encoder.encode(ItemType.preRuntime.rawValue)
                try encoder.encode(id)
                try encoder.encode(val)
            case .consensus(let id, let val):
                try encoder.encode(ItemType.consensus.rawValue)
                try encoder.encode(id)
                try encoder.encode(val)
            case .seal(let id, let val):
                try encoder.encode(ItemType.seal.rawValue)
                try encoder.encode(id)
                try encoder.encode(val)
            case .other(let val):
                try encoder.encode(ItemType.other.rawValue)
                try encoder.encode(val)
            case .runtimeEnvironmentUpdated:
                try encoder.encode(ItemType.runtimeEnvironmentUpdated.rawValue)
            }
        }
    }
}