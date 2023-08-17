//
//  BlockExtrinsic.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation

public struct BlockExtrinsic<TManager: ExtrinsicManager>: OpaqueExtrinsic {
    public typealias TManager = TManager
    public typealias THash = TManager.RC.THasher.THash
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
        try! runtime.hash(type: TManager.RC.THasher.THash.self, data: data)
    }
    
    public func decode<C: Call & RuntimeDynamicDecodable>() throws -> AnyExtrinsic<C, TManager> {
        var decoder = runtime.decoder(with: data)
        return try TManager.get(from: runtime).decode(from: &decoder)
    }
    
    public static var version: UInt8 { TManager.version }
}
