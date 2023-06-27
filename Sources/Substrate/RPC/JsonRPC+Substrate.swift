//
//  JsonRPC+Substrate.swift
//  
//
//  Created by Yehor Popovych on 30.12.2022.
//

import Foundation
import JsonRPC
@_exported import func JsonRPC.Params

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
    public static let substrateRuntime = CodingUserInfoKey(rawValue: "SubstrateRuntimeKey")!
}

extension Encoder {
    public var runtime: any Runtime { userInfo[.substrateRuntime]! as! any Runtime }
}

extension Decoder {
    public var runtime: any Runtime { userInfo[.substrateRuntime]! as! any Runtime }
}

extension ContentEncoder {
    public var runtime: any Runtime {
        get { context[.substrateRuntime]! as! any Runtime }
        set { context[.substrateRuntime] = newValue }
    }
}

extension ContentDecoder {
    public var runtime: any Runtime {
        get { context[.substrateRuntime]! as! any Runtime }
        set { context[.substrateRuntime] = newValue }
    }
}
