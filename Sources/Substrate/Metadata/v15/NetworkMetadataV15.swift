//
//  NetworkMetadataV15.swift
//  
//
//  Created by Yehor Popovych on 24.04.2023
//

import Foundation
import ScaleCodec

public extension MetadataV15 {
    struct Network: ScaleCodec.Codable, NetworkMetadata {
        public var version: UInt8 { 15 }
        public let types: NetworkType.Registry
        public let pallets: [Pallet]
        public let extrinsic: Extrinsic
        public let runtimeType: NetworkType.Id
        public let apis: [RuntimeApi]
        public let outerEnums: OuterEnums?
        public let custom: Dictionary<String, (NetworkType.Id, Data)>?
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            types = try decoder.decode()
            pallets = try decoder.decode()
            extrinsic = try decoder.decode()
            runtimeType = try decoder.decode()
            apis = try decoder.decode()
            guard decoder.length > 0 else {
                self.outerEnums = nil
                self.custom = nil
                return
            }
            outerEnums = try decoder.decode()
            custom = try Dictionary(from: &decoder, lreader: { try $0.decode() }) { try ($0.decode(), $0.decode()) }
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(types)
            try encoder.encode(pallets)
            try encoder.encode(extrinsic)
            try encoder.encode(runtimeType)
            try encoder.encode(apis)
            if let enums = outerEnums, let custom = self.custom {
                try encoder.encode(enums)
                try custom.encode(in: &encoder, lwriter: { try $1.encode($0) }) { tuple, encoder in
                    try encoder.encode(tuple.0)
                    try encoder.encode(tuple.1)
                }
            }
        }
        
        public func asMetadata() throws -> Metadata {
            try MetadataV15(network: self)
        }
        
        public static var versions: Set<UInt32> { [15, UInt32.max] }
    }
}

public extension MetadataV15.Network {
    typealias Extrinsic = MetadataV14.Network.Extrinsic
    typealias PalletStorage = MetadataV14.Network.PalletStorage
    typealias PalletConstant = MetadataV14.Network.PalletConstant
    typealias StorageHasher = MetadataV14.Network.StorageHasher
    typealias StorageEntryModifier = MetadataV14.Network.StorageEntryModifier
    
    struct Pallet: ScaleCodec.Codable {
        public let name: String
        public let storage: Optional<PalletStorage>
        public let call: Optional<NetworkType.Id>
        public let event: Optional<NetworkType.Id>
        public let constants: [PalletConstant]
        public let error: Optional<NetworkType.Id>
        public let index: UInt8
        public let docs: [String]
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            storage = try decoder.decode()
            call = try decoder.decode()
            event = try decoder.decode()
            constants = try decoder.decode()
            error = try decoder.decode()
            index = try decoder.decode()
            docs = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(storage)
            try encoder.encode(call)
            try encoder.encode(event)
            try encoder.encode(constants)
            try encoder.encode(error)
            try encoder.encode(index)
            try encoder.encode(docs)
        }
    }
}

public extension MetadataV15.Network {
    struct RuntimeApi: ScaleCodec.Codable {
        public let name: String
        public let methods: [RuntimeApiMethod]
        public let docs: [String]
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            methods = try decoder.decode()
            docs = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(methods)
            try encoder.encode(docs)
        }
    }
}

public extension MetadataV15.Network {
    struct RuntimeApiMethod: ScaleCodec.Codable {
        public let name: String
        public let inputs: [RuntimeApiMethodParam]
        public let output: NetworkType.Id
        public let docs: [String]
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            inputs = try decoder.decode()
            output = try decoder.decode()
            docs = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(inputs)
            try encoder.encode(output)
            try encoder.encode(docs)
        }
    }
}

public extension MetadataV15.Network {
    struct RuntimeApiMethodParam: ScaleCodec.Codable {
        public let name: String
        public let type: NetworkType.Id
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            type = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(type)
        }
    }
}

public extension MetadataV15.Network {
    struct OuterEnums: ScaleCodec.Codable {
        /// The type of the outer `RuntimeCall` enum.
        public let callEnumType: NetworkType.Id
        /// The type of the outer `RuntimeEvent` enum.
        public let eventEnumType: NetworkType.Id
        /// The module error type of the
        /// [`DispatchError::Module`](https://docs.rs/sp-runtime/24.0.0/sp_runtime/enum.DispatchError.html#variant.Module) variant.
        ///
        /// The `Module` variant will be 5 scale encoded bytes which are normally decoded into
        /// an `{ index: u8, error: [u8; 4] }` struct. This type ID points to an enum type which instead
        /// interprets the first `index` byte as a pallet variant, and the remaining `error` bytes as the
        /// appropriate `pallet::Error` type. It is an equally valid way to decode the error bytes, and
        /// can be more informative.
        ///
        /// # Note
        ///
        /// - This type cannot be used directly to decode `sp_runtime::DispatchError` from the
        ///   chain. It provides just the information needed to decode `sp_runtime::DispatchError::Module`.
        /// - Decoding the 5 error bytes into this type will not always lead to all of the bytes being consumed;
        ///   many error types do not require all of the bytes to represent them fully.
        public let moduleErrorEnumType: NetworkType.Id
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            callEnumType = try decoder.decode()
            eventEnumType = try decoder.decode()
            moduleErrorEnumType = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(callEnumType)
            try encoder.encode(eventEnumType)
            try encoder.encode(moduleErrorEnumType)
        }
    }
}
