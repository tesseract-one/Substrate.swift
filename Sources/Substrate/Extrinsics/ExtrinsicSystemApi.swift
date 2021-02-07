//
//  ExtrinsicSystemApi.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

public struct SubstrateExtrinsicSystemApi<S: SubstrateProtocol>: SubstrateExtrinsicApi {
    public weak var substrate: S!

    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func setCode(
        code: Data, extra: S.R.TExtrinsicExtra,
        with accountId: S.R.TAccountId, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        signAndSubmit(call: SystemSetCodeCall<S.R>(code: code), extra: extra, with: accountId, timeout: timeout, cb)
    }
}

extension SubstrateExtrinsicApi where S.R.TExtrinsicExtra: SignedExtrinsicExtra, S.R.TExtrinsicExtra.S == S.R {
    public func setCode(
        code: Data, with accountId: S.R.TAccountId, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        signAndSubmit(call: SystemSetCodeCall<S.R>(code: code), with: accountId, timeout: timeout, cb)
    }
}

extension SubstrateExtrinsicApiRegistry {
    public var system: SubstrateExtrinsicSystemApi<S> { getExtrinsicApi(SubstrateExtrinsicSystemApi<S>.self) }
}