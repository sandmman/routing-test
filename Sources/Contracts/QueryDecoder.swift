import Foundation
import LoggerAPI

public class QueryDecoder: Coder, Decoder {
    public var codingPath: [CodingKey] = []

    public var userInfo: [CodingUserInfoKey : Any] = [:]

    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedContainer(decoder: self)
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return UnkeyedContainer(decoder: self)
    }

    // public static func decode<T: Decodable>(_ type: T.Type, from dictionary: [String : String]) throws -> T {
    //     return try QueryDecoder(dictionary: dictionary).decode(T.self)
    // }

    public var dictionary: [String : String]

    public init(dictionary: [String : String]) {
        self.dictionary = dictionary
        super.init()
    }

    private func decodingError() -> DecodingError {
        let fieldName = Coder.getFieldName(from: codingPath)
        let errorMsg = "Could not process field named '\(fieldName)'."
        Log.error(errorMsg)
        let errorCtx = DecodingError.Context(codingPath: codingPath, debugDescription: errorMsg)
        return DecodingError.dataCorrupted(errorCtx)
    }

    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let fieldName = Coder.getFieldName(from: codingPath)
        let fieldValue = dictionary[fieldName]
        Log.verbose("fieldName: \(fieldName), fieldValue: \(String(describing: fieldValue))")

        switch type {
        // Ints
        case is Array<Int>.Type:
            if let ints = fieldValue?.intArray as? T {
                return ints
            } else {
                throw decodingError()
            }
        case is Int.Type:
            if let intValue = fieldValue?.int as? T {
                return intValue
            } else {
                throw decodingError()
            }
        case is Array<UInt>.Type:
            if let uInts = fieldValue?.uIntArray as? T {
                return uInts
            } else {
                throw decodingError()
            }
        case is UInt.Type:
            if let uIntValue = fieldValue?.uInt as? T {
                return uIntValue
            } else {
                throw decodingError()
            }
        // Floats
        case is Float.Type:
            if let floatValue = fieldValue?.float as? T {
                return floatValue
            } else {
                throw decodingError()
            }
        case is Array<Float>.Type:
            if let floats = fieldValue?.floatArray as? T {
                return floats
            } else {
                throw decodingError()
            }
        // Doubles
        case is Double.Type:
            if let doubleValue = fieldValue?.double as? T {
                return doubleValue
            } else {
                throw decodingError()
            }
        case is Array<Double>.Type:
            if let doubles = fieldValue?.doubleArray as? T {
                return doubles
            } else {
                throw decodingError()
            }
        // Boolean
        case is Bool.Type:
            if let booleanValue = fieldValue?.boolean as? T {
                return booleanValue
            } else {
                throw decodingError()
            }
        // Strings
        case is String.Type:
            if let stringValue = fieldValue?.string as? T {
                return stringValue
            } else {
               throw decodingError()
            }
        case is Array<String>.Type:
            if let strings = fieldValue?.stringArray as? T {
                return strings
            } else {
                throw decodingError()
            }
        // Dates
        case is Date.Type:
            if let dateValue = fieldValue?.date(dateFormatter) as? T {
                return dateValue
            }
            else {
                throw decodingError()
            }
        case is Array<Date>.Type:
            if let dates = fieldValue?.dateArray(dateFormatter) as? T {
                return dates
            } else {
                throw decodingError()
            }
        default:
            Log.verbose("Decoding: \(T.Type.self)")
            if fieldName.isEmpty {
                return try T(from: self)
            } else {    // Processing an instance member of the class/struct
                if let decodable = fieldValue?.decodable(T.self) {
                    return decodable
                } else {
                    throw decodingError()
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
            return false
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return try decoder.unkeyedContainer()
        }

        func superDecoder() throws -> Decoder {
            return decoder
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
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
