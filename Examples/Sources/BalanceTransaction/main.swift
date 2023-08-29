import Foundation
import Substrate
import SubstrateRPC
import SubstrateKeychain
import Bip39

// Json RPC client for local node
let client = JsonRpcClient(.ws(url: URL(string: "ws://127.0.0.1:9944")!,
                               maximumMessageSize: 16*1024*1024)) // 16 Mb messages
// Enable if you want to see rpc request logs
// client.debug = true

print("Initialization...")

// Api instance for local node with Dynamic config and RPC client.
let api = try await Api(rpc: client, config: .dynamic)

print("=======\nTransfer Transaction\n=======")

// Root key pair with developer test phrase
let rootKeyPair = try Sr25519KeyPair(phrase: DEFAULT_DEV_PHRASE)

// Derived key for Alice
let alice = try rootKeyPair.derive(path: [PathComponent(string: "/Alice")])
// Derived key for Bob
let bob = try rootKeyPair.derive(path: [PathComponent(string: "/Bob")])
// Obtain address from PublicKey
let to = try bob.address(in: api)

// Dynamic call for transfer
let call = AnyCall(name: "transfer_allow_death",
                   pallet: "Balances",
                   params: ["dest": to, "value": 15483812850])

// Create new transaction from call
let tx = try await api.tx.new(call)

// Sign it and submit. Wait for success
let events = try await tx.signSendAndWatch(signer: alice)
    .waitForFinalized()
    .success()

// Parsed events
for event in try events.parsed() {
    print(event)
}

print("=======\nEnd of Transfer Transaction\n=======\n")
