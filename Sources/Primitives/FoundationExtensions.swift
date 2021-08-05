//
//  FoundationExtension.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec

extension NSRegularExpression {
    public func replacingMatches(
        in source: String,
        options: MatchingOptions,
        matcher: @escaping (NSTextCheckingResult) -> String?
    ) -> String {
        var result = ""
        var lastIndex = source.startIndex
        enumerateMatches(
            in: source,
            options: options,
            range: NSRange(location: 0, length: source.count)
        ) { (match, _, _) in
            guard let match = match else { return }
            let start = source.index(source.startIndex, offsetBy: match.range.location)
            let end = source.index(start, offsetBy: match.range.length)
            result += source[lastIndex..<start]
            if let replacement = matcher(match) {
                result += replacement
            } else {
                result += source[start..<end]
            }
            lastIndex = end
        }
        result += source[lastIndex...]
        return result
    }
}


extension String {
    public func substr(from: Int, length: Int) -> Substring {
        guard length > 0 else { return "" }
        return substr(from: from, to: from + length - 1)
    }
    
    public func substr(from: Int, maxLength: Int) -> Substring {
        let to = (from + maxLength) > count ? count : from + maxLength
        return substr(from: from, to: to - 1)
    }
    
    public func substr(from: Int, to: Int? = nil) -> Substring {
        let to = to ?? count - 1
        guard from <= to else { return "" }
        let start = index(startIndex, offsetBy: from)
        let end = index(startIndex, offsetBy: to)
        return self[start...end]
    }
    
    public func substr(from: Int, removing: Int) -> Substring {
        let start = index(startIndex, offsetBy: from)
        let end = index(endIndex, offsetBy: -removing)
        return self[start..<end]
    }
    
    public func char(at index: Int) -> Character? {
        guard index >= 0 && index < count else {
            return nil
        }
        return self[self.index(startIndex, offsetBy: index)]
    }
}

extension CodingUserInfoKey {
    public static let typeRegistry = Self(rawValue: "SubstrateTypeRegistry")!
}

extension Decoder {
    public var typeRegistry: TypeRegistryProtocol? {
        if let registry = userInfo[.typeRegistry] as? TypeRegistryProtocol? {
            return registry
        }
        return nil
    }
}

public struct NoError: Error {}

extension Result {
    public func pour(queue: DispatchQueue? = nil, error cb: @escaping (Failure) -> Void) -> Result<Success, NoError> {
        self.mapError { err in
            if let queue = queue {
                queue.async { cb(err) }
            } else {
                cb(err)
            }
            return NoError()
        }
    }
    
    public func pour<V>(queue: DispatchQueue? = nil, error cb: @escaping (Result<V, Failure>) -> Void) -> Result<Success, NoError> {
        self.pour(queue: queue) { cb(.failure($0)) }
    }
}

extension Result where Failure == NoError {
    public func onSuccess(_ cb: @escaping (Success) throws -> Void) rethrows {
        switch self {
        case .failure: return
        case .success(let ok): try cb(ok)
        }
    }
}
