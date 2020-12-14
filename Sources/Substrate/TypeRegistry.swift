//
//  TypeRegistry.swift
//  
//
//  Created by Yehor Popovych on 12/14/20.
//

import Foundation
import Primitives
import ScaleCodec


public class TypeRegistry: Primitives.TypeRegistry {
    private let _events: Dictionary<String, Event.Type>
    private let _calls: Dictionary<String, Call.Type>
    private let _types: Dictionary<SType, ScaleRegistryDecodable.Type>
    
    public let metadata: Metadata
    
    public required init(metadata: Metadata) throws {
        self.metadata = metadata
    }
    
    
    public func decodeEvent(from decoder: ScaleDecoder) throws -> AnyEvent {
        <#code#>
    }
    
    public func registerEvent<E>(_ t: E.Type) throws where E : Event {
        <#code#>
    }
    
    public func encode<V>(value: V, type: SType, in encoder: ScaleEncoder) throws where V : ScaleRegistryEncodable {
        <#code#>
    }
    
    public func decodeValue(type: SType, from decoder: ScaleDecoder) throws -> ScaleRegistryDecodable {
        <#code#>
    }
    
    public func registerType<T>(_ t: T.Type, as type: SType) throws where T : ScaleRegistryDecodable {
        <#code#>
    }
    
    public func encode<C>(call: C, in encoder: ScaleEncoder) throws where C : AnyCall {
        <#code#>
    }
    
    public func decodeCall(from decoder: ScaleDecoder) throws -> AnyCall {
        <#code#>
    }
    
    public func registerCall<C>(_ t: C.Type) throws where C : Call {
        <#code#>
    }
}
