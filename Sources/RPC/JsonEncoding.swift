//
//  JsonEncoding.swift
//  
//
//  Created by Yehor Popovych on 10/28/20.
//

import Foundation

extension Formatter {
    public static let substrate_iso8601millis: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}

extension JSONDecoder.DateDecodingStrategy {
    public static let substrate_iso8601millis = formatted(.substrate_iso8601millis)
}

extension JSONEncoder.DateEncodingStrategy {
    public static let substrate_iso8601millis = formatted(.substrate_iso8601millis)
}


extension JSONDecoder.DataDecodingStrategy {
    public static let substrate_hex = custom { decoder in
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        guard let data = Hex.decode(hex: hex) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad Hex value")
        }
        return data
    }
}

extension JSONEncoder.DataEncodingStrategy {
    public static let substrate_prefixedHex = custom { data, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(Hex.encode(data: data, prefix: true)) 
    }
    
    public static let substrate_nonPrefixedHex = custom { data, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(Hex.encode(data: data, prefix: false))
    }
}


extension JSONEncoder {
    public static var substrate: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .substrate_prefixedHex
        encoder.dateEncodingStrategy = .substrate_iso8601millis
        encoder.nonConformingFloatEncodingStrategy = .throw
        return encoder
    }()
}

extension JSONDecoder {
    public static var substrate: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .substrate_hex
        decoder.dateDecodingStrategy = .substrate_iso8601millis
        decoder.nonConformingFloatDecodingStrategy = .throw
        return decoder
    }()
}
