import Foundation

public class QueryEncoder: Coder, Encoder {
    
    public var codingPath: [CodingKey] = []
    
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    public func encode<T: Encodable>(_ value: T) {

        
        switch value {
        case let v as Int:
            print("\(codingPath.flatMap({"\($0)"}).joined(separator: ".")) = Int \(value)")
        case let v as UInt:
           print("\(codingPath) = UInt \(value)")
        case let v as Float:
            print("\(codingPath) = Float \(value)")
        case let v as Double:
            print("\(codingPath) = Double \(value)")
        case let v as Bool:
            print("\(codingPath) = Bool \(value)")
        case let v as String:
            print("\(codingPath.flatMap({"\($0)"}).joined(separator: ".")) = String \(value)")
        default:
            print("Encoding \(T.Type.self)")
            try! value.encode(to: self)
        }
    }
    
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        //print("container")
        return KeyedEncodingContainer(KeyedContainer<Key>(encoder: self))
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        //print("unkeyed container")
        return UnkeyedContanier(encoder: self)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        //print("single value container")
        return UnkeyedContanier(encoder: self)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var encoder: QueryEncoder
        
        var codingPath: [CodingKey] { return [] }
        
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            //print("Keyed container \(value) \(key)")
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }
            try encoder.encode(value)
        }
        
        func encodeNil(forKey key: Key) throws {}
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return encoder.unkeyedContainer()
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return encoder
        }
    }
    
    private struct UnkeyedContanier: UnkeyedEncodingContainer, SingleValueEncodingContainer {
        var encoder: QueryEncoder
        
        var codingPath: [CodingKey] { return [] }
        
        var count: Int { return 0 }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return self
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
        
        func encodeNil() throws {}
        
        func encode<T>(_ value: T) throws where T : Encodable {
            //print("UnKeyed container \(value)")
            try encoder.encode(value)
        }
    }
}
