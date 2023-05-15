//
//  RpcApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import JsonRPC
import Serializable
#if !COCOAPODS
import JsonRPCSerializable
#endif

public protocol RuntimeApi<S> {
    associatedtype S: SomeSubstrate
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S) async
}

extension RuntimeApi {
    public static var id: String { String(describing: self) }
}

public class RuntimeApiRegistry<S: SomeSubstrate> {
    private actor Registry {
        private var _apis: [String: any RuntimeApi] = [:]
        public func getApi<A, S: SomeSubstrate>(substrate: S) async -> A
            where A: RuntimeApi, A.S == S
        {
            if let api = _apis[A.id] as? A {
                return api
            }
            let api = await A(substrate: substrate)
            _apis[A.id] = api
            return api
        }
    }
    private var _apis: Registry
    
    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Registry()
    }
    
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) async -> A where A: RuntimeApi, A.S == S {
        await _apis.getApi(substrate: substrate)
    }
}

public extension RuntimeApiRegistry {
    func execute<C: RuntimeCall>(call: C,
                                 at hash: S.RC.THasher.THash? = nil) async throws -> C.TReturn {
        let encoder = substrate.runtime.encoder()
        try call.encodeParams(in: encoder, runtime: substrate.runtime)
        let data = try await substrate.rpc.state.call(method: call.fullName,
                                                      data: encoder.output,
                                                      at: hash)
        return try call.decode(returnFrom: substrate.runtime.decoder(with: data),
                               runtime: substrate.runtime)
    }
    
    static func execute<C: StaticCodableRuntimeCall>(
        call: C, at hash: S.RC.THasher.THash?, with client: CallableClient
    ) async throws -> C.TReturn {
        let encoder = SCALE.default.encoder()
        try call.encodeParams(in: encoder)
        let data = try await RpcStateApi<S>.call(method: call.fullName,
                                                 data: encoder.output,
                                                 at: hash, with: client)
        return try call.decode(returnFrom: SCALE.default.decoder(data: data))
    }
    
    static func metadata(with client: CallableClient) async throws -> Metadata {
        let versions = try await Self.execute(call: MetadataRuntimeApi.MetadataVersions(),
                                              at: nil, with: client)
        let supported = VersionedMetadata.supportedVersions.intersection(versions)
        guard let max = supported.max() else {
            throw SDecodingError.dataCorrupted(
                SDecodingError.Context(
                    path: [],
                    description: "Unsupported metadata versions \(versions)"))
        }
        let data = try await Self.execute(call: MetadataRuntimeApi.MetadataAtVersion(version: max),
                                          at: nil, with: client)
        guard let data = data else {
            throw SDecodingError.dataCorrupted(
                SDecodingError.Context(
                    path: [],
                    description: "Null metadata"))
        }
        return try VersionedMetadata(from: SCALE.default.decoder(data: data)).metadata
    }
}
