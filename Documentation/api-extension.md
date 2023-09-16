# SDK Api Extension

SDK provides several points for static API extension. Full example can be found in the [CustomStaticConfig](../Examples/Sources/CustomStaticConfig/) example application.

## Call and Transaction
Extension point is a `ExtrinsicApiRegistry` and `ExtrinsicApi` protocol. 

Registry can be extended to provide named API like
```swift
public extension ExtrinsicApiRegistry where R.RC == MyConfig {
    var balances: MyBalancesApi<R> { _api() }
}
```

where `MyBalancesApi` implements `ExtrinsicApi` protocol.

There is a default `ExtrinsicApi` implementation called `FrameExtrinsicApi` which can be used with `Frame` implementations.

```swift
public extension ExtrinsicApiRegistry where R.RC == MyConfig {
    var balances: FrameExtrinsicApi<R, MyBalancesFrame> { _frame() }
}
```
where `MyBalancesFrame` implements `Frame` protocol.

Then `ExtrinsicApi` should provide method to create transactions. `FrameExtrinsicApi` can be extended for this like:
```swift
extension FrameExtrinsicApi where R.RC == MyConfig, F == MyBalancesFrame {    
    func transferAllowDeath(
        dest: ST<R.RC>.Address, value: F.Types.Balance
    ) async throws -> Submittable<R, F.Call.TransferAllowDeath,
                                  ST<R.RC>.ExtrinsicUnsignedExtra>
    {
        try await api.tx.new(F.Call.TransferAllowDeath(dest: dest, value: value))
    }
}
```

This will allow calls like:
```swift
let tx = try await api.tx.balances.transferAllowDeath(dest: to, value: 12345)
```

## Constants
Extension point is a `ConstantsApiRegistry` and `ConstantsApi` protocol. Logic is the same as for Calls. For `Frame` types implementation is `FrameConstantsApi`.

Example extension implementation:
```swift
extension ConstantsApiRegistry where R.RC == MyConfig {
    var system: FrameConstantsApi<R, MySystemFrame> { _frame() }
}

extension FrameConstantsApi where R.RC == MyConfig, F == MySystemFrame {
    var blockWeights: F.Types.BlockWeights { get throws {
        try api.constants.get(F.Constant.BlockWeights.self)
    }}
}
```

This will provide API:
```swift
let weights = try api.constants.system.blockWeights
```

## Storage
Extension point is a `StorageApiRegistry` and `StorageApi` protocol. Logic is the same as for Calls and Constants. For `Frame` types implementation is `FrameStorageApi`.

Example implementation:
```swift
extension StorageApiRegistry where R.RC == MyConfig {
    var system: FrameStorageApi<R, MySystemFrame> { _frame() }
}

extension FrameStorageApi where R.RC == MyConfig, F == MySystemFrame {
    var account: StorageEntry<R, F.Storage.Account> { api.query.entry() }
}
```

Provides API:
```swift
// iteration
for try await (key, val) in substrate.query.system.account.entries() {
// ...
}
// value for key
let value = try await api.query.system.account.value(accountId)
```

## Runtime Call
Extension point is a `RuntimeCallApiRegistry` and `RuntimeCallApi` protocol. Logic is the same as for Calls and Constants. For `RuntimeApiFrame` type implementation is `FrameRuntimeCallApi`.

Example implementation:
```swift
extension RuntimeCallApiRegistry where R.RC == MyConfig {
    var transaction: FrameRuntimeCallApi<R, TransactionPaymentApi> { _frame() }
}

extension FrameRuntimeCallApi where R.RC == MyConfig,
                                    F == TransactionPaymentApi
{
    func queryInfo<C: Call>(extrinsic: ST<R.RC>.SignedExtrinsic<C>) async throws -> F.QueryInfo.TReturn {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: api.runtime)
        let call = F.QueryInfo(extrinsic: encoder.output)
        return try await api.call.execute(call: call)
    }
}
```

which can be used as:
```swift
let info = try await api.call.transaction.queryInfo(extrinsic: myTx)
```

## Events
Events API extension is slightly different. It's implemented like filtering API for `ExtrinsicEvents` structure.

Extension point is a `ExtrinsicEvents` structure itself, for which we should return `ExtrinsicEventsFilter` instance, which is filtering events by pallet.

This structure should return `ExtrinsicEventsEventFilter` structure for each event type.

For `Frame` events there is a default implementation `ExtrinsicEventsFrameFilter`.

Extension example:
```swift
 extension ExtrinsicEvents where R.RC == MyConfig {
    var system: ExtrinsicEventsFrameFilter<R, MySystemFrame> {
        _frame()
    }
}

extension ExtrinsicEventsFrameFilter where R.RC == MyConfig, F == MySystemFrame {
    var extrinsicSuccess: ExtrinsicEventsEventFilter<R, F.Event.ExtrinsicSuccess>  { _event() }
}
```

this enables api:
```swift
let success = try events.system.extrinsicSuccess.first
```