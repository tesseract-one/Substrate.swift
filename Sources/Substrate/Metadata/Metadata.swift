//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation

public protocol RuntimeMetadata {
    var version: UInt8 { get }
    func asMetadata() -> Metadata
    
    static var versions: Set<UInt32> { get }
}

public protocol Metadata {
    var runtime: RuntimeMetadata { get }
    var extrinsic: ExtrinsicMetadata { get }
    var pallets: [String] { get }
    var apis: [String] { get }
    
    func resolve(type id: RuntimeTypeId) -> RuntimeType?
    func resolve(type path: [String]) -> RuntimeTypeInfo?
    func resolve(type name: String) -> RuntimeTypeInfo?
    func resolve(pallet index: UInt8) -> PalletMetadata?
    func resolve(pallet name: String) -> PalletMetadata?
    func resolve(api name: String) -> RuntimeApiMetadata?
}

public protocol PalletMetadata {
    var name: String { get }
    var index: UInt8 { get }
    var call: RuntimeTypeInfo? { get }
    var event: RuntimeTypeInfo? { get }
    var storage: [String] { get }
    var constants: [String] { get }
    
    func callName(index: UInt8) -> String?
    func callIndex(name: String) -> UInt8?
    func eventName(index: UInt8) -> String?
    func eventIndex(name: String) -> UInt8?
    
    func storage(name: String) -> StorageMetadata?
    func constant(name: String) -> ConstantMetadata?
}

public protocol StorageMetadata {
    var name: String { get }
    var modifier: StorageEntryModifier { get }
    var types: (keys: [(StorageHasher, RuntimeTypeInfo)], value: RuntimeTypeInfo) { get }
    var defaultValue: Data { get }
    var documentation: [String] { get }
}

public protocol ExtrinsicMetadata {
    var version: UInt8 { get }
    var type: RuntimeTypeInfo { get }
    var extensions: [ExtrinsicExtensionMetadata] { get }
}

public protocol ConstantMetadata {
    var name: String { get }
    var type: RuntimeTypeInfo { get }
    var value: Data { get }
    var documentation: [String] { get }
}

public protocol ExtrinsicExtensionMetadata {
    var identifier: String { get }
    var type: RuntimeTypeInfo { get }
    var additionalSigned: RuntimeTypeInfo { get }
}

public protocol RuntimeApiMetadata {
    var name: String { get }
    var methods: [String] { get }
    
    func resolve(method name: String) -> (params: [(String, RuntimeTypeInfo)], result: RuntimeTypeInfo)?
}
