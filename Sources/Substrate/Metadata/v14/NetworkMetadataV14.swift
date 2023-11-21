//
//  NetworkMetadataV14.swift
//  
//
//  Created by Yehor Popovych on 12/29/22.
//

import Foundation
import ScaleCodec

public extension MetadataV14 {
    struct Network: ScaleCodec.Codable, NetworkMetadata {
        public var version: UInt8 { 14 }
        public let types: NetworkType.Registry
        public let pallets: [Pallet]
        public let extrinsic: Extrinsic
        public let runtimeType: NetworkType.Id
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            types = try decoder.decode()
            pallets = try decoder.decode()
            extrinsic = try decoder.decode()
            runtimeType = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(types)
            try encoder.encode(pallets)
            try encoder.encode(extrinsic)
            try encoder.encode(runtimeType)
        }
        
        public func asMetadata() throws -> Metadata {
            try MetadataV14(network: self)
        }
        
        public static var versions: Set<UInt32> { [14] }
    }
}

public extension MetadataV14.Network {
    struct Pallet: ScaleCodec.Codable {
        public let name: String
        public let storage: Optional<PalletStorage>
        public let call: Optional<NetworkType.Id>
        public let event: Optional<NetworkType.Id>
        public let constants: [PalletConstant]
        public let error: Optional<NetworkType.Id>
        public let index: UInt8
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            storage = try decoder.decode()
            call = try decoder.decode()
            event = try decoder.decode()
            constants = try decoder.decode()
            error = try decoder.decode()
            index = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(storage)
            try encoder.encode(call)
            try encoder.encode(event)
            try encoder.encode(constants)
            try encoder.encode(error)
            try encoder.encode(index)
        }
    }
}

public extension MetadataV14.Network {
    struct PalletStorage: ScaleCodec.Codable {
        public let prefix: String
        public let entries: [PalletStorageEntry]
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            prefix = try decoder.decode()
            entries = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(prefix)
            try encoder.encode(entries)
        }
    }
}

public extension MetadataV14.Network {
    enum PalletStorageEntryType: ScaleCodec.Codable {
        case plain(_ value: NetworkType.Id)
        case map(hashers: [StorageHasher], key: NetworkType.Id, value: NetworkType.Id)
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            let caseId = try decoder.decode(.enumCaseId)
            switch caseId {
            case 0: self = try .plain(decoder.decode())
            case 1:
                self = try .map(hashers: decoder.decode(),
                                key: decoder.decode(),
                                value: decoder.decode())
            default: throw decoder.enumCaseError(for: caseId)
            }
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            switch self {
            case .plain(let ty):
                try encoder.encode(0, .enumCaseId)
                try encoder.encode(ty)
            case .map(hashers: let hashers, key: let key, value: let value):
                try encoder.encode(1, .enumCaseId)
                try encoder.encode(hashers)
                try encoder.encode(key)
                try encoder.encode(value)
            }
        }
    }
}

public extension MetadataV14.Network {
    struct PalletStorageEntry: ScaleCodec.Codable {
        public let name: String
        public let modifier: StorageEntryModifier
        public let type: PalletStorageEntryType
        public let defaultValue: Data
        public let documentation: [String]
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            modifier = try decoder.decode()
            type = try decoder.decode()
            defaultValue = try decoder.decode()
            documentation = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(modifier)
            try encoder.encode(type)
            try encoder.encode(defaultValue)
            try encoder.encode(documentation)
        }
    }
}

public extension MetadataV14.Network {
    enum StorageHasher: CaseIterable, ScaleCodec.Codable, CustomStringConvertible {
        case blake2b128
        case blake2b256
        case blake2b128concat
        case xx128
        case xx256
        case xx64concat
        case identity
        
        public var hasher: Hasher {
            switch self {
            case .blake2b128: return HBlake2b128.instance
            case .blake2b256: return HBlake2b256.instance
            case .blake2b128concat: return HBlake2b128Concat.instance
            case .xx128: return HXX128.instance
            case .xx256: return HXX256.instance
            case .xx64concat: return HXX64Concat.instance
            case .identity: return HIdentity.instance
            }
        }
        
        public var name: String {
            switch self {
            case .blake2b128: return "Blake2_128"
            case .blake2b256: return "Blake2_256"
            case .blake2b128concat: return "Blake2_128Concat"
            case .xx128: return "Twox128"
            case .xx256: return "Twox256"
            case .xx64concat: return "Twox64Concat"
            case .identity: return "Identity"
            }
        }
        
        @inlinable
        public var description: String { name }
    }

    enum StorageEntryModifier: CaseIterable, ScaleCodec.Codable, CustomStringConvertible {
        case optional
        case `default`
        
        public var description: String {
            switch self {
            case .optional: return "Optional"
            case .default: return "Default"
            }
        }
    }
}

public extension MetadataV14.Network {
    struct PalletConstant: ScaleCodec.Codable {
        public let name: String
        public let type: NetworkType.Id
        public let value: Data
        public let documentation: [String]
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            type = try decoder.decode()
            value = try decoder.decode()
            documentation = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(type)
            try encoder.encode(value)
            try encoder.encode(documentation)
        }
    }
}

public extension MetadataV14.Network {
    struct Extrinsic: ScaleCodec.Codable {
        public let type: NetworkType.Id
        public let version: UInt8
        public let signedExtensions: [ExtrinsicSignedExtension]
        
        public init(type: NetworkType.Id, version: UInt8, extensions: [ExtrinsicSignedExtension]) {
            self.type = type
            self.version = version
            self.signedExtensions = extensions
        }
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            type = try decoder.decode()
            version = try decoder.decode()
            signedExtensions = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(type)
            try encoder.encode(version)
            try encoder.encode(signedExtensions)
        }
    }
}

public extension MetadataV14.Network {
    struct ExtrinsicSignedExtension: ScaleCodec.Codable {
        public let identifier: String
        public let type: NetworkType.Id
        public let additionalSigned: NetworkType.Id
        
        public init(identifier: String, type: NetworkType.Id, additionalSigned: NetworkType.Id) {
            self.identifier = identifier
            self.type = type
            self.additionalSigned = additionalSigned
        }
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            identifier = try decoder.decode()
            type = try decoder.decode()
            additionalSigned = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(identifier)
            try encoder.encode(type)
            try encoder.encode(additionalSigned)
        }
    }
}
