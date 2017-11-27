import Foundation

public class QueryEncoder: Coder, Encoder {

    private var dictionary: [String : String]
    
    public var codingPath: [CodingKey] = []
    
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    public init() {
        self.dictionary = [:]
    }
    
    public func encode<T: Encodable>(_ value: T) throws -> [String : String] {
        print("In encode() 1")
        let fieldName = QueryEncoder.getFieldName(from: codingPath)   
        switch value {
        // Ints
        case let v as Int:
            self.dictionary[fieldName] = String(v)
            print("\(fieldName) = Int \(value)")
        case let v as Array<Int>:
            let strs: [String] = v.map { String($0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        case let v as UInt:
            self.dictionary[fieldName] = String(v)
        case let v as Array<UInt>:
            let strs: [String] = v.map { String($0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        // Floats
        case let v as Float:
            self.dictionary[fieldName] = String(v)
            print("\(codingPath) = Float \(value)")
        case let v as Array<Float>:
            let strs: [String] = v.map { String($0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        // Doubles     
        case let v as Double:
            self.dictionary[fieldName] = String(v)
            print("\(codingPath) = Double \(value)")
        case let v as Array<Double>:
            let strs: [String] = v.map { String($0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        // Boolean     
        case let v as Bool:
            self.dictionary[fieldName] = String(v)
            print("\(codingPath) = Bool \(value)")
        // Strings
        case let v as String:
            self.dictionary[fieldName] = v
        case let v as Array<String>:
            self.dictionary[fieldName] = v.joined(separator: ",")
        // Dates
        case let v as Date:
            self.dictionary[fieldName] = QueryEncoder.dateDecodingFormatter.string(from: v)
        case let v as Array<Date>:
            let strs: [String] = v.map { QueryEncoder.dateDecodingFormatter.string(from: $0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        default:
            print("Encoding \(T.Type.self)")
            if fieldName.isEmpty {
                try value.encode(to: self)
            } else {
                if let jsonData = try? JSONEncoder().encode(value) {
                    self.dictionary[fieldName] = String(data: jsonData, encoding: .utf8)
                }  else {
                    throw EncodingError()
                }           
            }           
        }
        return self.dictionary
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
             print("In encode() 2")
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
