//
//  MetadataError.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation
//import ScaleCodec

public enum MetadataError: Error {
    case typeNotFound(DType)
    case moduleNotFound(name: String)
    case moduleNotFound(index: UInt8)
    case eventNotFound(module: String, event: String)
    case callNotFound(module: String, function: String)
    case encodingNotSupported(for: DType)
    case expectedCollection(found: ScaleDynamicEncodable)
    case expectedMap(found: ScaleDynamicEncodable)
    case wrongElementCount(in: ScaleDynamicEncodable, expected: Int)
    case storageItemNotFound(prefix: String, item: String)
    case storageItemBadPathTypes(prefix: String, item: String, path: [ScaleDynamicEncodable], expected: [DType])
}
//
//public protocol MetadataProtocol: class {
//    var registry: TypeRegistryProtocol { get }
//
//    // StorageKey
//    func prefix<K: AnyStorageKey>(for key: K) throws -> Data
//    func key<K: AnyStorageKey>(for key: K) throws -> Data
//
//    // Call
//    func encode<T: AnyCall>(call: T, in encoder: ScaleEncoder) throws
//    //func decode<T: Call>(call t: T.Type, index: Int, module: Int, from decoder: ScaleDecoder) throws -> T
//    func decode(callFrom decoder: ScaleDecoder) throws -> AnyCall
//    func decode(call index: Int, module: Int, from decoder: ScaleDecoder) throws -> AnyCall
//    func find(call: Int, module: Int) -> (module: String, function: String)?
//
//    // Event
//    func decode(eventFrom decoder: ScaleDecoder) throws -> AnyEvent
//    func decode(event index: Int, module: Int, from decoder: ScaleDecoder) throws -> AnyEvent
//    //func decode<T: Event>(event t: T.Type, index: Int, module: Int, from decoder: ScaleDecoder) throws -> T
//    func find(event: Int, module: Int) -> (module: String, event: String)?
//
//    // Generic Values
//    func encode(value: ScaleDynamicEncodable, type: DType, in encoder: ScaleEncoder) throws
//    func decode(type: DType, from decoder: ScaleDecoder) throws -> DValue
//}
