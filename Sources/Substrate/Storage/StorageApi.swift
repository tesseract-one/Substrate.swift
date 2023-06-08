//
//  StorageAoi.swift
//  
//
//  Created by Yehor Popovych on 15/05/2023.
//

import Foundation
import ScaleCodec
import JsonRPC
import Serializable
#if !COCOAPODS
import JsonRPCSerializable
#endif

public protocol SrotageApi<S> {
    associatedtype S: SomeSubstrate
    var substrate: S! { get }
    init(substrate: S)
    static var id: String { get }
}

extension SrotageApi {
    public static var id: String { String(describing: self) }
}

public class StorageApiRegistry<S: SomeSubstrate> {
    private let _apis: Synced<[String: any SrotageApi]>

    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Synced(value: [:])
    }
    
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: SrotageApi, A.S == S {
        _apis.sync { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(substrate: substrate)
            apis[A.id] = api
            return api
        }
    }
}
