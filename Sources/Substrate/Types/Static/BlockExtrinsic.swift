//
//  BlockExtrinsic.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation

public struct BlockExtrinsic<M: ExtrinsicManager>: OpaqueExtrinsic, CustomStringConvertible, CustomDebugStringConvertible {
    public typealias THash = M.TConfig.THasher.THash
    public typealias TSignedExtra = M.TSignedExtra
    public typealias TUnsignedExtra = M.TUnsignedExtra
    
    public typealias AnyExtrinsic<C: Call> = Extrinsic<C, Either<TUnsignedExtra, TSignedExtra>>
    
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
    
    public func decode<C: Call & RuntimeDynamicDecodable>() throws -> AnyExtrinsic<C> {
        var decoder = runtime.decoder(with: data)
        return try runtime.decode(extrinsic: AnyExtrinsic<C>.self, from: &decoder)
    }
    
    public var description: String { data.hex() }
    
    public var debugDescription: String {
        do {
            let ext: AnyExtrinsic<AnyCall<NetworkType.Id>> = try decode()
            return ext.description
        } catch {
            return description
        }
    }
    
    public static var version: UInt8 { M.version }
}
