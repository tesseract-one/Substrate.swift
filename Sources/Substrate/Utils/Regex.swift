//
//  Regex.swift
//  
//
//  Created by Yehor Popovych on 08/07/2023.
//

import Foundation

public extension NSRegularExpression {
    @inlinable
    func matches(_ string: String,
                 options: NSRegularExpression.MatchingOptions = []) -> Bool {
        return firstMatch(in: string, options: options) != nil
    }
    
    @inlinable
    func enumerateMatches(
        in string: String, options: NSRegularExpression.MatchingOptions = [],
        using block: @escaping (NSTextCheckingResult?,
                                NSRegularExpression.MatchingFlags,
                                inout Bool) -> Void
    ) {
        let nsrange = NSRange(string.startIndex..<string.endIndex, in: string)
        enumerateMatches(in: string, options: options, range: nsrange) { (res, flags, bl) in
            var bool: Bool = bl.pointee.boolValue
            block(res, flags, &bool)
            bl.pointee = ObjCBool(bool)
        }
    }


    func numberOfMatches(in string: String,
                         options: NSRegularExpression.MatchingOptions = []) -> Int {
        let nsrange = NSRange(string.startIndex..<string.endIndex, in: string)
        return numberOfMatches(in: string, options: options, range: nsrange)
    }


    func rangeOfFirstMatch(in string: String,
                           options: NSRegularExpression.MatchingOptions = []) -> Range<String.Index> {
        let nsrange = NSRange(string.startIndex..<string.endIndex, in: string)
        let result = rangeOfFirstMatch(in: string, options: options, range: nsrange)
        return Range(result, in: string)!
    }
    
    @inlinable
    func firstMatch(in string: String,
                    options: NSRegularExpression.MatchingOptions = []) -> NSTextCheckingResult? {
        let nsrange = NSRange(string.startIndex..<string.endIndex, in: string)
        return firstMatch(in: string, options: options, range: nsrange)
    }
    
    @inlinable
    func matches(in string: String,
                 options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        let nsrange = NSRange(string.startIndex..<string.endIndex,
                              in: string)
        return matches(in: string, options: options, range: nsrange)
    }
}
