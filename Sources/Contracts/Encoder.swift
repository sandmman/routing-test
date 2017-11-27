import Foundation
import LoggerAPI

extension CharacterSet {
    static let customURLQueryAllowed = CharacterSet(charactersIn: "\"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~=:&")
}

public class QueryEncoder: Coder, Encoder {

    private var dictionary: [String : String]
    
    public var codingPath: [CodingKey] = []
    
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    public static func encode<T: Encodable>(_ value: T) throws -> [String : String] {
        return try QueryEncoder().encode(value)
    }

    public static func encode<T: Encodable>(_ value: T) throws -> String {
        let dict: [String : String] = try QueryEncoder.encode(value)
        let desc: String = dict.map { key, value in "\(key)=\(value)" }
            .reduce("") {pair1, pair2 in "\(pair1)&\(pair2)"}
            .addingPercentEncoding(withAllowedCharacters: CharacterSet.customURLQueryAllowed)!
        return "?" + String(desc.dropFirst())
    }

    public override init() {
        self.dictionary = [:]
        super.init()
    }

    private func encodingError(_ value: Any, underlyingError: Error?) -> EncodingError {
        let fieldName = Coder.getFieldName(from: codingPath)
        let errorCtx = EncodingError.Context(codingPath: codingPath, debugDescription: "Could not process field named '\(fieldName)'.", underlyingError: underlyingError)
        return EncodingError.invalidValue(value, errorCtx)
    }
    
    func encode<T: Encodable>(_ value: T) throws -> [String : String] {
        let fieldName = Coder.getFieldName(from: codingPath)
        Log.verbose("fieldName: \(fieldName), fieldValue: \(value)")  
        switch value {
        // Ints
        case let fieldValue as Int: 
            self.dictionary[fieldName] = String(fieldValue)
        case let fieldValue as Array<Int>:
            let strs: [String] = fieldValue.map { String($0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        case let fieldValue as UInt:
            self.dictionary[fieldName] = String(fieldValue)
        case let fieldValue as Array<UInt>:
            let strs: [String] = fieldValue.map { String($0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        // Floats
        case let fieldValue as Float:
            self.dictionary[fieldName] = String(fieldValue)
        case let fieldValue as Array<Float>:
            let strs: [String] = fieldValue.map { String($0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        // Doubles     
        case let fieldValue as Double:
            self.dictionary[fieldName] = String(fieldValue)
        case let fieldValue as Array<Double>:
            let strs: [String] = fieldValue.map { String($0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        // Boolean     
        case let fieldValue as Bool:
            self.dictionary[fieldName] = String(fieldValue)
        // Strings
        case let fieldValue as String:
            self.dictionary[fieldName] = fieldValue
        case let fieldValue as Array<String>:
            self.dictionary[fieldName] = fieldValue.joined(separator: ",")
        // Dates
        case let fieldValue as Date:
            self.dictionary[fieldName] = dateFormatter.string(from: fieldValue)
        case let fieldValue as Array<Date>:
            let strs: [String] = fieldValue.map { dateFormatter.string(from: $0) }
            self.dictionary[fieldName] = strs.joined(separator: ",")
        default:
            if fieldName.isEmpty {
                try value.encode(to: self)
            } else {
                do {
                    let jsonData = try JSONEncoder().encode(value) 
                    self.dictionary[fieldName] = String(data: jsonData, encoding: .utf8)
                } catch let error {
                    throw encodingError(value, underlyingError: error)
                }       
            }           
        }
        return self.dictionary
    }    
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KeyedContainer<Key>(encoder: self))
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContanier(encoder: self)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return UnkeyedContanier(encoder: self)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var encoder: QueryEncoder
        
        var codingPath: [CodingKey] { return [] }
        
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }
            let _ = try encoder.encode(value)
        }
        
        func encodeNil(forKey key: Key) throws { }
        
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
            let _ = try encoder.encode(value)
        }
    }
}
