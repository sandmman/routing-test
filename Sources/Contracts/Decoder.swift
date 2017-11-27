import Foundation
import LoggerAPI

public class QueryDecoder: Coder, Decoder {
    public var codingPath: [CodingKey] = []
    
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        //print("In container<Key>...")
        return KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        //print("In unkeyedContainer...")
        return UnkeyedContainer(decoder: self)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        //print("In singleValueContainer...")
        return UnkeyedContainer(decoder: self)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from dictionary: [String : String]) throws -> T {
        return try QueryDecoder(dictionary: dictionary).decode(T.self)
    }
    
    private let dictionary: [String : String]

    init(dictionary: [String : String]) {
        self.dictionary = dictionary
    }

    private func throwDecodingError() throws {
        let fieldName = QueryDecoder.getFieldName(from: codingPath)
        let errorCtx = Swift.DecodingError.Context(codingPath: codingPath, debugDescription: "Could not process field named '\(fieldName)'.")
        throw Swift.DecodingError.dataCorrupted(errorCtx)
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let fieldName = QueryDecoder.getFieldName(from: codingPath)
        print("fieldName: \(fieldName)")
        let fieldValue = dictionary[fieldName]
      
        switch type {
        // Ints
        case is Array<Int>.Type:
            if let ints = fieldValue?.intArray as? T {
                return ints
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        case is Int.Type:
            if let intValue = fieldValue?.int as? T {
                return intValue
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        case is Array<UInt>.Type:
            if let uInts = fieldValue?.uIntArray as? T {
                return uInts
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        case is UInt.Type:
            if let uIntValue = fieldValue?.uInt as? T {
                print("uIntValue: \(uIntValue)")
                return uIntValue
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        // Floats
        case is Float.Type:
            if let floatValue = fieldValue?.float as? T {
                print("floatValue: \(floatValue)")
                return floatValue
            } else {
                Log.error("Could not process field named '\(fieldName)'.")            
                throw DecodingError()
            }
        case is Array<Float>.Type:
            if let floats = fieldValue?.floatArray as? T {
                return floats
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        // Doubles
        case is Double.Type:
            if let doubleValue = fieldValue?.double as? T {
                print("doubleValue: \(doubleValue)")
                return doubleValue
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        case is Array<Double>.Type:
            if let doubles = fieldValue?.doubleArray as? T {
                return doubles
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        // Boolean
        case is Bool.Type:
            if let booleanValue = fieldValue?.boolean as? T {
                print("booleanValue: \(booleanValue)")
                return booleanValue
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        // Strings
        case is String.Type:
            if let stringValue = fieldValue?.string as? T {
                print("stringValue: \(stringValue)")
                return stringValue
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        case is Array<String>.Type:
            if let strings = fieldValue?.stringArray as? T {
                return strings
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        // Dates
        case is Date.Type:
            if let stringValue = fieldValue?.string, let dateValue = QueryDecoder.dateDecodingFormatter.date(from: stringValue) as? T {
                return dateValue
            }
            else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        case is Array<Date>.Type:
            if let strings = fieldValue?.stringArray,
                let dates = (strings.map { QueryDecoder.dateDecodingFormatter.date(from: $0) }.filter { $0 != nil }.map { $0! }) as? T {
                return dates
            } else {
                Log.error("Could not process field named '\(fieldName)'.")
                throw DecodingError()
            }
        default:
            Log.verbose("Decoding: \(T.Type.self)")
            if fieldName.isEmpty {
                return try T(from: self)
            } else {    // Processing an instance member of the class/struct
                if let decodable = fieldValue?.decodable(T.self) {
                    return decodable
                } else {
                    Log.error("Could not process field named '\(fieldName)'.")
                    //https://developer.apple.com/documentation/swift/decodingerror
                    //throw DecodingError()
                    let f = Swift.DecodingError.Context(codingPath: codingPath, debugDescription: "")
                    throw Swift.DecodingError.dataCorrupted(f)
                }
            }
        }
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var decoder: QueryDecoder
        
        var codingPath: [CodingKey] { return [] }
        
        var allKeys: [Key] { return [] }
        
        func contains(_ key: Key) -> Bool {
            return true
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            return try decoder.decode(T.self)
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            //print("decodeNil, key: \(key)")
            return false
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            //print("nestedContainer: decode type \(NestedKey.Type.self) forKey \(key)")
            return try decoder.container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            //print("nestedUnkeyedContainer: decode forKey \(key)")
            return try decoder.unkeyedContainer()
        }
        
        func superDecoder() throws -> Decoder {
            return decoder
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            //print("superDecoder, key: \(key)")
            return decoder
        }
    }
    
    private struct UnkeyedContainer: UnkeyedDecodingContainer, SingleValueDecodingContainer {
        var decoder: QueryDecoder
        
        var codingPath: [CodingKey] { return [] }
        
        var count: Int? { return nil }
        
        var currentIndex: Int { return 0 }
        
        var isAtEnd: Bool { return false }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            return try decoder.decode(type)
        }
        
        func decodeNil() -> Bool {
            return true
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return self
        }
        
        func superDecoder() throws -> Decoder {
            return decoder
        }
    }
}
