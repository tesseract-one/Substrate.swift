//
//  AnyStorageKey.swift
//  
//
//  Created by Yehor Popovych on 10.08.2021.
//

import Foundation
import ScaleCodec

public protocol AnyStorageKey: ScaleDynamicEncodable {
    var module: String { get }
    var field: String { get }
    var path: [Any?] { get }
    var hashes: [Data]? { get }
    
    // TODO: Refactor dynamic types (DYNAMIC)
    func decode(valueFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws -> Any
    
    static func prefix(from decoder: ScaleDecoder) throws -> Data
    static func prefix(module: String, field: String) -> Data
    static var prefixHasher: NormalHasher { get }
    static var prefixSize: UInt { get }
}

extension AnyStorageKey {
    public static func prefix(from decoder: ScaleDecoder) throws -> Data {
        try decoder.decode(Data.self, .fixed(Self.prefixSize))
    }
    
    public static func prefix(module: String, field: String) -> Data {
        Self.prefixHasher.hash(data: Data(module.utf8))
            + Self.prefixHasher.hash(data: Data(field.utf8))
    }
    
    public static var prefixSize: UInt {
        UInt(2 * Self.prefixHasher.hashPartByteLength)
    }
    
    public static var prefixHasher: NormalHasher { HXX128.hasher as! NormalHasher }
}
