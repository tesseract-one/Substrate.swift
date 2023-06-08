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

public protocol ExtrinsicApi<S> {
    associatedtype S: SomeSubstrate
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S) async
}

extension ExtrinsicApi {
    public static var id: String { String(describing: self) }
}

public class ExtrinsicApiRegistry<S: SomeSubstrate> {
    private actor Registry {
        private var _apis: [String: any ExtrinsicApi] = [:]
        public func getApi<A, S: SomeSubstrate>(substrate: S) async -> A
            where A: ExtrinsicApi, A.S == S
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
    
    public func getApi<A>(_ t: A.Type) async -> A where A: ExtrinsicApi, A.S == S {
        await _apis.getApi(substrate: substrate)
    }
    
    public func signer() throws -> any Signer {
        guard let signer = substrate.signer else {
            throw SubmittableError.signerIsNil
        }
        return signer
    }
}

public extension ExtrinsicApiRegistry {
    func account() async throws -> any PublicKey {
        try await signer().account(type: .account,
                                   algos: S.RC.TSignature.algorithms(runtime: substrate.runtime))
    }
}
