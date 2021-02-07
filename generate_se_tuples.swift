#!/usr/bin/env swift

import Foundation

let TAB_SIZE: Int = 4

func generate_struct_name(for size: Int) -> String {
    return "STuple\(size)"
}

func generate_where_type_list(for size: Int, proto: String, tab: Int) -> String {
    let prefix = String(repeating: " ", count: tab * TAB_SIZE)
    return stride(from: 0, to: size, by: 4)
        .map { yI in
            stride(from: 0, to: min(size - yI, 4), by: 1)
                .map { "T\($0+yI+1): \(proto)" }
                .joined(separator: ", ")
        }
        .joined(separator: ",\n" + prefix)
}

func generate_payload_type_list(for size: Int, field: String, tab: Int) -> String {
    let prefix = String(repeating: " ", count: tab * TAB_SIZE)
    return stride(from: 0, to: size, by: 3)
        .map { yI in
            stride(from: 0, to: min(size - yI, 3), by: 1)
                .map { "T\($0+yI+1).\(field)" }
                .joined(separator: ", ")
        }
        .joined(separator: ",\n" + prefix)
}

func generate_identifier_calls(for size: Int, arrayVar: String, tab: Int) -> String {
    let prefix = String(repeating: " ", count: tab * TAB_SIZE)
    return stride(from: 0, to: size, by: 2)
        .map { yI in
            stride(from: 0, to: min(size - yI, 2), by: 1)
                .map { "\(arrayVar).append(contentsOf: _\($0+yI).identifier)" }
                .joined(separator: "; ")
        }
        .joined(separator: "\n" + prefix)
}

func generate_additional_payload_calls(for size: Int, tab: Int) -> String {
    let prefix = String(repeating: " ", count: tab * TAB_SIZE)
    return stride(from: 0, to: size, by: 3)
        .map { yI in
            stride(from: 0, to: min(size - yI, 3), by: 1)
                .map { "_\($0+yI).additionalSignedPayload()" }
                .joined(separator: ", ")
        }
        .joined(separator: ",\n" + prefix)
}

func generate_tuple(for size: Int) -> String {
    let name = generate_struct_name(for: size)
    return """
    extension \(name): SignedExtension
        where
            \(generate_where_type_list(for: size, proto: "SignedExtension", tab: 2))
    {
        public typealias AdditionalSignedPayload = \(name)<
            \(generate_payload_type_list(for: size, field: "AdditionalSignedPayload", tab: 2))
        >
    
        public var identifier: [String] {
            var identifiers = Array<String>()
            \(generate_identifier_calls(for: size, arrayVar: "identifiers", tab: 2))
            return identifiers
        }
    
        public func additionalSignedPayload() throws -> AdditionalSignedPayload {
            return try AdditionalSignedPayload(
                \(generate_additional_payload_calls(for: size, tab: 3))
            )
        }
    
        public static var IDENTIFIER: String { "" }
    }
    """
}

// MAIN
let strFrom = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "2"
let strTo = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : strFrom
let from = Int(strFrom)!
let to = Int(strTo)!
let name = CommandLine.arguments[0].split(separator: "/").last!.split(separator: "\\").last!
print("//\n// Generated '\(Date())' with '\(name)'\n//")
print("import Foundation")
print("import ScaleCodec")
for i in from...to {
    print("")
    print(generate_tuple(for: i))
}
