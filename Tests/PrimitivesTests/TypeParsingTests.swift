//
//  TypeParsingTests.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import XCTest

#if !COCOAPODS
@testable import SubstratePrimitives
#else
@testable import Substrate
#endif

final class TypeParsingTests: XCTestCase {
    func testVectorParsing() {
        let type = try? DType(parse: "Vec<Bool>")
        XCTAssertNotNil(type, "Can't parse Vec type definition")
        XCTAssertEqual(type, .collection(element: .type(name: "Bool")))
    }
    
    func testSliceParcing() {
        // TODO: Should parse "&[Bool]"
        let type = try? DType(parse: "[Bool]")
        XCTAssertNotNil(type, "Can't parse Slice type definition")
        XCTAssertEqual(type, .collection(element: .type(name: "Bool")))
    }
    
    func testFixedArrayParcing() {
        let type = try? DType(parse: "[Bool; 25]")
        XCTAssertNotNil(type, "Can't parse fixed array type definition")
        XCTAssertEqual(type, .fixed(type: .type(name: "Bool"), count: 25))
    }
    
    func testTupleParsing() {
        let type = try? DType(parse: "(Bool, UInt8, String)")
        XCTAssertNotNil(type, "Can't parse tuple type definition")
        XCTAssertEqual(
            type,
            .tuple(elements: [.type(name: "Bool"), .type(name: "UInt8"), .type(name: "String")])
        )
    }
    
    func testNestedTupleParsing() {
        let type = try? DType(parse: "((Bool, Data), UInt8, String)")
        XCTAssertNotNil(type, "Can't parse nested tuple type definition")
        XCTAssertEqual(
            type,
            .tuple(elements: [
                .tuple(elements: [.type(name: "Bool"),
                                  .type(name: "Data")]),
                .type(name: "UInt8"),
                .type(name: "String")]
            )
        )
    }
    
    func testMapParsing() {
        let type = try? DType(parse: "HashMap<String, Bool>")
        XCTAssertNotNil(type, "Can't parse Map type definition")
        XCTAssertEqual(type, .map(key: .type(name: "String"), value: .type(name: "Bool")))
    }
    
    func testResultParsing() {
        let type = try? DType(parse: "Result<Bool, String>")
        XCTAssertNotNil(type, "Can't parse Result type definition")
        XCTAssertEqual(type, .result(success: .type(name: "Bool"), error: .type(name: "String")))
    }
    
    func testCompoundType() {
        let type = try? DType(parse: "Account<UInt64, String>")
        XCTAssertNotNil(type, "Can't parse compound type definition")
        XCTAssertEqual(type, .type(name: "Account"))
    }
    
    func testDoNotConstructParsing() {
        let type = try? DType(parse: "DoNotConstruct<A>")
        XCTAssertNotNil(type, "Can't parse DoNotConstruct type definition")
        XCTAssertEqual(type, .doNotConstruct(type: .type(name: "A")))
        
        let type2 = try? DType(parse: "DoNotConstruct<>")
        XCTAssertNotNil(type2, "Can't parse DoNotConstruct type definition")
        XCTAssertEqual(type2, .doNotConstruct(type: .null))
        
        let type3 = try? DType(parse: "DoNotConstruct")
        XCTAssertNotNil(type3, "Can't parse DoNotConstruct type definition")
        XCTAssertEqual(type3, .doNotConstruct(type: .null))
    }
    
    func testNestedSliceParcing() {
        
    }
    
    func testNestedFixedArrayParcing() {
        
    }
}
