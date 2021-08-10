//
//  TraceBlockResponse.swift
//  
//
//  Created by Yehor Popovych on 10.08.2021.
//

import Foundation

public enum TraceBlockResponse: Codable, Equatable {
    case traceError(TraceError)
    case blockTrace(BlockTrace)
    
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
        guard let key = container2.allKeys.first else {
            throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
        }
        switch key {
        case .blockTrace:
            self = try .blockTrace(container2.decode(BlockTrace.self, forKey: key))
        case .traceError:
            self = try .traceError(container2.decode(TraceError.self, forKey: key))
        default:
            throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .blockTrace(let t):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(t, forKey: .blockTrace)
        case .traceError(let e):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(e, forKey: .traceError)
        }
    }
}

private extension CodableComplexKey where T == TraceBlockResponse {
    static let traceError = Self(stringValue: "TraceError")!
    static let blockTrace = Self(stringValue: "BlockTrace")!
}

public struct TraceError: Codable, Equatable {
    public let error: String
}

public struct BlockTrace: Codable, Equatable {
    public let blockHash: String
    public let parentHash: String
    public let tracingTargets: String
    public let storageKeys: String
    public let spans: Array<BlockTraceSpan>
    public let events: Array<BlockTraceEvent>
}

public struct BlockTraceEvent: Codable, Equatable {
    public let target: String
    public let data: BlockTraceEventData
    public let parentId: UInt64?
}

public struct BlockTraceEventData: Codable, Equatable {
    public let stringValues: Dictionary<String, String>
}

public struct BlockTraceSpan: Codable, Equatable {
    public let id: UInt64
    public let parentId: UInt64?
    public let name: String
    public let target: String
    public let wasm: Bool
}
