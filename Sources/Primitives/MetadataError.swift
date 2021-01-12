//
//  MetadataError.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation

public enum MetadataError: Error {
    case typeNotFound(DType)
    case moduleNotFound(name: String)
    case moduleNotFound(index: UInt8)
    case eventNotFound(module: String, event: String)
    case callNotFound(module: String, function: String)
    case storageItemNotFound(prefix: String, item: String)
    case storageItemBadPathTypes(prefix: String, item: String, path: [ScaleDynamicEncodable], expected: [DType])
}
