//
//  BitSequence.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation
import ScaleCodec

public struct BitSequence: RandomAccessCollection, RangeReplaceableCollection,
                           MutableCollection, Hashable, Equatable, CustomStringConvertible
{
    private var storage: [Bool]
    
    public typealias Index = Int
    public typealias Element = Bool
    
    public var startIndex: Int { storage.startIndex }
    public var endIndex: Int { storage.endIndex }
    
    public init() {
        self.storage = []
    }
    
    public init(minimumCapacity n: Int) {
        self.init()
        storage.reserveCapacity(n)
    }
    
    public subscript(position: Int) -> Bool {
        get { storage[position] }
        set { storage[position] = newValue }
    }
    
    public mutating func replaceSubrange<C: Collection>(
        _ subrange: Range<Int>, with newElements: C
    ) where C.Element == Self.Element {
        storage.replaceSubrange(subrange, with: newElements)
    }
    
    public mutating func reserveCapacity(_ n: Int) {
        storage.reserveCapacity(n)
    }
    
    public var description: String {
        storage.description
    }
}

extension BitSequence {
    public struct Format: Hashable, Equatable {
        public enum Order: Hashable, Equatable {
            /// Least significant bit first.
            case lsb0
            /// Most significant bit first.
            case msb0
        }
        
        public enum Store: UInt8, Hashable, Equatable {
            case u8 = 8
            case u16 = 16
            case u32 = 32
            case u64 = 64
        }
        
        public enum Error: Swift.Error {
            case storeFormatNotFound(NetworkType.Id)
            case orderFormatNotFound(NetworkType.Id)
            case storeFormatNotSupported(NetworkType)
            case orderFormatNotSupported(NetworkType)
        }
        
        public let store: Store
        public let order: Order
        
        public init(store: Store, order: Order) {
            self.store = store
            self.order = order
        }
    }
}

extension BitSequence {
    public init<U: UnsignedInteger & FixedWidthInteger>(count: Int, storage: [U], order: Format.Order) {
        guard count > 0 else {
            self.init()
            return
        }
        let bits = MemoryLayout<U>.size * 8
        precondition(count <= storage.count * bits,
                     "Too many bits for \(storage.count) \(U.self) values")
        var count = count
        var bools: [Bool] = []
        bools.reserveCapacity(count)
        for uint in storage {
            let left = Swift.min(count, bits)
            let range = order == .lsb0
                ? stride(from: 0, through: left - 1, by: 1)
                : stride(from: bits - 1, through: bits - left, by: -1)
            for bit in range {
                bools.append((uint >> bit) & 1 == 1)
            }
            count -= left
        }
        self.init(bools)
    }
    
    public init(bits: [Bool], order: Format.Order) {
        switch order {
        case .lsb0: self.init(bits)
        case .msb0: self.init(bits.reversed())
        }
    }
    
    public func store<U: UnsignedInteger & FixedWidthInteger>(order: Format.Order) -> [U] {
        guard count > 0 else { return [] }
        switch order {
        case .lsb0: return _storeLSB()
        case .msb0: return _storeMSB()
        }
    }
    
    public func store<U: UnsignedInteger & FixedWidthInteger>(order: Format.Order, _ type: U.Type) -> [U] {
        self.store(order: order)
    }
    
    private func _storeLSB<U: UnsignedInteger & FixedWidthInteger>() -> [U] {
        let bits = MemoryLayout<U>.size * 8
        var store: [U] = []
        store.reserveCapacity(count.isMultiple(of: bits) ? count / bits : count / bits + 1)
        var value: U = 0
        var bitPosition: Int = 0
        for bool in self {
            value |= (bool ? 1 : 0) << bitPosition
            bitPosition += 1
            if bitPosition == bits {
                bitPosition = 0
                store.append(value)
                value = 0
            }
        }
        if bitPosition > 0 {
            store.append(value)
        }
        return store
    }
    
    private func _storeMSB<U: UnsignedInteger & FixedWidthInteger>() -> [U] {
        let bits = MemoryLayout<U>.size * 8
        var store: [U] = []
        store.reserveCapacity(count.isMultiple(of: bits) ? count / bits : count / bits + 1)
        var value: U = 0
        var bitPosition = bits - 1
        for bool in self {
            value |= (bool ? 1 : 0) << bitPosition
            if bitPosition == 0 {
                bitPosition = bits
                store.append(value)
                value = 0
            }
            bitPosition -= 1
        }
        if bitPosition < bits - 1 {
            store.append(value)
        }
        return store
    }
}

extension BitSequence {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, format: Format) throws {
        let bitCount = try decoder.decode(UInt32.self, .compact)
        let count = bitCount.isMultiple(of: format.store.bits)
            ? bitCount / format.store.bits
            : bitCount / format.store.bits + 1
        switch format.store {
        case .u8:
            try self.init(count: Int(bitCount),
                          storage: decoder.decode([UInt8].self, .fixed(UInt(count))),
                          order: format.order)
        case .u16:
            try self.init(count: Int(bitCount),
                          storage: decoder.decode([UInt16].self, .fixed(UInt(count))),
                          order: format.order)
        case .u32:
            try self.init(count: Int(bitCount),
                          storage: decoder.decode([UInt32].self, .fixed(UInt(count))),
                          order: format.order)
        case .u64:
            try self.init(count: Int(bitCount),
                          storage: decoder.decode([UInt64].self, .fixed(UInt(count))),
                          order: format.order)
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, format: Format) throws {
        try encoder.encode(UInt32(count), .compact)
        switch format.store {
        case .u8:
            let vals = store(order: format.order, UInt8.self)
            try encoder.encode(vals, .fixed(UInt(vals.count)))
        case .u16:
            let vals = store(order: format.order, UInt16.self)
            try encoder.encode(vals, .fixed(UInt(vals.count)))
        case .u32:
            let vals = store(order: format.order, UInt32.self)
            try encoder.encode(vals, .fixed(UInt(vals.count)))
        case .u64:
            let vals = store(order: format.order, UInt64.self)
            try encoder.encode(vals, .fixed(UInt(vals.count)))
        }
    }
}

extension BitSequence.Format {
    public init(store: NetworkType.Id, order: NetworkType.Id, runtime: Runtime) throws {
        try self.init(store: Store(type: store, runtime: runtime),
                      order: Order(type: order, runtime: runtime))
    }
    public static let u8msb0 = Self(store: .u8, order: .msb0)
    public static let u8lsb0 = Self(store: .u8, order: .lsb0)
    public static let u16msb0 = Self(store: .u16, order: .msb0)
    public static let u16lsb0 = Self(store: .u16, order: .lsb0)
    public static let u32msb0 = Self(store: .u32, order: .msb0)
    public static let u32lsb0 = Self(store: .u32, order: .lsb0)
    public static let u64msb0 = Self(store: .u64, order: .msb0)
    public static let u64lsb0 = Self(store: .u64, order: .lsb0)
}

extension BitSequence.Format.Store {
    public init(type: NetworkType.Id, runtime: Runtime) throws {
        guard let bitStore = runtime.resolve(type: type) else {
            throw BitSequence.Format.Error.storeFormatNotFound(type)
        }
        switch bitStore.definition {
        case .primitive(is: .u8): self = .u8
        case .primitive(is: .u16): self = .u16
        case .primitive(is: .u32): self = .u32
        case .primitive(is: .u64): self = .u64
        default: throw BitSequence.Format.Error.storeFormatNotSupported(bitStore)
        }
    }
    
    public var bits: UInt32 {
        UInt32(self.rawValue)
    }
}

extension BitSequence.Format.Order {
    public init(type: NetworkType.Id, runtime: Runtime) throws {
        guard let orderStore = runtime.resolve(type: type) else {
            throw BitSequence.Format.Error.orderFormatNotFound(type)
        }
        switch orderStore.path.last {
        case .some("Lsb0"): self = .lsb0
        case .some("Msb0"): self = .msb0
        default: throw BitSequence.Format.Error.orderFormatNotSupported(orderStore)
        }
    }
}

extension CustomEncoderFactory where T == BitSequence {
    public static func format(_ format: BitSequence.Format) -> CustomEncoderFactory {
        CustomEncoderFactory { encoder, val in
            try val.encode(in: &encoder, format: format)
        }
    }
}

extension CustomDecoderFactory where T == BitSequence {
    public static func format(_ format: BitSequence.Format) -> CustomDecoderFactory {
        CustomDecoderFactory { decoder in
            try BitSequence(from: &decoder, format: format)
        }
    }
}

extension BitSequence: ValueRepresentable {
    public func asValue(runtime: Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        try Self.validate(runtime: runtime, type: type).getValueError()
        return .bits(self, type)
    }
}

extension BitSequence: RuntimeDynamicValidatable {
    public static func validate(runtime: Runtime,
                                type id: NetworkType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard info.isBitSequence(runtime) else {
            return .failure(.wrongType(got: info, for: "BitSequence"))
        }
        return .success(())
    }
}
