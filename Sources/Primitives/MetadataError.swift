//
//  MetadataError.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation

public enum MetadataError: Error {
    case typeNotFound(DType)
    case typeParsingError(error: DTypeParsingError)
    case moduleNotFound(name: String)
    case moduleNotFound(index: UInt8)
    case eventNotFound(module: String, index: UInt8)
    case eventNotFound(module: String, event: String)
    case callNotFound(module: String, function: String)
    case callNotFound(module: String, index: UInt8)
    case storageItemNotFound(prefix: String, item: String)
    case constantNotFound(module: String, name: String)
    case unknown(error: Error)
}

extension DType {
    // Helper method for proper error propagation
    public static func fromMeta(type: String) throws -> DType {
        do {
            return try DType(parse: type)
        } catch let e as DTypeParsingError {
            throw MetadataError.typeParsingError(error: e)
        } catch {
            throw MetadataError.unknown(error: error)
        }
    }
}
