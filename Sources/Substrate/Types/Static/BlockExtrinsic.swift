//
//  BlockExtrinsic.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation

public struct BlockExtrinsic<TManager: ExtrinsicManager>: OpaqueExtrinsic {
    public typealias TManager = TManager
    public typealias THash = TManager.TConfig.THasher.THash
    public typealias TSignedExtra = TManager.TSignedExtra
    public typealias TUnsignedExtra = TManager.TUnsignedExtra
    
    public let data: Data
    public let runtime: any Runtime
    
    public init(from decoder: Swift.Decoder, runtime: any Runtime) throws {
        let container = try decoder.singleValueContainer()
        self.data = try container.decode(Data.self)
        self.runtime = runtime
    }
    
    public func hash() -> THash {
        try! runtime.hash(type: THash.self, data: data)
    }
    
    public func decode<C: Call & RuntimeDynamicDecodable>() throws -> AnyExtrinsic<C, TManager> {
        var decoder = runtime.decoder(with: data)
        return try runtime.decode(extrinsic: AnyExtrinsic<C, TManager>.self, from: &decoder)
    }
    
    public static var version: UInt8 { TManager.version }
}
