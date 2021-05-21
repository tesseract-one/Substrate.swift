//
//  ExtrinsicApi.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

public typealias SExtrinsicApiResult<V, R: Runtime> = Result<V, SubstrateExtrinsicApiError<R>>
public typealias SExtrinsicApiCallback<V, R: Runtime> = (SExtrinsicApiResult<V, R>) -> Void

public protocol SubstrateExtrinsicApi {
    associatedtype S: SubstrateProtocol
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S)
}

extension SubstrateExtrinsicApi {
    public static var id: String { String(describing: self) }
    
    public func nonce(
        accountId: S.R.TAccountId, timeout: TimeInterval? = nil, _ cb: @escaping SExtrinsicApiCallback<S.R.TIndex, S.R>
    ) {
        substrate.query.system.accountInfo(accountId: accountId) { result in
            let res = result
                .map { $0.nonce }
                .mapError(SubstrateExtrinsicApiError<S.R>.rpc)
            cb(res)
        }
    }
}

extension SubstrateExtrinsicApi where S.R: Session {
    public func submit<C: AnyCall>(
        unsgined call: C, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        substrate.rpc.author.submit(extrinsic: SExtrinsic<C, S.R>(call: call)) {
            cb($0.mapError(SubstrateExtrinsicApiError<S.R>.rpc))
        }
    }

    public func submit<E: ExtrinsicProtocol>(
        extrinsic: E, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        substrate.rpc.author.submit(extrinsic: extrinsic, timeout: timeout) {
            cb($0.mapError(SubstrateExtrinsicApiError<S.R>.rpc))
        }
    }
}

public final class SubstrateExtrinsicApiRegistry<S: SubstrateProtocol> {
    private var _apis: [String: Any] = [:]
    public internal(set) weak var substrate: S!
    
    public func getExtrinsicApi<A>(_ t: A.Type) -> A where A: SubstrateExtrinsicApi, A.S == S {
        if let api = _apis[A.id] as? A {
            return api
        }
        let api = A(substrate: substrate)
        _apis[A.id] = api
        return api
    }
}

extension SubstrateExtrinsicApiRegistry where S.R: Session {
    public func submit<E: ExtrinsicProtocol>(
        extrinsic: E, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        substrate.rpc.author.submit(extrinsic: extrinsic, timeout: timeout) {
            cb($0.mapError(SubstrateExtrinsicApiError<S.R>.rpc))
        }
    }
}

public enum SubstrateExtrinsicApiError<R: Runtime>: Error {
    case rpc(error: SubstrateRpcApiError)
    case signer(error: SubstrateSignerError)
    case payload(error: Error)
    case dontHaveSigner
    case badSs58Format(format: Ss58AddressFormat, expected: Ss58AddressFormat)
}
