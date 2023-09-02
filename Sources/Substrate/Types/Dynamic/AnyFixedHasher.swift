//
//  AnyFixedHasher.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation

public struct AnyFixedHasher: FixedHasher, Equatable {
    public enum HashType: Equatable, Hashable {
        case blake2b128
        case blake2b256
        case blake2b512
        case xx128
        case xx256
        
        public init?(name: String) {
            switch name.lowercased() {
            case "blake2b128", "blaketwo128": self = .blake2b128
            case "blake2b256", "blaketwo256": self = .blake2b256
            case "blake2b512", "blaketwo512": self = .blake2b512
            case "xx128", "twox128": self = .xx128
            case "xx256", "twox256": self = .xx256
            default: return nil
            }
        }
        
        public var hasher: any Hasher {
            switch self {
            case .xx256: return HXX256.instance
            case .xx128: return HXX128.instance
            case .blake2b128: return HBlake2b128.instance
            case .blake2b256: return HBlake2b256.instance
            case .blake2b512: return HBlake2b512.instance
            }
        }
    }
    
    public typealias THash = AnyHash
    
    public let hasher: any Hasher
    
    public init?(name: String) {
        guard let type = HashType(name: name) else {
            return nil
        }
        self.init(type: type)
    }
    
    public init(type: HashType) {
        self.hasher = type.hasher
    }
    
    public func hash(data: Data, runtime: any Runtime) throws -> THash {
        try runtime.create(hash: THash.self, raw: hasher.hash(data: data))
    }
    
    @inlinable
    public var name: String { hasher.name }
    @inlinable
    public var hashPartByteLength: Int { hasher.hashPartByteLength }
    @inlinable
    public var bitWidth: Int { hasher.hashPartByteLength * 8 }
    @inlinable
    public func hash(data: Data) -> Data { hasher.hash(data: data) }
    
    public static func == (lhs: AnyFixedHasher, rhs: AnyFixedHasher) -> Bool {
        lhs.name == rhs.name
    }
    
    public static func validate(runtime: Runtime,
                                type id: NetworkType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let name = info.path.last, HashType(name: name) != nil else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return .success(())
    }
}
