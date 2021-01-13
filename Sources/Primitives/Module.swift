//
//  Module.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

public protocol TypeRegistrator {
    func registerEventsCallsAndTypes<R: TypeRegistryProtocol>(in registry: R) throws
}

public protocol ModuleProtocol: TypeRegistrator {
    associatedtype Frame
    
    static var NAME: String { get }
}

open class PrimitivesModule<S>: ModuleProtocol {
    public typealias Frame = S
    
    public static var NAME: String { "_Primitives" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
        try registry.register(type: UInt8.self, as: .type(name: "u8"))
        try registry.register(type: UInt16.self, as: .type(name: "u16"))
        try registry.register(type: UInt32.self, as: .type(name: "u32"))
        try registry.register(type: UInt64.self, as: .type(name: "u64"))
        try registry.register(type: SUInt128.self, as: .type(name: "u128"))
        try registry.register(type: SUInt256.self, as: .type(name: "u256"))
        try registry.register(type: SUInt512.self, as: .type(name: "u512"))
        try registry.register(type: Int8.self, as: .type(name: "i8"))
        try registry.register(type: Int16.self, as: .type(name: "i16"))
        try registry.register(type: Int32.self, as: .type(name: "i32"))
        try registry.register(type: Int64.self, as: .type(name: "i64"))
        try registry.register(type: SInt128.self, as: .type(name: "i128"))
        try registry.register(type: SInt256.self, as: .type(name: "i256"))
        try registry.register(type: SInt512.self, as: .type(name: "i512"))
        try registry.register(type: SCompact<UInt8>.self, as: .compact(type: .type(name: "u8")))
        try registry.register(type: SCompact<UInt16>.self, as: .compact(type: .type(name: "u16")))
        try registry.register(type: SCompact<UInt32>.self, as: .compact(type: .type(name: "u32")))
        try registry.register(type: SCompact<UInt64>.self, as: .compact(type: .type(name: "u64")))
        try registry.register(type: SCompact<SUInt128>.self, as: .compact(type: .type(name: "u128")))
        try registry.register(type: SCompact<SUInt256>.self, as: .compact(type: .type(name: "u256")))
        try registry.register(type: SCompact<SUInt512>.self, as: .compact(type: .type(name: "u512")))
        try registry.register(type: Data.self, as: .type(name: "Bytes"))
        try registry.register(type: String.self, as: .type(name: "String"))
        try registry.register(type: DNull.self, as: .type(name: "Null"))
        try registry.register(type: Moment.self, as: .type(name: "Moment"))
        try registry.register(type: BitVec.self, as: .type(name: "BitVec"))
    }
}
