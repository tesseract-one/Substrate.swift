//
//  RuntimeMetadataV15.swift
//  
//
//  Created by Yehor Popovych on 24.04.2023
//

import Foundation
import ScaleCodec

public struct RuntimePalletMetadataV15: ScaleCodable {
    public let name: String
    public let storage: Optional<RuntimePalletStorageMedatadaV14>
    public let call: Optional<RuntimeTypeId>
    public let event: Optional<RuntimeTypeId>
    public let constants: [RuntimePalletConstantMetadataV14]
    public let error: Optional<RuntimeTypeId>
    public let index: UInt8
    public let docs: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        storage = try decoder.decode()
        call = try decoder.decode()
        event = try decoder.decode()
        constants = try decoder.decode()
        error = try decoder.decode()
        index = try decoder.decode()
        docs = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name)
            .encode(storage)
            .encode(call)
            .encode(event)
            .encode(constants)
            .encode(error)
            .encode(index)
            .encode(docs)
    }
}

public struct RuntimeMetadataV15: ScaleCodable, RuntimeMetadata {
    public var version: UInt8 { 14 }
    public let types: [RuntimeTypeInfo]
    public let pallets: [RuntimePalletMetadataV15]
    public let extrinsic: RuntimeExtrinsicMetadataV14
    public let runtimeType: RuntimeTypeId
    public let apis: [RuntimeRuntimeApiMetadataV15]
//    public let outerEnums: RuntimeMetadataOuterEnumsV15
//    public let custom: Dictionary<String, (RuntimeTypeId, Data)>
    
    public init(from decoder: ScaleDecoder) throws {
        types = try decoder.decode()
        pallets = try decoder.decode()
        extrinsic = try decoder.decode()
        runtimeType = try decoder.decode()
        apis = try decoder.decode()
        
        //outerEnums = try decoder.decode()
        //custom = try Dictionary(from: decoder, lreader: { try $0.decode() }) { try ($0.decode(), $0.decode()) }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(types).encode(pallets)
            .encode(extrinsic).encode(runtimeType).encode(apis)
            //.encode(outerEnums)
//        try custom.encode(in: encoder, lwriter: { try $1.encode($0) }) { tuple, encoder in
//            try encoder.encode(tuple.0).encode(tuple.1)
//        }
    }
    
    public func asMetadata() throws -> Metadata {
        try MetadataV15(runtime: self)
    }
    
    public static var versions: Set<UInt32> { [15, UInt32.max] }
}

public struct RuntimeRuntimeApiMetadataV15: ScaleCodable {
    public let name: String
    public let methods: [RuntimeRuntimeApiMethodMetadataV15]
    public let docs: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        methods = try decoder.decode()
        docs = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(methods).encode(docs)
    }
}

public struct RuntimeRuntimeApiMethodMetadataV15: ScaleCodable {
    public let name: String
    public let inputs: [RuntimeRuntimeApiMethodParamMetadataV15]
    public let output: RuntimeTypeId
    public let docs: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        inputs = try decoder.decode()
        output = try decoder.decode()
        docs = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(inputs)
                .encode(output).encode(docs)
    }
}

public struct RuntimeRuntimeApiMethodParamMetadataV15: ScaleCodable {
    public let name: String
    public let type: RuntimeTypeId
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(type)
    }
}

public struct RuntimeMetadataOuterEnumsV15: ScaleCodable {
    /// The type of the outer `RuntimeCall` enum.
    public let callEnumType: RuntimeTypeId
    /// The type of the outer `RuntimeEvent` enum.
    public let eventEnumType: RuntimeTypeId
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
    public let moduleErrorEnumType: RuntimeTypeId
    
    public init(from decoder: ScaleCodec.ScaleDecoder) throws {
        callEnumType = try decoder.decode()
        eventEnumType = try decoder.decode()
        moduleErrorEnumType = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleCodec.ScaleEncoder) throws {
        try encoder.encode(callEnumType).encode(eventEnumType).encode(moduleErrorEnumType)
    }
}
