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
    
    private var _events: Dictionary<String, StaticEvent.Type> = [:]
    private var _calls: Dictionary<String, StaticCall.Type> = [:]
    private var _keys: Dictionary<String, StaticStorageKey.Type> = [:]
    private var _keyPrefixes: Dictionary<Data, (module: String, field: String)> = [:]
    private var _types: Dictionary<DType, ScaleDynamicCodable.Type> = [:]
    private var _reverseTypes: Dictionary<String, DType> = [:]
    
    public var ss58AddressFormat: Ss58AddressFormat = .substrate
    
    public init(metadata: Metadata) {
        self.metadata = metadata
        for (modName, module) in metadata.modulesByName {
            for fieldName in module.storage.keys {
                let prefix = DStorageKey.prefix(module: modName, field: fieldName)
                _keyPrefixes[prefix] = (module: modName, field: fieldName)
            }
        }
    }
    
    public func validate(modules: Array<ModuleBase>? = nil) throws {
        let names = modules.map { Set($0.map { $0.name }) }
        try _validate(modules: names, types: _types, metadata: metadata)
    }
    
    func decode(static: DType, from decoder: ScaleDecoder) throws -> ScaleDynamicCodable {
        guard let T = _types[`static`] else {
            throw TypeRegistryError.typeNotFound(`static`)
        }
        return try _typeDecodingError(`static`) { try T.init(from: decoder, registry: self) }
    }
}

extension TypeRegistry: TypeRegistryProtocol {
    public func register<T>(type: T.Type, as dynamic: DType) throws where T : ScaleDynamicCodable {
        _types[dynamic] = type
        _reverseTypes[type.id] = dynamic
    }
    
    public func register<C>(call: C.Type) throws where C : Call {
        _calls["\(C.MODULE).\(C.FUNCTION)"] = call
    }
    
    public func register<E>(event: E.Type) throws where E : Event {
        _events["\(E.MODULE).\(E.EVENT)"] = event
    }
    
    public func register<K>(key: K.Type) throws where K: StorageKey {
        _keys["\(K.MODULE).\(K.FIELD)"] = key
    }
    
    public func type<T>(of t: T.Type) throws -> DType where T : DynamicTypeId {
        guard let type = _reverseTypes[t.id] else {
            throw TypeRegistryError.unknownType(t)
        }
        return type
    }
    
    public func info(forKey prefix: Data) throws -> (module: String, field: String) {
        guard let info = _keyPrefixes[prefix] else {
            throw TypeRegistryError.storageItemUnknownPrefix(prefix: prefix)
        }
        return info
    }
    
    public func hashers(forKey field: String, in module: String) throws -> [Hasher] {
        try _metaError { try self.metadata.hashers(forKey: field, in: module) }
    }
    
    public func types(forKey field: String, in module: String) throws -> [DType] {
        try _metaError { try self.metadata.types(forKey: field, in: module) }
    }
    
    public func value(defaultOf key: DStorageKey) throws -> DValue {
        try _metaError { try self.metadata.value(defaultOf: key, registry: self) }
    }
    
    public func decode(keyFrom decoder: ScaleDecoder) throws -> AnyStorageKey {
        let prefix = try _decodingError { try DStorageKey.prefix(from: decoder) }
        let info = try info(forKey: prefix)
        if let kt = _keys["\(info.module).\(info.field)"] {
            return try _decodingError {
                try kt.init(parsingPathFrom: decoder, registry: self)
            }
        } else {
            return try _decodingError  {
                try DStorageKey(module: info.module, field: info.field, decoder: decoder, registry: self)
            }
        }
    }
    
    public func value<K: StorageKey>(defaultOf key: K) throws -> K.Value {
        try _metaError { try self.metadata.value(defaultOf: key, registry: self)}
    }
    
    public func value<C: DynamicConstant>(of constant: C) throws -> DValue {
        try _metaError { try self.metadata.value(of: constant, registry: self) }
    }
    
    public func value<C: Constant>(of constant: C) throws -> C.Value {
        try _metaError { try self.metadata.value(of: constant, registry: self) }
    }
    
    public func type<C: AnyConstant>(of constant: C) throws -> DType {
        try _metaError { try self.metadata.type(of: constant) }
    }
    
    public func info(forEvent header: (module: UInt8, event: UInt8)) throws -> (module: String, event: String) {
        try _metaError {
            let mod = try self.metadata.module(index: header.module)
            let event = try mod.event(index: header.event)
            return (module: mod.name, event: event.name)
        }
    }
    
    public func types(forEvent event: String, in module: String) throws -> [DType] {
        try _metaError {
            let mod = try self.metadata.module(name: module)
            let evt = try mod.event(name: event)
            return evt.arguments
        }
    }
    
    public func decode(eventFrom decoder: ScaleDecoder) throws -> AnyEvent {
        let header = try _decodingError { try DEvent.decode(headerFrom: decoder) }
        let info = try info(forEvent: header)
        if let event = _events["\(info.module).\(info.event)"] {
            return try _eventDecodingError(module: info.module, event: info.event) {
                try event.init(decodingDataFrom: decoder, registry: self)
            }
        } else {
            return try _eventDecodingError(module: info.module, event: info.event) {
                try DEvent(module: info.module, event: info.event, decoder: decoder, registry: self)
            }
        }
    }
    
    public func encode(value: ScaleDynamicEncodable, type: DType, in encoder: ScaleEncoder) throws {
        try _typeEncodingError(value) { try self._encode(value: value, type: type, in: encoder) }
    }
    
    public func encode(dynamic: DValue, type: DType, in encoder: ScaleEncoder) throws {
        try _encode(dynamic: dynamic, type: type, in: encoder)
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
    
    public func types(forCall call: String, in module: String) throws -> [(String, DType)] {
        return try _metaError {
            try self.metadata.module(name: module).call(name: call).argumentsList
        }
    }
    
    public func info(forCall header: (module: UInt8, call: UInt8)) throws -> (module: String, call: String) {
        return try _metaError {
            let mod = try self.metadata.module(index: header.module)
            let call = try mod.call(index: header.call)
            return (module: mod.name, call: call.name)
        }
    }
    
    public func header(forCall call: String, in module: String) throws -> (module: UInt8, call: UInt8) {
        return try _metaError {
            let mod = try self.metadata.module(name: module)
            let call = try mod.call(name: call)
            return (module: mod.index, call: call.index)
        }
    }
    
    public func decode(callFrom decoder: ScaleDecoder) throws -> AnyCall {
        let header = try _decodingError { try DCall.decode(headerFrom: decoder) }
        let info = try info(forCall: header)
        if let call = _calls["\(info.module).\(info.call)"] {
            return try _callDecodingError(module: info.module, funct: info.call) {
                try call.init(decodingParamsFrom: decoder, registry: self)
            }
        } else {
            return try _callDecodingError(module: info.module, funct: info.call) {
                try DCall(module: info.module, function: info.call, decoder: decoder, registry: self)
            }
        }
    }
}

extension TypeRegistry {
    var meta: Metadata { metadata }
    
    func _eventDecodingError<T>(module: String, event: String, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SDecodingError {
            throw TypeRegistryError.eventDecodingError(module: module, event: event, error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    func _callDecodingError<T>(module: String, funct: String, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SDecodingError {
            throw TypeRegistryError.callDecodingError(module: module, function: funct, error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    func _decodingError<T>(_ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SDecodingError {
            throw TypeRegistryError.decoding(error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
//    @discardableResult
//    func _callEncodingError<T>(_ call: AnyCall, _ f: @escaping () throws -> T) throws -> T {
//        do {
//            return try f()
//        } catch let e as TypeRegistryError {
//            throw e
//        } catch let e as SEncodingError {
//            throw TypeRegistryError.callEncodingError(call: call, error: e)
//        } catch {
//            throw TypeRegistryError.unknown(error: error)
//        }
//    }
    
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
