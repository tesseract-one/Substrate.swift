//
//  RuntimeCallApi.swift
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

public protocol RuntimeCallApi<S> {
    associatedtype S: SomeSubstrate
    var substrate: S! { get }
    init(substrate: S)
    static var id: String { get }
}

extension RuntimeCallApi {
    public static var id: String { String(describing: self) }
}

public class RuntimeCallApiRegistry<S: SomeSubstrate> {
    private let _apis: Synced<[String: any RuntimeCallApi]>
    
    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Synced(value: [:])
    }
    
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: RuntimeCallApi, A.S == S {
        _apis.sync { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(substrate: self.substrate)
            apis[A.id] = api
            return api
        }
    }
}

public extension RuntimeCallApiRegistry {
    func execute<C: RuntimeCall>(call: C,
                                 at hash: S.RC.THasher.THash? = nil) async throws -> C.TReturn {
        try await substrate.client.execute(call: call, at: hash)
    }
}
