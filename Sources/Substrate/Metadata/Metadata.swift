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
    func resolve(pallet index: UInt8) -> PalletMetadata?
    func resolve(pallet name: String) -> PalletMetadata?
}

public protocol PalletMetadata {
    var name: String { get }
    var index: UInt8 { get }
    var call: RuntimeTypeInfo? { get }
    
    func callName(index: UInt8) -> String?
    func callIndex(name: String) -> UInt8?
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
