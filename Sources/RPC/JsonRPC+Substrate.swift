//
//  JsonRPC+Substrate.swift
//  
//
//  Created by Yehor Popovych on 30.12.2022.
//

import Foundation
import Substrate
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
