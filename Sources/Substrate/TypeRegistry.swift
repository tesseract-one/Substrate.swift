//
//  TypeRegistry.swift
//  
//
//  Created by Yehor Popovych on 12/14/20.
//

import Foundation
import SubstratePrimitives
import ScaleCodec

public class TypeRegistry {
    private let metadata: Metadata
    
    private var _events: Dictionary<String, AnyEvent.Type> = [:]
    private var _calls: Dictionary<String, AnyCall.Type> = [:]
    private var _types: Dictionary<DType, ScaleDynamicDecodable.Type> = [:]
    
    public init(metadata: Metadata) {
        self.metadata = metadata
    }
    
    public func validate() throws {
        
    }
    
    func decode(static: DType, from decoder: ScaleDecoder) throws -> ScaleDynamicDecodable {
        guard let T = _types[`static`] else {
            throw TypeRegistryError.typeNotFound(`static`)
        }
        return try _typeDecodingError(`static`) { try T.init(from: decoder, registry: self) }
    }
}

extension TypeRegistry: TypeRegistryProtocol {
    public func register<T>(type: T.Type, as dynamic: DType) throws where T : ScaleDynamicDecodable {
        _types[dynamic] = type
    }
    
    public func register<C>(call: C.Type) throws where C : Call {
        _calls["\(C.MODULE).\(C.FUNCTION)"] = call
    }
    
    public func register<E>(event: E.Type) throws where E : Event {
        _events["\(E.MODULE).\(E.EVENT)"] = event
    }
    
    public func key(for key: AnyStorageKey) throws -> Data {
        try _metaError { try self.metadata.key(for: key, registry: self) }
    }
    
    public func prefix(for key: AnyStorageKey) throws -> Data {
        try _metaError { try self.metadata.prefix(for: key) }
    }
    
    public func defaultValue(for key: AnyStorageKey) throws -> DValue {
        try _metaError { try self.metadata.defaultValue(for: key, registry: self) }
    }
    
    public func defaultValue<K: StorageKey>(parsed key: K) throws -> K.Value {
        try _metaError { try self.metadata.defaultValue(parsed: key, registry: self) }
    }
    
    public func value(of constant: AnyConstant) throws -> DValue {
        try _metaError { try self.metadata.value(of: constant, registry: self) }
    }
    
    public func value<C>(parsed constant: C) throws -> C.Value where C : Constant {
        try _metaError { try self.metadata.value(parsed: constant, registry: self) }
    }
    
    public func decodeEvent(from decoder: ScaleDecoder) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    
    public func decode<E>(event: E.Type, from decoder: ScaleDecoder) throws -> E where E: Event {
        fatalError("Not implemented")
    }
    
    public func encode(value: ScaleDynamicEncodable, type: DType, in encoder: ScaleEncoder) throws {
        try _typeEncodingError(value) { try self._encode(value: value, type: type, in: encoder) }
    }
    
    public func decode<V>(static: V.Type, as type: DType, from decoder: ScaleDecoder) throws -> V where V : ScaleDynamicDecodable {
        guard _types[type] == `static` else {
            throw TypeRegistryError.typeNotFound(type)
        }
        return try _typeDecodingError(type) { try V(from: decoder, registry: self) }
    }
    
    public func decode(dynamic: DType, from decoder: ScaleDecoder) throws -> DValue {
        return try _typeDecodingError(dynamic) { try self._decode(type: dynamic, from: decoder) }
    }
    
    public func encode(call: AnyCall, in encoder: ScaleEncoder) throws {
        fatalError("Not implemented")
    }
    
    public func decodeCall(from decoder: ScaleDecoder) throws -> AnyCall {
        fatalError("Not implemented")
    }
    
    public func decode<C>(call: C.Type, from decoder: ScaleDecoder) throws -> C where C: Call {
        fatalError("Not implemented")
    }
}

extension TypeRegistry {
    @discardableResult
    func _metaError<T>(_ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as MetadataError {
            throw TypeRegistryError.metadata(error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    @discardableResult
    func _typeDecodingError<T>(_ type: DType, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SDecodingError {
            throw TypeRegistryError.typeDecodingError(type: type, error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    @discardableResult
    func _typeEncodingError<T>(_ value: ScaleDynamicEncodable, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SEncodingError {
            throw TypeRegistryError.encodingError(error: e, value: value)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
}
