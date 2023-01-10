//
//  JsonRPC+Substrate.swift
//  
//
//  Created by Yehor Popovych on 30.12.2022.
//

import Foundation
import JsonRPC

extension JSONEncoder {
    public static var substrate: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .prefixedHex
        encoder.dateEncodingStrategy = .iso8601withFractionalSeconds
        encoder.nonConformingFloatEncodingStrategy = .throw
        return encoder
    }()
}

extension JSONDecoder {
    public static var substrate: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .hex
        decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
        decoder.nonConformingFloatDecodingStrategy = .throw
        return decoder
    }()
}

extension CodingUserInfoKey {
    public static let registry = CodingUserInfoKey(rawValue: "SubstrateTypeRegistry")!
}

extension ContentEncoder {
    public var registry: Registry {
        get { context[.registry]! as! Registry }
        set { context[.registry] = newValue }
    }
}

extension ContentDecoder {
    public var registry: Registry {
        get { context[.registry]! as! Registry }
        set { context[.registry] = newValue }
    }
}

public func RpcClient<Factory: ServiceFactory>(_ cfp: ServiceFactoryProvider<Factory>, queue: DispatchQueue, encoder: ContentEncoder = JSONEncoder.substrate, decoder: ContentDecoder = JSONDecoder.substrate) -> SubscribableRpcClient where Factory.Connection: PersistentConnection, Factory.Delegate == AnyObject {
    SubscribableRpcClient(client: JsonRpc(cfp, queue: queue, encoder: encoder, decoder: decoder), delegate: nil)
}

public func RpcClient<Factory: ServiceFactory>(_ cfp: ServiceFactoryProvider<Factory>, queue: DispatchQueue, encoder: ContentEncoder = JSONEncoder.substrate, decoder: ContentDecoder = JSONDecoder.substrate) -> CallableRpcClient where Factory.Connection: SingleShotConnection {
    CallableRpcClient(client: JsonRpc(cfp, queue: queue, encoder: encoder, decoder: decoder))
}
