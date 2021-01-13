//
//  Digest.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct Digest<Hash: ScaleFixedData>: ScaleDynamicCodable {
    public let logs: Array<Hash>
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        logs = try Array<Hash>(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try logs.encode(in: encoder, registry: registry)
    }
}

public enum DigestItem<Hash: ScaleDynamicCodable>: ScaleDynamicCodable {
    case changesTrieRoot(Hash)
    case preRuntime(ConsensusEngineId, Data)
    case consensus(ConsensusEngineId, Data)
    case seal(ConsensusEngineId, Data)
    case changesTrieSignal(ChangesTrieSignal)
    case other(Data)
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let id = try decoder.decode(.enumCaseId)
        switch id {
        case 0: self = try .changesTrieRoot(Hash(from: decoder, registry: registry))
        case 1: self = try .preRuntime(decoder.decode(), decoder.decode())
        case 2: self = try .consensus(decoder.decode(), decoder.decode())
        case 3: self = try .seal(decoder.decode(), decoder.decode())
        case 4: self = try .changesTrieSignal(decoder.decode())
        case 5: self = try .other(decoder.decode())
        default: throw decoder.enumCaseError(for: id)
        }
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        switch self {
        case .changesTrieRoot(let hash): try hash.encode(in: encoder.encode(0, .enumCaseId), registry: registry)
        case .preRuntime(let id, let d): try encoder.encode(1, .enumCaseId).encode(id).encode(d)
        case .consensus(let id, let d): try encoder.encode(2, .enumCaseId).encode(id).encode(d)
        case .seal(let id, let d): try encoder.encode(3, .enumCaseId).encode(id).encode(d)
        case .changesTrieSignal(let signal): try encoder.encode(4, .enumCaseId).encode(signal)
        case .other(let d): try encoder.encode(5, .enumCaseId).encode(d)
        }
    }
}

public enum ChangesTrieSignal: ScaleCodable, ScaleDynamicCodable {
    case newConfiguration(ChangesTrieConfiguration?)
    
    public init(from decoder: ScaleDecoder) throws {
        let id = try decoder.decode(.enumCaseId)
        switch id {
        case 0: self = try .newConfiguration(decoder.decode())
        default: throw decoder.enumCaseError(for: id)
        }
    }
       
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .newConfiguration(let config): try encoder.encode(0, .enumCaseId).encode(config)
        }
    }
}

public struct ChangesTrieConfiguration: ScaleCodable, ScaleDynamicCodable {
    public let digestInterval: UInt32
    public let digestLevels: UInt32
    
    public init(from decoder: ScaleDecoder) throws {
        digestInterval = try decoder.decode()
        digestLevels = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(digestInterval).encode(digestLevels)
    }
}

public struct ConsensusEngineId: ScaleFixedData, ScaleDynamicCodable, Hashable, Equatable {
    public static var fixedBytesCount: Int = 4
    public let id: [UInt8]
    
    public init(decoding data: Data) throws {
        id = Array(data)
    }
    
    public func encode() throws -> Data {
        return Data(id)
    }
}





