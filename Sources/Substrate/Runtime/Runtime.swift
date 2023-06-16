//
//  Runtime.swift
//  
//
//  Created by Yehor Popovych on 30.12.2022.
//

import Foundation
import ScaleCodec

public protocol Runtime: AnyObject {
    var addressFormat: SS58.AddressFormat { get }
    var metadata: any Metadata { get }
    var hasher: any Hasher { get }
    
    // configurations
    var blockHeaderType: RuntimeTypeInfo { get throws }
    var addressType: RuntimeTypeInfo { get throws }
    var signatureType: RuntimeTypeInfo { get throws }
    var extrinsicExtraType: RuntimeTypeInfo { get throws }
    
    func encoder() -> any ScaleEncoder
    func decoder(with data: Data) -> any ScaleDecoder
    
    func resolve(type id: RuntimeTypeId) -> RuntimeType?
    func resolve(type path: [String]) -> RuntimeTypeInfo?
    func resolve(palletName index: UInt8) -> String?
    func resolve(palletIndex name: String) -> UInt8?
        
    // Calls
    func resolve(callType pallet: UInt8) -> RuntimeTypeInfo?
    func resolve(callType pallet: String) -> RuntimeTypeInfo?
    func resolve(callName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)?
    func resolve(callIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)?
    
    // Runtime Calls
    func resolve(
        runtimeCall method: String, api: String
    ) -> (params: [(String, RuntimeTypeInfo)], result: RuntimeTypeInfo)?
    
    // Events
    func resolve(eventType pallet: UInt8) -> RuntimeTypeInfo?
    func resolve(eventType pallet: String) -> RuntimeTypeInfo?
    func resolve(eventName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)?
    func resolve(eventIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)?
    
    //Constants
    func resolve(constant name: String, pallet: String) -> (value: Data, type: RuntimeTypeInfo)?
    
    // Storage
    func resolve(
        storage name: String, pallet: String
    ) -> (keys: [(StorageHasher, RuntimeTypeId)], value: RuntimeTypeId, `default`: Data)?
}

public protocol RuntimeAware {
    var runtime: any Runtime { get }
}

public protocol RuntimeHolder: RuntimeAware {
    func setRuntime(runtime: any Runtime) throws
}

public extension Runtime {
    @inlinable
    func resolve(type id: RuntimeTypeId) -> RuntimeType? {
        metadata.resolve(type: id)
    }
    
    @inlinable
    func resolve(type path: [String]) -> RuntimeTypeInfo? {
        metadata.resolve(type: path)
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
    func resolve(
        runtimeCall method: String, api: String
    ) -> (params: [(String, RuntimeTypeInfo)], result: RuntimeTypeInfo)? {
        metadata.resolve(api: api)?.resolve(method: method)
    }
    
    @inlinable
    func resolve(eventType pallet: UInt8) -> RuntimeTypeInfo? {
        metadata.resolve(pallet: pallet)?.event
    }
    
    @inlinable
    func resolve(eventType pallet: String) -> RuntimeTypeInfo? {
        metadata.resolve(pallet: pallet)?.event
    }
    
    @inlinable
    func resolve(eventName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)? {
        metadata.resolve(pallet: pallet).flatMap { pallet in
            pallet.eventName(index: index).map { (pallet.name, $0) }
        }
    }
    
    @inlinable
    func resolve(eventIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)? {
        metadata.resolve(pallet: pallet).flatMap { pallet in
            pallet.eventIndex(name: name).map { (pallet.index, $0) }
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
    func resolve(constant name: String, pallet: String) -> (value: Data, type: RuntimeTypeInfo)? {
        guard let constant = metadata.resolve(pallet: pallet)?.constant(name: name) else {
            return nil
        }
        return (constant.value, constant.type)
    }
    
    @inlinable
    func resolve(
        storage name: String, pallet: String
    ) -> (keys: [(StorageHasher, RuntimeTypeId)], value: RuntimeTypeId, `default`: Data)? {
        metadata.resolve(pallet: pallet)?.storage(name: name).flatMap {
            let (keys, value) = $0.types
            return (keys.map { ($0.0, $0.1.id) }, value.id, $0.defaultValue)
        }
    }
}
