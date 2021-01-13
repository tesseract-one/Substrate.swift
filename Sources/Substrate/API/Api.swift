//
//  Api.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc
import ScaleCodec

public protocol SubstrateApi {
    associatedtype S: SubstrateProtocol
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S)
}

extension SubstrateApi {
    public static var id: String { String(describing: self) }
    
    public func encode<V: ScaleDynamicEncodable, R>(value: V, _ errcb: SApiCallback<R>) -> Data? {
        do {
            let encoder = SCALE.default.encoder()
            try value.encode(in: encoder, registry: substrate.registry)
            return encoder.output
        } catch {
            errcb(.failure(.from(error: error)))
            return nil
        }
    }
    
    public func decode<V: ScaleDynamicDecodable, R>(_ t: V.Type, from data: Data, _ errcb: SApiCallback<R>) -> V? {
        do {
            let decoder = SCALE.default.decoder(data: data)
            return try V(from: decoder, registry: substrate.registry)
        } catch {
            errcb(.failure(.from(error: error)))
            return nil
        }
    }
}

public typealias SApiResult<R> = Result<R, SubstrateApiError>
public typealias SApiCallback<R> = (SApiResult<R>) -> Void

public enum SubstrateApiError: Error {
    case encoding(error: SEncodingError)
    case decoding(error: SDecodingError)
    case type(error: DTypeParsingError)
    case registry(error: TypeRegistryError)
    case rpc(error: RpcClientError)
    case unknown(error: Error)
    
    public static func from(error: Error) -> SubstrateApiError {
        switch error {
        case let e as SEncodingError: return .encoding(error: e)
        case let e as SDecodingError: return .decoding(error: e)
        case let e as RpcClientError: return .rpc(error: e)
        case let e as DTypeParsingError: return .type(error: e)
        case let e as TypeRegistryError: return .registry(error: e)
        default: return .unknown(error: error)
        }
    }
}
