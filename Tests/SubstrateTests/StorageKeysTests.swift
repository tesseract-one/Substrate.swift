//
//  StorageKeysTests.swift
//  
//
//  Created by Yehor Popovych on 15/07/2023.
//

import XCTest
import ScaleCodec
@testable import Substrate

final class StorageKeysTests: XCTestCase {
    func runtime() throws -> ExtendedRuntime<DynamicConfig> {
        let data = Resources.inst.metadadav15()
        let opaq = try ScaleCodec.decode(Optional<OpaqueMetadata>.self, from: data)!
        let versioned = try ScaleCodec.decode(VersionedMetadata.self, from: opaq.raw)
        let metadata = try versioned.metadata.asMetadata()
        return try ExtendedRuntime(config: try DynamicConfig(),
                                   metadata: metadata,
                                   metadataHash: nil,
                                   genesisHash: AnyHash(unchecked: Data()),
                                   version: AnyRuntimeVersion(specVersion: 0,
                                                              transactionVersion: 4,
                                                              other: [:]),
                                   properties: AnySystemProperties(ss58Format: .substrate,
                                                                   other: [:]))
    }
    
    func testEncDecAnyKey() throws {
        let keys = [
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a000003adc196911e491e08264834504a64ace1373f0c8ed5d57381ddf54a2f67a318fa42b1352681606d",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a000016d5103a6adeae4fc21ad1e5198cc0dc3b0f9f43a50f292678f63235ea321e59385d7ee45a720836",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00002a47718370fccca6c6332dd72fc6d33bf202a531e66cfaf46e6161640f91864f23f82b31b38c5f11",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00003635b95e2a31e59704b42c45250880695e6cec68c5adce35a0e2ec60ed46b77b734ad6020b991658",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00003ecb31e90f8870f218164fa6f9ce28792fb781185e8de4e6eaae34c0f545e5864952fe23c183df0c",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00004245138345ca3fd8aebb0211dbb07b4d335a657257b8ac5e53794c901e4f616d4a254f2490c43934",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00004f0f0dc89f14ad14767f36484b1e2acf5c265c7a64bfb46e95259c66a8189bbcd216195def436852"
        ]
        
        let runtime = try self.runtime()
        
        for hex in keys {
            var decoder = ScaleCodec.decoder(from: Data(hex: hex)!)
            let key = try AnyValueStorageKey(from: &decoder,
                                             base: (name: "ErasStakers", pallet: "Staking"),
                                             runtime: runtime)
            XCTAssertEqual(key.hash.hex(), hex)
        }
    }
}
