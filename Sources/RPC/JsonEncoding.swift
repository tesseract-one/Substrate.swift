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

extension JSONEncoder {
    public static var substrate: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .substrate_iso8601millis
        encoder.nonConformingFloatEncodingStrategy = .throw
        return encoder
    }()
}

extension JSONDecoder {
    public static var substrate: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .substrate_iso8601millis
        decoder.nonConformingFloatDecodingStrategy = .throw
        return decoder
    }()
}
