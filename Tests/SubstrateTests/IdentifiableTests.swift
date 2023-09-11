//
//  IdentifiableTests.swift
//  
//
//  Created by Yehor Popovych on 10/09/2023.
//

import XCTest
@testable import Substrate

final class IdentifiableTests: XCTestCase {
    func testRecursiveInit() {
        let registry = TypeRegistry<TypeDefinition.TypeId>()
        let _ = registry.def(A.self)
        let _ = registry.def(B.self)
        let _ = registry.def(C.self)
    }
    
    func testEquatable() {
        let registry = TypeRegistry<TypeDefinition.TypeId>()
        let defC = registry.def(C.self)
        let defCC = registry.def(CC.self)
        let defCCC = registry.def(CCC.self)
        XCTAssertEqual(defC, defCC)
        XCTAssertNotEqual(defC, defCCC)
    }
    
    func testHashable() {
        let registry = TypeRegistry<TypeDefinition.TypeId>()
        let defC = registry.def(C.self)
        let defC2 = registry.def(C.self)
        let defA = registry.def(A.self)
        let defCC = registry.def(CC.self)
        XCTAssertEqual(defC.hashValue, defC2.hashValue)
        XCTAssertNotEqual(defC.hashValue, defCC.hashValue)
        XCTAssertNotEqual(defA.hashValue, defC.hashValue)
    }
    
    func testValidatable() throws {
        let registry = TypeRegistry<TypeDefinition.TypeId>()
        let defC = registry.def(C.self)
        let defCC = registry.def(CC.self)
        let defCCC = registry.def(CCC.self)
        try defC.validate(for: Self.self, as: defCC).get()
        try defC.validate(for: Self.self, as: defCCC).get()
    }
    
    final class A: IdentifiableType {
        public let b: [B]
        public let c: C?
        public let e: String?
        
        init(b: [B], c: C?, e: String?) {
            self.b = b
            self.c = c
            self.e = e
        }
        
        static func definition(in reg: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
            .composite(fields: [
                .kv("b", reg.def([B].self)),
                .kv("c", reg.def(C?.self)),
                .kv("e", reg.def(String?.self))
            ])
        }
    }
    
    final class B: IdentifiableType {
        public let aOrC: Either<A, C>
        public let fb: [B]
        public let co: [C?]
        
        init(aOrC: Either<A, C>, fb: [B], co: [C?]) {
            self.aOrC = aOrC
            self.fb = fb
            self.co = co
        }
        
        static func definition(in reg: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
            .composite(fields: [
                .kv("aOrC", reg.def(Either<A, C>.self)),
                .kv("fb", reg.def([B].self, .fixed(10))),
                .kv("co", reg.def([C?].self))
            ])
        }
    }
    
    public enum C: IdentifiableType {
        case a(A)
        case b(B)
        case d(Compact<UInt64>, [C])
        case e(String)
        case z
        
        public static func definition(in reg: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
            .variant(variants: [
                .s(0, "a", reg.def(A.self)),
                .s(2, "b", reg.def(B.self)),
                .m(3, "d", [reg.def(Compact<UInt64>.self), reg.def([C].self)]),
                .s(7, "e", reg.def(String.self)),
                .e(8, "z")
            ])
        }
    }
    
    public enum CC: IdentifiableType {
        case a(A)
        case b(B)
        case d(Compact<UInt64>, [C])
        case e(String)
        case z
        
        public static func definition(in reg: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
            .variant(variants: [
                .s(0, "a", reg.def(A.self)),
                .s(2, "b", reg.def(B.self)),
                .m(3, "d", [reg.def(Compact<UInt64>.self), reg.def([C].self)]),
                .s(7, "e", reg.def(String.self)),
                .e(8, "z")
            ])
        }
    }
    
    public enum CCC: IdentifiableType {
        case a(A)
        case b(B)
        case d(Compact<UInt32>, [CC])
        case e(String)
        case z
        
        public static func definition(in reg: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
            .variant(variants: [
                .s(0, "a", reg.def(A.self)),
                .s(2, "b", reg.def(B.self)),
                .m(3, "d", [reg.def(Compact<UInt32>.self), reg.def([C].self)]),
                .s(7, "e", reg.def(String.self)),
                .e(8, "z")
            ])
        }
    }
}
