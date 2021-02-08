#!/usr/bin/env swift

import Foundation

let TAB_SIZE: Int = 4

func generate_struct_name(for size: Int) -> String {
    return "STuple\(size)"
}

func generate_list(for size: Int, prefix: String, inc: Int) -> String {
    return stride(from: 0, to: size, by: 1)
        .map { "\(prefix)\($0 + inc)" }
        .joined(separator: ", ")
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

func generate_encode_calls(for size: Int, encVar: String, regVar: String, tab: Int) -> String {
    let prefix = String(repeating: " ", count: tab * TAB_SIZE)
    return stride(from: 0, to: size, by: 2)
        .map { yI in
            stride(from: 0, to: min(size - yI, 2), by: 1)
                .map { "try _\($0+yI).encode(in: \(encVar), registry: \(regVar))" }
                .joined(separator: "; ")
        }
        .joined(separator: "\n" + prefix)
}

func generate_decode_calls(for size: Int, decVar: String, regVar: String, tab: Int) -> String {
    let prefix = String(repeating: " ", count: tab * TAB_SIZE)
    return stride(from: 0, to: size, by: 3)
        .map { yI in
            stride(from: 0, to: min(size - yI, 3), by: 1)
                .map { "T\($0+yI+1)(from: \(decVar), registry: \(regVar))" }
                .joined(separator: ", ")
        }
        .joined(separator: ",\n" + prefix)
}

func generate_storage_vars(for size: Int, tab: Int) -> String {
    let prefix = String(repeating: " ", count: tab * TAB_SIZE)
    return stride(from: 0, to: size, by: 1)
        .map { "public let _\($0): T\($0 + 1)" }
        .joined(separator: "\n" + prefix)
}

func generate_tuple(for size: Int) -> String {
    let name = generate_struct_name(for: size)
    let encWhereList = generate_where_type_list(for: size, proto: "ScaleDynamicEncodable", tab: 2)
    return """
    extension \(name): ScaleDynamicEncodable
        where
            \(encWhereList)
    {
        public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
            \(generate_encode_calls(for: size, encVar: "encoder", regVar: "registry", tab: 2))
        }
    }
    
    extension \(name): ScaleDynamicEncodableArrayMaybeConvertible
        where
            \(encWhereList)
    {
        public var encodableArray: Array<ScaleDynamicEncodable>? {
            [\(generate_list(for: size, prefix: "_", inc: 0))]
        }
    }

    extension \(name): ScaleDynamicDecodable
        where
            \(generate_where_type_list(for: size, proto: "ScaleDynamicDecodable", tab: 2))
    {
        public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
            try self.init(
                \(generate_decode_calls(for: size, decVar: "decoder", regVar: "registry", tab: 3))
            )
        }
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
