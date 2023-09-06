//
//  ErrorMethodInfo.swift
//  
//
//  Created by Yehor Popovych on 06/09/2023.
//

import Foundation

public struct ErrorMethodInfo: Equatable, Hashable, Codable,
                               CustomDebugStringConvertible
{
#if DEBUG || ERROR_METHOD_INFO
    public let file: String
    public let function: String
    public let line: Int
    
    @inlinable
    public init(file: String, line: Int, function: String)
    {
        self.file = file
        self.line = line
        self.function = function
    }
    
    public static func get(file: String = #file,
                           line: Int = #line,
                           function: String = #function) -> Self
    {
        Self(file: file, line: line, function: function)
    }
    
    @inlinable
    public var debugDescription: String {
        "\(file):\(function):\(line)"
    }
#else
    @inlinable
    public init() {}
    
    @inlinable
    public static func get() -> Self { Self() }
    
    @inlinable
    public var debugDescription: String { "" }
#endif
}
