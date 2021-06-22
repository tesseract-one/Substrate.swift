@_exported import Substrate

public struct PolkadotRuntime {}

extension PolkadotRuntime: Balances {
    public typealias TBalance = SUInt128
}

extension PolkadotRuntime: System {
    public typealias TIndex = UInt32
    public typealias TBlockNumber = UInt32
    public typealias THash = Hash256
    public typealias THasher = HBlake2b256
    public typealias TAccountId = Sr25519PublicKey
    public typealias TAddress = MultiAddress<TAccountId, TIndex>
    public typealias THeader = Header<TBlockNumber, THash>
    public typealias TExtrinsic = OpaqueExtrinsic
    public typealias TAccountData = AccountData<TBalance>
}

extension PolkadotRuntime: Staking {}

extension PolkadotRuntime: Session {
    public typealias TValidatorId = Self.TAccountId
    public typealias TKeys = KusamaSessionKeys
}

extension PolkadotRuntime: Babe {}
extension PolkadotRuntime: Grandpa {}
extension PolkadotRuntime: BeefyApi {
    public typealias TBeefyPayload = Hash256
    public typealias TBeefyValidatorSetId = UInt64
}

extension PolkadotRuntime: Runtime {
    public typealias TSignature = MultiSignature
    public typealias TExtrinsicExtra = DefaultExtrinsicExtra<Self>
    
    public var supportedSpecVersions: Range<UInt32> {
        return 30..<UInt32.max
    }
    
    public var modules: [ModuleBase] {
        [PrimitivesModule<Self>(), SystemModule<Self>(),
         SessionModule<Self>(), BalancesModule<Self>(),
         StakingModule<Self>()]
    }
}


public typealias Polkadot<C: RpcClient> = Substrate<PolkadotRuntime, C>


extension Polkadot {
    public static func create<C: RpcClient>(
        client: C, signer: SubstrateSigner? = nil, _ cb: @escaping SRpcApiCallback<Polkadot<C>>
    ) {
        Self.create(client: client, runtime: PolkadotRuntime(), signer: signer, cb)
    }
}
