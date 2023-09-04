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
    var extrinsicDecoder: any ExtrinsicDecoder { get }
    
    var types: DynamicTypes { get }
    
    func encoder() -> any ScaleCodec.Encoder
    func encoder(reservedCapacity: Int) -> any ScaleCodec.Encoder
    func decoder(with data: Data) -> any ScaleCodec.Decoder
    
    func resolve(type id: NetworkType.Id) -> NetworkType?
    // Joined by "."
    func resolve(type path: String) -> NetworkType.Info?
    func resolve(palletName index: UInt8) -> String?
    func resolve(palletIndex name: String) -> UInt8?
    
    func custom(coder type: NetworkType.Id) -> RuntimeCustomDynamicCoder?
    
    // Calls
    func resolve(callName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)?
    func resolve(callIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)?
    func resolve(callParams name: String, pallet: String) -> [(field: NetworkType.Field,
                                                               type: NetworkType)]?
    
    // Runtime Calls
    func resolve(
        runtimeCall method: String, api: String
    ) -> (params: [(name: String, type: NetworkType.Info)], result: NetworkType.Info)?
    
    // Events
    func resolve(eventName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)?
    func resolve(eventIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)?
    func resolve(eventParams name: String, pallet: String) -> [(field: NetworkType.Field,
                                                                type: NetworkType)]?
    
    //Constants
    func resolve(
        constant name: String, pallet: String
    ) -> (value: Data, type: NetworkType.Info)?
    
    // Storage
    func resolve(
        storage name: String, pallet: String
    ) -> (keys: [(hasher: LatestMetadata.StorageHasher, type: NetworkType.Info)],
          value: NetworkType.Info,
          `default`: Data)?
}

public extension Runtime {
    @inlinable
    func resolve(type id: NetworkType.Id) -> NetworkType? {
        metadata.resolve(type: id)
    }
    
    @inlinable
    func resolve(type path: String) -> NetworkType.Info? {
        metadata.resolve(type: path)
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
    func resolve(callParams name: String, pallet: String) -> [(field: NetworkType.Field,
                                                               type: NetworkType)]?
    {
        metadata.resolve(pallet: pallet)?.callParams(name: name)
    }
    
    @inlinable
    func resolve(
        runtimeCall method: String, api: String
    ) -> (params: [(name: String, type: NetworkType.Info)], result: NetworkType.Info)? {
        metadata.resolve(api: api)?.resolve(method: method)
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
    func resolve(eventParams name: String, pallet: String) -> [(field: NetworkType.Field,
                                                                type: NetworkType)]?
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
    func resolve(
        constant name: String, pallet: String
    ) -> (value: Data, type: NetworkType.Info)? {
        guard let constant = metadata.resolve(pallet: pallet)?.constant(name: name) else {
            return nil
        }
        return (constant.value, constant.type)
    }
    
    @inlinable
    func resolve(
        storage name: String, pallet: String
    ) -> (keys: [(hasher: LatestMetadata.StorageHasher, type: NetworkType.Info)],
          value: NetworkType.Info,
          `default`: Data)?
    {
        metadata.resolve(pallet: pallet)?.storage(name: name).flatMap {
            ($0.types.keys, $0.types.value, $0.defaultValue)
        }
    }
}
