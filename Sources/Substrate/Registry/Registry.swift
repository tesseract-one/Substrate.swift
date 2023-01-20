//
//  Registry.swift
//  
//
//  Created by Yehor Popovych on 30.12.2022.
//

import Foundation
import ScaleCodec

public protocol Registry: AnyObject {
    var addressFormat: SS58.AddressFormat { get }
    var metadata: Metadata { get }
    var extrinsicDecoder: ExtrinsicDecoder { get }
    
    func encoder() -> ScaleEncoder
    func decoder(with data: Data) -> ScaleDecoder
    
    func resolve(type id: RuntimeTypeId) -> RuntimeType?
    func resolve(palletName index: UInt8) -> String?
    func resolve(palletIndex name: String) -> UInt8?
    func resolve(callType pallet: UInt8) -> RuntimeTypeInfo?
    func resolve(callType pallet: String) -> RuntimeTypeInfo?
    func resolve(callName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)?
    func resolve(callIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)?
}

public protocol RegistryOwner {
    var registry: any Registry { get set }
}

public extension Registry {
    @inlinable
    func resolve(type id: RuntimeTypeId) -> RuntimeType? {
        metadata.resolve(type: id)
    }
    
    @inlinable
    func resolve(callType pallet: UInt8) -> RuntimeTypeInfo? {
        metadata.resolve(pallet: pallet)?.call
    }
    
    @inlinable
    func resolve(callType pallet: String) -> RuntimeTypeInfo? {
        metadata.resolve(pallet: pallet)?.call
    }
    
    @inlinable
    func resolve(callName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)? {
        metadata.resolve(pallet: pallet).flatMap { pallet in
            pallet.callName(index: index).map { (pallet.name, $0) }
        }
    }
    
    @inlinable
    func resolve(callIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)? {
        metadata.resolve(pallet: pallet).flatMap { pallet in
            pallet.callIndex(name: name).map { (pallet.index, $0) }
        }
    }
    
    @inlinable
    func resolve(palletName index: UInt8) -> String? {
        metadata.resolve(pallet: index)?.name
    }
    
    @inlinable
    func resolve(palletIndex name: String) -> UInt8? {
        metadata.resolve(pallet: name)?.index
    }
    
    @inlinable
    func encoder() -> ScaleEncoder { SCALE.default.encoder() }
    
    @inlinable
    func decoder(with data: Data) -> ScaleDecoder { SCALE.default.decoder(data: data) }
}

public class TypeRegistry: Registry {
    public let addressFormat: SS58.AddressFormat
    public let metadata: Metadata
    public let extrinsicDecoder: ExtrinsicDecoder
    
    public init(metadata: Metadata, addressFormat: SS58.AddressFormat, decoder: ExtrinsicDecoder) {
        self.metadata = metadata
        self.addressFormat = addressFormat
        self.extrinsicDecoder = decoder
    }
}
