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
}

public protocol Metadata {
    var runtime: RuntimeMetadata { get }
    
    var extrinsic: ExtrinsicMetadata { get }
    
    func resolve(type id: RuntimeTypeId) -> RuntimeType?
    func resolve(type path: [String]) -> RuntimeTypeInfo?
    func resolve(pallet index: UInt8) -> PalletMetadata?
    func resolve(pallet name: String) -> PalletMetadata?
}

public protocol PalletMetadata {
    var name: String { get }
    var index: UInt8 { get }
    var call: RuntimeTypeInfo? { get }
    var event: RuntimeTypeInfo? { get }
    
    func callName(index: UInt8) -> String?
    func callIndex(name: String) -> UInt8?
    func eventName(index: UInt8) -> String?
    func eventIndex(name: String) -> UInt8?
    
    func storage(name: String) -> StorageMetadata?
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

public protocol ExtrinsicExtensionMetadata {
    var identifier: String { get }
    var type: RuntimeTypeInfo { get }
    var additionalSigned: RuntimeTypeInfo { get }
}
