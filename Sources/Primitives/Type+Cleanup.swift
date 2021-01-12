//
//  Type+Cleanup.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

extension DType {
    static func cleanup(string: String, allowNamespaces: Bool = false) throws -> String {
        let options = Options(allowNamespaces: allowNamespaces)
        return try MAPPINGS.reduce(string.trimmingCharacters(in: .whitespacesAndNewlines)) { (result, fn) in
            try fn(result, options)
        }
    }
    
    static func typeSplit(type: String) throws -> [String] {
        var result = [String]()
        var cDepth = 0; var fDepth = 0; var sDepth = 0; var tDepth = 0
        var start = type.index(type.startIndex, offsetBy: 0)
        
        let isNotNested = { (counters: [Int]) -> Bool in
            !counters.contains { $0 != 0 }
        }
        
        let extract = { (index: String.Index) in
            if isNotNested([cDepth, fDepth, sDepth, tDepth]) {
                result.append(type[start..<index].trimmingCharacters(in: .whitespacesAndNewlines))
                start = type.index(index, offsetBy: 1)
            }
        }
        
        for index in type.indices {
            switch type[index] {
            case ",": extract(index)
            case "<": cDepth += 1
            case ">": cDepth -= 1
            case "[": fDepth += 1
            case "]": fDepth -= 1
            case "{": sDepth += 1
            case "}": sDepth -= 1
            case "(": tDepth += 1
            case ")": tDepth -= 1
            default: continue
            }
        }
        
        guard isNotNested([cDepth, fDepth, sDepth, tDepth]) else {
            throw DTypeParsingError.unclosedBracket(in: type)
        }
        
        result.append(type[start...].trimmingCharacters(in: .whitespacesAndNewlines))
        return result
    }
    
    // given a starting index, find the closing bracket
    static func findClosingBracket(in value: String, from: Int, lbr: Character, rbr: Character) throws -> Int {
        var depth = 0
        
        let start = value.index(value.startIndex, offsetBy: from)
        
        for index in value.indices where index >= start {
            let char = value[index]
            switch char {
            case rbr:
                if depth == 0 { return value.distance(from: value.startIndex, to: index) }
                depth -= 1
            case lbr:
                depth += 1
            default: continue
            }
        }
        
        throw DTypeParsingError.unclosedBracket(in: value)
    }
}

private struct Options {
    public let allowNamespaces: Bool
}

private typealias Mapper = (String, Options) throws -> String

private let ALLOWED_BOXES = [
    "BTreeMap", "BTreeSet", "Compact", "DoNotConstruct",
    "HashMap", "Int", "Linkage", "Result", "Option", "UInt", "Vec", "Map"
]

// start of vec, tuple, fixed array, part of struct def or in tuple
private let BOX_PRECEDING: Set<Character> = ["<", "(", "[", "\"", ",", " "]

private let MAPPINGS: [Mapper] = [
    // alias <T::InherentOfflineReport as InherentOfflineReport>::Inherent -> InherentOfflineReport
    alias(["<T::InherentOfflineReport as InherentOfflineReport>::Inherent"], "InherentOfflineReport", false),
    // Replace collections with base types
    alias(["VecDeque<", "BTreeSet<"], "Vec<", false),
    alias(["BTreeMap<", "HashMap<"], "Map<", false),
    // <T::Balance as HasCompact>
    cleanupCompact(),
    // Remove all the trait prefixes
    removeTraits(),
    // remove PairOf<T> -> (T, T)
    removePairOf(),
    // remove boxing, `Box<Proposal>` -> `Proposal`
    removeWrap("Box"),
    // remove generics, `MisbehaviorReport<Hash, BlockNumber>` -> `MisbehaviorReport`
    removeGenerics(),
    // alias Vec<u8> -> Bytes
    alias(["Vec<u8>", "&\\[u8\\]"], "Bytes"),
    // alias RawAddress -> Address
    alias(["RawAddress"], "Address"),
    // lookups, mapped to Address/AccountId as appropriate in runtime
    alias(["Lookup::Source"], "LookupSource"),
    alias(["Lookup::Target"], "LookupTarget"),
    // HACK duplication between contracts & primitives, however contracts prefixed with exec
    alias(["exec::StorageKey"], "ContractStorageKey"),
    // flattens tuples with one value, `(AccountId)` -> `AccountId`
    flattenSingleTuple(),
    // converts ::Type to Type, <T as Trait<I>>::Proposal -> Proposal
    removeColons()
]

private func alias(_ src: [String], _ dest: String, _ withChecks: Bool = true) -> Mapper {
    let regexes = src.map { (src: String) -> NSRegularExpression in
        let pattern = "(^\(src)|\(BOX_PRECEDING.map{"\\\($0)\(src)"}.joined(separator: "|")))"
        return try! NSRegularExpression(pattern: pattern, options: [])
    }
    return { (value, _) in
        regexes.reduce(value) { (value, regex) in
            regex.replacingMatches(in: value, options: []) { src in
                let start = value.index(value.startIndex, offsetBy: src.range.lowerBound)
                let boxChar = value[start]
                return (withChecks && BOX_PRECEDING.contains(boxChar))
                    ? "\(boxChar)\(dest)" : dest
            }
        }
    }
}

private func cleanupCompact() -> Mapper {
  return { (value, _) in
    var value = value
    
    for index in value.indices {
        let char = value[index]
        if (char != "<") { continue }
        
        let iIndex = value.distance(from: value.startIndex, to: index)
        let end = try DType.findClosingBracket(in: value, from: iIndex+1, lbr: "<", rbr: ">")
        
        if value.substr(from: end, maxLength: 14) == " as HasCompact" {
            value = "Compact<\(value.substr(from: iIndex+1, to: end-1))>"
        }
    }

    return value
  }
}

private func flattenSingleTuple() -> Mapper {
    let regex = try! NSRegularExpression(pattern: #"\(([^,]+)\)"#, options: [])
    return { (value, _) in
        regex.stringByReplacingMatches(
            in: value,
            options: [],
            range: NSRange(location: 0, length: value.count),
            withTemplate: "$1")
    }
}

private func removeTraits() -> Mapper {
    let regexes = [
        // remove all whitespaces
        (try! NSRegularExpression(pattern: "\\s", options: []), ""),
        // anything `T::<type>` to end up as `<type>`
        (try! NSRegularExpression(pattern: "(T|Self)::", options: []), ""),
        // replace `<T as Trait>::` (whitespaces were removed above)
        (try! NSRegularExpression(pattern: "<(T|Self)asTrait>::", options: []), ""),
        // replace `<T as something::Trait>::` (whitespaces were removed above)
        (try! NSRegularExpression(pattern: "<Tas[a-z]+::Trait>::", options: []), ""),
        // replace <Lookup as StaticLookup>
        (try! NSRegularExpression(pattern: "<LookupasStaticLookup>", options: []), "Lookup"),
        // replace `<...>::Type`
        (try! NSRegularExpression(pattern: "<::Type>", options: []), ""),
    ]
    return { (value, _) in
        regexes.reduce(value) { (value, repl) in
            let (regex, replace) = repl
            return regex.stringByReplacingMatches(
                in: value, options: [],
                range: NSRange(location: 0, length: value.count),
                withTemplate: replace
            )
        }
    }
}

// remove the PairOf wrappers
private func removePairOf() -> Mapper {
    return { (value, _) in
        var value = value
        var range: Range? = value.index(value.startIndex, offsetBy: 0)..<value.index(value.endIndex, offsetBy: 0)
        range = value.range(of: "PairOf<", options: [], range: range!)
        while range != nil {
            let index = value.distance(from: value.startIndex, to: range!.lowerBound)
            let start = value.distance(from: value.startIndex, to: range!.upperBound)
            let end = try DType.findClosingBracket(in: value, from: start, lbr: "<", rbr: ">")
            let type = value.substr(from: start, to: end-1)
            value = "\(value.substr(from: 0, length: index))(\(type),\(type))\(value.substr(from: end+1))"
            range = range!.lowerBound ..< value.index(value.endIndex, offsetBy: 0)
            range = value.range(of: "PairOf<", options: [], range: range!)
        }
        return value
    }
}

// remove wrapping values, i.e. Box<Proposal> -> Proposal
private func removeWrap(_ _check: String) -> Mapper {
    let check = "\(_check)<"
    return { (value, _) in
        var value = value
        var range: Range? = value.index(value.startIndex, offsetBy: 0)..<value.index(value.endIndex, offsetBy: 0)
        range = value.range(of: check, options: [], range: range!)
        while range != nil {
            let index = value.distance(from: value.startIndex, to: range!.lowerBound)
            let start = value.distance(from: value.startIndex, to: range!.upperBound)
            let end = try DType.findClosingBracket(in: value, from: start, lbr: "<", rbr: ">")
            value = "\(value.substr(from: 0, length: index))" +
                    "\(value.substr(from: start, to: end-1))" +
                    "\(value.substr(from: end+1))"
            range = range!.lowerBound ..< value.index(value.endIndex, offsetBy: 0)
            range = value.range(of: check, options: [], range: range!)
        }
        return value
    }
}

private func removeGenerics() -> Mapper {
    return { (value, _) in
        var value = value
        var index = value.index(value.startIndex, offsetBy: 0)
        while value.distance(from: index, to: value.endIndex) > 0 {
            if value[index] == "<" {
                let iIndex = value.distance(from: value.startIndex, to: index)
                // check against the allowed wrappers, be it Vec<..>, Option<...> ...
                let box = ALLOWED_BOXES.first { box in
                    let start = iIndex - box.count
                    return (start >= 0 && value.substr(from: start, length: box.count) == box) && (
                        // make sure it is stand-alone, i.e. don't catch ElectionResult<...> as Result<...>
                        start == 0 || BOX_PRECEDING.contains(value.char(at: start-1)!)
                    )
                }
                // we have not found anything, unwrap generic innards
                if box == nil {
                    let end = try DType.findClosingBracket(in: value, from: iIndex + 1, lbr: "<", rbr: ">")
                    value = "\(value.substr(from: 0, length: iIndex))\(value.substr(from: end+1))"
                    index = value.index(value.startIndex, offsetBy: iIndex)
                }
            }
            if value.distance(from: index, to: value.endIndex) > 0 {
                index = value.index(index, offsetBy: 1)
            }
        }
        return value
    }
}

private func removeColons() -> Mapper {
    return { (value, options) in
        var value = value
        var range: Range? = value.index(value.startIndex, offsetBy: 0)..<value.index(value.endIndex, offsetBy: 0)
        range = value.range(of: "::", options: [], range: range!)

        while range != nil {
            let index = value.distance(from: value.startIndex, to: range!.lowerBound)
            
            if index == 0 {
                value = String(value.substr(from: 2))
            } else if (index > 0) {
                if options.allowNamespaces {
                    return value
                }

                var start = index

                while start != -1 && !BOX_PRECEDING.contains(value.char(at: start)!) {
                  start -= 1
                }

                value = "\(value.substr(from: 0, length: start + 1))\(value.substr(from: index + 2))"
            }
            range = value.index(value.startIndex, offsetBy: 0) ..< value.index(value.endIndex, offsetBy: 0)
            range = value.range(of: "::", options: [], range: range!)
        }

        return value
    }
}
