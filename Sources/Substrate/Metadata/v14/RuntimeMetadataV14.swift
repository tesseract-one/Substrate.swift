//
//  RuntimeMetadataV14.swift
//  
//
//  Created by Yehor Popovych on 12/29/22.
//

import Foundation
import ScaleCodec

public struct RuntimePalletMetadataV14: ScaleCodec.Codable {
    public let name: String
    public let storage: Optional<RuntimePalletStorageMedatadaV14>
    public let call: Optional<RuntimeType.Id>
    public let event: Optional<RuntimeType.Id>
    public let constants: [RuntimePalletConstantMetadataV14]
    public let error: Optional<RuntimeType.Id>
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

public struct RuntimePalletStorageMedatadaV14: ScaleCodec.Codable {
    public let prefix: String
    public let entries: [RuntimePalletStorageEntryMedatadaV14]
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        prefix = try decoder.decode()
        entries = try decoder.decode()
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        try encoder.encode(prefix)
        try encoder.encode(entries)
    }
}

public enum RuntimePalletStorageEntryTypeV14: ScaleCodec.Codable {
    case plain(_ value: RuntimeType.Id)
    case map(hashers: [StorageHasher], key: RuntimeType.Id, value: RuntimeType.Id)
    
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

public struct RuntimePalletStorageEntryMedatadaV14: ScaleCodec.Codable {
    public let name: String
    public let modifier: StorageEntryModifier
    public let type: RuntimePalletStorageEntryTypeV14
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

public struct RuntimePalletConstantMetadataV14: ScaleCodec.Codable {
    public let name: String
    public let type: RuntimeType.Id
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

public struct RuntimeExtrinsicMetadataV14: ScaleCodec.Codable {
    public let type: RuntimeType.Id
    public let version: UInt8
    public let signedExtensions: [RuntimeExtrinsicSignedExtensionV14]
    
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

public struct RuntimeExtrinsicSignedExtensionV14: ScaleCodec.Codable {
    public let identifier: String
    public let type: RuntimeType.Id
    public let additionalSigned: RuntimeType.Id
    
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

public struct RuntimeMetadataV14: ScaleCodec.Codable, RuntimeMetadata {
    public var version: UInt8 { 14 }
    public let types: RuntimeType.Registry
    public let pallets: [RuntimePalletMetadataV14]
    public let extrinsic: RuntimeExtrinsicMetadataV14
    public let runtimeType: RuntimeType.Id
    
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
        try MetadataV14(runtime: self)
    }
    
    public static var versions: Set<UInt32> { [14] }
}
