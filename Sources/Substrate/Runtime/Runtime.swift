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
    var hasher: any FixedHasher { get }
    var extrinsicDecoder: any ExtrinsicDecoder { get }
    var isBatchSupported: Bool { get }
    
    var types: DynamicTypes { get }
    var staticTypes: Synced<TypeRegistry<TypeDefinition.TypeId>> { get }
    var dynamicCustomCoders: [ObjectIdentifier: any CustomDynamicCoder] { get }
    var dynamicRuntimeCustomCoders: [ObjectIdentifier: any RuntimeCustomDynamicCoder] { get }
    
    func encoder() -> any ScaleCodec.Encoder
    func encoder(reservedCapacity: Int) -> any ScaleCodec.Encoder
    func decoder(with data: Data) -> any ScaleCodec.Decoder
    
    // Joined by "."
    func resolve(type path: String) -> TypeDefinition?
    func resolve(palletName index: UInt8) -> String?
    func resolve(palletIndex name: String) -> UInt8?
    func resolve(palletError index: UInt8) -> (pallet: String, type: TypeDefinition)?
    func resolve(palletError name: String) -> (pallet: UInt8, type: TypeDefinition)?
    
    // Calls
    func resolve(palletCall name: String) -> (pallet: UInt8, type: TypeDefinition)?
    func resolve(palletCall index: UInt8) -> (pallet: String, type: TypeDefinition)?
    func resolve(callName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)?
    func resolve(callIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)?
    func resolve(callParams name: String, pallet: String) -> [TypeDefinition.Field]?
    
    // Runtime Calls
    func resolve(
        runtimeCall method: String, api: String
    ) -> (params: [(name: String, type: TypeDefinition)], result: TypeDefinition)?
    
    // Events
    func resolve(palletEvent name: String) -> (pallet: UInt8, type: TypeDefinition)?
    func resolve(palletEvent index: UInt8) -> (pallet: String, type: TypeDefinition)?
    func resolve(eventName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)?
    func resolve(eventIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)?
    func resolve(eventParams name: String, pallet: String) -> [TypeDefinition.Field]?
    //Constants
    func resolve(
        constant name: String, pallet: String
    ) -> (value: Data, type: TypeDefinition)?
    
    // Storage
    func resolve(
        storage name: String, pallet: String
    ) -> (keys: [(hasher: LatestMetadata.StorageHasher, type: TypeDefinition)],
          value: TypeDefinition, `default`: Data)?
}

public extension Runtime {
    @inlinable
    func resolve(type path: String) -> TypeDefinition? {
        metadata.resolve(type: path)
    }
    
    @inlinable
    func resolve(palletCall name: String) -> (pallet: UInt8, type: TypeDefinition)? {
        metadata.resolve(pallet: name).flatMap{p in p.call.map{(p.index, $0)}}
    }
    
    @inlinable
    func resolve(palletCall index: UInt8) -> (pallet: String, type: TypeDefinition)? {
        metadata.resolve(pallet: index).flatMap{p in p.call.map{(p.name, $0)}}
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
    func resolve(callParams name: String, pallet: String) -> [TypeDefinition.Field]?
    {
        metadata.resolve(pallet: pallet)?.callParams(name: name)
    }
    
    @inlinable
    func resolve(
        runtimeCall method: String, api: String
    ) -> (params: [(name: String, type: TypeDefinition)], result: TypeDefinition)? {
        metadata.resolve(api: api)?.resolve(method: method)
    }
    
    @inlinable
    func resolve(palletEvent name: String) -> (pallet: UInt8, type: TypeDefinition)? {
        metadata.resolve(pallet: name).flatMap{p in p.event.map{(p.index, $0)}}
    }
    
    @inlinable
    func resolve(palletEvent index: UInt8) -> (pallet: String, type: TypeDefinition)? {
        metadata.resolve(pallet: index).flatMap{p in p.event.map{(p.name, $0)}}
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
    func resolve(eventParams name: String, pallet: String) -> [TypeDefinition.Field]?
    {
        metadata.resolve(pallet: pallet)?.eventParams(name: name)
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
    func resolve(palletError index: UInt8) -> (pallet: String, type: TypeDefinition)? {
        metadata.resolve(pallet: index).flatMap{p in p.error.map{(p.name, $0)}}
    }
    
    @inlinable
    func resolve(palletError name: String) -> (pallet: UInt8, type: TypeDefinition)? {
        metadata.resolve(pallet: name).flatMap{p in p.error.map{(p.index, $0)}}
    }
    
    @inlinable
    func resolve(
        constant name: String, pallet: String
    ) -> (value: Data, type: TypeDefinition)? {
        guard let constant = metadata.resolve(pallet: pallet)?.constant(name: name) else {
            return nil
        }
        return (constant.value, constant.type)
    }
    
    @inlinable
    func resolve(
        storage name: String, pallet: String
    ) -> (keys: [(hasher: LatestMetadata.StorageHasher, type: TypeDefinition)],
          value: TypeDefinition, `default`: Data)?
    {
        metadata.resolve(pallet: pallet)?.storage(name: name).flatMap {
            ($0.types.keys, $0.types.value, $0.defaultValue)
        }
    }
}
