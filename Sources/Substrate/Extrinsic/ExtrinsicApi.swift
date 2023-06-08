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
    var substrate: S! { get }
    init(substrate: S)
    static var id: String { get }
}

extension ExtrinsicApi {
    public static var id: String { String(describing: self) }
}

public class ExtrinsicApiRegistry<S: SomeSubstrate> {
    private let _apis: Synced<[String: any ExtrinsicApi]>
    
    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Synced(value: [:])
    }
    
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: ExtrinsicApi, A.S == S {
        _apis.sync { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(substrate: substrate)
            apis[A.id] = api
            return api
        }
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
