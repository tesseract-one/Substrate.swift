@_exported import Substrate

public struct KusamaRuntime {}

extension KusamaRuntime: Balances {
    public typealias TBalance = SUInt128
}

extension KusamaRuntime: System {
    public typealias TIndex = UInt32
    public typealias TBlockNumber = UInt32
    public typealias THash = Hash256
    public typealias THasher = HBlake2b256
    public typealias TAccountId = AccountId
    public typealias TAddress = Address<TAccountId, UInt32>
    public typealias THeader = Header<TBlockNumber, THash>
    public typealias TExtrinsic = OpaqueExtrinsic
    public typealias TAccountData = AccountData<TBalance>
}

extension KusamaRuntime: Staking {}

extension KusamaRuntime: Runtime {
    public typealias TSignature = MultiSignature
    public typealias TExtrinsicExtra = DefaultExtrinsicExtra<Self>
    
    public var modules: [TypeRegistrator] {
        [PrimitivesModule<Self>(), SystemModule<Self>(),
         BalancesModule<Self>(), StakingModule<Self>()]
    }
}


public typealias Polkadot<C: RpcClient> = Substrate<KusamaRuntime, C>


extension Polkadot {
    public static func create<C: RpcClient>(
        client: C, signer: SubstrateSigner? = nil, _ cb: @escaping SRpcApiCallback<Polkadot<C>>
    ) {
        Self.create(client: client, runtime: KusamaRuntime(), signer: signer, cb)
    }
}
